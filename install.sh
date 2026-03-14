#!/usr/bin/env bash
set -euo pipefail

# Install skills into Claude Code and/or Codex based on frontmatter type field.
#
# type: command  → ~/.claude/commands/<name>.md  (symlink SKILL.md)
# type: agent    → ~/.claude/agents/<name>.md    (symlink SKILL.md)
# type: skill    → ~/.claude/commands/<name>.md  (symlink SKILL.md)
#
# All types also get symlinked into Codex skills/ (directory symlink).
#
# Usage: ./install.sh [--uninstall] [--dry-run]

CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${HOME}/.codex"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

DRY_RUN=false
MODE="install"

for arg in "$@"; do
  case "$arg" in
    --uninstall) MODE="uninstall" ;;
    --dry-run)   DRY_RUN=true ;;
    -h|--help)
      echo "Usage: $0 [--uninstall] [--dry-run]"
      echo "  --uninstall  Remove installed skill symlinks"
      echo "  --dry-run    Show what would be done without making changes"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--uninstall] [--dry-run]"
      exit 1
      ;;
  esac
done

run() {
  if [ "$DRY_RUN" = true ]; then
    echo "    (dry-run) $*"
  else
    "$@"
  fi
}

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
    run ln -sf "$src" "$dest"
  elif [ -e "$dest" ]; then
    echo "  ⚠ exists (not a symlink), backing up: ${label}"
    run mv "$dest" "${dest}.bak"
    run ln -s "$src" "$dest"
  else
    echo "  + linking: ${label}"
    run ln -s "$src" "$dest"
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
    run ln -sfn "$src" "$dest"
  elif [ -d "$dest" ]; then
    echo "  ⚠ exists (not a symlink), backing up: ${label}"
    run mv "$dest" "${dest}.bak"
    run ln -sfn "$src" "$dest"
  else
    echo "  + linking: ${label}"
    run ln -sfn "$src" "$dest"
  fi
}

unlink_path() {
  local src="$1" dest="$2" label="$3"
  if [ -L "$dest" ]; then
    local current
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      run rm "$dest"
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
  awk '/^---$/{n++; next} n==1 && /^type:/{print $2; exit}' "$skill_md"
}

# Gather all skills
skill_dirs=()
for d in "${SKILLS_DIR}"/*/; do
  [ -f "${d}SKILL.md" ] && skill_dirs+=("${d%/}")
done

if [ ${#skill_dirs[@]} -eq 0 ]; then
  echo "No skills found in ${SKILLS_DIR}/"
  exit 1
fi

# Uninstall mode
if [ "$MODE" = "uninstall" ]; then
  for skill_path in "${skill_dirs[@]}"; do
    name="$(basename "$skill_path")"
    type="$(get_type "${skill_path}/SKILL.md")"

    if [ -z "$type" ]; then
      echo "  ⚠ ${name}: no type in frontmatter, skipping"
      continue
    fi

    case "$type" in
      command|skill)
        unlink_path "${skill_path}/SKILL.md" "${CLAUDE_DIR}/commands/${name}.md" "claude:commands/${name}.md"
        ;;
      agent)
        unlink_path "${skill_path}/SKILL.md" "${CLAUDE_DIR}/agents/${name}.md" "claude:agents/${name}.md"
        ;;
    esac

    # All skills unlink from Codex
    if [ -d "${CODEX_DIR}" ]; then
      unlink_path "${skill_path}" "${CODEX_DIR}/skills/${name}" "codex:skills/${name}"
    fi
  done

  echo "Done."
  exit 0
fi

# Install mode
run mkdir -p "${CLAUDE_DIR}/commands" "${CLAUDE_DIR}/agents"
[ -d "${CODEX_DIR}" ] && run mkdir -p "${CODEX_DIR}/skills"

echo "Installing skills..."
echo ""

for skill_path in "${skill_dirs[@]}"; do
  name="$(basename "$skill_path")"
  type="$(get_type "${skill_path}/SKILL.md")"

  if [ -z "$type" ]; then
    echo "  ⚠ ${name}: no type in frontmatter, skipping"
    continue
  fi

  echo "  ${name} (type: ${type})"

  # Claude Code: symlink SKILL.md into commands/ or agents/
  case "$type" in
    command|skill)
      link_file "${skill_path}/SKILL.md" "${CLAUDE_DIR}/commands/${name}.md" "  → claude:commands/${name}.md"
      ;;
    agent)
      link_file "${skill_path}/SKILL.md" "${CLAUDE_DIR}/agents/${name}.md" "  → claude:agents/${name}.md"
      ;;
    *)
      echo "    ⚠ unknown type '${type}', skipping Claude Code install"
      ;;
  esac

  # Codex: symlink entire directory
  if [ -d "${CODEX_DIR}" ]; then
    link_dir "${skill_path}" "${CODEX_DIR}/skills/${name}" "  → codex:skills/${name}"
  fi

  echo ""
done

echo "Installed! Run './install.sh --uninstall' to remove."
