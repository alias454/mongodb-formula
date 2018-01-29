# Disable transparent hugepages
mongodb-/etc/default/grub:
  file.replace:
    - name: /etc/default/grub
    - pattern: rhgb quiet
    - repl: rhgb quiet transparent_hugepage=never
    - onlyif: grep "rhgb quiet\"" /etc/default/grub

# Rebuild the grub config
command-rebuild-mongodb-grub-cfg:
  cmd.run:
    - name: grub2-mkconfig -o /boot/grub2/grub.cfg
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

