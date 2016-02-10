# Virtual Machine environment

This inventory is used to provision a virtual machine with the ``*.local.cnx.org`` domains.

## Prerequisite

You should add the following to your host system's ``/etc/hosts`` file when using this environment.

```
<vm-ip-address>  local.cnx.org archive.local.cnx.org authoring.local.cnx.org legacy.local.cnx.org zope.local.cnx.org
```

## Usage

For provisioning the cnx-suite onto a VM:

```sh
ansible-playbook -i environments/vm/inventory main.yml
```

This will run the ``main.yml`` playbook on the systems within the vm inventory. At this time that includes ``local.cnx.org``.

The above command assumes that you have setup the system to use an *SSH keypair* and have setup the authenticated user with *passwordless sudo* access. If you didn't setup passwordless sudo, append the ``--ask-become-pass`` option to the ``ansible-playbook`` command.

For provisioning the zope application onto a VM:

```sh
ansible-playbook -i environments/vm/inventory plone.yml
```

The difference here is the use of the ``plone.yml`` playbook. (In the future, this playbook may merge into ``main.yml``.
