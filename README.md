# Linux Hardening Pack

Standardized Linux hardening scripts and security configurations designed to demonstrate practical systems administration, baseline security enforcement, validation workflows, and rollback awareness.

## Purpose

This repository showcases a practical Linux hardening approach for entry-level to junior systems, cloud, and DevOps environments. It focuses on turning common security best practices into repeatable scripts, baseline configs, and verification steps.

## What This Repo Demonstrates

- SSH hardening
- Firewall baseline configuration
- Fail2ban baseline protection
- Kernel and system hardening via sysctl
- Validation and verification scripting
- Rollback-aware operational thinking
- CI-based script linting and validation

## Repository Structure

```text
.
├── .github/workflows/   # CI workflow for linting and validation
├── configs/             # Hardened baseline configuration files
├── docs/                # Hardening standard, threat model, verification notes
├── scripts/             # Automation scripts for apply, verify, and rollback
└── README.md
