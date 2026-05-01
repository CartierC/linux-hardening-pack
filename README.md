# Linux Hardening Pack

[![CI](https://github.com/CartierC/linux-hardening-pack/actions/workflows/ci.yml/badge.svg)](https://github.com/CartierC/linux-hardening-pack/actions/workflows/ci.yml)

Standardized Linux security hardening — scripts, configs, verification, and CI/CD pipeline
for enforcing a reproducible security baseline on Ubuntu/Debian servers.

> **In 30 seconds:** Clone → run one script → verify 35 security controls pass → roll back safely.
> Every change is backed up, every control is verified, and the full apply → verify → rollback
> cycle runs automatically on a real Ubuntu VM on every push.

---

## Skills Demonstrated

| Skill Area | What This Repo Shows |
|------------|----------------------|
| Bash scripting | `set -euo pipefail`, argument parsing, `--dry-run` mode, structured audit logging |
| Linux administration | sshd_config, sysctl.d, UFW, fail2ban, systemd service management, file permissions |
| Security hardening | SSH hardening, kernel parameter tuning, defense in depth, least privilege |
| Operational discipline | Backup-before-change, verify-after-apply, idempotent rollback with restore |
| CI/CD | GitHub Actions: ShellCheck → config validation → integration test on ephemeral Ubuntu VM |
| Technical documentation | Threat model, hardening standard, verification checklist, example runbook output |

---

## Purpose

This project implements a real-world Linux hardening baseline using repeatable automation,
structured configuration files, and a full verify-and-rollback workflow.

Controls implemented:

- SSH hardening and key-based authentication enforcement
- Kernel network hardening via sysctl (20+ parameters)
- Firewall configuration (UFW default deny)
- Automated brute-force protection (fail2ban SSH jail)
- File permission hardening on critical paths
- Service minimization (disable unused daemons)
- Operational discipline: apply → verify → rollback
- CI/CD validation pipeline (ShellCheck + config syntax + integration test)

---

## Repo Structure

```
linux-hardening-pack/
│
├── scripts/
│   ├── harden.sh          # Apply the full hardening baseline
│   ├── verify.sh          # Verify every control — structured PASS/FAIL/WARN report
│   └── rollback.sh        # Restore original config from backup
│
├── configs/
│   ├── sshd_config.secure     # Hardened OpenSSH configuration
│   ├── sysctl.conf.secure     # Kernel hardening parameters (sysctl.d drop-in)
│   └── fail2ban.local         # Fail2ban SSH jail configuration
│
├── docs/
│   ├── hardening-standard.md     # Full specification of every control and rationale
│   ├── threat-model.md           # Threats addressed, mitigations, residual risks
│   ├── verification-checklist.md # Manual audit checklist mirroring verify.sh
│   └── verification-output.md    # Example verify.sh output (35 PASS)
│
├── logs/                      # Runtime logs (created at first run, excluded from git)
│   └── harden-<timestamp>.log
│
└── .github/
    └── workflows/
        └── ci.yml             # CI: file check → lint → config validation → integration test
```

### How the Scripts Relate

```
harden.sh
  ├── Backs up /etc/ssh/sshd_config  → /var/backups/linux-hardening-pack/
  ├── Backs up /etc/sysctl.conf      → /var/backups/linux-hardening-pack/
  ├── Deploys configs/sshd_config.secure  → /etc/ssh/sshd_config
  ├── Deploys configs/sysctl.conf.secure  → /etc/sysctl.d/99-hardening.conf
  ├── Deploys configs/fail2ban.local      → /etc/fail2ban/jail.local
  └── Logs every action              → logs/harden-<timestamp>.log

verify.sh
  ├── Reads /etc/ssh/sshd_config + sshd -T (live effective config)
  ├── Reads live sysctl values
  ├── Queries UFW status
  ├── Queries fail2ban-client
  ├── Checks file stat permissions
  └── Outputs PASS / FAIL / WARN per control → summary with exit code

rollback.sh
  ├── Restores /etc/ssh/sshd_config  from backup
  ├── Removes /etc/sysctl.d/99-hardening.conf, reloads kernel params
  ├── Restores /etc/fail2ban/jail.local from backup (or removes)
  ├── Disables UFW
  └── Logs every action              → logs/rollback-<timestamp>.log
```

---

## Quick Start

```bash
git clone https://github.com/CartierC/linux-hardening-pack.git
cd linux-hardening-pack
chmod +x scripts/*.sh

# Preview all actions without making changes
sudo bash scripts/harden.sh --dry-run

# Apply the full hardening baseline
sudo bash scripts/harden.sh

# Verify all 35 controls pass
sudo bash scripts/verify.sh

# Roll back to original state when done
sudo bash scripts/rollback.sh
```

> **Before running:** Ensure at least one SSH public key is in `~/.ssh/authorized_keys`.
> `harden.sh` disables password authentication — a missing key locks you out remotely.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 20.04 LTS or 22.04 LTS (Debian-based) |
| Shell | Bash 4.x+ |
| Privileges | `sudo` / root required for harden.sh, rollback.sh, verify.sh |
| Packages | `ufw`, `fail2ban` — auto-installed by harden.sh if missing |
| SSH key | At least one public key in `~/.ssh/authorized_keys` **before running** |

---

## Usage

### 1. Apply the hardening baseline

```bash
sudo bash scripts/harden.sh
```

Optional dry-run (preview all actions, make no changes):

```bash
sudo bash scripts/harden.sh --dry-run
```

Every script supports `--help`:

```bash
bash scripts/harden.sh   --help
bash scripts/verify.sh   --help
bash scripts/rollback.sh --help
```

### 2. Verify the baseline

```bash
sudo bash scripts/verify.sh
```

Expected output after successful hardening:

```
  RESULT: PASS — All checks passed. Baseline is active.
```

See [docs/verification-output.md](docs/verification-output.md) for the full 35-check example.

### 3. Roll back all changes

```bash
sudo bash scripts/rollback.sh
```

Restores original configs from `/var/backups/linux-hardening-pack/` and disables
UFW and fail2ban. Run `verify.sh` after rollback to confirm state.

---

## CI/CD Pipeline

The `.github/workflows/ci.yml` pipeline runs on every push and pull request to `main`.

### Pipeline Jobs

| Job | What It Does |
|-----|-------------|
| **lint-scripts** | Verifies required files exist; ShellCheck lints all `.sh` files; bash syntax check; `--help` flag test |
| **validate-configs** | Python validates sshd_config keywords; format-checks sysctl.conf; validates fail2ban structure |
| **integration-test** | Full `harden.sh` → `verify.sh` → `rollback.sh` run on an ephemeral Ubuntu VM |

The integration test is gated — it only runs if both `lint-scripts` and `validate-configs` pass.
Hardening logs are uploaded as CI artifacts (retained 7 days).

---

## Configuration Files

### `configs/sshd_config.secure`

Key hardening settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| `PermitRootLogin` | `no` | Block direct root SSH |
| `PasswordAuthentication` | `no` | Key-only access — eliminates password spray attacks |
| `MaxAuthTries` | `4` | Throttle brute-force attempts per connection |
| `LoginGraceTime` | `30` | Auto-drop stalled authentication attempts |
| `X11Forwarding` | `no` | Remove X11 attack surface |
| `AllowTcpForwarding` | `no` | Block tunnel abuse |
| `AllowAgentForwarding` | `no` | Prevent credential pivoting |
| `LogLevel` | `VERBOSE` | Log key fingerprints for audit trail |
| `Compression` | `no` | Mitigate CRIME-like compression oracle attacks |

### `configs/sysctl.conf.secure`

Key hardening parameters:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `net.ipv4.ip_forward` | `0` | Not a router — disable packet forwarding |
| `net.ipv4.tcp_syncookies` | `1` | SYN flood / DoS protection |
| `net.ipv4.conf.all.rp_filter` | `1` | Drop spoofed source-address packets |
| `net.ipv4.conf.all.accept_redirects` | `0` | Block ICMP redirect MITM attacks |
| `kernel.randomize_va_space` | `2` | Full ASLR — randomize all memory segments |
| `fs.suid_dumpable` | `0` | No SUID core dumps (prevent credential leaks) |
| `kernel.kptr_restrict` | `2` | Hide kernel pointers in /proc from non-root |
| `kernel.yama.ptrace_scope` | `1` | Restrict ptrace to parent processes only |

### `configs/fail2ban.local`

| Setting | Value | Purpose |
|---------|-------|---------|
| `maxretry` | `3` | Ban after 3 SSH auth failures |
| `bantime` | `24h` | 24-hour IP ban |
| `findtime` | `10m` | Failure observation window |
| `backend` | `systemd` | Ubuntu 22.04 journal-based log parsing |

---

## Logs

All hardening and rollback actions are logged with timestamps:

```
logs/harden-2026-04-21_14-30-01.log
logs/rollback-2026-04-21_15-00-43.log
```

Log format:

```
[2026-04-21 14:30:01] EXEC: cp configs/sshd_config.secure /etc/ssh/sshd_config
[2026-04-21 14:30:01] SSH hardened and restarted.
```

Log files are excluded from version control (`.gitignore`) — the `logs/` directory is tracked
with a `.gitkeep` placeholder.

---

## Documentation

| Document | Purpose |
|----------|---------|
| [hardening-standard.md](docs/hardening-standard.md) | Full specification: every control, setting, and rationale |
| [threat-model.md](docs/threat-model.md) | Threats addressed, mitigations per threat, residual risks |
| [verification-checklist.md](docs/verification-checklist.md) | Manual audit checklist — every verify.sh check with manual command |
| [verification-output.md](docs/verification-output.md) | Example verify.sh output — 35 PASS checks after hardening |

---

## Evidence / Verification

The CI badge at the top of this file shows live evidence that:

- ShellCheck passes on all scripts
- All config files validate syntactically
- The full `harden.sh` → `verify.sh` → `rollback.sh` cycle runs cleanly on a real Ubuntu VM

Additional evidence:

- **[verification-output.md](docs/verification-output.md)** — example output showing 35 PASS checks
- **[verification-checklist.md](docs/verification-checklist.md)** — every check mapped to a manual command
- **CI artifacts** — hardening logs uploaded on every integration test run (retained 7 days)

To reproduce locally on any Ubuntu 20.04+ system:

```bash
sudo bash scripts/harden.sh && sudo bash scripts/verify.sh
# Expected: RESULT: PASS — All checks passed. Baseline is active.
```

---

## Hiring Relevance

This repo demonstrates real, testable engineering work — not a tutorial project.

**DevOps / SRE:**
- Infrastructure-as-code mindset applied to server hardening
- CI/CD with gated progression: lint → validate → integration test
- Operational discipline: backup, verify, rollback — not just "apply and hope"
- Timestamped audit logging for every system change

**Security Engineering:**
- Layered defense-in-depth across SSH, kernel, firewall, and intrusion detection
- Threat model with mitigations explicitly mapped to controls
- Compliance-adjacent verification: every control is automated and auditable
- Residual risks documented honestly in [threat-model.md](docs/threat-model.md)

**Linux / Systems Administration:**
- sshd_config, sysctl.d drop-ins, UFW rules, fail2ban jails
- systemd service management (enable, disable, restart)
- Critical file permission hardening (`chmod`, `chown`, `stat`)
- Config backup and restore with validation before service restart

> Every control has a documented rationale in [hardening-standard.md](docs/hardening-standard.md)
> and a mapped threat in [threat-model.md](docs/threat-model.md).

---

## Safety Disclaimer

- **Always have a working SSH key in `~/.ssh/authorized_keys` before running `harden.sh`.**
  Password authentication is disabled by this baseline — no key means no remote access.
- Use `--dry-run` first to preview every action without making system changes.
- Backups are written to `/var/backups/linux-hardening-pack/`. Protect this directory.
- This is a hardening baseline, not a full CIS Benchmark implementation.
  See [hardening-standard.md](docs/hardening-standard.md) for scope and limitations.
- After a major OS upgrade, re-run `harden.sh` to ensure configs remain current.
