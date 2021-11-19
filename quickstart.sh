#!/usr/bin/env bash

set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install wget -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y;
    wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/quickstart.yml    
    ansible-playbook quickstart.yml
    wget https://raw.githubusercontent.com/guinslym/linode_ansible_quickstart_server/main/install_docker.sh
    chmod 777 install_docker.sh
    sudo bash install_docker.sh
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y;
    sudo rm install_docker.sh
    sudo rm quickstart.yml
    sudo rm quickstart.sh
};

patching;
