#!/bin/sh
# run after castle setup
# This should be run as castle user!

#REPO NAME
DEPLOYMENT_KEY_NAME="castle_deployment_key"
REPO_NAME="castle-server"
REPO_DESTINATION="src"
BRANCH="develop"

#CREATE SSH DIR IF NOT EXISTS
mkdir -p ~/.ssh

#CREATE SSH CONFIG FILE
cat >> ~/.ssh/config <<EOF
#Castle Repository
HostName bitbucket.org
    Compression yes
    PreferredAuthentications publickey
    IdentityFile ~/.ssh/$DEPLOYMENT_KEY_NAME
    StrictHostKeyChecking no
EOF

#CREATE DEPLOYMENT KEY
cat >> ~/.ssh/$DEPLOYMENT_KEY_NAME <<'EOF'
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAuvMAfR+LcR6CDZu++tZB2taxSdkJUTVBGkllWtHsdxiNii0c
03byiGw2NtVD4dxvHLB/K82dpbvJN/X8+OP86bChG/eH84nEyj0X1+0Sg49ZT3bu
3xfbjVJea3qgVymPT80Du2l/BfFQXFwsYTQdS4ZxPlO73iyVu5qdF5667KuhYVGg
YIJxnjc45100oUFNubbP9QZr8XeLvXaGGhJD96yupmiHLVtvDlGnzILJUoFIWWk4
ThFKxSb6dbfAQSMjTIFXjxIPTW3o1ybTbHeGRZIITlnajjvRiEFStscf8Mwwaib1
xg2uoGh+7B9uPOIB+/PMaS33NycFHBteULWeTQIDAQABAoIBAAlA9gk7gn967x0V
VIK+EExwzB3HrHpklHBkqauxMG9Eu9zXFtIw1RiDortcGxwW+TkGU4UrjF4jyXYH
qxn2zxISOCdWPViEvUT1eTSq+3ufoOAaFwDcAXYhWaMgUsd9uyZME583PZ5hr4Si
21+EYN7YLMrVAjuhIVhD8vq0VLRaRNVbrBCHaWUqzgI4IzKZRvaN4UlGiTITJ8kK
k5gAWLq2YZdChVMBKNugrG94eNKOgeFDxouR4BfOisZXLfk3i53lc82D/QL8791u
6SYXrVjhxAvCoC0L24UN2AZAVPdir+rccB2zF9mDviAQvKFMSgUep3Wd5LE9QW3W
xCx+ilECgYEA55Tx3UvxMFAepgQVhMjEm5niyv52HH1qn0OLp3+bXH1QbeSzufzV
F0+snLIFauKEAbznJMD300GrZFDMube2Qg5ZZFfVHRavXGhl8ETcYjccJeGQf5Le
T4+VD3CSyohEwM4Cf4+cAGNP4/qXTKycCq4HJ+u8JHmxXxtr11Wot6cCgYEAzqlL
w2FQZJz+wTV/cmRJb4iPiKjs61dMOXtPMv8qJCisuOS8VM2G/CQqj/wdYp4g6TGv
Ow9vCYgCfDDCR9jaCEVU9I9S18d6dOMDSao5VJ+740BiI8RwFkJt/iMjWYjA8OiB
B+D2c3pdw1zyI0wEraT+RhYd/bz9fLkD9xkjuOsCgYAKtAqdtMXX+sv/1k58TZ8w
peMiiLJCzNUhuUh6HF683pnaCmj4HqRmqGsM7vlrID8DqYxxWW3a2L0oLMfZiZEl
6m3dQmX6KzM9rSGRAk3BSFTHt24rR0l5GeTEyuot7DBpTNw2sxd9uRlXKxzVEWFA
6Rwxjyap9OnqwGSyliXvHwKBgCBErPDH7B6ZqOmQKeM5p4HDx+2lusCQc/VxvI8Q
6oqU00tXY9S19sK9/utWiVwRpr/ioyLMqSDK3OB5WIyRXpH2CWraSiwpGITRwXyq
GKOPAW5dajV9gaboHnaVE/rx8HZtR2Bsju6/B47un1xFjWFzpsRYxbwN22KzHNxj
T4GbAoGBANOTd9EyvuWkfXz2zzVh78uUn8FrIqrsP4S7ydVb14U/o2+6sZ1nKY61
OW8HVVnw/pwQ7Zqm80PmwJyrSTkE/KMeRwBAiO2U1+CTrYRPnkKEsap4qAboWjYU
SzNc4+erA2c3jRe4Zz0mSsVK31VhDn92ECw/bavUI9N5QHNtyYM8
-----END RSA PRIVATE KEY-----
EOF

#SET KEY PERMISSION
chmod 600 ~/.ssh/$DEPLOYMENT_KEY_NAME

# git clone into proper directory
git clone git@bitbucket.org:incuvo/$REPO_NAME.git
mv $REPO_NAME/ $REPO_DESTINATION/
cd $REPO_DESTINATION
git checkout $BRANCH

echo "Repository cloned."
echo "Now run nvm_prepare for node server and npm."