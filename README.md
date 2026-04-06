# Linux Hardening Pack

Standardized Linux hardening scripts and security configurations designed to demonstrate practical Linux administration, security baseline enforcement, verification workflows, and rollback awareness.

---

## Purpose

This project demonstrates a real-world approach to Linux system hardening using repeatable scripts, structured configurations, and verification processes.  

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
