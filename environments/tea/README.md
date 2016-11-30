# Development environment

This inventory is used to provision and update the TEA project's servers.

The servers are ``tea##.cnx.org`` (00-01 at this time)

## Prerequisite

You will need an SSH public key in your homedir for any CNX server that authenticates against LDAP.

Make sure you have sudo access to both the ``tea##`` hosts. Chances are if you can access one, you'll be able to access all of them.

You will also need the vault password to decrypt the file at
``environments/tea/group_vars/all/vault.yml``.

## Usage

For provisioning:

```sh
ansible-playbook -i environments/tea/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
