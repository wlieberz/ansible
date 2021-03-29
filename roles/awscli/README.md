Role Name
=========

The role checks if awscli is installed, and installs it if not installed.

The role assumes that the remote host might not be able to pull the installer from AWS, but that the Ansible host can, so the installer zip is downloaded locally on the Ansible host, then copied to the remote host, unzipped, then the installer is run. Finally, the installer dir and installer zip are removed from the remote host.

All steps are idempotent. 

See Role Variables.

Requirements
------------

None that I'm aware of.

Role Variables
--------------

Please see the variables in defaults/main.yml. You should be able to run the role without needing to override the default values of the vars, but the option is open to you should you need, for example, to change the package to 32-bit, etc.

Dependencies
------------

None.

Example Playbook
----------------

- hosts: INVENTORY-HOSTGROUP
  roles:
    - awscli

License
-------

BSD

Author Information
------------------

William Lieberz
