#!/usr/bin/env bash
set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install vim -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install tree -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install htop -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ffmpeg -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install make -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install gcc -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install yamllint -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ntp -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install curl -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install build-essential -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install libssl-dev -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install libffi-dev -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install libpq-dev -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install systat -y;
};

patching;

while read package
do
apt install ${package} -y
done < requirement.txt
