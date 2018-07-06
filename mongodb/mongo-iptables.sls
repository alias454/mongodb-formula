{% from "mongodb/map.jinja" import host_lookup as config with context %}
{% if config.firewall.iptables.status == 'Active' %}

# add some firewall magic
include:
  - firewall.iptables

# Only enable firewall rules if use_replica_set == true
{% if config.mongodb.use_replica_set == 'true' %}

# Loop through list of sources and create firewall rules
{% for node in config.mongodb.sources %}

#-A INPUT -p tcp -m state --state NEW -m tcp --dport 27017 -j ACCEPT        
iptables-firewall-rule-mongo-replica-set-allowed-{{ node.name }}:
  iptables.insert:
    - position: 2
    - table: filter
    - chain: INPUT
    - match: state
    - connstate: NEW
    - proto: tcp
    - comment: "mongodb-replica-set"
    - source: {{ node.ip }}{{ node.mask }}
    - dport: {{ node.port }}
    - jump: ACCEPT
    - save: True 

{% endfor %}

iptables-firewall-rule-allow-established:
  iptables.insert:
    - position: 1
    - table: filter
    - chain: INPUT
    - match: state
    - connstate: ESTABLISHED,RELATED
    - jump: ACCEPT
    - save: True

iptables-firewall-rule-allow-lo:
  iptables.insert:
    - position: 1
    - table: filter
    - chain: INPUT
    - match: state
    - connstate: NEW
    - source: '127.0.0.1'
    - jump: ACCEPT
    - save: True

iptables-firewall-rule-allow-ssh:
  iptables.insert:
    - position: 1
    - table: filter
    - chain: INPUT
    - match: state
    - connstate: NEW
    - proto: tcp
    - dport: 22
    - jump: ACCEPT
    - save: True

iptables-firewall-rule-reject:
  iptables.append:
    - position: 101
    - table: filter
    - chain: INPUT
    - jump: REJECT
    - save: True

{% endif %}
{% endif %}
