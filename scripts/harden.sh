#!/bin/bash
# harden.sh — Apply linux-hardening-pack security baseline
# Target: Ubuntu/Debian-based Linux systems

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="$REPO_ROOT/configs"
LOG_DIR="$REPO_ROOT/logs"
BACKUP_DIR="/var/backups/linux-hardening-pack"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
LOG_FILE="$LOG_DIR/harden-${TIMESTAMP}.log"
DRY_RUN=false

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Apply the linux-hardening-pack security baseline to this system.

OPTIONS:
  -h, --help      Show this help message and exit
  --dry-run       Print all actions without making any changes

WHAT THIS SCRIPT DOES:
  1. Backs up original SSH, sysctl, and fail2ban configs
  2. Deploys hardened configs from $CONFIG_DIR
  3. Configures and enables UFW firewall (default deny incoming)
  4. Configures and enables fail2ban SSH jail
  5. Applies kernel sysctl hardening parameters
  6. Hardens critical file permissions
  7. Disables unused services (avahi-daemon, cups, bluetooth)
  8. Logs all actions with timestamps to $LOG_DIR

REQUIREMENTS:
  Must be run as root: sudo bash scripts/harden.sh
  To reverse: sudo bash scripts/rollback.sh
  To verify:  sudo bash scripts/verify.sh
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

run() {
    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY-RUN] $*"
    else
        log "EXEC: $*"
        "$@"
    fi
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)   usage ;;
        --dry-run)   DRY_RUN=true ;;
        *)           die "Unknown option: $1. Use -h for help." ;;
    esac
    shift
done

[[ "$EUID" -eq 0 ]] || die "This script must be run as root. Use: sudo bash $0"

# Ensure log and backup directories exist
mkdir -p "$LOG_DIR" "$BACKUP_DIR"

log "============================================================"
log "  Linux Hardening Pack — harden.sh"
log "  Timestamp : $TIMESTAMP"
log "  Host      : $(hostname)"
log "  Dry run   : $DRY_RUN"
log "  Repo root : $REPO_ROOT"
log "  Backup dir: $BACKUP_DIR"
log "============================================================"

# ---------------------------------------------------------------------------
# SECTION 1: Backup original configs
# ---------------------------------------------------------------------------
log "--- [1/7] Backing up original configurations ---"

backup_file() {
    local src="$1"
    local dest
    dest="$BACKUP_DIR/$(basename "$src").bak"
    if [[ -f "$src" ]]; then
        if [[ ! -f "$dest" ]]; then
            run cp -p "$src" "$dest"
            log "  Backed up: $src -> $dest"
        else
            log "  Backup exists (skipping): $dest"
        fi
    else
        log "  WARNING: $src not found — no backup created"
    fi
}

backup_file /etc/ssh/sshd_config
backup_file /etc/sysctl.conf
if [[ -f /etc/fail2ban/jail.local ]]; then
    backup_file /etc/fail2ban/jail.local
fi

# ---------------------------------------------------------------------------
# SECTION 2: Install required packages
# ---------------------------------------------------------------------------
log "--- [2/7] Installing required packages ---"
run apt-get update -qq
run apt-get install -y ufw fail2ban
log "  Packages installed: ufw fail2ban"

# ---------------------------------------------------------------------------
# SECTION 3: SSH hardening
# ---------------------------------------------------------------------------
log "--- [3/7] Applying SSH hardening ---"

[[ -f "$CONFIG_DIR/sshd_config.secure" ]] \
    || die "Config not found: $CONFIG_DIR/sshd_config.secure"

run cp "$CONFIG_DIR/sshd_config.secure" /etc/ssh/sshd_config
run chmod 600 /etc/ssh/sshd_config
run chown root:root /etc/ssh/sshd_config

if [[ "$DRY_RUN" == "false" ]]; then
    if ls /etc/ssh/ssh_host_*_key > /dev/null 2>&1; then
        sshd -t || die "sshd config validation failed — SSH service NOT restarted."
        log "  sshd config syntax: OK"
    else
        log "  WARN: No SSH host keys found — skipping sshd -t validation."
    fi
fi

run systemctl restart ssh
log "  SSH hardened and restarted."

# ---------------------------------------------------------------------------
# SECTION 4: Sysctl kernel hardening
# ---------------------------------------------------------------------------
log "--- [4/7] Applying sysctl kernel hardening ---"

[[ -f "$CONFIG_DIR/sysctl.conf.secure" ]] \
    || die "Config not found: $CONFIG_DIR/sysctl.conf.secure"

run cp "$CONFIG_DIR/sysctl.conf.secure" /etc/sysctl.d/99-hardening.conf
run chmod 644 /etc/sysctl.d/99-hardening.conf
run chown root:root /etc/sysctl.d/99-hardening.conf

if [[ "$DRY_RUN" == "false" ]]; then
    sysctl -p /etc/sysctl.d/99-hardening.conf
    log "  Sysctl parameters applied."
fi

# ---------------------------------------------------------------------------
# SECTION 5: Firewall (UFW)
# ---------------------------------------------------------------------------
log "--- [5/7] Configuring UFW firewall ---"
run ufw --force reset
run ufw default deny incoming
run ufw default allow outgoing
run ufw allow OpenSSH
run ufw --force enable
log "  UFW active — default deny incoming, SSH allowed."

# ---------------------------------------------------------------------------
# SECTION 6: Fail2ban
# ---------------------------------------------------------------------------
log "--- [6/7] Configuring fail2ban ---"

[[ -f "$CONFIG_DIR/fail2ban.local" ]] \
    || die "Config not found: $CONFIG_DIR/fail2ban.local"

run cp "$CONFIG_DIR/fail2ban.local" /etc/fail2ban/jail.local
run chmod 640 /etc/fail2ban/jail.local
run chown root:root /etc/fail2ban/jail.local
run systemctl enable fail2ban
run systemctl restart fail2ban
log "  Fail2ban configured, enabled, and restarted."

# ---------------------------------------------------------------------------
# SECTION 7: File permissions + service hardening
# ---------------------------------------------------------------------------
log "--- [7/7] Hardening file permissions and disabling unused services ---"

run chmod 700 /root
run chmod 640 /etc/shadow
run chmod 644 /etc/passwd
run chmod 644 /etc/group
run chmod 000 /etc/gshadow
run chmod 600 /etc/ssh/sshd_config
run chown root:root /etc/crontab
run chmod og-rwx /etc/crontab

# Harden cron directories if they exist
for crondir in /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly; do
    if [[ -d "$crondir" ]]; then
        run chmod og-rwx "$crondir"
    fi
done

log "  File permissions hardened."

# Disable unused services
UNUSED_SERVICES=(avahi-daemon cups bluetooth)
for svc in "${UNUSED_SERVICES[@]}"; do
    if systemctl list-unit-files "${svc}.service" &>/dev/null \
        && systemctl is-enabled "${svc}.service" &>/dev/null 2>&1; then
        run systemctl disable --now "${svc}.service"
        log "  Disabled service: $svc"
    else
        log "  Service not present or already disabled: $svc"
    fi
done

# ---------------------------------------------------------------------------
# DONE
# ---------------------------------------------------------------------------
log "============================================================"
log "  Hardening complete."
log "  Log file : $LOG_FILE"
log "  Next step: sudo bash scripts/verify.sh"
log "  Rollback : sudo bash scripts/rollback.sh"
log "============================================================"
