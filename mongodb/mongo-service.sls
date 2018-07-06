{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Make sure the service is running and restart the service unless
# restart_service_after_state_change is false
service-mongod:
  service.running:
    - name: mongod
    - enable: True
    - init_delay: 5
    - require:
      - pkg: package-install-mongodb
  {% if config.mongodb.restart_service_after_state_change == 'true' %}
    - watch:
      - file: /etc/mongod.conf
  {% endif %}
