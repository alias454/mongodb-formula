{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Don't create user if use_replica_set == true
# unless node is master. trying to create user
# on downstream servers results in error
{% set run_states = 'false' %}
{% if config.mongodb.use_replica_set == 'true' %}
  {% if config.mongodb.is_master == 'true' %}
    {% set run_states = 'true' %}
  {% endif %}
{% else %}
{% set run_states = 'true' %}
{% endif %}

# Setup default admin user if auth == true
{% if run_states == 'true' %}
{% if config.mongodb.use_security_auth == 'true' %}
{% if config.mongodb.security_auth == 'enabled' %}

{% set defined_role = 'executeEval' %}
{% for db in salt['pillar.get']('mongodb:lookup:managed_dbs') %}
    {% set name = db.name %}
    {% set passwd = db.passwd %}
    {% set user = db.user %}
    {% set password = db.password %}
    {% set database = db.database %}
    {% set authdb = db.authdb %}

# If creating the first user there won't be any
# authentication available. If trying to create the
# admin account on the admin DB we assume it is
# the first pass and don't use user,password,authdb
mongodb-create-{{ name }}-account:
  module.run:
    - name: mongodb.user_create
    - m_name: {{ name }}
    - passwd: {{ passwd }}
    - database: {{ database }}
  {% if database != 'admin' %}
    - user: {{ user }}
    - password: {{ password }}
    - authdb: {{ authdb }}
  {% endif %}
    - host: {{ config.mongodb.local_net_bindip }}
    - port: {{ config.mongodb.net_port }}
  {% if name == 'admin' %}
    - roles:
      - root
  {% else %}
    - roles:
      - dbOwner
  {% endif %}
    - require:
      - pip: pip-package-install-pymongo
      - service: service-mongod
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getUser('{{ name }}')" {{ database }} |grep user

# Check for admin DB. The admin account has to exist
# or states will fail. Adding these roles allow
# using mongo salt modules to perform actions 
# on DBs otherwise gets an eval() error. 
{% if database == 'admin' %}

# Create the defined role
comand-mongodb-create-{{ defined_role }}-role:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval 
        "db.createRole({role:'{{ defined_role }}',privileges:[{resource:{anyResource: true},actions:['anyAction']}],roles:[]})"
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getRoles()" {{ database }} |grep {{ defined_role }} 

# Grant role to user
comand-mongodb-grant-{{ defined_role }}-role-to-admin:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval 
        "db.grantRolesToUser('{{ name }}',[{role:'{{ defined_role }}',db:'{{ database }}'}])"
    - output_loglevel: quiet
    - require:
      - cmd: comand-mongodb-create-{{ defined_role }}-role
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getUser('{{ name }}')" {{ database }} |grep {{ defined_role }}

{% endif %} # check database
{% endfor %} # end managed_dbs loop

{% endif %} # security_auth
{% endif %} # use_security_auth
{% endif %} # run_states
