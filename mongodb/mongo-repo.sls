# Configure repo file for RHEL based systems

/etc/yum.repos.d/MongoDB-3.4.repo:
  file.managed:
    - source: salt://mongodb/files/MongoDB-3.4.repo
    - user: root
    - group: root
    - mode: '0644'
