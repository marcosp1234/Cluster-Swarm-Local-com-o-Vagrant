# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Configuração comum para todas as máquinas
  config.vm.box = "ubuntu/focal64"
  config.vm.provision "shell", inline: <<-SHELL
    # Instalar Docker
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
  SHELL

  # Configuração da máquina master (manager do Swarm)
  config.vm.define "master" do |master|
    master.vm.hostname = "master"
    master.vm.network "private_network", ip: "192.168.56.10"
    
    master.vm.provision "shell", inline: <<-SHELL
      # Inicializar o Docker Swarm
      docker swarm init --advertise-addr 192.168.56.10
      
      # Gerar token para workers e salvar em /vagrant/join-token
      docker swarm join-token worker | grep "docker swarm join" > /vagrant/join-token
    SHELL
  end

  # Configuração dos workers
  (1..3).each do |i|
    config.vm.define "node0#{i}" do |node|
      node.vm.hostname = "node0#{i}"
      node.vm.network "private_network", ip: "192.168.56.1#{i}"
      
      node.vm.provision "shell", inline: <<-SHELL
        # Aguardar o token ser gerado pelo master
        while [ ! -f /vagrant/join-token ]; do
          sleep 5
          echo "Aguardando token de join do master..."
        done
        
        # Entrar no cluster Swarm
        bash /vagrant/join-token
      SHELL
    end
  end
end