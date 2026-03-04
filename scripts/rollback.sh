#!/bin/bash

echo "Starting rollback procedure..."

echo "Restoring SSH configuration..."

sed -i 's/PermitRootLogin no/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config

systemctl restart ssh

echo "Disabling firewall..."

ufw disable

echo "Stopping fail2ban..."

systemctl stop fail2ban
systemctl disable fail2ban

echo "Rollback complete."