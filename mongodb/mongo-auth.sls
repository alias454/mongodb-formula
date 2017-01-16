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

{% set name = salt['pillar.get']('mongodb:lookup:admin_db:name') %}
{% set passwd = salt['pillar.get']('mongodb:lookup:admin_db:passwd') %}
{% set user = salt['pillar.get']('mongodb:lookup:admin_db:user') %}
{% set password = salt['pillar.get']('mongodb:lookup:admin_db:password') %}
{% set database = salt['pillar.get']('mongodb:lookup:admin_db:database') %}
{% set authdb = salt['pillar.get']('mongodb:lookup:admin_db:authdb') %}
{% set defined_role = 'executeEval' %}

mongodb-create-admin-account:
  module.run:
    - name: mongodb.user_create
    - m_name: {{ name }}
    - passwd: {{ passwd }}
    - database: {{ database }}
    - authdb: {{ authdb }}
    - host: {{ config.mongodb.local_net_bindip }}
    - port: {{ config.mongodb.net_port }}
    - require:
      - pip: pip-package-install-pymongo
      - service: service-mongod
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getUser('{{ name }}')" {{ database }} |grep user

comand-mongodb-create-{{ defined_role }}-role:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval 
        "db.createRole({role:'{{ defined_role }}',privileges:[{resource:{anyResource: true},actions:['anyAction']}],roles:[]})"
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getRoles()" {{ database }} |grep {{ defined_role }} 

comand-mongodb-grant-{{ defined_role }}-role-to-admin:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval 
        "db.grantRolesToUser('{{ name }}',[{role:'{{ defined_role }}',db:'{{ database }}'}])"
    - output_loglevel: quiet
    - require:
      - cmd: comand-mongodb-create-{{ defined_role }}-role
    - unless: mongo -u {{ name }} -p {{ passwd }} --quiet --eval "db.getUser('{{ name }}')" {{ database }} |grep {{ defined_role }}

{% endif %} # security_auth
{% endif %} # use_security_auth
{% endif %} # run_states
