#!/usr/bin/env bash
set -euo pipefail

# idempotent Rosetta 2 installer/updater for Apple silicon
# - installs Rosetta if missing
# - updates Rosetta when softwareupdate advertises an update
# - otherwise "reinstalls" Rosetta, which is safe and brings it to the latest for this macOS


# Only relevant on Apple silicon
if [[ "$(uname -m)" != "arm64" ]]; then
  echo "Rosetta not needed on this Mac (arch: $(uname -m))."
  exit 0
fi

export installed=0 current_ver=""
if /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
  export installed=1
  current_ver="$(
    /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto \
      | awk -F': ' '/^version:/ {print $2}'
  )"
  echo "Rosetta present (version: ${current_ver})."
else
  echo "Rosetta not installed."
fi

# See if softwareupdate advertises a Rosetta update


if [[ $installed -eq 0 ]]; then
  echo "Installing Rosetta 2..."
  /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  if ! /usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    echo "ERROR: Rosetta not installed after attempted install" >&2
    exit 1
  fi
  ros_ver="$(/usr/sbin/pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto \
    | awk -F': ' '/^version:/ {print $2}')"
  echo "Rosetta version: ${ros_ver}"
  exit 0
fi
