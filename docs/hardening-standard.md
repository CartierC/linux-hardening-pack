# Linux Hardening Standard
Repository: linux-hardening-pack  
Baseline Target: Ubuntu 22.04 LTS (Debian-based systems)

---

## Objective

This hardening standard defines a reproducible security baseline for Linux systems.  
The goal is to reduce attack surface, enforce secure defaults, and implement layered defense.

This standard is implemented via:
- scripts/harden.sh
- scripts/verify.sh
- configs/*.secure

---

# 1. Access Control Hardening

## SSH Configuration

| Control | Setting | Rationale |
|----------|----------|------------|
| Disable root login | PermitRootLogin no | Prevent direct root compromise |
| Disable password auth | PasswordAuthentication no | Enforce key-based access |
| Disable X11 forwarding | X11Forwarding no | Reduce attack surface |
| Limit auth attempts | MaxAuthTries 4 | Mitigate brute force |
| Idle timeout | ClientAliveInterval 300 | Drop stale sessions |

Security Principle: Least Privilege + Minimized Exposure

---

# 2. Network Hardening

## Kernel Networking Controls (sysctl)

| Control | Value | Rationale |
|----------|--------|------------|
| Disable IP forwarding | net.ipv4.ip_forward=0 | Prevent routing abuse |
| Disable redirects | accept_redirects=0 | Prevent MITM manipulation |
| Enable rp_filter | rp_filter=1 | Prevent spoofed packets |
| Disable source routing | accept_source_route=0 | Block malicious routing |

Security Principle: Trust Boundary Enforcement

---

# 3. Firewall Controls

UFW baseline:

- Default deny incoming
- Default allow outgoing
- Allow OpenSSH only
- Explicit allow rules required for additional services

Security Principle: Default Deny

---

# 4. Intrusion Prevention

Fail2ban baseline:

- SSH jail enabled
- maxretry: 5
- bantime: 1h
- findtime: 10m

Security Principle: Automated Threat Mitigation

---

# 5. Logging & Monitoring

- SSH verbose logging enabled
- Fail2ban active monitoring
- Hardening actions logged under logs/

Future Enhancements:
- Centralized logging (rsyslog / ELK)
- OSSEC/Wazuh integration
- AIDE file integrity monitoring

---

# 6. Scope Limitations

This baseline does NOT include:
- Disk encryption enforcement
- SELinux/AppArmor tuning
- Full CIS benchmark coverage
- Advanced auditd policies

These can be layered in future versions.

---

# Summary

This hardening baseline provides:

- Secure remote access
- Kernel-level network protection
- Firewall enforcement
- Automated brute-force mitigation
- Reproducible automation with rollback capability

It is suitable for:
- Cloud VMs
- Development servers
- Lab environments
- Small production workloads