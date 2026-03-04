# Threat Model
Repository: linux-hardening-pack

---

## 1. Assets Protected

- Remote SSH access
- System kernel networking stack
- Open ports/services
- User authentication mechanisms
- Service availability

---

## 2. Threat Actors

| Actor | Capability | Risk |
|-------|------------|------|
| Internet brute-force bots | Automated password attacks | High |
| Opportunistic scanners | Port scanning & service probing | High |
| Low-skill attackers | Default config exploitation | Medium |
| Insider misuse | Misconfigured privileges | Medium |

---

## 3. Primary Threats

### 1. SSH Brute Force Attacks
Mitigated by:
- PasswordAuthentication no
- Fail2ban SSH jail
- MaxAuthTries limit

---

### 2. Credential Stuffing
Mitigated by:
- Key-based authentication only
- Disabled root login

---

### 3. Network Spoofing / MITM
Mitigated by:
- rp_filter enabled
- Redirects disabled
- Source routing disabled

---

### 4. Unauthorized Service Exposure
Mitigated by:
- UFW default deny incoming
- Explicit allow rules only

---

### 5. Privilege Escalation
Partially mitigated by:
- Disabled root SSH login
- Reduced attack surface

---

## 4. Residual Risks

- Compromised private SSH keys
- Zero-day kernel exploits
- Application-layer vulnerabilities
- Weak IAM in cloud environment

---

## 5. Security Philosophy

Defense in Depth:
1. Reduce attack surface
2. Enforce secure defaults
3. Add automated protection
4. Verify configuration state
5. Enable rollback for safe change management

---

## Conclusion

This threat model focuses on real-world Linux server risks:
- Remote access abuse
- Misconfiguration
- Opportunistic internet scanning

It intentionally prioritizes high-frequency attack patterns over advanced nation-state threats.