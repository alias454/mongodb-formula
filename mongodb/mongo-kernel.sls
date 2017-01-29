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
    - source: salt://mongodb/files/90-mongodb.conf
    - user: root
    - group: root
    - mode: '0644'
