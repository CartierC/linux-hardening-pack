# Security Policy

## Scope

This is a portfolio project demonstrating Linux hardening automation.
It is not production infrastructure. No sensitive systems depend on this code.

## Reporting Issues

If you identify a bug in a script that could cause unintended system changes
(e.g., data loss, lockout risk, destructive rollback behavior), open a GitHub Issue.

## Safe Usage

- Always run `sudo bash scripts/harden.sh --dry-run` before applying changes.
- Ensure a valid SSH public key exists in `~/.ssh/authorized_keys` before hardening.
- Review `docs/threat-model.md` for documented residual risks.
