{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Create user if use_replica_set == true only if
# node is master. trying to create user on downstream servers
# will result in errors
{% set run_states = 'false' %}
{% if config.mongodb.use_replica_set == 'true' %}
  {% if config.mongodb.is_master == 'true' %}
    {% set run_states = 'true' %}
  {% endif %}
{% else %}
{% set run_states = 'false' %}
{% endif %}

# Setup default admin user if auth == true
{% if run_states == 'true' %}
{% if config.mongodb.use_security_auth == 'true' %}
{% if config.mongodb.security_auth == 'enabled' %}

# The admin account has to exist or states will fail.
# If trying to create the admin account we assume it is
# the first account and don't use user,password,authdb
{% set database = 'admin' %}
{% set admin_user = salt['pillar.get']('mongodb:lookup:admin_user') %}
{% set admin_passwd = salt['pillar.get']('mongodb:lookup:admin_passwd') %}
mongodb-create-admin-account:
  cmd.run:
    - name: >-
        echo 'db = db.getSiblingDB("{{ database }}"),
        db.createUser({ user: "{{ admin_user }}", pwd: "{{ admin_passwd }}", roles: [{ role: "root", db: "{{ database }}" }] });'
        | mongo
    - output_loglevel: quiet
    - require:
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "db.getUser('{{ admin_user }}')" |grep user

# Create proper roles to allow invoking eval from the shell
# Set the defined role name
{% set defined_role = 'executeEval' %}

# Create the defined role
comand-mongodb-create-{{ defined_role }}-role:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval
        "db.createRole({role:'{{ defined_role }}',privileges:[{resource:{anyResource: true},actions:['anyAction']}],roles:[]})"
    - output_loglevel: quiet
    - require:
      - cmd: mongodb-create-admin-account
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "db.getRoles()" |grep {{ defined_role }}

# Grant role to admin user
comand-mongodb-grant-{{ defined_role }}-role-to-admin:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval
        "db.grantRolesToUser('{{ admin_user }}',[{role:'{{ defined_role }}',db:'{{ database }}'}])"
    - output_loglevel: quiet
    - require:
      - cmd: comand-mongodb-create-{{ defined_role }}-role
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "db.getUser('{{ admin_user }}')" |grep {{ defined_role }}``

# After the admin user is created, setup additional managed dbs
{% for db in salt['pillar.get']('mongodb:lookup:managed_dbs') %}
    {% set authDB = 'admin' %}
    {% set database = db.database %}
    {% set user = db.user %}
    {% set passwd = db.passwd %}

# Creating users requires admin authentication
mongodb-create-{{ user }}-account:
  cmd.run:
    - name: >-
        echo 'db = db.getSiblingDB("{{ database }}"),
        db.createUser({ user: "{{ user }}", pwd: "{{ passwd }}", roles: [{ role: "dbOwner", db: "{{ database }}" }] });'
        | mongo {{ authDB }} -u {{ admin_user }} -p {{ admin_passwd }}
    - output_loglevel: quiet
    - require:
      - cmd: mongodb-create-admin-account
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ user }} -p {{ passwd }} --quiet --eval "db.getUser('{{ user }}')" |grep user

{% endfor %} # end managed_dbs loop

{% endif %} # security_auth
{% endif %} # use_security_auth
{% endif %} # run_states
