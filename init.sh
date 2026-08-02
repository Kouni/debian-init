#!/usr/bin/env bash
#
# Idempotent Debian initialization script for APT policies and locales.
# Strictly adheres to Google Shell Style Guide.

set -euo pipefail

readonly APT_CONF="/etc/apt/apt.conf.d/99norecommends"

configure_apt() {
  local desired_apt_conf
  desired_apt_conf='APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::PDiffs "false";'

  local current_apt_conf=""
  if [[ -f "${APT_CONF}" ]]; then
    current_apt_conf="$(cat "${APT_CONF}")"
  fi

  if [[ "${current_apt_conf}" != "${desired_apt_conf}" ]]; then
    cat <<'EOF' > "${APT_CONF}"
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Acquire::PDiffs "false";
EOF
    chmod 644 "${APT_CONF}"
    echo "OK"
  else
    echo "SKIP"
  fi
}

configure_locales() {
  local desired_locale_gen
  desired_locale_gen='en_US.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8'

  local current_locale_gen=""
  if [[ -f "/etc/locale.gen" ]]; then
    current_locale_gen="$(grep -v '^#' /etc/locale.gen | \
      grep -v '^\s*$' || true)"
  fi

  local current_default_locale=""
  if [[ -f "/etc/default/locale" ]]; then
    current_default_locale="$(grep '^LANG=' /etc/default/locale | \
      cut -d= -f2 | tr -d '"' || true)"
  fi

  local locales_installed=true
  if ! dpkg -s locales >/dev/null 2>&1; then
    locales_installed=false
  fi

  local installed_locales=""
  installed_locales="$(locale -a 2>/dev/null || true)"

  local has_zh=""
  has_zh="$(echo "${installed_locales}" | grep -i 'zh_TW' || true)"

  local has_en=""
  has_en="$(echo "${installed_locales}" | grep -i 'en_US' || true)"

  if [[ "${locales_installed}" == "false" ]] || \
     [[ "${current_locale_gen}" != "${desired_locale_gen}" ]] || \
     [[ "${current_default_locale}" != "C.UTF-8" ]] || \
     [[ -z "${has_zh}" ]] || \
     [[ -z "${has_en}" ]]; then

    if [[ "${locales_installed}" == "false" ]]; then
      DEBIAN_FRONTEND=noninteractive apt-get update -qq </dev/null
      DEBIAN_FRONTEND=noninteractive apt-get install -qq -y locales </dev/null
    fi

    cat <<'EOF' > /etc/locale.gen
en_US.UTF-8 UTF-8
zh_TW.UTF-8 UTF-8
EOF

    if command -v debconf-set-selections >/dev/null 2>&1; then
      local sel_locales="locales locales/locales_to_be_generated multiselect"
      sel_locales+=" en_US.UTF-8 UTF-8, zh_TW.UTF-8 UTF-8"
      local sel_default="locales locales/default_environment_locale"
      sel_default+=" select C.UTF-8"
      printf '%s\n%s\n' "${sel_locales}" "${sel_default}" | \
        debconf-set-selections
    fi

    update-locale LANG=C.UTF-8

    if command -v dpkg-reconfigure >/dev/null 2>&1; then
      DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive \
        locales </dev/null >/dev/null 2>&1
    elif command -v locale-gen >/dev/null 2>&1; then
      locale-gen --purge </dev/null >/dev/null 2>&1
    fi
    echo "OK"
  else
    echo "SKIP"
  fi
}

main() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "[ERROR] Root privileges required." >&2
    exit 1
  fi

  local status_apt=""
  status_apt="$(configure_apt)"

  local status_locales=""
  status_locales="$(configure_locales)"

  echo "[STATUS] APT Configuration: [${status_apt}]"
  echo "[STATUS] Locale Configuration: [${status_locales}]"
}

main "$@"
