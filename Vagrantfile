# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # We define two VMs in the developer environment:
  #   1. cnx-deploy: The VM that we use to execute the deployment using Ansible
  #   2. cnx-target: The target VM for the deployment (e.g. where the local
  #      local CNX environment will be provisioned)
  #
  # The setup defines static IPs for the VMs on a private network so we can set
  # /etc/hosts appropriately. If the use of the 10.0.10.0/24 subnet happens to
  # conflict with your environment, you may  need to modify the addresses
  # accordingly.

  config.vm.define "cnx-target" do |host|
    host.vm.hostname = "cnx-target"
    host.vm.box = "bento/ubuntu-16.04"
    host.vm.network "private_network", ip: "10.0.10.10"

    host.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", 2048]
    end
  end

  config.vm.define "cnx-deploy" do |host|
    host.vm.hostname = "cnx-deploy"
    host.vm.box = "bento/ubuntu-18.04"
    host.vm.network "private_network", ip: "10.0.10.2"

    host.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", 1024]
    end

    host.vm.provision "shell", inline: <<-SHELL
      # Delete vault file as it's not needed for development
      rm -f /vagrant/group_vars/all/vault.yml
      # Configure /etc/hosts if needed
      if [ ! -n "$(grep 10.0.10.10 /etc/hosts)" ]; then
        echo "10.0.10.10 local.cnx.org archive.local.cnx.org authoring.local.cnx.org legacy.local.cnx.org zope.local.cnx.org" >> /etc/hosts
      fi
      # Inject the ssh private key for target VM into the deployer
      if [ ! -f "/home/vagrant/.ssh/id_rsa" ]; then
        cp /vagrant/.vagrant/machines/cnx-target/virtualbox/private_key /home/vagrant/.ssh/id_rsa
        chown vagrant:vagrant /home/vagrant/.ssh/id_rsa
      fi
      # Setup ansible.cfg
      if [ ! -f "/home/vagrant/.ansible.cfg" ]; then
        echo "[defaults]" > /home/vagrant/.ansible.cfg
        echo "host_key_checking = False" >> /home/vagrant/.ansible.cfg
        chown vagrant:vagrant /home/vagrant/.ansible.cfg
      fi
    SHELL

    # Run playbook to setup /etc/hosts on target host
    host.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "configure_hosts.yml"
      ansible.inventory_path = "environments/vm/inventory"
      ansible.limit = "all"
      ansible.verbose = "-vvv"
    end

    # Run main playbook
    host.vm.provision "ansible_local" do |ansible|
      ansible.playbook = "main.yml"
      ansible.inventory_path = "environments/vm/inventory"
      ansible.limit = "all"
      ansible.verbose = "-vvv"
    end
  end
end
