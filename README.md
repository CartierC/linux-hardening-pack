# Linux Hardening Pack

Standardized Linux hardening scripts and baseline security configurations designed to demonstrate practical system administration, security enforcement, verification workflows, and rollback awareness.

## What This Project Covers
- SSH hardening
- sysctl security tuning
- Fail2Ban baseline configuration
- Validation and verification workflows
- Safer change management through rollback-aware scripting

## Why This Matters
This project reflects the kind of repeatable operational discipline used in real infrastructure environments where security, stability, and auditability matter.
---

It is designed as a **portfolio-ready proof of skill** for roles in:
- IT Support
- Systems Administration
- Cloud Engineering
- DevOps

---

## What This Repo Demonstrates

- SSH hardening awareness
- Firewall validation (UFW)
- Fail2ban service verification
- Kernel hardening checks via `sysctl`
- Security-focused shell scripting
- Operational thinking (apply → verify → rollback)
- CI-based script validation
- Professional repo organization

---

## Repository Structure

```text
.
├── .github/workflows/   # CI workflow for script validation
├── configs/             # Hardened baseline configuration files
├── docs/                # Hardening standards, threat model, verification proof
├── scripts/             # Apply, verify, and rollback scripts
└── README.md
