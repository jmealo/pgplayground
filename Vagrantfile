# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  config.vm.box = "trusty64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/trusty/20150611/trusty-server-cloudimg-amd64-vagrant-disk1.box"

  config.vm.network "public_network", bridge: 'en0: Wi-Fi (AirPort)'

  config.vm.synced_folder './scripts', '/vagrant/scripts'

  config.vm.provider "virtualbox" do |vb|
    # Virtualbox Name
    vb.customize ["modifyvm", :id, "--name", "PostgreSQL", "--ostype", "Ubuntu_64"]

    # Memory
    vb.customize ["modifyvm", :id, "--memory", "4096"]

    #CPU up to 4 cores and ioapic
    vb.customize ["modifyvm", :id, "--ioapic", "on"]
    vb.customize ["modifyvm", :id, "--cpus", "4"]
    vb.customize ["modifyvm", :id, "--pae", "on"]

    # Chipset (Supposedly better CPU performance)
    vb.customize [ "modifyvm", :id, "--chipset", "ich9" ]

    # NIC 1 (Better TCP over NAT performance, at least on Windows)
    #vb.customize ["modifyvm", :id, "--nic1", "nat", "--nictype1", "virtio"] 
    #vb.customize ["modifyvm", :id, "--natsettings1", "9000,1024,1024,1024,1024"]  

    vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]

    # SSD Settings
    vb.customize ["storagectl", :id, "--name", "SATAController", "--controller", "IntelAHCI", "--portcount", "1", "--hostiocache", "on"]

    vb.customize ['createhd', '--filename', 'zfs1.vdi', '--size', 4 * 1024]
    vb.customize ['createhd', '--filename', 'zfs2.vdi', '--size', 4 * 1024]
    vb.customize ['createhd', '--filename', 'zfs3.vdi', '--size', 4 * 1024]
    vb.customize ['createhd', '--filename', 'zfs4.vdi', '--size', 4 * 1024]
    vb.customize ['storageattach', :id, '--storagectl', "SATAController", '--port', 1, '--device', 0, '--type', 'hdd', '--nonrotational', 'on', '--medium', 'zfs1.vdi' ]
    vb.customize ['storageattach', :id, '--storagectl', "SATAController", '--port', 2, '--device', 0, '--type', 'hdd', '--nonrotational', 'on', '--medium', 'zfs2.vdi' ]
    vb.customize ['storageattach', :id, '--storagectl', "SATAController", '--port', 3, '--device', 0, '--type', 'hdd', '--nonrotational', 'on', '--medium', 'zfs3.vdi' ]
    vb.customize ['storageattach', :id, '--storagectl', "SATAController", '--port', 4, '--device', 0, '--type', 'hdd', '--nonrotational', 'on', '--medium', 'zfs4.vdi' ]
  end

  config.vm.provision :shell, :path => "scripts/provisioning.sh"
  #config.vm.provision :shell, :path => "ansible_provisioning.sh"

  #config.vm.provision "ansible" do |ansible|
  #  ansible.playbook = "provisioning/lamp.yml"
  #  ansible.verbose = "extra"
  #end

end