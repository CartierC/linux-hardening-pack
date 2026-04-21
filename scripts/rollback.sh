#!/bin/bash
# rollback.sh — Reverse linux-hardening-pack security baseline
# Restores original configs from backups created by harden.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$REPO_ROOT/logs"
BACKUP_DIR="/var/backups/linux-hardening-pack"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
LOG_FILE="$LOG_DIR/rollback-${TIMESTAMP}.log"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Reverse every change made by harden.sh, restoring original system state.
Configurations are restored from backups created by harden.sh at:
  $BACKUP_DIR

OPTIONS:
  -h, --help      Show this help message and exit

WHAT THIS SCRIPT REVERSES:
  1. SSH config  — restored from backup, service restarted
  2. Sysctl      — hardening drop-in removed, kernel params reloaded
  3. UFW         — disabled
  4. Fail2ban    — jail.local restored from backup (or removed), service restarted
  5. Note: file permission changes and disabled services are logged
     but must be reviewed and reversed manually (system-specific).

REQUIREMENTS:
  Must be run as root: sudo bash scripts/rollback.sh
  harden.sh must have been run first to create backups.
EOF
    exit 0
}

log() {
    local msg
    msg="[$(date '+%Y-%m-%d %H:%M:%S')] $*"
    echo "$msg"
    echo "$msg" >> "$LOG_FILE"
}

die() {
    log "FATAL: $*" >&2
    exit 1
}

warn() {
    log "WARNING: $*"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)   usage ;;
        *)           die "Unknown option: $1. Use -h for help." ;;
    esac
    shift
done

[[ "$EUID" -eq 0 ]] || die "This script must be run as root. Use: sudo bash $0"

mkdir -p "$LOG_DIR"

[[ -d "$BACKUP_DIR" ]] \
    || die "Backup directory not found: $BACKUP_DIR — was harden.sh run first?"

log "============================================================"
log "  Linux Hardening Pack — rollback.sh"
log "  Timestamp : $TIMESTAMP"
log "  Host      : $(hostname)"
log "  Backup dir: $BACKUP_DIR"
log "============================================================"

# ---------------------------------------------------------------------------
# SECTION 1: Restore SSH config
# ---------------------------------------------------------------------------
log "--- [1/4] Restoring SSH configuration ---"

SSH_BAK="$BACKUP_DIR/sshd_config.bak"
if [[ -f "$SSH_BAK" ]]; then
    cp -p "$SSH_BAK" /etc/ssh/sshd_config
    chmod 600 /etc/ssh/sshd_config
    chown root:root /etc/ssh/sshd_config
    log "  Restored /etc/ssh/sshd_config from $SSH_BAK"
    if sshd -t; then
        systemctl restart ssh
        log "  SSH service restarted successfully."
    else
        warn "Restored sshd_config failed syntax check — SSH NOT restarted."
        warn "Inspect $SSH_BAK manually before restarting SSH."
    fi
else
    warn "No SSH backup found at $SSH_BAK — skipping SSH restore."
fi

# ---------------------------------------------------------------------------
# SECTION 2: Restore sysctl (remove hardening drop-in)
# ---------------------------------------------------------------------------
log "--- [2/4] Removing sysctl hardening configuration ---"

SYSCTL_DROPIN="/etc/sysctl.d/99-hardening.conf"
if [[ -f "$SYSCTL_DROPIN" ]]; then
    rm -f "$SYSCTL_DROPIN"
    log "  Removed $SYSCTL_DROPIN"
fi

SYSCTL_BAK="$BACKUP_DIR/sysctl.conf.bak"
if [[ -f "$SYSCTL_BAK" ]]; then
    cp -p "$SYSCTL_BAK" /etc/sysctl.conf
    log "  Restored /etc/sysctl.conf from $SYSCTL_BAK"
fi

sysctl --system > /dev/null 2>&1
log "  Kernel parameters reloaded from remaining sysctl configs."

# ---------------------------------------------------------------------------
# SECTION 3: Disable UFW
# ---------------------------------------------------------------------------
log "--- [3/4] Disabling UFW firewall ---"

if command -v ufw > /dev/null 2>&1; then
    ufw disable || true
    log "  UFW disabled."
else
    log "  UFW not installed — nothing to disable."
fi

# ---------------------------------------------------------------------------
# SECTION 4: Restore fail2ban config
# ---------------------------------------------------------------------------
log "--- [4/4] Restoring fail2ban configuration ---"

FAIL2BAN_BAK="$BACKUP_DIR/jail.local.bak"
if [[ -f "$FAIL2BAN_BAK" ]]; then
    cp -p "$FAIL2BAN_BAK" /etc/fail2ban/jail.local
    log "  Restored /etc/fail2ban/jail.local from $FAIL2BAN_BAK"
else
    # No original existed before harden.sh; remove the deployed config
    rm -f /etc/fail2ban/jail.local
    log "  No prior jail.local backup — removed deployed config."
fi

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    systemctl restart fail2ban
    log "  Fail2ban restarted."
fi

# ---------------------------------------------------------------------------
# MANUAL REVIEW NOTICE
# ---------------------------------------------------------------------------
log "============================================================"
log "  Rollback of automated changes complete."
log ""
log "  MANUAL REVIEW REQUIRED:"
log "  - File permissions (shadow, passwd, crontab) were not"
log "    automatically restored. Verify with: stat /etc/shadow"
log "  - Services disabled by harden.sh (avahi-daemon, cups,"
log "    bluetooth) were NOT re-enabled. Re-enable if needed:"
log "      systemctl enable --now <service>"
log ""
log "  Log file: $LOG_FILE"
log "  Verify state: sudo bash scripts/verify.sh"
log "============================================================"
