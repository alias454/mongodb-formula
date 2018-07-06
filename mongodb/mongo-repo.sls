{% from "mongodb/map.jinja" import host_lookup as config with context -%}

# Configure repo file for RHEL based systems
{% if salt.grains.get('os_family') == 'RedHat' %}
mongodb_repo:
  pkgrepo.managed:
    - name: MongoDB
    - comments: |
        # Managed by Salt Do not edit
        # MongoDB repository for {{ config.package.repo_version }} packages
    - baseurl: {{ config.package.repo_baseurl }}
    - gpgcheck: 1
    - gpgkey: {{ config.package.repo_gpgkey }}
    - enabled: 1

# Configure repo file for Debian based systems
{% elif salt.grains.get('os_family') == 'Debian' %}
# Import keys for pfring
#command-apt-key-mongodb:
  #cmd.run:
    #- name: apt-key adv --keyserver {{ config.package.repo_key }}
    #- unless: apt-key list mongodb

mongodb_repo:
  pkgrepo.managed:
    - name: {{ config.package.repo_baseurl }} /
    - file: /etc/apt/sources.list.d/mongodb-org.list
    - comments: |
        # Managed by Salt Do not edit
        # MongoDB repository for {{ config.package.repo_version }} packages (Debian) 
    - keyserver: {{ config.package.repo_keyserver }}
    - keyid: {{ config.package.repo_key }}
{% endif %}
