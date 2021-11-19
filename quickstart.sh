#!/usr/bin/env bash
set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install vim -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install tree -y;
    sudo DEBIAN_FRONTEND=noninteractive apt install ansible -y;
};

patching;

while read package
do
apt install ${package} -y
done < requirement.txt
