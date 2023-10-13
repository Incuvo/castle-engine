#!/bin/sh

#Instalacja NVM
# run as target user

# Always check:
# https://github.com/creationix/nvm/releases
# for new versions
cd ~/
mkdir nvm_install
cd nvm_install
wget https://raw.githubusercontent.com/creationix/nvm/v0.31.1/install.sh
bash install.sh
cd ..

echo "Now exit and come back to run:"
echo "nvm install 0.10"
echo "npm install -g coffee-script mocha"



