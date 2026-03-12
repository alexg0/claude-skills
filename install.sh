#!/usr/bin/env bash
set -euo pipefail

# Install Claude Code custom commands/agents and Codex skills
# Usage: ./install.sh [--uninstall]

CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${HOME}/.dotfiles/codex"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

commands=(
  "generate-pdfs.md"
  "health-analysis.md"
)

agents=(
  "crash-diagnostics.md"
)

codex_skills=(
  "devonthink-mcp"
  "general-pr-helper"
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

link_dir() {
  local src="$1" dest="$2"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  ✓ already linked: $(basename "$dest")"
      return
    fi
    echo "  ↻ updating link: $(basename "$dest")"
    ln -sfn "$src" "$dest"
  elif [ -d "$dest" ]; then
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
  echo "Uninstalling Claude Code commands..."
  for f in "${commands[@]}"; do
    unlink_file "${SCRIPT_DIR}/commands/${f}" "${CLAUDE_DIR}/commands/${f}"
  done

  echo "Uninstalling Claude Code agents..."
  for f in "${agents[@]}"; do
    unlink_file "${SCRIPT_DIR}/agents/${f}" "${CLAUDE_DIR}/agents/${f}"
  done

  echo "Uninstalling Codex skills..."
  for skill in "${codex_skills[@]}"; do
    unlink_file "${SCRIPT_DIR}/codex-skills/${skill}" "${CODEX_DIR}/skills/${skill}"
  done

  echo "Done."
  exit 0
fi

# Install Claude Code extensions
mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"

echo "Installing Claude Code commands..."
for f in "${commands[@]}"; do
  link_file "${SCRIPT_DIR}/commands/${f}" "${CLAUDE_DIR}/commands/${f}"
done

echo "Installing Claude Code agents..."
for f in "${agents[@]}"; do
  link_file "${SCRIPT_DIR}/agents/${f}" "${CLAUDE_DIR}/agents/${f}"
done

# Install Codex skills
if [ -d "${CODEX_DIR}" ]; then
  mkdir -p "${CODEX_DIR}/skills"

  echo "Installing Codex skills..."
  for skill in "${codex_skills[@]}"; do
    link_dir "${SCRIPT_DIR}/codex-skills/${skill}" "${CODEX_DIR}/skills/${skill}"
  done
else
  echo ""
  echo "Skipping Codex skills — ${CODEX_DIR} not found."
  echo "Set CODEX_DIR env var if your Codex config is elsewhere."
fi

echo ""
echo "Installed! Extensions are available in your next session."
echo "Run './install.sh --uninstall' to remove."
