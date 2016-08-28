# CTE development environment

This inventory is used to provision and update the CTE feature development servers.

The CTE servers are ``cte-legacy-dev.cnx.org`` & ``cte-cnx-dev.cnx.org``, use respectively got deploy an instance of zope and the cnx-suite. Also, ``cte-cnx-dev.cnx.org`` has the following host names pointing to it: ``archive-cte-cnx-dev.cnx.org``, ``authoring-cte-cnx-dev.cnx.org`` and ``legacy-cte-cnx-dev.cnx.org``.

## Prerequisite

You will need an SSH public key in your homedir for any CNX server that authenticates against LDAP.

Make sure you have sudo access to both the ``cte-legacy-dev`` and ``cte-cnx-dev`` hosts.

You will also need the vault password to decrypt the file at
``environments/cte-dev/group_vars/all/vault.yml``.

## Usage

For provisioning the cnx-suite onto a VM:

```sh
ansible-playbook -i environments/cte-dev/inventory main.yml --ask-become-pass --ask-vault-pass
```

This will run the ``main.yml`` playbook on the systems.
