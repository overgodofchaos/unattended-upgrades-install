#!/usr/bin/env bash

# Ensure the script is running in bash
if [[ -z "$BASH_VERSION" ]]; then
    echo "Error: bash required" >&2
    exit 1
fi

set -euo pipefail

# Resolve the script directory path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! [[ -f "$SCRIPT_DIR/install.sh" ]];  then
    echo "Error: The script directory could not be determined correctly."
    exit 1
fi

# Check root
if [[ $EUID -ne 0 ]]; then
  echo "Error: root required" >&2
  exit 1
fi

. /etc/os-release

# Check os release
if [[ "$ID" != "debian" && "$ID" != "ubuntu" ]]; then
    echo "Error: supports only debian and ubuntu"
    exit 1
fi

# Check systemd
if ! command -v systemctl >/dev/null 2>&1; then
  echo "Error: supports only systemd." >&2
  exit 1
fi

# Install packages
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades

# Set up
if [[ -f "/etc/apt/apt.conf.d/20auto-upgrades" ]]; then
  mkdir -p "/bak"
  cp "/etc/apt/apt.conf.d/20auto-upgrades" "/bak/20auto-upgrades"
else
  cp "$SCRIPT_DIR/20-auto-upgrades" "/etc/apt/apt.conf.d/20auto-upgrades"
fi

if [[ "$ID" == "debian" ]]; then
  cp "$SCRIPT_DIR/debian/99-unattended-upgrades-settings" "/etc/apt/apt.conf.d/99-unattended-upgrades-settings"
fi

if [[ "$ID" == "ubuntu" ]]; then
  cp "$SCRIPT_DIR/ubuntu/99-unattended-upgrades-settings" "/etc/apt/apt.conf.d/99-unattended-upgrades-settings"
fi

systemctl daemon-reload
systemctl enable --now apt-daily.timer apt-daily-upgrade.timer

echo "Success"


