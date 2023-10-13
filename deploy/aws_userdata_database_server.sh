#!/bin/bash
apt-get update
apt-get -y upgrade

# build tools
apt-get install -y build-essential cmake tcl

# synchro tools
apt-get install -y curl git

# local load balancer and ssl termination (haproxy REMOVED IN FAVOR OF AWS ELB)
apt-get install -y openssl libssl-dev

# put public pan_serwer key in authorized_keys or use script: 
cat << EOF >> /home/ubuntu/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/6QYhIEF9OInrNisVFDTp3sw2Nsp4WfSH0a6BW9TPDMfUAN5PBpkkWv4F/MynRAalhMRs8Vh2YxKu8j/9NuuK8uqzKYU92vWD/dSFh8qBAo0m5sQF6D/wp8fZrWD6SA75A8dOEuNTg3ZLLx62yaVGUM8qzSCopotq5natc8BhMtlcXv1sZzHhiE3ukzgYMhybt+vHcBI0Jjvz4tLl1glqA9Yuwz3mhBskARTKMjoBUGNHkiDrcSZY5ciLNWGd/qYZrJKH/BydoudSqjasNoaXAuOQIBY/RnSC1ipDDL+sbAfNQb02+gkx5II8mmiIP8Mmojmf8MvL8p4EAiwtaqZt imported-openssh-key
EOF

# Syslog configuration - enable udp, add a sender, add a source, restart syslog

sed -i '/^#.*module(load="imudp")/s/^#//' /etc/rsyslog.conf
sed -i '/^#.*input(type="imudp" port="514")/s/^#//' /etc/rsyslog.conf
sed -i '/type="imudp" port="514"/a $AllowedSender UDP, 127.0.0.1' /etc/rsyslog.conf
sed -i -e 's/\*\.\*;auth,authpriv.none/\*\.\*;auth,authpriv.none;local2.none/g' /etc/rsyslog.d/50-default.conf
systemctl restart rsyslog
echo "Rsyslog reconfigured"


# Redis install and config

cd /tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
cd redis-stable/
make && make test && make install
mkdir /etc/redis
cp /tmp/redis-stable/redis.conf /etc/redis/

sed -i -e 's/^bind 127.0.0.1/bind 0.0.0.0/g' /etc/redis/redis.conf
sed -i -e 's/^supervised no/supervised systemd/g' /etc/redis/redis.conf
sed -i -e 's/^dir \.\//dir \/var\/lib\/redis/g' /etc/redis/redis.conf
sed -i -e 's/^protected-mode yes/protected-mode no/g' /etc/redis/redis.conf

cat << EOF > /etc/systemd/system/redis.service

[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
User=redis
Group=redis
ExecStart=/usr/local/bin/redis-server /etc/redis/redis.conf
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always

[Install]
WantedBy=multi-user.target

EOF

adduser --system --group --no-create-home redis
mkdir /var/lib/redis
chown redis:redis /var/lib/redis
chmod 770 /var/lib/redis
systemctl start redis
systemctl enable redis

# MongoDB install and config

apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.2 multiverse" >> /etc/apt/sources.list.d/mongodb-org-3.2.list

apt-get update
apt-get install -y mongodb-org
sed -i -e 's/bindIp: 127.0.0.1/bindIp: 0.0.0.0/g' /etc/mongod.conf

cat << EOF > /etc/systemd/system/mongodb.service

[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target

[Service]
User=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target

EOF

systemctl start mongodb
systemctl enable mongodb