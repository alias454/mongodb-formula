{% from "mongodb/map.jinja" import host_lookup as config with context %}

include:
  - .mongo-repo
  - .mongo-prereqs
  - .mongo-package
  - .mongo-config
  - .mongo-selinux
  - .mongo-kernel
  - .{{ config.firewall.firewall_include }}
  - .mongo-service
  - .mongo-replication
  - .mongo-auth
