#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${1:?Usage: $0 <user> <host>}"
TARGET_HOST="${2:?Usage: $0 <user> <host>}"

# Fail fast if we cannot SSH with keys (avoids falling back to passwords)
ssh -o BatchMode=yes "${TARGET_USER}@${TARGET_HOST}" 'echo "SSH ok"'

# Run the bootstrap on the target with sudo (will prompt once for sudo if needed)
ssh -t -o BatchMode=yes "${TARGET_USER}@${TARGET_HOST}" 'bash -s' <<'REMOTE'
set -euo pipefail

echo "==> Checking Command Line Tools (CLT) status"
if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing CLT headlessly via softwareupdate"
  # Make CLT appear in `softwareupdate -l`
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  # Find the most recent "Command Line Tools" label
  LABEL="$(/usr/sbin/softwareupdate -l 2>/dev/null \
    | grep "\*.*Command Line" \
    | awk -F"*" '{print $2}' \
    | sed -e 's/^ Label: //' -e 's/^ *//' \
    | tail -n 1 || true)"

  if [[ -z "\$LABEL" ]]; then
    echo "!! Could not find a CLT label in softwareupdate output."
    echo "   You may need to run once interactively: xcode-select --install"
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    exit 1
  fi

  echo "==> Installing: $LABEL"
  /usr/sbin/softwareupdate -i "$LABEL" --agree-to-license

  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
else
  echo "==> CLT already installed"
fi
REMOTE

ssh -t -o BatchMode=yes "${TARGET_USER}@${TARGET_HOST}" 'bash -s' <<'REMOTE'
echo "==> Verifying /usr/bin/python3"
/usr/bin/python3 - <<'PY'
import sys
print("Python OK:", sys.version)
PY

echo "==> Done"
REMOTE
