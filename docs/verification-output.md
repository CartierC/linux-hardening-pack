# Verification Output Example
Repository: linux-hardening-pack

Sample output from `sudo bash scripts/verify.sh` after a successful `harden.sh` run.

## Command Used

```bash
sudo bash scripts/verify.sh
```

## Output

```
Linux Hardening Pack — verify.sh
Run date : Mon Apr 21 14:32:07 UTC 2026
Hostname : ubuntu-hardened-01
User     : root
======================================

=== SSH Configuration ===
  [PASS] SSH PermitRootLogin = no
  [PASS] SSH PasswordAuthentication = no
  [PASS] SSH X11Forwarding = no
  [PASS] SSH MaxAuthTries = 4
  [PASS] SSH PubkeyAuthentication = yes
  [PASS] SSH PermitEmptyPasswords = no
  [PASS] SSH AllowTcpForwarding = no
  [PASS] SSH HostbasedAuthentication = no
  [PASS] SSH IgnoreRhosts = yes
  [PASS] SSH LoginGraceTime = 30
  [PASS] SSH service is running

=== Kernel Hardening (sysctl) ===
  [PASS] sysctl net.ipv4.ip_forward = 0
  [PASS] sysctl net.ipv4.conf.all.accept_redirects = 0
  [PASS] sysctl net.ipv4.conf.default.accept_redirects = 0
  [PASS] sysctl net.ipv4.conf.all.send_redirects = 0
  [PASS] sysctl net.ipv4.conf.default.send_redirects = 0
  [PASS] sysctl net.ipv4.conf.all.accept_source_route = 0
  [PASS] sysctl net.ipv4.conf.default.accept_source_route = 0
  [PASS] sysctl net.ipv4.conf.all.rp_filter = 1
  [PASS] sysctl net.ipv4.conf.default.rp_filter = 1
  [PASS] sysctl net.ipv4.tcp_syncookies = 1
  [PASS] sysctl net.ipv4.conf.all.log_martians = 1
  [PASS] sysctl net.ipv4.conf.default.log_martians = 1
  [PASS] sysctl net.ipv4.icmp_echo_ignore_broadcasts = 1
  [PASS] sysctl net.ipv4.icmp_ignore_bogus_error_responses = 1
  [PASS] sysctl net.ipv6.conf.all.accept_redirects = 0
  [PASS] sysctl net.ipv6.conf.default.accept_redirects = 0
  [PASS] sysctl kernel.randomize_va_space = 2
  [PASS] sysctl fs.suid_dumpable = 0
  [PASS] sysctl fs.protected_hardlinks = 1
  [PASS] sysctl fs.protected_symlinks = 1

=== Firewall (UFW) ===
  [PASS] UFW is active
  [PASS] UFW default incoming policy: deny
  [PASS] UFW: SSH (port 22 / OpenSSH) is allowed

=== Fail2ban ===
  [PASS] fail2ban service is running
  [PASS] fail2ban SSH jail (sshd) is active
  [PASS] fail2ban bantime=86400s  maxretry=3

=== File Permissions ===
  [PASS] Permissions /etc/shadow = 640
  [PASS] Permissions /etc/gshadow = 0
  [PASS] Permissions /etc/passwd = 644
  [PASS] Permissions /etc/group = 644
  [PASS] Permissions /etc/ssh/sshd_config = 600
  [PASS] Permissions /etc/crontab = 600
  [PASS] Permissions /root = 700

=== Hardening Log ===
  [PASS] Hardening log found: /opt/linux-hardening-pack/logs/harden-2026-04-21_14-30-01.log

======================================
  VERIFICATION SUMMARY
======================================
  PASS : 35
  FAIL : 0
  WARN : 0
======================================
  RESULT: PASS — All checks passed. Baseline is active.
```

## Exit Code

| Exit Code | Meaning |
|-----------|---------|
| `0` | All checks passed (PASS or PASS with WARNs) |
| `1` | One or more FAIL checks — hardening not fully applied |

## Typical FAIL Output (before hardening)

```
=== SSH Configuration ===
  [FAIL] SSH PermitRootLogin: expected 'no', got 'prohibit-password'
  [FAIL] SSH PasswordAuthentication: expected 'no', got 'yes'
  [PASS] SSH X11Forwarding = no
  ...

=== Firewall (UFW) ===
  [FAIL] UFW is not active

======================================
  VERIFICATION SUMMARY
======================================
  PASS : 28
  FAIL : 3
  WARN : 1
======================================
  RESULT: FAIL — 3 check(s) failed. Review FAIL items above.
```
