#!/bin/bash
echo "LOCKED: Disabling Root Login..."
sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
echo "LOCKED: Enabling Firewall..."
ufw allow 22/tcp
ufw enable
