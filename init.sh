#!/usr/bin/env bash
# Description: Idempotent Debian initialization script for APT policies and locale configuration.
set -euo pipefail

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Root privileges required." >&2
    exit 1
fi

STATUS_APT="SKIP"
STATUS_LOCALES="SKIP"

# 1. APT Settings Check & Apply
APT_CONF="/etc/apt/apt.conf.d/99norecommends"
DESIRED_APT_CONF='APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::PDiffs "false";'

CURRENT_APT_CONF=""
if [ -f "$APT_CONF" ]; then
    CURRENT_APT_CONF="$(cat "$APT_CONF")"
fi

if [ "$CURRENT_APT_CONF" != "$DESIRED_APT_CONF" ]; then
    cat <<'EOF' > "$APT_CONF"
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::PDiffs "false";
EOF
    chmod 644 "$APT_CONF"
    STATUS_APT="OK"
fi

# 2. Locales Check & Apply
DESIRED_LOCALE_GEN="en_US.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8"

CURRENT_LOCALE_GEN=""
if [ -f "/etc/locale.gen" ]; then
    CURRENT_LOCALE_GEN="$(grep -v '^#' /etc/locale.gen | grep -v '^\s*$' || true)"
fi

CURRENT_DEFAULT_LOCALE=""
if [ -f "/etc/default/locale" ]; then
    CURRENT_DEFAULT_LOCALE="$(grep '^LANG=' /etc/default/locale | cut -d= -f2 | tr -d '"' || true)"
fi

LOCALES_INSTALLED=true
if ! dpkg -s locales >/dev/null 2>&1; then
    LOCALES_INSTALLED=false
fi

INSTALLED_LOCALES="$(locale -a 2>/dev/null || true)"
HAS_ZH=$(echo "$INSTALLED_LOCALES" | grep -i 'zh_TW' || true)
HAS_EN=$(echo "$INSTALLED_LOCALES" | grep -i 'en_US' || true)

if [ "$LOCALES_INSTALLED" = false ] || [ "$CURRENT_LOCALE_GEN" != "$DESIRED_LOCALE_GEN" ] || [ "$CURRENT_DEFAULT_LOCALE" != "C.UTF-8" ] || [ -z "$HAS_ZH" ] || [ -z "$HAS_EN" ]; then
    if [ "$LOCALES_INSTALLED" = false ]; then
        DEBIAN_FRONTEND=noninteractive apt-get update -qq </dev/null
        DEBIAN_FRONTEND=noninteractive apt-get install -qq -y locales </dev/null
    fi

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
        DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive locales </dev/null >/dev/null 2>&1
    elif command -v locale-gen >/dev/null 2>&1; then
        locale-gen --purge </dev/null >/dev/null 2>&1
    fi
    STATUS_LOCALES="OK"
fi

# Print status summary
echo "[STATUS] APT Configuration: [${STATUS_APT}]"
echo "[STATUS] Locale Configuration: [${STATUS_LOCALES}]"
