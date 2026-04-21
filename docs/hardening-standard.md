# Linux Hardening Standard
Repository: linux-hardening-pack
Baseline Target: Ubuntu 22.04 LTS (Debian-based systems)
Version: 2.0

---

## Objective

This hardening standard defines a reproducible, auditable security baseline for
Linux servers. The goal is to reduce attack surface, enforce secure defaults, and
implement layered defense across access control, network, kernel, filesystem, and
service management domains.

This standard is implemented and enforced by:

| Component | File |
|-----------|------|
| Apply baseline | `scripts/harden.sh` |
| Verify baseline | `scripts/verify.sh` |
| Reverse baseline | `scripts/rollback.sh` |
| SSH config | `configs/sshd_config.secure` |
| Kernel params | `configs/sysctl.conf.secure` |
| Brute-force protection | `configs/fail2ban.local` |

---

## 1. Access Control Hardening

### 1.1 SSH Configuration

| Control | Setting | Rationale |
|---------|---------|-----------|
| Disable root login | `PermitRootLogin no` | Prevent direct root compromise over SSH |
| Disable password auth | `PasswordAuthentication no` | Enforce key-based authentication only |
| Disable challenge-response | `ChallengeResponseAuthentication no` | Close secondary password path |
| Disable empty passwords | `PermitEmptyPasswords no` | No accounts without credentials |
| Disable X11 forwarding | `X11Forwarding no` | Reduce attack surface |
| Disable TCP forwarding | `AllowTcpForwarding no` | Block tunnel abuse |
| Disable agent forwarding | `AllowAgentForwarding no` | Prevent credential pivoting |
| Disable host-based auth | `HostbasedAuthentication no` | Block legacy trust mechanisms |
| Ignore rhosts | `IgnoreRhosts yes` | Disable .rhosts file trust |
| Disable user env | `PermitUserEnvironment no` | Prevent env injection |
| Limit auth attempts | `MaxAuthTries 4` | Mitigate brute force |
| Limit sessions | `MaxSessions 4` | Restrict parallel connections |
| Auth timeout | `LoginGraceTime 30` | Drop stalled auth attempts |
| Idle timeout | `ClientAliveInterval 300` | Terminate idle sessions after 5 min |
| Idle count | `ClientAliveCountMax 2` | Two missed intervals = disconnect |
| Force protocol 2 | `Protocol 2` | Protocol 1 has known weaknesses |
| Disable compression | `Compression no` | Mitigate CRIME-like attacks |
| Verbose logging | `LogLevel VERBOSE` | Full key fingerprint logging |
| Login banner | `Banner /etc/issue.net` | Legal notice before authentication |
| Strict mode | `StrictModes yes` | Enforce correct file ownership/permissions |
| Disable DNS lookup | `UseDNS no` | Prevent login delay + DNS spoofing |

**Security Principle:** Least Privilege + Minimized Exposure

---

## 2. Network Hardening

### 2.1 Kernel Networking Controls (sysctl)

| Control | Parameter | Value | Rationale |
|---------|-----------|-------|-----------|
| Disable IP forwarding | `net.ipv4.ip_forward` | `0` | Not a router |
| Disable IPv6 forwarding | `net.ipv6.conf.all.forwarding` | `0` | Not a router |
| Disable ICMP redirects (recv) | `net.ipv4.conf.all.accept_redirects` | `0` | Prevent MITM route manipulation |
| Disable ICMP redirects (send) | `net.ipv4.conf.all.send_redirects` | `0` | Not a router |
| Disable secure redirects | `net.ipv4.conf.all.secure_redirects` | `0` | Prevent gateway redirect abuse |
| Disable IPv6 redirects | `net.ipv6.conf.all.accept_redirects` | `0` | IPv6 equivalent |
| Disable source routing | `net.ipv4.conf.all.accept_source_route` | `0` | Block malicious routing headers |
| Reverse path filter | `net.ipv4.conf.all.rp_filter` | `1` | Drop spoofed source packets |
| SYN cookies | `net.ipv4.tcp_syncookies` | `1` | Mitigate SYN flood DoS attacks |
| Log martians | `net.ipv4.conf.all.log_martians` | `1` | Log impossible-source packets |
| Ignore broadcast ICMP | `net.ipv4.icmp_echo_ignore_broadcasts` | `1` | Prevent Smurf amplification |
| Ignore bogus ICMP errors | `net.ipv4.icmp_ignore_bogus_error_responses` | `1` | Suppress spoofed ICMP errors |
| Disable IPv6 RA | `net.ipv6.conf.all.accept_ra` | `0` | Prevent rogue router advertisements |

**Security Principle:** Trust Boundary Enforcement

---

## 3. Kernel Security Features

| Control | Parameter | Value | Rationale |
|---------|-----------|-------|-----------|
| ASLR (full) | `kernel.randomize_va_space` | `2` | Randomize all memory segments |
| Disable setuid core dumps | `fs.suid_dumpable` | `0` | Prevent credential leaks via cores |
| Protect hardlinks | `fs.protected_hardlinks` | `1` | Prevent TOCTOU file attacks |
| Protect symlinks | `fs.protected_symlinks` | `1` | Prevent symlink redirect attacks |
| Hide kernel pointers | `kernel.kptr_restrict` | `2` | Block /proc kernel address leakage |
| Restrict dmesg | `kernel.dmesg_restrict` | `1` | Non-root cannot read kernel ring buffer |
| Restrict ptrace | `kernel.yama.ptrace_scope` | `1` | Only parent can trace child processes |

**Security Principle:** Kernel Attack Surface Reduction

---

## 4. Firewall Controls

UFW baseline configured by `harden.sh`:

| Rule | Setting | Rationale |
|------|---------|-----------|
| Default incoming | `deny` | Block all inbound unless explicitly allowed |
| Default outgoing | `allow` | Permit all outbound traffic |
| SSH | `allow OpenSSH` | Maintain administrative access |

Additional services must be explicitly added:
```bash
sudo ufw allow <port/service>
```

**Security Principle:** Default Deny

---

## 5. Intrusion Prevention (Fail2ban)

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| SSH jail | `enabled = true` | Monitor SSH auth failures |
| `maxretry` | `3` | Ban after 3 failures |
| `bantime` | `24h` | 24-hour ban per offending IP |
| `findtime` | `10m` | Failure window for counting |
| `backend` | `systemd` | Ubuntu 22.04 journal-based parsing |

**Security Principle:** Automated Threat Mitigation

---

## 6. File System Permissions

| File/Path | Mode | Owner | Rationale |
|-----------|------|-------|-----------|
| `/etc/shadow` | `640` | `root:shadow` | Password hashes — restricted read |
| `/etc/gshadow` | `000` | `root:shadow` | Group password hashes — no world access |
| `/etc/passwd` | `644` | `root:root` | World-readable; no passwords stored here |
| `/etc/group` | `644` | `root:root` | World-readable group membership |
| `/etc/ssh/sshd_config` | `600` | `root:root` | SSH config — root read only |
| `/etc/crontab` | `600` | `root:root` | Cron jobs — root only |
| `/root` | `700` | `root:root` | Root home — no outside access |

**Security Principle:** Least Privilege

---

## 7. Service Minimization

Services disabled by `harden.sh` if present:

| Service | Reason |
|---------|--------|
| `avahi-daemon` | mDNS/DNS-SD — unnecessary on most servers |
| `cups` | Print daemon — unnecessary on servers |
| `bluetooth` | Bluetooth daemon — unnecessary on VMs/servers |

**Security Principle:** Attack Surface Reduction

---

## 8. Logging & Monitoring

| Component | Mechanism |
|-----------|-----------|
| SSH authentication | `LogLevel VERBOSE` in sshd_config |
| Fail2ban bans | `/var/log/fail2ban.log` |
| Hardening actions | `logs/harden-<timestamp>.log` in repo |
| Rollback actions | `logs/rollback-<timestamp>.log` in repo |
| Martian packets | Kernel sysctl — logged to syslog |

**Future Enhancements:**
- Centralized log aggregation (rsyslog / Loki / ELK)
- OSSEC/Wazuh HIDS integration
- AIDE file integrity monitoring
- auditd policy for privilege escalation events

---

## 9. Scope Limitations

This baseline does **not** include:

- Disk encryption enforcement (LUKS)
- SELinux / AppArmor profile tuning
- Full CIS Benchmark coverage (Level 1/2)
- Advanced auditd rule sets
- Application-layer hardening (web servers, databases)

These can be layered as extensions to this baseline.

---

## Summary

This hardening baseline provides coverage across:

| Domain | Controls |
|--------|----------|
| Remote Access | SSH key-only, no root, session limits |
| Network | IP forward off, SYN cookies, anti-spoof, anti-redirect |
| Kernel | ASLR, ptrace restriction, core dump restriction |
| Firewall | UFW default deny, SSH explicit allow |
| Brute Force | Fail2ban 3-strike, 24h ban |
| Filesystem | Critical file permissions locked down |
| Services | Unnecessary daemons disabled |
| Audit | Timestamped logs for all actions |

Suitable for: cloud VMs, development servers, lab environments, and small production workloads.
