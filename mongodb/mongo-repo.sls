{% from "mongodb/map.jinja" import host_lookup as config with context -%}

# Configure repo file for RHEL based systems
{% if salt.grains.get('os_family') == 'RedHat' %}
mongodb_repo:
  pkgrepo.managed:
    - name: MongoDB
    - comments: |
        # Managed by Salt Do not edit
        # MongoDB repository for {{ config.mongodb.repo_version }} packages
    - baseurl: {{ config.mongodb.repo_baseurl }}
    - gpgcheck: 1
    - gpgkey: {{ config.mongodb.repo_gpgkey }}
    - enabled: 1
{% endif %}
