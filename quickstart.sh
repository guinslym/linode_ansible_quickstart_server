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
    neofetch
    sudo rm quickstart.yml
    sudo rm quickstart.sh
};

patching;
