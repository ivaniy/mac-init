#!/usr/bin/env bash
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
