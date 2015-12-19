# Connexions Deployment

The Darwin deployments are experimental at best.

## Prerequisites

### OpenStax Accounts

You will need an instance of [OpenStax Accounts](https://github.com/openstax/accounts) either installed locally or out in the interwebs. If you are connecting to one in the interweb, you will need to contact n sys admin (or devops) person to register for an api key/secret pair.

If you need help setting up Accounts locally, see the info labeled Installing OpenStax Accounts in the Appendix section of this document.

If you are running Accounts locally, you can setup the key/secret pair yourself.

### Darwin (aka OS X)

You will need to install [XCode](https://developer.apple.com/xcode/) and the XCode tools. After you've installed XCode, the XCode tools can be installed via the commandline using: ``xcode-select --install``

You will need to install [Homebrew](http://brew.sh/), which is a package manager for OS X.

The Darwin install will always be a **Use At Your Own Risk** scenario. It is available, but it will likely dip into periods of disrepair.

## Installation

It goes without saying that you should use a [virtualenv](https://virtualenv.readthedocs.org/en/latest/), but it's outside the scope of this documentation to explain that. So wear a virtualenv for your own protection. Thank you.

```sh
pip install -r requirements.txt
```

## Troubleshooting

1. Search through the issues on github. If you find the issue, check for a resolution. If there is no resolution, let your voice be heard and wait for a reply.

2. Please file a issue on github for this project.

3. Please treat the problem as a challenge and try to fix it! =)

If you have questions, put those in a github issue as well.

## Environments

### Local

Deploying the system locally:

```sh
ansible-playbook -i environments/local/inventory local.yml --ask-become-pass
```

The ``local.yml`` file is the playbook which installs the system locally (your machine), which is defined in the ``environments/local/inventory`` file.
The ``--ask-become-pass`` will ask for your sudo password once and use it many times throughout the playbook.

## Q&A

**Q**: Why doesn't this install an [OpenStax Accounts](https://github.com/openstax/accounts) instance?

**A**: There is already a working ansible playbook for installing accounts within [tutor-deployment](https://github.com/openstax/tutor-deployment). There is no reason to replicate that effort here.


**Q**: Why is this not a part of [tutor-deployment](https://github.com/openstax/tutor-deployment)?

**A**: Connexions is a distinctly separate entity that is availble for use outside the OpenStax ecosystem, therefore it should be independently buildable. And It's hard to see the forest through the trees, meaning, there is a lot of stuff going on in tutor-deployment.

## Appendix

### Discovering info about your system


To inspect you local environment run:

```sh
ansible local -i environments/local/inventory -m setup
```

### Creating a VM

This can be tricky for some... If you have questions, just ask. This VM will need to be passwordless (via an ssh key) and sudo should not ask for a password. 

### Installing OpenStax Accounts

Create a virtual machine (VM). 

Find the IP address of the VM and then make the following registration in your ``/etc/hosts`` file:

```
192.168.x.x  accounts.local.openstax.org
```

Replace ``192.168.x.x`` with the IP address in your VM.

Run the custom play!

```sh
ansible-playbook -i environments/local-accounts-vm/inventory provision_accounts.yml
```
