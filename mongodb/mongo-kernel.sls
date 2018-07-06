# Configure grub command for RHEL based systems
{% if salt.grains.get('os_family') == 'RedHat' %}
  {% set grub_command = 'grub2-mkconfig -o /boot/grub2/grub.cfg' %}
# Configure grub command for Debian based systems
{% elif salt.grains.get('os_family') == 'Debian' %}
  {% set grub_command = 'grub-mkconfig -o /boot/grub/grub.cfg' %}
{% endif %}

# Disable transparent hugepages
mongodb-/etc/default/grub:
  file.replace:
    - name: /etc/default/grub
    - pattern: quiet
    - repl: quiet transparent_hugepage=never
    - onlyif: grep "quiet\"" /etc/default/grub

# Rebuild the grub config
command-rebuild-mongodb-grub-cfg:
  cmd.run:
    - name: {{ grub_command }}
    - onchanges:
      - file: /etc/default/grub

# Set resource limits for the mongo user
/etc/security/limits.d/90-mongodb.conf:
  file.managed:
    - user: root
    - group: root
    - mode: '0644'
    - contents: |
        # Managed by Salt do not edit
        # Set resource limits for mongod user
        mongod soft nofile 64000
        mongod hard nofile 64000
        mongod soft nproc 32000
        mongod hard nproc 32000

