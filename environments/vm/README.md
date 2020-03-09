# Virtual Machine environment

This inventory is used to provision a virtual machine with the ``*.local.cnx.org`` domains.

## Prerequisite

You should add the following to your host system's ``/etc/hosts`` file when using this environment.

```
<vm-ip-address>  local.cnx.org archive.local.cnx.org authoring.local.cnx.org legacy.local.cnx.org zope.local.cnx.org
```

## Usage

Set up the ``/etc/hosts`` file on the vm:

```sh
ansible-playbook -i environments/vm/inventory configure_hosts.yml
```

For provisioning the cnx-suite onto a VM:

```sh
rm group_vars/all/vault.yml  # this is not necessary for development
ansible-playbook -i environments/vm/inventory main.yml
```

This will run the ``main.yml`` playbook on the systems within the vm inventory. At this time that includes ``local.cnx.org``.

The above command assumes that you have setup the system to use an *SSH keypair* and have setup the authenticated user with *passwordless sudo* access. If you didn't setup passwordless sudo, append the ``--ask-become-pass`` option to the ``ansible-playbook`` command.

## Using Vagrant
There is a `Vagrantfile` in the root of the project which can be used to deploy a local environment with minimal assumptions about your host environment. It automates the basic bootstrapping of a deployment node (`cnx-deploy`) and then uses the built-in `ansible-local` provisioner to install Ansible plus execute the playbooks above from that VM against a `cnx-target` VM. You will need to install the following dependencies on your machine to make use of this tool:

* [Virtualbox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)

Once installed, you can kickoff the deployment by simply running `vagrant up` from the root of this repository. If you get a failure along the way, you can try `vagrant up --provision` to see if it is able to succeed. You can use commands such as `vagrant ssh cnx-target` to ssh into the VMs, etc. as needed.
