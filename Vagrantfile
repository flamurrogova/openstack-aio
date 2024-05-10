# -*- mode: ruby -*-
# vi: set ft=ruby :

ENV["LC_ALL"] = "en_US.UTF-8"

nodes = [
  { 
    :hostname => "deploy", 
    :cpu => 1,
    :ram => 2048,
    :management_ip => "10.10.10.50"
  },
  { 
    :hostname => "aio", 
    :cpu => 24,
    :ram => 32768,
    :api_ip => "10.10.30.50",
    :neutron_ip => "192.168.100.50",
    :management_ip => "10.10.10.51"
  },
]


Vagrant.configure("2") do |config|

  config.ssh.insert_key = false
  config.vm.box = "generic/ubuntu2204"
  config.vm.synced_folder ".", "/vagrant", type: "rsync"

  nodes.each do |node|

    config.vm.define node[:hostname] do |cfg|
      
      cfg.vm.provider :libvirt do |libvirt|
        libvirt.cpus = node[:cpu]
        libvirt.memory = node[:ram]
        libvirt.storage_pool_name = "IMAGES-1"
      end
      
      cfg.vm.hostname = node[:hostname]
      cfg.vm.network :private_network, :ip => node[:management_ip]

      if node[:hostname] == "aio"
        cfg.vm.network :private_network, :ip => node[:api_ip]
        cfg.vm.network :private_network, :ip => node[:neutron_ip]
        cfg.vm.provider :libvirt do |lv|
          lv.storage :file, :size => '300G'
        end
      end

      
      if node[:hostname] == "deploy"

        cfg.vm.provision "shell", inline: <<-SHELL
          exit 0
          # https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script
          curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
          sudo sh /tmp/get-docker.sh
          #
          # run local docker registry
          echo "\nrun local registry\n"
          sudo /vagrant/scripts/run-local-registry.sh
          #
          echo "\npull skopeo\n"
          sudo docker pull quay.io/skopeo/stable
        SHELL
        
      end
      
    end
  end
end
