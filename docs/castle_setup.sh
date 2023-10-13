#!/bin/sh
# run after env setup

echo "Creating users..."
# sudo useradd -U -m castle
sudo useradd -U stud
sudo useradd -U supervisord

#echo "Changing limits of open files..."
#sudo su 
#cat >> /etc/security/limits.conf <<'EOF'
#
#mongodb     soft    nofile  100000
#mongodb     hard    nofile  100000
#
#redis     soft    nofile  100000
#redis     hard    nofile  100000

#haproxy     soft    nofile  100000
#haproxy     hard    nofile  100000

#stud     soft    nofile  100000
#stud     hard    nofile  100000

#castle     soft    nofile  100000
#castle     hard    nofile  100000

#EOF

#exit

#echo "Modifying session limits..."
#sudo sed -i '/# session    required   pam_limits.so/c\session   required    pam_limits.so' /etc/pam.d/su

echo "Now login to castle:"
echo " sudo -Hu castle bash"
echo " "
echo " and clone repo (repo.sh)"
