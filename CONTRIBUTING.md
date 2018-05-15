# Contributing

Submit issues for any questions or problems that occur. Please use the following format when creating issues.

## Issues

When submitting an issue please be sure to include a summary of the issue and the environment in which the issue is occuring.

The following issue template can be used to help expedite the process:

```
## Summary

Put a summary of the issue here... Do you have a traceback? What have you tried so far?

## Environment

Put your environment here... What is the name of the environment you are using (i.e ``environments/___``)? What is the OS name and version that you are deploying on.

```

The summary can be the traceback and the actions you have taken thus far.

The environment should be the name of the environment you are using (i.e ``environments/___``) and the OS name and version that you are deploying on.

## Style

Ansible playbooks are written in YAML.

### YAML

This project prefers that you not use the ``key=value`` style when declaring a subvalue.

Please use the following style:

```yml
  apt:
    name: python
    state: present
```

Do NOT use this style:

```yml
  apt: name=python state=present
```

### Layout

When creating templates or files, put them in the same directory you intend them to end up in on the destination filesystem. For example:

```yml
- name: configure postgres role connection trust
  become: yes
  template:
    src: etc/postgresql/_/main/pg_hba.conf
    dest: "/etc/postgresql/{{ postgres_version }}/main/pg_hba.conf"
    owner: postgres
    group: postgres
    mode: 0640
  notify:
    - reload postgresql
```

In this example the template file is put in `./templates/etc/postgresql/_/main/pg_hba.conf`. The `./templates` directory is either relative to the role or global playbook. The template file does not require a template file extension. Be assured that it is a template if it is in the templates directory. Lastly, for variable directorys like version numbers, the `_` directory can be used to specify something of a dynamic nature.

### Global Playbooks

The ansible best practice this project follows is to use the main/site playbook with supporting playbooks organized by host group (e.g. database and nfs).

The exception to this rule is for specific operations or usecases that support the main playbook or have specific environmental needs. Where possible it is recommended that the environment's inventory or tags be used to limit and narrow the scope of an existing playbook to fill the usecase.

We follow this best practice so that we can limit the number of playbooks in the root of this project, thus making the project clean and easier to maintain.
