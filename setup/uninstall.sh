#!/usr/bin/env bash
set -euo pipefail

SLUG="codex-edamame"
MCP_KEY="edamame-codex"

OS_KERNEL="$(uname -s)"
case "$OS_KERNEL" in
  Darwin)
    CONFIG_HOME="$HOME/Library/Application Support/$SLUG"
    STATE_HOME="$CONFIG_HOME/state"
    DATA_HOME="$HOME/Library/Application Support/$SLUG"
    ;;
  *)
    CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/$SLUG"
    STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}/$SLUG"
    DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/$SLUG"
    ;;
esac

remove_codex_mcp_entry() {
  local config_path="${CODEX_HOME:-$HOME/.codex}/config.toml"
  [[ -f "$config_path" ]] || return 0
  python3 - "$config_path" <<'PYCODEX'
import shutil
import sys
from pathlib import Path
config_path = Path(sys.argv[1])
marker = "[mcp_servers.edamame-codex]"
raw = config_path.read_text(encoding="utf-8")
if marker not in raw:
    sys.exit(0)
shutil.copy2(config_path, Path(str(config_path) + ".bak"))
lines = raw.splitlines()
out = []
skipping = False
for line in lines:
    if line.strip() == marker:
        skipping = True
        continue
    if skipping and line.startswith("[") and line.strip() != marker:
        skipping = False
    if not skipping:
        out.append(line)
config_path.write_text("\n".join(out).rstrip() + "\n", encoding="utf-8")
PYCODEX
}

remove_codex_mcp_entry

rm -rf "$DATA_HOME"
if [[ "$CONFIG_HOME" != "$DATA_HOME" ]]; then
  rm -rf "$CONFIG_HOME"
fi
if [[ "$STATE_HOME" != "$DATA_HOME" && "$STATE_HOME" != "$CONFIG_HOME" ]]; then
  rm -rf "$STATE_HOME"
fi

echo "Uninstalled EDAMAME for Codex CLI from:"
echo "  $DATA_HOME"
