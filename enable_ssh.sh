#!/usr/bin/env bash

set -euo pipefail

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Please run as root: sudo $0 [username]"
  exit 1
fi

TARGET_USER="${1:-${SUDO_USER:-$USER}}"
echo "Selected User: $TARGET_USER"
echo "Sudo User: $SUDO_USER"

echo "Enabling OpenSSH via launchctl"
launchctl enable system/com.openssh.sshd || true
if ! launchctl print system/com.openssh.sshd >/dev/null 2>&1; then
  echo "Bootstraping ssh.plist via launchctl"
  launchctl bootstrap system /System/Library/LaunchDaemons/ssh.plist || true
fi
echo "Kickstart OpenSSH via launchctl"
launchctl kickstart -k system/com.openssh.sshd || true


# 2) Restrict SSH to specific users via the special group com.apple.access_ssh
if ! dscl . -read /Groups/com.apple.access_ssh >/dev/null 2>&1; then
  echo "Restrict SSH to special group com.apple.access_ssh"
  dseditgroup -o create com.apple.access_ssh
fi
if ! dseditgroup -o checkmember -m "$TARGET_USER" com.apple.access_ssh | grep -q "yes"; then
  echo "Adding $TARGET_USER to special group com.apple.access_ssh"
  dseditgroup -o edit -a "$TARGET_USER" -t user com.apple.access_ssh
fi

# 3) Make sure the macOS Application Firewall allows sshd (usually auto, but ensure)
echo "Making sure the macOS Application Firewall allows sshd"
/usr/libexec/ApplicationFirewall/socketfilterfw --add /usr/libexec/sshd-keygen-wrapper >/dev/null 2>&1 || true
/usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp /usr/libexec/sshd-keygen-wrapper >/dev/null 2>&1 || true

STATUS="Off"
STATUS_CHECKMARK="❌"
launchctl print system/com.openssh.sshd >/dev/null 2>&1 && STATUS="On" && STATUS_CHECKMARK="✅"

# 4) Show how to connect
HOSTNAME="$(scutil --get LocalHostName 2>/dev/null || echo "$(hostname -s)").local"
IP="$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || true)"
echo "$STATUS_CHECKMARK Remote Login is $STATUS and limited to: $TARGET_USER"
echo "   Try from your old Mac:"
echo "     ssh $TARGET_USER@$HOSTNAME"
[[ -n "$IP" ]] && echo "     or: ssh $TARGET_USER@$IP"
