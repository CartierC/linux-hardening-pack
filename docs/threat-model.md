# Threat Model
Repository: linux-hardening-pack
Version: 2.0

---

## 1. Assets Protected

| Asset | Description |
|-------|-------------|
| Remote SSH access | Administrative entry point — highest value target |
| Kernel networking stack | IP stack, routing, socket behavior |
| Authentication mechanisms | Password hashes, public key material |
| Open ports and services | Any service listening on a network interface |
| Filesystem integrity | Sensitive config and credential files |
| Service availability | Stability of running processes |

---

## 2. Threat Actors

| Actor | Capability | Likelihood | Risk |
|-------|------------|------------|------|
| Internet brute-force bots | Automated credential stuffing + password spray | Very High | High |
| Opportunistic scanners | Port scanning, service fingerprinting, CVE matching | Very High | High |
| Low-skill attackers | Default config exploitation, leaked credentials | Medium | Medium |
| Insider / misconfiguration | Accidental exposure, over-privileged accounts | Low | Medium |
| Targeted attacker | Exploit chaining, privilege escalation | Low | High |

---

## 3. Primary Threats and Mitigations

### 3.1 SSH Brute Force Attacks

**Attack pattern:** Automated bots attempt thousands of username/password combinations
against exposed SSH port 22.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| Disable password authentication | `PasswordAuthentication no` — eliminates password-based attacks entirely |
| Fail2ban SSH jail | Ban IP after 3 failures within 10 minutes; 24-hour ban |
| Limit auth attempts per connection | `MaxAuthTries 4` |
| Short auth timeout | `LoginGraceTime 30` |

**Residual risk:** Compromised private SSH keys used directly.

---

### 3.2 Credential Stuffing

**Attack pattern:** Attacker reuses leaked username/password pairs from data breaches
to attempt login on SSH.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| Key-only authentication | `PasswordAuthentication no` + `PubkeyAuthentication yes` |
| Root login disabled | `PermitRootLogin no` — eliminates highest-value target account |
| No empty passwords | `PermitEmptyPasswords no` |

**Residual risk:** Key material on a compromised endpoint device.

---

### 3.3 Network Spoofing and MITM

**Attack pattern:** Attacker sends crafted ICMP redirect packets or source-routed
packets to manipulate routing and intercept traffic.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| Reverse path filtering | `net.ipv4.conf.all.rp_filter=1` — drops packets with invalid source routes |
| Disable ICMP redirects | `accept_redirects=0`, `secure_redirects=0` — reject route manipulation |
| Disable source routing | `accept_source_route=0` — block attacker-supplied routing headers |
| Disable send redirects | `send_redirects=0` — not a router |
| Log martian packets | `log_martians=1` — log impossible source addresses for investigation |

**Residual risk:** Attacks at OSI layers above the kernel (application-layer MITM).

---

### 3.4 SYN Flood Denial of Service

**Attack pattern:** Attacker sends high volume of TCP SYN packets to exhaust server
connection table and cause service unavailability.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| SYN cookies | `net.ipv4.tcp_syncookies=1` — stateless SYN response; no half-open connection table exhaustion |

**Residual risk:** Volumetric DDoS beyond kernel-level SYN cookies (requires upstream filtering).

---

### 3.5 Privilege Escalation

**Attack pattern:** Attacker with low-privilege shell access attempts to escalate
to root via kernel exploits, SUID binaries, symlink attacks, or
TOCTOU race conditions.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| ASLR full randomization | `kernel.randomize_va_space=2` — randomizes stack, heap, VDSO, mmap |
| Disable setuid core dumps | `fs.suid_dumpable=0` — prevent credential leaks from core files |
| Protect hardlinks | `fs.protected_hardlinks=1` — restrict hardlink creation to file owner |
| Protect symlinks | `fs.protected_symlinks=1` — prevent symlink TOCTOU attacks |
| Restrict ptrace | `kernel.yama.ptrace_scope=1` — only parent processes may trace children |
| Root SSH disabled | `PermitRootLogin no` — reduces attacker's ultimate target availability |
| Root home locked | `/root` mode `700` — no outside filesystem access to root home |

**Residual risk:** Zero-day kernel vulnerabilities; application-level escalation.

---

### 3.6 Kernel Exploits

**Attack pattern:** Attacker exploits a kernel vulnerability to escape a process
sandbox, bypass ASLR, or achieve arbitrary kernel code execution. Common
vectors: use-after-free, heap overflow, integer overflow in syscall handlers.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| ASLR (`randomize_va_space=2`) | Randomizes memory layout, making address-prediction exploits harder |
| Hide kernel pointers | `kernel.kptr_restrict=2` — `/proc/kallsyms` and similar show 0x0000 to non-root |
| Restrict dmesg | `kernel.dmesg_restrict=1` — hide kernel messages that reveal addresses/state |
| Restrict ptrace | `kernel.yama.ptrace_scope=1` — limits process introspection |
| Disable core dumps for SUID | `fs.suid_dumpable=0` — SUID process core files cannot be written |

**Residual risk:** Kernel 0-days that bypass all of the above. Mitigated in combination
with timely kernel patching (`apt-get upgrade`), which harden.sh initiates.

---

### 3.7 Unauthorized Service Exposure

**Attack pattern:** A misconfigured or newly installed service binds to a network
interface and becomes accessible to attackers before it is explicitly permitted.

**Mitigations applied:**

| Mitigation | Mechanism |
|------------|-----------|
| UFW default deny incoming | All inbound ports blocked unless explicitly allowed |
| Explicit SSH-only allow | Only OpenSSH passes the firewall; all other ports blocked by default |
| Service minimization | `avahi-daemon`, `cups`, `bluetooth` disabled — reduce listening footprint |

**Residual risk:** Services installed after hardening that are not reviewed against
UFW rules. Mitigate by auditing `ss -tlnp` periodically.

---

## 4. Residual Risks Summary

| Risk | Severity | Mitigated By This Pack |
|------|----------|------------------------|
| Compromised SSH private key | High | No — key hygiene is out of scope |
| Zero-day kernel exploits | High | Partially — ASLR, kptr_restrict, patch on deploy |
| Application-layer vulnerabilities | Medium | No — app hardening is out of scope |
| Cloud IAM misconfiguration | Medium | No — cloud control plane is out of scope |
| Insider threat with sudo access | Medium | Partially — audit logs, no root SSH |
| Post-install service exposure | Low | Partially — UFW default deny covers it if not bypassed |

---

## 5. Security Philosophy

**Defense in Depth** — no single control is relied upon exclusively:

```
Layer 1: Reduce attack surface
         → Disable password auth, unused services, forwarding
Layer 2: Enforce secure defaults
         → Harden sshd_config, sysctl, file permissions
Layer 3: Automated detection and response
         → Fail2ban auto-ban after 3 SSH failures
Layer 4: Verify configuration state
         → verify.sh — automated PASS/FAIL for every control
Layer 5: Reversible change management
         → rollback.sh — restore original state from backup
Layer 6: Continuous validation
         → CI pipeline runs lint, config validation, full integration test on every push
```

---

## Conclusion

This threat model targets the highest-frequency, highest-impact threats against
Linux servers exposed to the internet:

- **Remote access abuse** (SSH brute force, credential stuffing) — fully mitigated
- **Opportunistic scanning** (default configs, open ports) — fully mitigated
- **Network-layer attacks** (spoofing, MITM, SYN flood) — fully mitigated
- **Local privilege escalation** (kernel features, SUID abuse) — substantially mitigated
- **Kernel exploits** — partially mitigated (requires patch management in addition)

It intentionally defers advanced threats (nation-state, complex APT, zero-day chains)
to additional tooling: AIDE, auditd, SELinux/AppArmor, EDR/XDR.
