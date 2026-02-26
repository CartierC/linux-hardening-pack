#!/bin/bash

echo "Starting Linux Hardening..."

# Update packages
apt update && apt upgrade -y

# Disable root login
sed -i 's/^#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Disable password authentication
sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/^PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

systemctl restart ssh

# Install firewall
apt install ufw -y
ufw allow OpenSSH
ufw enable

# Install fail2ban
apt install fail2ban -y
systemctl enable fail2ban
systemctl start fail2ban

echo "Hardening complete."
