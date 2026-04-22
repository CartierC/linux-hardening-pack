#!/bin/bash
# verify.sh — Verify linux-hardening-pack baseline is active
# Outputs a structured PASS/FAIL/WARN report for every hardening control

set -euo pipefail

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SSHD_CONFIG="/etc/ssh/sshd_config"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Verify that every linux-hardening-pack hardening control is active.
Outputs a PASS / FAIL / WARN line for each check, followed by a summary.

OPTIONS:
  -h, --help      Show this help message and exit

CHECKS PERFORMED:
  - SSH configuration parameters (PermitRootLogin, PasswordAuthentication, etc.)
  - SSH service active state
  - Kernel sysctl hardening parameters
  - UFW firewall active + default deny incoming
  - Fail2ban service + SSH jail active
  - Critical file permissions (/etc/shadow, /etc/passwd, sshd_config, /root)
  - Hardening log existence

REQUIREMENTS:
  Best run as root (sudo) — some checks require elevated read access.
  sudo bash scripts/verify.sh
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)   usage ;;
        *)           echo "Unknown option: $1. Use -h for help." >&2; exit 1 ;;
    esac
    # shellcheck disable=SC2317
    shift
done

pass() {
    echo "  [PASS] $*"
    PASS_COUNT=$(( PASS_COUNT + 1 ))
}

fail() {
    echo "  [FAIL] $*"
    FAIL_COUNT=$(( FAIL_COUNT + 1 ))
}

warn() {
    echo "  [WARN] $*"
    WARN_COUNT=$(( WARN_COUNT + 1 ))
}

section() {
    echo ""
    echo "=== $* ==="
}

# ---------------------------------------------------------------------------
echo "Linux Hardening Pack — verify.sh"
echo "Run date : $(date)"
echo "Hostname : $(hostname)"
echo "User     : $(whoami)"
echo "======================================"

# ---------------------------------------------------------------------------
# SECTION 1: SSH configuration
# ---------------------------------------------------------------------------
section "SSH Configuration"

# Read a directive's effective value from sshd_config
# sshd -T gives the full runtime config; fall back to grep if unavailable
get_sshd_value() {
    local param="$1"
    local val=""
    # Try sshd -T first (requires valid config + running sshd)
    if val=$(sshd -T 2>/dev/null | grep -i "^${param} " | awk '{print $2}' | head -1); then
        [[ -n "$val" ]] && { echo "$val"; return; }
    fi
    # Fallback: grep config file directly
    val=$(grep -iE "^[[:space:]]*${param}[[:space:]]" "$SSHD_CONFIG" 2>/dev/null \
          | awk '{print $2}' | head -1)
    echo "${val:-not_set}"
}

check_sshd() {
    local param="$1"
    local expected="$2"
    local actual
    actual=$(get_sshd_value "$param")
    if [[ "${actual,,}" == "${expected,,}" ]]; then
        pass "SSH ${param} = ${expected}"
    else
        fail "SSH ${param}: expected '${expected}', got '${actual}'"
    fi
}

check_sshd "PermitRootLogin"         "no"
check_sshd "PasswordAuthentication"  "no"
check_sshd "X11Forwarding"           "no"
check_sshd "MaxAuthTries"            "4"
check_sshd "PubkeyAuthentication"    "yes"
check_sshd "PermitEmptyPasswords"    "no"
check_sshd "AllowTcpForwarding"      "no"
check_sshd "HostbasedAuthentication" "no"
check_sshd "IgnoreRhosts"            "yes"
check_sshd "LoginGraceTime"          "30"

# SSH service running
if systemctl is-active --quiet ssh 2>/dev/null \
    || systemctl is-active --quiet sshd 2>/dev/null; then
    pass "SSH service is running"
else
    fail "SSH service is not running"
fi

# ---------------------------------------------------------------------------
# SECTION 2: Kernel hardening (sysctl)
# ---------------------------------------------------------------------------
section "Kernel Hardening (sysctl)"

check_sysctl() {
    local param="$1"
    local expected="$2"
    local actual
    actual=$(sysctl -n "$param" 2>/dev/null || echo "not_set")
    if [[ "$actual" == "$expected" ]]; then
        pass "sysctl ${param} = ${expected}"
    else
        fail "sysctl ${param}: expected '${expected}', got '${actual}'"
    fi
}

check_sysctl "net.ipv4.ip_forward"                        "0"
check_sysctl "net.ipv4.conf.all.accept_redirects"         "0"
check_sysctl "net.ipv4.conf.default.accept_redirects"     "0"
check_sysctl "net.ipv4.conf.all.send_redirects"           "0"
check_sysctl "net.ipv4.conf.default.send_redirects"       "0"
check_sysctl "net.ipv4.conf.all.accept_source_route"      "0"
check_sysctl "net.ipv4.conf.default.accept_source_route"  "0"
check_sysctl "net.ipv4.conf.all.rp_filter"                "1"
check_sysctl "net.ipv4.conf.default.rp_filter"            "1"
check_sysctl "net.ipv4.tcp_syncookies"                    "1"
check_sysctl "net.ipv4.conf.all.log_martians"             "1"
check_sysctl "net.ipv4.conf.default.log_martians"         "1"
check_sysctl "net.ipv4.icmp_echo_ignore_broadcasts"       "1"
check_sysctl "net.ipv4.icmp_ignore_bogus_error_responses" "1"
check_sysctl "net.ipv6.conf.all.accept_redirects"         "0"
check_sysctl "net.ipv6.conf.default.accept_redirects"     "0"
check_sysctl "kernel.randomize_va_space"                  "2"
check_sysctl "fs.suid_dumpable"                           "0"
check_sysctl "fs.protected_hardlinks"                     "1"
check_sysctl "fs.protected_symlinks"                      "1"

# ---------------------------------------------------------------------------
# SECTION 3: Firewall (UFW)
# ---------------------------------------------------------------------------
section "Firewall (UFW)"

if command -v ufw > /dev/null 2>&1; then
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        pass "UFW is active"

        if ufw status verbose 2>/dev/null | grep -q "Default: deny (incoming)"; then
            pass "UFW default incoming policy: deny"
        else
            fail "UFW default incoming is NOT deny"
        fi

        if ufw status 2>/dev/null | grep -qiE "OpenSSH|22/tcp.*ALLOW"; then
            pass "UFW: SSH (port 22 / OpenSSH) is allowed"
        else
            fail "UFW: SSH is not explicitly allowed"
        fi
    else
        fail "UFW is not active"
    fi
else
    warn "UFW is not installed — firewall checks skipped"
fi

# ---------------------------------------------------------------------------
# SECTION 4: Fail2ban
# ---------------------------------------------------------------------------
section "Fail2ban"

if command -v fail2ban-client > /dev/null 2>&1; then
    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        pass "fail2ban service is running"

        JAIL_STATUS=$(fail2ban-client status sshd 2>/dev/null || echo "error")
        if echo "$JAIL_STATUS" | grep -qiE "Currently banned|Total banned|Jail list"; then
            pass "fail2ban SSH jail (sshd) is active"

            BAN_TIME=$(fail2ban-client get sshd bantime 2>/dev/null || echo "unknown")
            MAX_RETRY=$(fail2ban-client get sshd maxretry 2>/dev/null || echo "unknown")
            pass "fail2ban bantime=${BAN_TIME}s  maxretry=${MAX_RETRY}"
        else
            fail "fail2ban SSH jail is not active or not responding"
        fi
    else
        fail "fail2ban service is not running"
    fi
else
    warn "fail2ban is not installed — fail2ban checks skipped"
fi

# ---------------------------------------------------------------------------
# SECTION 5: File permissions
# ---------------------------------------------------------------------------
section "File Permissions"

check_perms() {
    local file="$1"
    local expected="$2"
    if [[ -e "$file" ]]; then
        local actual
        actual=$(stat -c "%a" "$file" 2>/dev/null || echo "error")
        if [[ "$actual" == "$expected" ]]; then
            pass "Permissions ${file} = ${expected}"
        else
            fail "Permissions ${file}: expected ${expected}, got ${actual}"
        fi
    else
        warn "File not found: ${file} — skipping permission check"
    fi
}

check_perms /etc/shadow       "640"
check_perms /etc/gshadow      "0"
check_perms /etc/passwd       "644"
check_perms /etc/group        "644"
check_perms /etc/ssh/sshd_config "600"
check_perms /etc/crontab      "600"
check_perms /root             "700"

# ---------------------------------------------------------------------------
# SECTION 6: Hardening log
# ---------------------------------------------------------------------------
section "Hardening Log"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$(dirname "$SCRIPT_DIR")/logs"

if ls "${LOG_DIR}"/harden-*.log > /dev/null 2>&1; then
    LATEST_LOG=$(find "${LOG_DIR}" -name "harden-*.log" -type f | sort -t_ | tail -1)
    pass "Hardening log found: $LATEST_LOG"
    LOG_AGE_DAYS=$(( ( $(date +%s) - $(stat -c %Y "$LATEST_LOG") ) / 86400 ))
    if [[ $LOG_AGE_DAYS -gt 30 ]]; then
        warn "Latest hardening log is ${LOG_AGE_DAYS} days old — consider re-running harden.sh"
    fi
else
    warn "No hardening log found in ${LOG_DIR} — harden.sh may not have been run"
fi

# ---------------------------------------------------------------------------
# SUMMARY
# ---------------------------------------------------------------------------
echo ""
echo "======================================"
echo "  VERIFICATION SUMMARY"
echo "======================================"
printf "  PASS : %d\n" "$PASS_COUNT"
printf "  FAIL : %d\n" "$FAIL_COUNT"
printf "  WARN : %d\n" "$WARN_COUNT"
echo "======================================"

if [[ "$FAIL_COUNT" -eq 0 && "$WARN_COUNT" -eq 0 ]]; then
    echo "  RESULT: PASS — All checks passed. Baseline is active."
    exit 0
elif [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo "  RESULT: PASS with warnings — Review WARN items above."
    exit 0
else
    echo "  RESULT: FAIL — ${FAIL_COUNT} check(s) failed. Review FAIL items above."
    exit 1
fi
