sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys
sudo echo 'PermitRootLogin prohibit-password' | sudo tee -a /etc/ssh/sshd_config