# Verification Checklist
Repository: linux-hardening-pack

This checklist is used after running:

sudo ./scripts/harden.sh --apply  
sudo ./scripts/verify.sh

---

# 1. SSH Verification

[ ] Root login disabled  
[ ] Password authentication disabled  
[ ] X11 forwarding disabled  
[ ] MaxAuthTries set to 4  
[ ] SSH service restarted successfully  

Command: 

sudo grep -E "PermitRootLogin|PasswordAuthentication|X11Forwarding|MaxAuthTries" /etc/ssh/sshd_config


---

# 2. Sysctl Verification

[ ] net.ipv4.ip_forward = 0  
[ ] kernel.randomize_va_space = 2  
[ ] rp_filter enabled  

Command:

sudo sysctl -a | grep -E "ip_forward|randomize_va_space|rp_filter"

---

# 3. Firewall Verification

[ ] UFW active  
[ ] Default deny incoming  
[ ] OpenSSH allowed  

Command:

sudo ufw status verbose

---

# 4. Fail2ban Verification

[ ] Fail2ban service active  
[ ] SSH jail enabled  

Command:

sudo systemctl status fail2ban
sudo fail2ban-client status sshd


---

# 5. Log Verification

[ ] Hardening log generated  
[ ] No syntax errors during apply  

Log location:

logs/


---

# Final Result

If all checks pass:

✔ System meets linux-hardening-pack baseline standard.