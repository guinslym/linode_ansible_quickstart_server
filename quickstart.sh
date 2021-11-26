#!/usr/bin/env bash

set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install wget -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y;
    wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/quickstart.yml    
    ansible-playbook quickstart.yml
    sudo apt install neofetch
    wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/docker.yml
    ansible-playbook docker.yml
    curl -L https://github.com/docker/machine/releases/download/v0.13.0/docker-machine-`uname -s`-`uname -m` -o ~/docker-machine
    chmod +x ~/docker-machine
    sudo cp ~/docker-machine /usr/local/bin/
    neofetch
    sudo rm quickstart.yml
    sudo rm quickstart.sh
};

patching;
