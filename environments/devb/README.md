# Development environment

This inventory is used to provision and update the feature development servers.

The server is ``devb.cnx.org``

## Prerequisite

You will need an SSH public key in your homedir for any CNX server that authenticates against LDAP.

Make sure you have sudo access to ``devb.cnx.org``.

You will also need the vault password to decrypt the file at
``environments/devb/group_vars/all/vault.yml``.

## Usage

For provisioning the cnx-suite onto a VM:

```sh
ansible-playbook -i environments/devb/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
