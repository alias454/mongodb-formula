{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Setup replica set if use_replica_set == true
{% if config.mongodb.use_replica_set == 'true' %}
{% if config.mongodb.is_master == 'true' %}

{% set replset_config = {'_id': config.mongodb.replication_replsetname, 'members': []} %}
{% set name = salt['pillar.get']('mongodb:lookup:admin_db:name') %}
{% set passwd = salt['pillar.get']('mongodb:lookup:admin_db:passwd') %}
{% set user = salt['pillar.get']('mongodb:lookup:admin_db:user') %}
{% set password = salt['pillar.get']('mongodb:lookup:admin_db:password') %}
{% set database = salt['pillar.get']('mongodb:lookup:admin_db:database') %}
{% set authdb = salt['pillar.get']('mongodb:lookup:admin_db:authdb') %}
{% set server = [] %}

{% for node in config.mongodb.sources %}
{% do server.append(node.name) %}

# ideas for handling replica sets were influenced
# from https://github.com/mitodl/mongodb-formula
{% if node.master == 'true' %}

mongodb-initiate-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} --quiet --eval
        "rs.initiate()"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - pip: pip-package-install-pymongo
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }} 

mongodb-status-{{ node.name }}-replset:
  cmd.run:
    - name: |
        until [ `mongo {{ database }} --quiet --eval \
        'rs.status()' |grep -i PRIMARY |wc -l` -eq 1 ]
        do
          sleep 1
        done
        sleep 5 # Add a brief extra wait for things to settle
    - shell: /bin/bash
    - output_loglevel: quiet
    - require_in:
      - module: mongodb-create-admin-account 
    - require:
      - cmd: mongodb-initiate-{{ node.name }}-replset 
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }} 

mongodb-reconfig-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval
        "cfg = rs.conf(); cfg.members[0].host = '{{ node.fqdn }}:{{ node.port }}'; rs.reconfig(cfg);"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }} 

{% elif node.arbiter == 'true' %}

mongodb-add-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval
        "rs.add('{{ node.fqdn }}:{{ node.port }}, true')"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
      - pip: pip-package-install-pymongo
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

{% else %}

mongodb-add-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval
        "rs.add('{{ node.fqdn }}:{{ node.port }}')"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
      - pip: pip-package-install-pymongo
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

{% endif %}
{% endfor %}

{% endif %}
{% endif %}