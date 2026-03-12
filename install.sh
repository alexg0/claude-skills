#!/usr/bin/env bash
set -euo pipefail

# Install skills into Claude Code and/or Codex based on frontmatter type field.
#
# type: command  → ~/.claude/commands/<name>.md  (symlink SKILL.md)
# type: agent    → ~/.claude/agents/<name>.md    (symlink SKILL.md)
# type: skill    → ~/.dotfiles/codex/skills/<name>/ (symlink directory)
#
# All types also get symlinked into Codex skills/ (directory symlink).
#
# Usage: ./install.sh [--uninstall]

CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${HOME}/.dotfiles/codex"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

link_file() {
  local src="$1" dest="$2" label="$3"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  ✓ already linked: ${label}"
      return
    fi
    echo "  ↻ updating link: ${label}"
    ln -sf "$src" "$dest"
  elif [ -e "$dest" ]; then
    echo "  ⚠ exists (not a symlink), backing up: ${label}"
    mv "$dest" "${dest}.bak"
    ln -s "$src" "$dest"
  else
    echo "  + linking: ${label}"
    ln -s "$src" "$dest"
  fi
}

link_dir() {
  local src="$1" dest="$2" label="$3"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  ✓ already linked: ${label}"
      return
    fi
    echo "  ↻ updating link: ${label}"
    ln -sfn "$src" "$dest"
  elif [ -d "$dest" ]; then
    echo "  ⚠ exists (not a symlink), backing up: ${label}"
    mv "$dest" "${dest}.bak"
    ln -s "$src" "$dest"
  else
    echo "  + linking: ${label}"
    ln -s "$src" "$dest"
  fi
}

unlink_path() {
  local src="$1" dest="$2" label="$3"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      rm "$dest"
      echo "  - removed: ${label}"
    else
      echo "  ⚠ skipping ${label} — points elsewhere"
    fi
  elif [ -e "$dest" ]; then
    echo "  ⚠ skipping ${label} — not a symlink"
  else
    echo "  · not installed: ${label}"
  fi
}

# Extract type from SKILL.md frontmatter
get_type() {
  local skill_md="$1"
  sed -n '/^---$/,/^---$/p' "$skill_md" | grep '^type:' | head -1 | awk '{print $2}'
}

# Gather all skills
skill_dirs=()
for d in "${SKILLS_DIR}"/*/; do
  [ -f "${d}SKILL.md" ] && skill_dirs+=("$d")
done

if [ ${#skill_dirs[@]} -eq 0 ]; then
  echo "No skills found in ${SKILLS_DIR}/"
  exit 1
fi

# Uninstall mode
if [ "${1:-}" = "--uninstall" ]; then
  for skill_path in "${skill_dirs[@]}"; do
    name="$(basename "$skill_path")"
    type="$(get_type "${skill_path}SKILL.md")"

    case "$type" in
      command)
        unlink_path "${skill_path}SKILL.md" "${CLAUDE_DIR}/commands/${name}.md" "claude:commands/${name}.md"
        ;;
      agent)
        unlink_path "${skill_path}SKILL.md" "${CLAUDE_DIR}/agents/${name}.md" "claude:agents/${name}.md"
        ;;
    esac

    # All skills unlink from Codex
    unlink_path "${skill_path%/}" "${CODEX_DIR}/skills/${name}" "codex:skills/${name}"
  done

  echo "Done."
  exit 0
fi

# Install mode
mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"
[ -d "${CODEX_DIR}" ] && mkdir -p "${CODEX_DIR}/skills"

echo "Installing skills..."
echo ""

for skill_path in "${skill_dirs[@]}"; do
  name="$(basename "$skill_path")"
  type="$(get_type "${skill_path}SKILL.md")"

  echo "  ${name} (type: ${type})"

  # Claude Code: symlink SKILL.md as flat file
  case "$type" in
    command)
      link_file "${skill_path}SKILL.md" "${CLAUDE_DIR}/commands/${name}.md" "  → claude:commands/${name}.md"
      ;;
    agent)
      link_file "${skill_path}SKILL.md" "${CLAUDE_DIR}/agents/${name}.md" "  → claude:agents/${name}.md"
      ;;
    skill)
      echo "    (Claude Code: skipped — skill type not directly supported)"
      ;;
    *)
      echo "    ⚠ unknown type '${type}', skipping Claude Code install"
      ;;
  esac

  # Codex: symlink entire directory
  if [ -d "${CODEX_DIR}" ]; then
    link_dir "${skill_path%/}" "${CODEX_DIR}/skills/${name}" "  → codex:skills/${name}"
  fi

  echo ""
done

echo "Installed! Extensions are available in your next session."
echo "Run './install.sh --uninstall' to remove."
