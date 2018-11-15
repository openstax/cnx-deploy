# Development environment

This inventory is used to provision and update the Katalyst server.

The server is ``autodev01.cnx.org``

## Prerequisite

You will need an SSH public key in your homedir for this server. It does not have LDAP.

Make sure you have sudo access to the ``autodev01`` host.

You will also need the vault password to decrypt the file at
``environments/autodev01/group_vars/all/vault.yml``.

## Usage

For provisioning the cnx-suite onto a VM:

```sh
ansible-playbook -i environments/autodev01/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
