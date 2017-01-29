# Install mongodb from a package
package-install-mongodb:
  pkg.installed:
    - pkgs:
      - epel-release   # Base install
      - policycoreutils-python   # Base install
      - numactl
      - mongodb-org
    - refresh: True
    - require:
      - file: /etc/yum.repos.d/MongoDB-3.4.repo

# Install pip
pip-install-mongodb:
  pkg.installed:
    - pkgs:
      - python2-pip
    - refresh: True
    - require:
      - pkg: package-install-mongodb

# Upgrade older versions of pip
pip-upgrade-mongodb:
  cmd.run:
    - name: pip install --upgrade pip
    - onlyif: pip list --outdated --format=legacy |grep pymongo 
    - require:
      - pkg: pip-install-mongodb

# This is needed for mongodb_* states to work in the same Salt job
pip-package-install-pymongo:
  pip.installed:
    - name: pymongo
    - reload_modules: True
    - require:
      - pkg: package-install-mongodb
      - cmd: pip-upgrade-mongodb
