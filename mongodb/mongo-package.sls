{% from "mongodb/map.jinja" import host_lookup as config with context %}

# Install mongodb from a package
package-install-mongodb:
  pkg.installed:
    - pkgs:
      - mongodb-org
    - refresh: True
    - require:
      - pkgrepo: mongodb_repo
