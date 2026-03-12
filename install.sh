#!/usr/bin/env bash
set -euo pipefail

# Install Claude Code custom commands and agents
# Usage: ./install.sh [--uninstall]

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

commands=(
  "generate-pdfs.md"
  "health-analysis.md"
)

agents=(
  "crash-diagnostics.md"
)

link_file() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  ✓ already linked: $(basename "$dest")"
      return
    fi
    echo "  ↻ updating link: $(basename "$dest")"
    ln -sf "$src" "$dest"
  elif [ -e "$dest" ]; then
    echo "  ⚠ exists (not a symlink), backing up: $(basename "$dest")"
    mv "$dest" "${dest}.bak"
    ln -s "$src" "$dest"
  else
    echo "  + linking: $(basename "$dest")"
    ln -s "$src" "$dest"
  fi
}

unlink_file() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      rm "$dest"
      echo "  - removed: $(basename "$dest")"
    else
      echo "  ⚠ skipping $(basename "$dest") — points elsewhere"
    fi
  elif [ -e "$dest" ]; then
    echo "  ⚠ skipping $(basename "$dest") — not a symlink"
  else
    echo "  · not installed: $(basename "$dest")"
  fi
}

if [ "${1:-}" = "--uninstall" ]; then
  echo "Uninstalling commands..."
  for f in "${commands[@]}"; do
    unlink_file "${SCRIPT_DIR}/commands/${f}" "${CLAUDE_DIR}/commands/${f}"
  done

  echo "Uninstalling agents..."
  for f in "${agents[@]}"; do
    unlink_file "${SCRIPT_DIR}/agents/${f}" "${CLAUDE_DIR}/agents/${f}"
  done

  echo "Done."
  exit 0
fi

# Install
mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"

echo "Installing commands..."
for f in "${commands[@]}"; do
  link_file "${SCRIPT_DIR}/commands/${f}" "${CLAUDE_DIR}/commands/${f}"
done

echo "Installing agents..."
for f in "${agents[@]}"; do
  link_file "${SCRIPT_DIR}/agents/${f}" "${CLAUDE_DIR}/agents/${f}"
done

echo ""
echo "Installed! Commands and agents are available in your next Claude Code session."
echo "Run './install.sh --uninstall' to remove."
