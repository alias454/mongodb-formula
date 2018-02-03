{% from "mongodb/map.jinja" import host_lookup as config with context %}
{% if config.firewall.firewalld.status == 'Active' %}

# add some firewall magic
include:
  - firewall.firewalld

# Only enable firewall rules if use_replica_set == true
{% if config.mongodb.use_replica_set == 'true' %}

# Create XML configuration file for firewalld service
/etc/firewalld/services/mongodb-replica-set.xml:
  file.managed:
    - source: salt://mongodb/files/mongodb-replica-set.xml
    - user: root
    - group: root
    - mode: '0640'

# This may be irrelevant
command-restorecon-mongodb-/etc/firewalld/services:
  cmd.run:
    - name: restorecon -R /etc/firewalld/services
    - unless:
      - ls -Z /etc/firewalld/services/mongodb-replica-set.xml| grep firewalld_etc_rw_t

# Reload firewalld so mongo rules take effect
command-mongodb-firewalld-reload:
  cmd.run:
    - name: firewall-cmd --reload

# Loop through list of sources and create firewall rules
{% for node in config.mongodb.sources %}

# Add permanent rule enabled on restarts
command-add-perm-rich-rule-mongodb-replica-set-{{ node.name }}:
  cmd.run:
    - name: firewall-cmd --zone=internal --add-rich-rule="rule family="ipv4" source address="{{ node.ip }}{{ node.mask }}" service name="mongodb-replica-set" accept" --permanent
    - onchanges_in:
      - cmd: command-mongodb-firewalld-reload
    - require:
      - cmd: command-restorecon-mongodb-/etc/firewalld/services
    - unless: firewall-cmd --zone=internal --list-all |grep {{ node.ip }}{{ node.mask }} |grep mongodb-replica-set

{% endfor %}
{% endif %}
{% endif %}
