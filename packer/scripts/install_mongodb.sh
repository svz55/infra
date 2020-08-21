#!/bin/bash

#sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
#sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" > /etc/apt/sources.list.d/mongodb-org-3.2.list'
sudo rm /etc/apt/sources.list.d/mongodb*.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E52529D4
sudo bash -c 'echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/4.0 multiverse" > /etc/apt/sources.list.d/mongodb-org-4.0.list'
sudo apt update
sudo apt install -y mongodb-org
sudo rm /etc/mongod.conf
sudo mv /tmp/mongod.conf /etc/
sudo chown root:root /etc/mongod.conf
sudo systemctl daemon-reload
sudo systemctl start mongod
sudo systemctl enable mongod
