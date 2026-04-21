# Verification Checklist
Repository: linux-hardening-pack
Version: 2.0

This checklist maps directly to every check performed by `scripts/verify.sh`.
Use it for manual audits or post-deployment confirmation.

## Workflow

```bash
# 1. Apply hardening
sudo bash scripts/harden.sh

# 2. Run automated verification (recommended)
sudo bash scripts/verify.sh

# 3. Or work through this checklist manually
```

---

## 1. SSH Configuration

| Check | Expected Value | Verify Command |
|-------|---------------|----------------|
| [ ] Root login disabled | `PermitRootLogin no` | `sudo sshd -T \| grep permitrootlogin` |
| [ ] Password auth disabled | `PasswordAuthentication no` | `sudo sshd -T \| grep passwordauthentication` |
| [ ] X11 forwarding disabled | `X11Forwarding no` | `sudo sshd -T \| grep x11forwarding` |
| [ ] Max auth tries set | `MaxAuthTries 4` | `sudo sshd -T \| grep maxauthtries` |
| [ ] Public key auth enabled | `PubkeyAuthentication yes` | `sudo sshd -T \| grep pubkeyauthentication` |
| [ ] Empty passwords blocked | `PermitEmptyPasswords no` | `sudo sshd -T \| grep permitemptypasswords` |
| [ ] TCP forwarding disabled | `AllowTcpForwarding no` | `sudo sshd -T \| grep allowtcpforwarding` |
| [ ] Host-based auth disabled | `HostbasedAuthentication no` | `sudo sshd -T \| grep hostbasedauthentication` |
| [ ] Rhosts ignored | `IgnoreRhosts yes` | `sudo sshd -T \| grep ignorerhosts` |
| [ ] Login grace time | `LoginGraceTime 30` | `sudo sshd -T \| grep logingracetime` |
| [ ] SSH service running | active | `systemctl is-active ssh` |

---

## 2. Kernel Hardening (sysctl)

| Check | Expected Value | Verify Command |
|-------|---------------|----------------|
| [ ] IP forwarding off | `0` | `sysctl net.ipv4.ip_forward` |
| [ ] ICMP redirects off (all) | `0` | `sysctl net.ipv4.conf.all.accept_redirects` |
| [ ] ICMP redirects off (default) | `0` | `sysctl net.ipv4.conf.default.accept_redirects` |
| [ ] Send redirects off | `0` | `sysctl net.ipv4.conf.all.send_redirects` |
| [ ] Source routing off (all) | `0` | `sysctl net.ipv4.conf.all.accept_source_route` |
| [ ] Source routing off (default) | `0` | `sysctl net.ipv4.conf.default.accept_source_route` |
| [ ] Reverse path filter on | `1` | `sysctl net.ipv4.conf.all.rp_filter` |
| [ ] SYN cookies enabled | `1` | `sysctl net.ipv4.tcp_syncookies` |
| [ ] Log martians (all) | `1` | `sysctl net.ipv4.conf.all.log_martians` |
| [ ] Log martians (default) | `1` | `sysctl net.ipv4.conf.default.log_martians` |
| [ ] Ignore ICMP broadcasts | `1` | `sysctl net.ipv4.icmp_echo_ignore_broadcasts` |
| [ ] Ignore bogus ICMP errors | `1` | `sysctl net.ipv4.icmp_ignore_bogus_error_responses` |
| [ ] IPv6 redirects off (all) | `0` | `sysctl net.ipv6.conf.all.accept_redirects` |
| [ ] IPv6 redirects off (default) | `0` | `sysctl net.ipv6.conf.default.accept_redirects` |
| [ ] ASLR full randomization | `2` | `sysctl kernel.randomize_va_space` |
| [ ] Setuid core dumps off | `0` | `sysctl fs.suid_dumpable` |
| [ ] Protected hardlinks | `1` | `sysctl fs.protected_hardlinks` |
| [ ] Protected symlinks | `1` | `sysctl fs.protected_symlinks` |

---

## 3. Firewall (UFW)

| Check | Expected Value | Verify Command |
|-------|---------------|----------------|
| [ ] UFW active | `Status: active` | `sudo ufw status` |
| [ ] Default deny incoming | `deny (incoming)` | `sudo ufw status verbose` |
| [ ] SSH explicitly allowed | `ALLOW` for port 22/OpenSSH | `sudo ufw status` |

---

## 4. Fail2ban

| Check | Expected Value | Verify Command |
|-------|---------------|----------------|
| [ ] Fail2ban service running | `active` | `systemctl status fail2ban` |
| [ ] SSH jail active | shows banned counts | `sudo fail2ban-client status sshd` |
| [ ] Bantime set | `86400` (24h in seconds) | `sudo fail2ban-client get sshd bantime` |
| [ ] Maxretry set | `3` | `sudo fail2ban-client get sshd maxretry` |

---

## 5. File Permissions

| Path | Expected Mode | Verify Command |
|------|--------------|----------------|
| [ ] `/etc/shadow` | `640` | `stat -c "%a %n" /etc/shadow` |
| [ ] `/etc/gshadow` | `000` | `stat -c "%a %n" /etc/gshadow` |
| [ ] `/etc/passwd` | `644` | `stat -c "%a %n" /etc/passwd` |
| [ ] `/etc/group` | `644` | `stat -c "%a %n" /etc/group` |
| [ ] `/etc/ssh/sshd_config` | `600` | `stat -c "%a %n" /etc/ssh/sshd_config` |
| [ ] `/etc/crontab` | `600` | `stat -c "%a %n" /etc/crontab` |
| [ ] `/root` directory | `700` | `stat -c "%a %n" /root` |

---

## 6. Hardening Log

| Check | Expected State | Verify Command |
|-------|---------------|----------------|
| [ ] Hardening log exists | file present | `ls -la logs/harden-*.log` |
| [ ] No error entries in log | no `FATAL:` lines | `grep FATAL logs/harden-*.log` |

---

## 7. Backup Verification

| Check | Expected State | Verify Command |
|-------|---------------|----------------|
| [ ] SSH config backup exists | `.bak` file present | `ls /var/backups/linux-hardening-pack/sshd_config.bak` |
| [ ] sysctl backup exists | `.bak` file present | `ls /var/backups/linux-hardening-pack/sysctl.conf.bak` |

---

## Final Result

If all boxes are checked:

```
RESULT: PASS — System meets linux-hardening-pack baseline standard.
```

If any checks fail, run harden.sh to remediate:

```bash
sudo bash scripts/harden.sh
sudo bash scripts/verify.sh
```
