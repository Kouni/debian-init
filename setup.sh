#!/usr/bin/env bash
# Description: Disable automatic installation of recommended and suggested APT packages on Debian.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Root privileges required." >&2
    exit 1
fi

cat <<'EOF' > /etc/apt/apt.conf.d/99norecommends
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
chmod 644 /etc/apt/apt.conf.d/99norecommends

echo "[OK] Disabled APT recommended and suggested packages."
