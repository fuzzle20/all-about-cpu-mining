#!/bin/bash
sudo apt-get update
sudo apt-get remove dante-server -y && sudo apt-get purge dante-server -y && sudo apt-get autoremove -y
sudo apt-get install dante-server -y
sudo service danted restart
nic=$(ip route get 8.8.8.8 | sed -nr 's/.*dev ([^\ ]+).*/\1/p')
CONFIG="logoutput: syslog\n"
CONFIG+="user.privileged: root\n"
CONFIG+="user.notprivileged: nobody\n"
CONFIG+="internal: 0.0.0.0 port = 9952\n"
CONFIG+="external: $nic\n"
CONFIG+="method: none\n"
CONFIG+="client pass {\n"
CONFIG+="from: 0.0.0.0/0 to: 0.0.0.0/0\n"
CONFIG+="log: connect disconnect error\n"
CONFIG+="}\n"
CONFIG+="pass {\n"
CONFIG+="from: 0.0.0.0/0 to: 0.0.0.0/0\n"
CONFIG+="log: error connect disconnect\n"
CONFIG+="}\n"
sudo rm -rf /etc/danted.conf
sudo touch /etc/danted.conf
sudo printf "$CONFIG" >> /etc/danted.conf
sudo iptables -I INPUT -p tcp --dport 9952 -j ACCEPT
sudo systemctl daemon-reload
sudo systemctl enable danted.service
sudo systemctl restart danted
rm -rf script
sudo touch /etc/danted.conf
