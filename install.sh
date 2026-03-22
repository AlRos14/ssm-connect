#!/usr/bin/env bash
# install.sh — Install ssm-connect to /usr/local/bin
# Usage: curl -fsSL https://raw.githubusercontent.com/AlRos14/ssm-connect/main/install.sh | bash

set -euo pipefail

REPO="AlRos14/ssm-connect"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="ssm-connect"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main/${SCRIPT_NAME}"

GREEN='\033[0;32m'; CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info() { echo -e "${CYAN}ℹ $*${RESET}"; }
ok()   { echo -e "${GREEN}✔ $*${RESET}"; }

# Check dependencies
for cmd in aws jq; do
  command -v "$cmd" &>/dev/null || {
    echo "✖ Required command not found: $cmd" >&2
    exit 1
  }
done

info "Downloading ssm-connect…"
tmp=$(mktemp)
curl -fsSL "$RAW_URL" -o "$tmp"
chmod +x "$tmp"

# Validate it's a real ssm-connect script
bash -n "$tmp" || { echo "✖ Downloaded script failed syntax check" >&2; rm -f "$tmp"; exit 1; }

if [[ -w "$INSTALL_DIR" ]]; then
  mv "$tmp" "${INSTALL_DIR}/${SCRIPT_NAME}"
else
  sudo mv "$tmp" "${INSTALL_DIR}/${SCRIPT_NAME}"
fi

ok "Installed to ${INSTALL_DIR}/${SCRIPT_NAME}"
echo ""
echo -e "Run ${BOLD}ssm-connect${RESET} to start an interactive session."
