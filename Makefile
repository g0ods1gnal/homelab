# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANT_API_VERSION = "2"

VM_BOX_UBUNTU = "generic/ubuntu2204"  # Ubuntu 22.04 LTS
VM_BOX_KALI = "kalilinux/rolling"     # Kali Linux (pentesting distro)

# Network configuration
# We use a private network so VMs can talk to each other
ELK_SERVER_IP = "192.168.56.10"
UBUNTU_CLIENT_IP = "192.168.56.20"
KALI_ATTACKER_IP = "192.168.56.50"

Vagrant.configure(VAGRANT_API_VERSION) do |config|
  
  # Global settings that apply to all VMs
  config.vm.box_check_update = false  # Don't check for updates every time
  config.vm.synced_folder ".", "/vagrant", disabled: false  # Share this directory
  
  #
  # ELK Server
  # This VM runs Elasticsearch, Logstash, and Kibana
  #
  config.vm.define "elk-server" do |elk|
    elk.vm.box = VM_BOX_UBUNTU
    elk.vm.hostname = "elk-server"
    
    # Networking: NAT (internet access) + Private network (VM-to-VM)
    # NAT is automatic, we just need to add the private network
    elk.vm.network "private_network", ip: ELK_SERVER_IP
    
    # Port forwarding: Access Kibana from your host browser
    elk.vm.network "forwarded_port", guest: 5601, host: 5601, host_ip: "127.0.0.1"
    elk.vm.network "forwarded_port", guest: 9200, host: 9200, host_ip: "127.0.0.1"
    
    # Resources - Elasticsearch is HUNGRY
    # In real life, SIEM servers have 64GB+ RAM. For lab: 6GB minimum.
    elk.vm.provider "virtualbox" do |vb|
      vb.name = "elk-siem-server"
      vb.memory = 6144  # 6GB RAM (Elasticsearch + Kibana + Logstash)
      vb.cpus = 2
      
      # These DNS settings fix common networking issues
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
    end
    
    # Provisioning: Shell commands to run on first boot
    # We install Python because Ansible needs it
    elk.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      
      # Add /etc/hosts entries so VMs can find each other by name
      cat >> /etc/hosts << 'HOSTS'
192.168.56.10   elk-server
192.168.56.20   ubuntu-client
192.168.56.50   kali-attacker
HOSTS
    SHELL
  end

  #
  # Ubuntu Client
  # This VM generates logs (web server, SSH, system logs)
  #
  config.vm.define "ubuntu-client" do |client|
    client.vm.box = VM_BOX_UBUNTU
    client.vm.hostname = "ubuntu-client"
    
    # Private network for SIEM communication
    client.vm.network "private_network", ip: UBUNTU_CLIENT_IP
    
    # Lighter resources - this is just generating logs
    client.vm.provider "virtualbox" do |vb|
      vb.name = "elk-siem-client"
      vb.memory = 2048
      vb.cpus = 1
    end
    
    client.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      
      # Add hosts
      cat >> /etc/hosts << 'HOSTS'
192.168.56.10   elk-server
192.168.56.20   ubuntu-client
192.168.56.50   kali-attacker
HOSTS
    SHELL
  end

  #
  # Kali Attacker
  # This VM runs attack tools
  #
  config.vm.define "kali-attacker" do |kali|
    kali.vm.box = VM_BOX_KALI
    kali.vm.hostname = "kali-attacker"
    
    kali.vm.network "private_network", ip: KALI_ATTACKER_IP
    
    kali.vm.provider "virtualbox" do |vb|
      vb.name = "elk-siem-attacker"
      vb.memory = 2048
      vb.cpus = 2
      vb.gui = false
    end
    
    kali.vm.provision "shell", inline: <<-SHELL
      apt-get update
      apt-get install -y python3 python3-pip
      
      # Install attack tools (most are pre-installed in Kali)
      apt-get install -y hydra nmap sqlmap nikto
      
      # Add hosts
      cat >> /etc/hosts << 'HOSTS'
192.168.56.10   elk-server
192.168.56.20   ubuntu-client
192.168.56.50   kali-attacker
HOSTS
    SHELL
  end
end
