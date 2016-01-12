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
