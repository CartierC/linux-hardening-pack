#!/bin/bash

echo "Starting security verification..."

echo "Checking SSH configuration..."

grep -E "PermitRootLogin|PasswordAuthentication" /etc/ssh/sshd_config

echo ""
echo "Checking firewall status..."

ufw status verbose

echo ""
echo "Checking fail2ban status..."

systemctl status fail2ban --no-pager

echo ""
echo "Checking kernel hardening values..."

sysctl net.ipv4.ip_forward
sysctl kernel.randomize_va_space
sysctl net.ipv4.conf.all.rp_filter

echo ""
echo "Verification complete."