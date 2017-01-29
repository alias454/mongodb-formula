{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Setup replica set if use_replica_set == true
{% if config.mongodb.use_replica_set == 'true' %}
{% if config.mongodb.is_master == 'true' %}

{% set server = [] %}
{% for db in salt['pillar.get']('mongodb:lookup:managed_dbs') %}
{% if db.name == 'admin' %}
    {% set name = db.name %}
    {% set passwd = db.passwd %}
    {% set user = db.user %}
    {% set password = db.password %}
    {% set database = db.database %}
    {% set authdb = db.authdb %}

{% for node in config.mongodb.sources %}
{% do server.append(node.name) %}

# ideas for handling replica sets were influenced
# from https://github.com/mitodl/mongodb-formula
{% if node.master == 'true' %}

# Initiate the replica set with default settings
# on the defined master
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

# Run until replica set has initialized
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

# After the replica set has been initialized
# rconfigure the cluster so our defined node 
# has a higher priority and set the fqdn
mongodb-reconfig-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval
        "cfg = rs.conf(); cfg.members[0].priority = 2; cfg.members[0].host = '{{ node.fqdn }}:{{ node.port }}'; rs.reconfig(cfg);"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - module: mongodb-create-admin-account 
    - unless: mongo {{ database }} -u {{ name }} -p {{ passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }} 

{% elif node.arbiter == 'true' %}

# If the node is an arbiter 
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

# Otherwise it is a full member of the replica set
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

{% endif %} # check db.database
{% endfor %} # end user loop

{% endif %}
{% endif %}
