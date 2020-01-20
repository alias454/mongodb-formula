{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Setup replica set if use_replica_set == true
{% if config.mongodb.use_replica_set == 'true' %}
{% if config.mongodb.is_master == 'true' %}

# The admin account has to exist or states will fail.
{% set database = 'admin' %}
{% set admin_user = salt['pillar.get']('mongodb:lookup:admin_user') %}
{% set admin_passwd = salt['pillar.get']('mongodb:lookup:admin_passwd') %}

# Iterate through list of nodes and add them to replica set
{% set server = [] %}
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
        'rs.initiate({_id: "{{ config.mongodb.replication_replsetname }}", members: [{"_id":0, "host":"{{ node.fqdn }}:{{ node.port }}"}]})'
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

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
      - cmd: mongodb-create-admin-account
    - require:
      - cmd: mongodb-initiate-{{ node.name }}-replset
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

# After the replica set has been initialized
# reconfigure the cluster so our defined node
# has a higher priority and set the fqdn
mongodb-reconfig-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval
        "cfg = rs.conf(); cfg.members[0].priority = 2; cfg.members[0].host = '{{ node.fqdn }}:{{ node.port }}'; rs.reconfig(cfg);"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - cmd: mongodb-create-admin-account
      - cmd: comand-mongodb-grant-executeEval-role-to-admin
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

{% elif node.arbiter == 'true' %}

# If the node is an arbiter
mongodb-add-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval
        "rs.add('{{ node.fqdn }}:{{ node.port }}, true')"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - cmd: mongodb-create-admin-account
      - cmd: comand-mongodb-grant-executeEval-role-to-admin
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

{% else %}

# Otherwise it is a full member of the replica set
mongodb-add-{{ node.name }}-replset:
  cmd.run:
    - name: >-
        mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval
        "rs.add('{{ node.fqdn }}:{{ node.port }}')"
    - shell: /bin/bash
    - output_loglevel: quiet
    - require:
      - cmd: mongodb-create-admin-account
      - cmd: comand-mongodb-grant-executeEval-role-to-admin
      - file: {{ config.mongodb.security_keyfile  }}
      - service: service-mongod
    - unless: mongo {{ database }} -u {{ admin_user }} -p {{ admin_passwd }} --quiet --eval "rs.status()" |grep {{ node.fqdn }}:{{ node.port }}

{% endif %}
{% endfor %}

{% endif %}
{% endif %}
