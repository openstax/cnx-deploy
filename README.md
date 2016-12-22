# Connexions Deployment

The currently supported operating system (OS) is: Ubuntu 16.04 LTS (Xenial)


## Installation

It goes without saying that you should use a [virtualenv](https://virtualenv.readthedocs.org/en/latest/), but it's outside the scope of this documentation to explain that. So use a virtualenv for your own protection.

To install the necessary dependencies run:

```sh
pip install -r requirements.txt
```

After this, read the ``README.md`` document inside the environments directory you are working with. For example, if you are setting up the site within a VM, look at the ``environments/vm/README.md`` file.

It is recommended that you be able to run this setup and deploy on your local system using a VM or the host system itself (see the supported architectures above) before trying to deploy to a shared environment (and/or production environment). After this, you and everyone else around you will feel more comfortable giving you keys to deploy to a shared environment.

If you need assistance setting up a local VM for this project, see the Creating a VM section below.

## General usage

The generalized usage looks something like this:

```sh
export ENV=vm
ansible-playbook -i environments/$ENV/inventory main.yml
```

Please see the environment's README for specific details.

## Troubleshooting

1. Search through the issues on github. If you find the issue, check for a resolution. If there is no resolution, let your voice be heard and wait for a reply.

2. Please file a issue on github for this project.

3. Please treat the problem as a challenge and try to fix it! =)

If you have questions, put those in a github issue as well.

## Environments

To view the available environments, run ``ls environments/``. Within the environment directory, look for documentation in a ``README.md`` file or at the head of the ``inventory`` file.

## Q&A

**Q**: Why doesn't this install an [OpenStax Accounts](https://github.com/openstax/accounts) instance?

**A**: There is already a working ansible playbook for installing accounts within [tutor-deployment](https://github.com/openstax/tutor-deployment). There is no reason to replicate that effort here.


**Q**: Why is this not a part of [tutor-deployment](https://github.com/openstax/tutor-deployment)?

**A**: Connexions is a distinctly separate entity that is availble for use outside the OpenStax ecosystem, therefore it should be independently buildable. And It's hard to see the forest through the trees, meaning, there is a lot of stuff going on in tutor-deployment.






## Setting up OpenStax Accounts

You will need an instance of [OpenStax Accounts](https://github.com/openstax/accounts) either installed locally or out in the interwebs. If you are connecting to one in the interweb, you will need to contact a sys admin (or devops) person to register for an api key/secret pair.

Continue reading if you need help setting up Accounts locally.

If you are running Accounts locally, you can setup the key/secret pair yourself.

### Installing OpenStax Accounts

Create a virtual machine (VM). As of writing this, it will only install on Ubuntu 14.02.

Find the IP address of the VM and then make the following registration in your ``/etc/hosts`` file:

```
192.168.x.x  accounts.local.openstax.org
```

Replace ``192.168.x.x`` with the IP address in your VM.

Run the custom play!

```sh
ansible-playbook -i environments/local-accounts-vm/inventory provision_accounts.yml
```

#### Running accounts commands

To run one of the accounts rake commands use:

```sh
RAILS_ENV=production RBENV_ROOT=/home/ostaccounts/.rbenv/ rbenv exec bundle exec rake
```

Make sure to run this command as 'ostaccounts'.
