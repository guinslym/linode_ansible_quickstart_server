#!/usr/bin/env bash

set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install wget -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y;
    wget --no-check-certificate --no-cache --no-cookies https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/quickstart.yml    
    ansible-playbook quickstart.yml
    sudo DEBIAN_FRONTEND=noninteractive apt install neofetch -y
    wget --no-check-certificate --no-cache --no-cookies https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/docker.yml
    ansible-playbook docker.yml
    curl -L https://github.com/docker/machine/releases/download/v0.13.0/docker-machine-`uname -s`-`uname -m` -o ~/docker-machine
    chmod +x ~/docker-machine
    sudo cp ~/docker-machine /usr/local/bin/
    neofetch
    sudo rm quickstart.yml
    sudo rm quickstart.sh
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" -y
    sudo reboot
};

patching;
