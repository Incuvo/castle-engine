#!/bin/sh

#Instalacja Ubuntu
  #aktualizacja
    echo "Updating system"
    sudo apt-get -y update
    sudo apt-get -y upgrade
  #utils: git, vim, htop, unzip, screen, ntp
    echo "Installing add-ons"
    sudo apt-get install -y git vim htop unzip screen build-essential g++ openjdk-6-jre libssl-dev
    sudo apt-get install -y ntp ntpdate
  #node
    #curl -sL https://deb.nodesource.com/setup | sudo bash -
    #sudo apt-get install -y nodejs
  #mongo
    echo "Installing Mongo"
    sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
    echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
    sudo apt-get -y update
    sudo apt-get install -y mongodb-org
    sudo service mongod status
  #haproxy
    # this gets stuck on a question!
    echo "Installing haproxy"
    sudo add-apt-repository -y ppa:vbernat/haproxy-1.6
    sudo apt-get -y update
    sudo apt-get install -y haproxy
  #redis
  echo "Installing redis"
    cd ~/
    sudo apt-get install -y tcl
    wget http://download.redis.io/releases/redis-3.0.7.tar.gz
    tar zxf redis-3.0.7.tar.gz
    cd redis-3.0.7
    make
    sudo mkdir /etc/redis
    sudo cp redis.conf /etc/redis/redis.conf
    sudo mkdir /var/lib/redis
  #stud
  echo "Installing stud"
    cd ~/
    git clone https://github.com/bumptech/stud.git
    cd stud
    sudo apt-get install -y libssl-dev libev-dev
    make
    sudo make install

    echo "Now run bash castle_setup.sh"
    sudo useradd -U -m castle


