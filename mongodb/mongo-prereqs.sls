# Install epel if running RHEL based system
{% if grains['os_family'] == 'RedHat' %}
package-install-prereqs-mongodb:
  pkg.installed:
    - pkgs:
      - epel-release             # Base install
      - policycoreutils-python   # Base install
      - numactl
    - refresh: True
{% endif %}
