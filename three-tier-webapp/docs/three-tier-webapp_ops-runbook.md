# Ops runbook

This document covers getting a server from a base (unconfigured) state to serving the full three-tier-webapp application stack.

## Ansible set-up:

Before you can use any of the Ansible playbooks described below, your Ansible environment must be properly configured.

There are many ways to do this. This is what works for me. I have successfully used this method on Ubuntu 20.04, Fedora 32, and RHEL 7. Commands may differ on Windows or MacOS.

**From a high level:**

* Set-up a Python3 virtual env (venv).
* Activate the venv.
* Install Ansible and dependencies within the venv.
* Configure Ansible via ansible.cfg.
* Set-up the Ansible vault password. 

**Detailed steps:**

I like to create a directory in my home directory for all my python virtual envs.

First ensure you have virtualenv installed. If you have multiple versions of python installed, you should install virtualenv for the version of Python you wish to use within your env. You can do that with something like this:

`python3 -m pip install virtualenv`

Create virtual-env:

    mkdir ~/env
    cd ~/env
    python3 -m virtualenv -p /path/to/your/python3 name-of-your-new-venv


Now, you can activate the virtual-env:

`source ~/venv/<name of your venv>/bin/activate`

Optionally, if you want to double-check, you can verify your version of python within the venv. For instance, on Ubuntu 20.04 there is no default python, you must specify either python2 or python3 at the shell, however once the venv is activated you can simply:

    ```
    venv$ python --version
    Python 3.8.2

    ```

Now would be a good time to upgrade pip within the venv:
`python -m pip install --upgrade pip`

Install Ansible. The IaC code was written and tested with Ansible version 2.9.13, so if you want you can install that specific version, or just get the latest.

Specific version:

`pip install 'ansible==2.9.13'`

Latest version:

`pip install ansible`

You need paramiko installed.

`pip install paramiko`

Now, you need to configure Ansible. You can have several Ansible conf files, the one in the present working directory will take precedence. There is a conf file incuded in the root of this repo, so as long as you execute playbooks from the repo root, you shouldn't need to worry about configuration. However, there are a few things to be aware of regarding the configuration. 

For ansible-vault to be able to decrypt encrypted variables on-the-fly during playbook execution, there is a reference in the conf file to a file in your home directory which stores the vault password. This file needs to be manually created. The password file should be locked down such that you are the only person who can read the file, eg `chmod 400 ~/.ansible/.three-tier-webapp_vault-pass`. 

If your workstation's hard drive is not encrypted at rest or if you are not comfortable storing the ansible-vault password in plaintext on your workstation, you can optionally comment out the line in ansible.cfg like so:

`# vault_password_file = ~/.ansible/.three-tier-webapp_vault-pass`

If you do decide to comment out the `vault_password_file` directive, as above, whenever you run a playbook which relies on an encrypted variable, it needs to be run with an extra flag to ask you for the vault password interactively, for example:

`ansible-playbook playbooks/deploy-code.yml --ask-vault-pass`

A basic verification that your ansible is working and that you communicate with the server:

`ansible three-tier-webapp -m ping`

Should return results like:

    three-tier-webapp | SUCCESS => {
        "ansible_facts": {
            "discovered_interpreter_python": "/usr/bin/python"
        },
        "changed": false,
        "ping": "pong"
    }

Finally, a note on credentials. First you need the ansible-vault password for decrypting encrypted content in this repo, e.g `vars/passwd.yml`. Next, you need an account on the three-tier-webapp server with appropiate sudo rights. Even if you have an ssh key on the server, you will need to know your server-account password, unless your account is configured for sudo nopasswd.

## Server configuration:

**Note: this "server configuration" subsection is intended for Sys Admins when initially provisioning the server. If you are merely looking to deploy code updates on an already provisioned server, you can safely skip this section.**

As of the time of writing we assume the server is Red Hat Enterprise Linux 7.7. At the time of writing all services run on a single server.

From the root of the this repo, provision the server with:

`ansible-playbook site.yml` 


After running this, the server should have all dependencies installed and configured such that you can then do the following:

**Post provisioning tasks (covered later in the document):**
* Import the database schema & empty database.
* Transfer database data to the server for import.
* Unpack and import the data into the database. 
* Deploy the full code stack.
* Deploy updates to the code stack as needed.
* Clean and re-import database schema changes and data.

## Database Operations:

#### Drop MySQL database:

You may need or want to drop the MySQL database in order to redefine the schema and re-import the data.

From the root of this repo:

`ansible-playbook playbooks/drop-database-three-tier-webapp.yml --limit three-tier-webapp`
 

#### Create database/schema from SQL script:

After dropping the database (see above) you will want to recreate the database and import the schema.

From the root of the this repo:

`ansible-playbook playbooks/import-schema-three-tier-webapp.yml --limit three-tier-webapp`

Note: for this to succeed, you must place the latest version of the schema file into the correct place. From the root of this repo place the schema file  in: `playbooks/files/` .
TODO: automate this.


#### Importing data into the database:

With the database in an initialized (with schema) but empty state, the following needs to occur:

**High-level steps:**
* Transfer the tarred data to the server for import.
* Set-up environment for running the database import script.
* Run the db import python script.
* Clean-up import staging area to re-claim disk space.


##### Transfer data to server for import:

Any users who needs to be able to transfer data to the server needs to be added to the local group `data-importers` and should have a login on the server.

To copy data from where it is generated, this rsync command may be used:

`rsync -vrlth --progress ./data-out.tar.gz $USER@three-tier-webapp.example.com:/data/three-tier-webapp/data-import/`

##### DB import script set-up:

The server has a local user `deployment-user`. Users can be added to the `deployers` local posix group which will allow them to become the deployment-user via sudo.

After ssh'ing into the server, become the deployment-user:

`sudo -u deployment-user bash -i`

Activate the venv for running the import scripts. 
`source ~/import-env/bin/activate`


For your convenience, the env has already been configured for the deployment-user, so the above steps to become the deployment-user and activate the env should be all that is necessary. For the sake of completeness, here are the steps which were taken to set-up the venv:

###### Virtual env set-up:

*These steps are very similar to the Ansible set-up earlier in this document.*

* Create virtual-env:
  * `virtualenv -p /bin/python3 import-env`

* Activate virtual-env:
  * `source import-env/bin/activate`

  * The build (next step) fails without devel headers. You shouldn't need to do this (Ansible provisioning takes care of this on the server), but just to capture this requirement, it would be: `sudo yum install python3-devel.x86_64`

* Finally, install the requirements:
  * `pip install -r requirements.txt`

## Code Deployment:

Deploy **full code stack**:

From the root of this repo, run:

`ansible-playbook playbooks/deploy-code.yml`

You will require appropiate sudo permissions on the server to run this. You can expect this command to take around 6.5 minutes to complete.

The deploy-code playbook does the following:

1. Clones app repo to the server if not present or does a fresh pull if present.
2. Runs yarn to build node modules and install dependencies. 
3. Runs ``yarn build-prod`` which builds the api-server (back-end), reactjs front-end, and any shared components to make the application components ready to serve. 
4. Cleans the web root directory. 
5. Copies the newly built web root directory to where nginx expects to serve it.
6. Restarts the nginx service.

7. Puts the `secrets.json` file in the correct location and locks down permissions on the file. Required for the api-server to be able to communicate with the database.
8. Fix permissions on api-server directories. 
9. Restarts the api-server systemd service. 
