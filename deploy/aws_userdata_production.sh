# Castle API installation

## Backend download and npm dependencies install
cd /home/ubuntu
sudo -Hu ubuntu git clone git@github.com:Incuvo/castle-engine.git
cd /home/ubuntu/castle-server
apt-get install -y python2.7 python2.7-dev
sudo -Hu ubuntu PYTHON=/usr/bin/python2.7 npm install

## Service Description - remember to set Env VARIABLES right!!

cat << EOF > /etc/systemd/system/castle-api.service

[Unit]
Description=Castle Revenge API Backend
After=network.target

[Service]
User=ubuntu
Group=ubuntu
ExecStart=/home/ubuntu/.npm-global/bin/coffee /home/ubuntu/castle-server/castle/web/api/app.coffee
SyslogIdentifier=castle-api
Environment=NODE_ENV=production
Environment=CASTLE_MONGODB_HOST=172.31.17.18
Environment=CASTLE_REDIS_HOST=172.31.17.18
Restart=always

[Install]
WantedBy=multi-user.target

EOF
systemctl enable castle-api
systemctl start castle-api
