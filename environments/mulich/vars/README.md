# Include Variables

This directory contains files that are read into a playbook via the [include_vars module](https://docs.ansible.com/ansible/include_vars_module.html).

The contents of these files are suppose to be mutable. The user is expected to change the files to meet the specific needs of the scenario.

Directories like this in other adjacent environment are immutable, because they have been created for specific environments where the variables are absolute.

You may want to ignore the changes if you are working on the project. In that case, use ``git update-index --assume-unchanged environments/local/vars``.
