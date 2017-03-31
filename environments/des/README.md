# Development environment

This inventory is used to provision and update the feature development (desarrollo en espanol) servers.

The servers are ``des##.cnx.org`` (00-03 at this time)

## Prerequisite

You will need an SSH public key in your homedir for any CNX server that authenticates against LDAP.

Make sure you have sudo access to both the ``des##`` hosts. Chances are if you can access one, you'll be able to access all of them.

You will also need the vault password to decrypt the file at
``environments/des/group_vars/all/vault.yml``.

## Usage

For provisioning the cnx-suite onto a VM:

```sh
ansible-playbook -i environments/des/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
