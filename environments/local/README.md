# Local Environment

This will deploy the system locally:

```sh
ansible-playbook -i environments/local/inventory local.yml --ask-become-pass
```

The ``local.yml`` file is the playbook which installs the system locally (your machine), which is defined in the ``environments/local/inventory`` file.
The ``local.yml`` playbook is almost identical to ``main.yml`` except that it contains certain fixes to allow things to run locally rather than remotely.
The ``--ask-become-pass`` will ask for your sudo password once and use it many times throughout the playbook.

This environment can also be used with the ``plone.yml`` playbook if your host machine runs Ubuntu.
