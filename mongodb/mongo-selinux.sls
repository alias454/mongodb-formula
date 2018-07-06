# Configure selinux allowed port
{% if grains['os_family'] == 'RedHat' %}
command-mongodb-tcp-27017-port:
  cmd.run:
    - name: semanage port -a -t mongod_port_t -p tcp 27017
    - unless: semanage port -l |grep mongo |grep 27017
    - require-in:
      - service: service-mongod
    - require:
      - pkg: package-install-mongodb
{% endif %}
