# Development environment

This inventory is used to provision and update the staging servers.

The servers are at ``*staging00.cnx.org``.

## Prerequisite

You will need an SSH public key in your homedir for any CNX server that authenticates against LDAP.

Make sure you have sudo access to the hosts.

You will also need the vault password to decrypt the file at
``environments/prod/group_vars/all/vault.yml``.

## Usage

For provisioning:

```sh
ansible-playbook -i environments/staging/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
