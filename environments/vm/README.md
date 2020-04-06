# Virtual Machine environment

This inventory is used to provision a virtual machine with the ``*.local.cnx.org`` domains. There are two approaches you can take in order to deploy to a VM:

1. Manually run `ansible-playbook` on your host and point it to run against a VM that you've created manually.
2. Use Vagrant for a fully automated deployment without running / installing `ansible` on your host OS

## Option 1: Run `ansible` on your host targeting a manually created VM

### Prerequisite

You should add the following to your host system's ``/etc/hosts`` file when using this environment to target a VM you've created / configured.

```
<vm-ip-address>  local.cnx.org archive.local.cnx.org authoring.local.cnx.org legacy.local.cnx.org zope.local.cnx.org
```

### Usage

Set up the ``/etc/hosts`` file on the vm:

```sh
ansible-playbook -i environments/vm/inventory configure_hosts.yml
```

For provisioning the cnx-suite onto a VM:

```sh
rm group_vars/all/vault.yml  # this is not necessary for development
ansible-playbook -i environments/vm/inventory main.yml
```

This will run the ``main.yml`` playbook on the systems within the vm inventory. At this time that includes ``local.cnx.org``.

The above command assumes that you have setup the system to use an *SSH keypair* and have setup the authenticated user with *passwordless sudo* access. If you didn't setup passwordless sudo, append the ``--ask-become-pass`` option to the ``ansible-playbook`` command.

## Option 2: Automated deployment using Vagrant
There is a `Vagrantfile` in the root of the project which can be used to deploy a local environment with minimal assumptions about your host environment. It automates the basic bootstrapping of a deployment node (`cnx-deploy`) and then uses the built-in `ansible-local` provisioner to install Ansible plus execute the playbooks above from that VM against a `cnx-target` VM. You will need to install some dependencies on your machine to make use of this tool.

### Step 1: Install dependencies

1. Install [Virtualbox](https://www.virtualbox.org/) on your host OS
2. Install [Vagrant](https://www.vagrantup.com/) on  your host OS

### Step 2: Kickoff deployment with Vagrant
You can kickoff the deployment by running the following command from the root of this repository:

```sh
vagrant up
```

The above command will run for quite a while, but as long as you continue to see output from `ansible` it's making progress. At the end, you should end up with something like the following when successful (note the `PLAY RECAP` line with `failed=0`):

```sh
TASK [notify slack] ************************************************************
task path: /vagrant/tasks/notify_slack.yml:4
skipping: [local.cnx.org] => (item=#cnx-stream)  => {
    "ansible_loop_var": "item",
    "changed": false,
    "item": "#cnx-stream",
    "skip_reason": "Conditional result was False"
}
skipping: [local.cnx.org] => (item=#deployments)  => {
    "ansible_loop_var": "item",
    "changed": false,
    "item": "#deployments",
    "skip_reason": "Conditional result was False"
}
META: ran handlers
META: ran handlers
PLAY RECAP *********************************************************************
local.cnx.org              : ok=512  changed=204  unreachable=0    failed=0    skipped=196  rescued=0    ignored=2
```

**NOTE:** Users have observed issues where they get a failure during the deployment. Sometimes (e.g. when there's not an underlying issue in the playbooks) invoking a second provisioning pass seems to address the issue (we know this isn't a desirable characteristic, and we hope to address the root cause). You can do this by running the following:

```sh
vagrant provision cnx-deploy
```

### Step 3: Login to the target VM and browse the services
You can use the standard `vagrant` commands to ssh into the VMs, etc. as needed. For example, running the following will ssh you into the VM with the cnx stack installed:

```sh
vagrant ssh cnx-target
```

Since the `Vagrantfile` is configured to set the target VM with IP `10.0.10.10`, if you configure your ``/etc/hosts`` with the following line you can access services via `local.cnx.org`, etc. in your browser:

```
10.0.10.10 local.cnx.org archive.local.cnx.org authoring.local.cnx.org legacy.local.cnx.org zope.local.cnx.org
```

**NOTE:** Since the certificates are self-signed, you will likely get some browser-specific nagging.

### Step 4: Basic lifecycle of the environment
If you want to close your VMs but not completely lose the deployment, you can run the following to place the VMs into saved state:

```sh
vagrant suspend
```

If you want to completely destroy the VMs and underlying resources in VirtualBox, you can run the following:

```sh
vagrant destroy
```

In both cases, a subsequent `vagrant up` will restart the environment. If you make changes to the deployment scripts and want to test, you can run the following:

```sh
vagrant provision cnx-deploy
```

### Debugging issues
#### Issue: I can't connect to my VM after deployment
If your VM deploys successfully, but you can't connect to `https://local.cnx.org`, there may be some networking issue. Here are suggested ways to debug / test:

* Run `vagrant port cnx-target` and confirm that it displays port 80 as being mapped from guest to host
    * If the port is missing, double check your configuration and / or try running `vagrant reload`
* Run `curl -ik https://10.0.10.10` to test for response from the server
    * If this shows a `301` response then you may have forgotten to update your `/etc/hosts`
* Run `ping 10.0.10.10`
    * If you don't get ping responses, there may be a routing issue on your host. This is most often due to a conflict with either a VPN or your home / office network configuration. Depending on your host OS, check and see if the traffic to the 10.0.10.0/24 subnet is pointing at a `vboxnet` (or similarly appropriate) interface:
        * macOS: `netstat -rn`
        * Linux: `route -n`
        * Windows: `route print`
    * If you confirm a route conflict, you can either:
        * Employ a temporary fix: If you can remove the conflicting route (e.g. by closing a VPN connection), do that and then:
            1. Delete the corresponding `vboxnet` network from VirtualBox's Host Network Manager
            2. Run `vagrant reload`. This will cause the network to be recreated, and the corresponding route to be inserted.
        * Employ a user local "permanent" fix: Modify the IP address ranges in the `Vagrantfile` as needed to avoid a conflict (e.g. replace all occurences of 10.0.10 with X.Y.Z where the X.Y.Z.0/24 subnet won't conflict). Once updated, you should also:
            1. Run `vagrant destroy` followed by `vagrant up` to do a full rebuild
            2. Update your `/etc/hosts` with the select IP address (e.g. instead of 10.0.10.10 use X.Y.Z.10)
