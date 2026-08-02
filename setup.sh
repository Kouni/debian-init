#!/usr/bin/env bash
# Description: Disable APT recommendations and configure locales (zh_TW.UTF-8, en_US.UTF-8, default C.UTF-8) on Debian.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Root privileges required." >&2
    exit 1
fi

# 1. Disable APT recommended and suggested packages
cat <<'EOF' > /etc/apt/apt.conf.d/99norecommends
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF
chmod 644 /etc/apt/apt.conf.d/99norecommends

# 2. Configure system locales and purge unselected locales
cat <<'EOF' > /etc/locale.gen
en_US.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
EOF

if command -v debconf-set-selections >/dev/null 2>&1; then
    debconf-set-selections <<'EOF'
locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8, zh_TW.UTF-8 UTF-8
locales locales/default_environment_locale select C.UTF-8
EOF
fi

update-locale LANG=C.UTF-8

if command -v dpkg-reconfigure >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive locales >/dev/null 2>&1
elif command -v locale-gen >/dev/null 2>&1; then
    locale-gen --purge >/dev/null 2>&1
fi

echo "[OK] Applied APT policies and locale configurations."
