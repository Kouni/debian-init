#!/usr/bin/env bash
#
# Linter and style verification script according to Google Shell Style Guide.

set -euo pipefail

main() {
  local failed=0

  echo "● Running shellcheck on shell scripts..."
  if command -v shellcheck >/dev/null 2>&1; then
    for f in *.sh; do
      if [[ -f "${f}" ]]; then
        if ! shellcheck "${f}"; then
          echo "  → [FAIL] shellcheck failed on ${f}"
          failed=1
        else
          echo "  → [OK] shellcheck passed for ${f}"
        fi
      fi
    done
  else
    echo "  → [WARNING] shellcheck not found."
  fi

  echo "● Checking line length (max 80 chars)..."
  for f in *.sh; do
    if [[ -f "${f}" ]]; then
      local long_lines
      long_lines="$(awk 'length > 80 { print NR ":" $0 }' "${f}")"
      if [[ -n "${long_lines}" ]]; then
        echo "  → [FAIL] Found lines over 80 characters in ${f}:"
        echo "${long_lines}"
        failed=1
      else
        echo "  → [OK] Line length check passed for ${f}"
      fi
    fi
  done

  echo "● Checking for tab characters..."
  for f in *.sh; do
    if [[ -f "${f}" ]]; then
      if grep -n $'\t' "${f}" >/dev/null 2>&1; then
        echo "  → [FAIL] Found tab characters in ${f}"
        failed=1
      else
        echo "  → [OK] No tabs found in ${f}"
      fi
    fi
  done

  if [[ "${failed}" -ne 0 ]]; then
    echo "[ERROR] Linting failed. Fix style issues before commit/push."
    exit 1
  fi

  echo "[OK] All style and linting checks passed cleanly."
}

main "$@"
