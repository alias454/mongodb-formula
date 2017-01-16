================
mongodb-formula
================

A saltstack formula to manage mongodb on RHEL based systems.

.. note::

    See the full `Salt Formulas installation and usage instructions
    <http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html>`_.

Available states
================

.. contents::
    :local:

``mongo-repo``
------------
Manage repo file on RHEL/CentOS 7 systems.

``mongo-package``
------------
Install mongodb and additional prerequisite packages

``mongo-config``
------------
Manage configuration file placement

``mongo-selinux``
------------
Setup selinux rule to allow mongodb communication

``mongo-kernel``
------------
Apply kernal tweaks and system tuning options

``mongo-firewalld``
------------
Optionally setup firewalld rules for mongodb replication and disable iptables
Requires the firewall-formula or another method of managing the firewalld service

``mongo-service``
------------
Sets up the mongodb service and makes sure it is running on RHEL/CentOS 7 systems.

``mongo-replication``
------------
Enable and configure replica sets

``mongo-auth``
------------
Configure authentication on mongodb

