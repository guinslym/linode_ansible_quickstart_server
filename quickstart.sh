#!/usr/bin/env bash
set -e

patching(){
    sudo apt-get update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y;
};

patching;

while read package
do
apt install ${package} -y
done < requirement.txt
