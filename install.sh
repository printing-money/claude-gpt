#!/usr/bin/env bash
# Installer for claude-gpt: routes Claude Code through claude-code-router (ccr)
# to an OpenAI-compatible gpt-5.x gateway.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DST="/usr/local/bin"
CCR_CONFIG_DIR="${HOME}/.claude-code-router"
CCR_CONFIG="${CCR_CONFIG_DIR}/config.json"

say() { printf '\033[36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mwarn:\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }

# 1. Node.js >= 20.12 check
command -v node >/dev/null 2>&1 || die "node not found. Install Node.js >= 20.12 first."
NODE_MAJOR="$(node -p 'process.versions.node.split(".")[0]')"
if [[ "$NODE_MAJOR" -lt 20 ]]; then
  die "Node $(node -v) is too old. Need >= 20.12 (NodeSource: curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -)."
fi
say "Node $(node -v) OK"

# 2. Install claude-code-router (ccr)
if ! command -v ccr >/dev/null 2>&1; then
  say "Installing @musistudio/claude-code-router globally..."
  npm i -g @musistudio/claude-code-router
else
  say "ccr already installed ($(ccr -v 2>/dev/null | head -1))"
fi

# 3. Install launchers
say "Installing launchers to ${BIN_DST}"
install -m 755 "${REPO_DIR}/bin/claude-real" "${BIN_DST}/claude-real"
install -m 755 "${REPO_DIR}/bin/claude-gpt5" "${BIN_DST}/claude-gpt5"

# 4. Scaffold ccr config (never overwrite an existing one)
mkdir -p "${CCR_CONFIG_DIR}"
if [[ -f "${CCR_CONFIG}" ]]; then
  warn "Config already exists at ${CCR_CONFIG} — leaving it untouched."
else
  install -m 600 "${REPO_DIR}/config/config.example.json" "${CCR_CONFIG}"
  warn "Wrote template ${CCR_CONFIG}. EDIT IT: set api_base_url and api_key."
fi

cat <<EOF

$(say "Done.")
Next:
  1. Edit ${CCR_CONFIG} (set your gateway api_base_url + api_key).
  2. ccr restart
  3. claude-gpt5            # or: claude-gpt5 -p "hello"
EOF
