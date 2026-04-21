# Linux Hardening Pack

Standardized Linux security hardening — scripts, configs, verification, and CI/CD pipeline
for enforcing a reproducible security baseline on Ubuntu/Debian servers.

---

## Purpose

This project implements a real-world Linux hardening baseline using repeatable automation,
structured configuration files, and a full verify-and-rollback workflow.

Designed as a portfolio-ready demonstration of:

- SSH hardening and key-based authentication enforcement
- Kernel network hardening via sysctl
- Firewall configuration (UFW default deny)
- Automated brute-force protection (fail2ban)
- File permission hardening
- Service minimization
- Operational discipline: apply → verify → rollback
- CI/CD validation pipeline (ShellCheck + config syntax + integration test)

---

## Architecture

```
linux-hardening-pack/
│
├── scripts/
│   ├── harden.sh          # Apply the full hardening baseline
│   ├── verify.sh          # Verify every control — PASS/FAIL report
│   └── rollback.sh        # Restore original config from backup
│
├── configs/
│   ├── sshd_config.secure     # Hardened OpenSSH configuration
│   ├── sysctl.conf.secure     # Kernel hardening parameters
│   └── fail2ban.local         # Fail2ban SSH jail configuration
│
├── docs/
│   ├── hardening-standard.md     # Full specification of every control
│   ├── threat-model.md           # Threats addressed and residual risks
│   ├── verification-checklist.md # Manual checklist mirroring verify.sh
│   └── verification-output.md    # Example verify.sh output
│
├── logs/                      # Runtime logs (created at first run)
│   └── harden-<timestamp>.log
│
└── .github/
    └── workflows/
        └── ci.yml             # CI: lint, config validation, integration test
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
  ├── Reads /etc/ssh/sshd_config + sshd -T
  ├── Reads live sysctl values
  ├── Queries UFW status
  ├── Queries fail2ban-client
  ├── Checks file stat permissions
  └── Outputs PASS / FAIL / WARN per control

rollback.sh
  ├── Restores /etc/ssh/sshd_config  from backup
  ├── Removes /etc/sysctl.d/99-hardening.conf
  ├── Restores /etc/fail2ban/jail.local  from backup (or removes)
  ├── Disables UFW
  └── Logs every action              → logs/rollback-<timestamp>.log
```

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| OS | Ubuntu 20.04 LTS or 22.04 LTS (Debian-based) |
| Shell | Bash 4.x+ |
| Privileges | `sudo` / root required for harden.sh, rollback.sh, verify.sh |
| Packages installed by script | `ufw`, `fail2ban` (auto-installed by harden.sh) |
| SSH key | At least one public key in `~/.ssh/authorized_keys` **before running** — password auth will be disabled |

> **Warning:** Do not run `harden.sh` on an SSH session without a working
> public key in `authorized_keys`. You will lock yourself out.

---

## Usage

### 1. Clone the repository

```bash
git clone https://github.com/CartierC/linux-hardening-pack.git
cd linux-hardening-pack
chmod +x scripts/*.sh
```

### 2. Apply the hardening baseline

```bash
sudo bash scripts/harden.sh
```

Optional dry-run to preview all actions without making changes:

```bash
sudo bash scripts/harden.sh --dry-run
```

### 3. Verify the baseline

```bash
sudo bash scripts/verify.sh
```

Expected output (all controls active):

```
  RESULT: PASS — All checks passed. Baseline is active.
```

### 4. Roll back all changes

```bash
sudo bash scripts/rollback.sh
```

Restores original configs from `/var/backups/linux-hardening-pack/` and disables
UFW and fail2ban. After rollback, run `verify.sh` to confirm state.

### 5. Getting help

Every script supports `--help`:

```bash
bash scripts/harden.sh   --help
bash scripts/verify.sh   --help
bash scripts/rollback.sh --help
```

---

## CI/CD Pipeline

The `.github/workflows/ci.yml` pipeline runs on every push and pull request to `main`.

### Pipeline Jobs

| Job | What It Does |
|-----|-------------|
| **lint-scripts** | ShellCheck lints all `.sh` files; bash syntax check; `--help` flag test |
| **validate-configs** | `sshd -t` validates sshd_config; Python validates fail2ban structure; format-checks sysctl.conf |
| **integration-test** | Full `harden.sh` → `verify.sh` → `rollback.sh` run on an ephemeral Ubuntu VM |

The integration test job only runs if both `lint-scripts` and `validate-configs` pass.
Hardening logs are uploaded as CI artifacts (retained 7 days).

---

## Configuration Files

### `configs/sshd_config.secure`

Key hardening settings:

| Setting | Value | Purpose |
|---------|-------|---------|
| `PermitRootLogin` | `no` | Block direct root SSH |
| `PasswordAuthentication` | `no` | Key-only access |
| `MaxAuthTries` | `4` | Brute-force throttle |
| `LoginGraceTime` | `30` | Auto-drop stalled auths |
| `X11Forwarding` | `no` | Reduce attack surface |
| `AllowTcpForwarding` | `no` | No tunnel abuse |
| `LogLevel` | `VERBOSE` | Log key fingerprints |

### `configs/sysctl.conf.secure`

Key hardening parameters:

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `net.ipv4.ip_forward` | `0` | Not a router |
| `net.ipv4.tcp_syncookies` | `1` | SYN flood protection |
| `net.ipv4.conf.all.rp_filter` | `1` | Block spoofed packets |
| `kernel.randomize_va_space` | `2` | Full ASLR |
| `fs.suid_dumpable` | `0` | No SUID core dumps |
| `kernel.kptr_restrict` | `2` | Hide kernel pointers |

### `configs/fail2ban.local`

| Setting | Value | Purpose |
|---------|-------|---------|
| `maxretry` | `3` | Ban after 3 SSH failures |
| `bantime` | `24h` | 24-hour ban |
| `findtime` | `10m` | 10-minute observation window |

---

## Logs

All hardening, rollback, and run actions are logged with timestamps:

```
logs/harden-2026-04-21_14-30-01.log
logs/rollback-2026-04-21_15-00-43.log
```

Log entries use the format:
```
[2026-04-21 14:30:01] EXEC: cp configs/sshd_config.secure /etc/ssh/sshd_config
[2026-04-21 14:30:01] SSH hardened and restarted.
```

---

## Documentation

| Document | Purpose |
|----------|---------|
| [hardening-standard.md](docs/hardening-standard.md) | Full specification of every control and rationale |
| [threat-model.md](docs/threat-model.md) | Threats addressed, mitigations, residual risks |
| [verification-checklist.md](docs/verification-checklist.md) | Manual audit checklist for every verify.sh check |
| [verification-output.md](docs/verification-output.md) | Example verify.sh output |

---

## Security Considerations

- **Always have a working SSH key loaded before running `harden.sh`.**
  Password authentication is disabled — a missing key means no remote access.
- Backups are stored at `/var/backups/linux-hardening-pack/`. Protect this directory.
- This baseline is a starting point, not a complete CIS benchmark implementation.
  Review [hardening-standard.md](docs/hardening-standard.md) for scope limitations.
- After a major OS upgrade, re-run `harden.sh` to ensure configs are current.
