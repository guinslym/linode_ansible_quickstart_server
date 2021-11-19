#!/usr/bin/env bash
set -e

patching(){
    sudo apt update -y;
    sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y;
};

patching;

while read package
do
apt install ${package} -y
done < requirement.txt
