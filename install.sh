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

# Detect worktree and resolve master paths for stable symlinks.
# When running from a worktree branch, prefer symlinking to the main
# worktree (master) when files are identical, so symlinks survive
# worktree deletion.
MAIN_WORKTREE=""
IS_WORKTREE=false

if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  _main_wt="$(git -C "$SCRIPT_DIR" worktree list --porcelain | head -1)"
  _main_wt="${_main_wt#worktree }"
  _current_wt="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"

  if [ "$_main_wt" != "$_current_wt" ]; then
    IS_WORKTREE=true
    if git -C "$SCRIPT_DIR" rev-parse --verify master &>/dev/null; then
      MAIN_WORKTREE="$_main_wt"
    else
      echo "⚠ master branch not found — all symlinks will point to this worktree"
    fi
  fi
fi

# Resolve the install source for a skill. In a worktree, prefer the master
# copy when the file/directory is identical. Returns the resolved path on
# stdout; warnings go to stderr.
resolve_source() {
  local current_src="$1"   # absolute path in current worktree
  local rel_path="$2"      # path relative to repo root (e.g. skills/foo/SKILL.md)

  if [ "$IS_WORKTREE" = false ] || [ -z "$MAIN_WORKTREE" ]; then
    echo "$current_src"
    return
  fi

  local master_src="${MAIN_WORKTREE}/${rel_path}"

  if [ ! -e "$master_src" ]; then
    echo "    ⚠ not on master — linking to worktree" >&2
    echo "$current_src"
    return
  fi

  # Compare: file vs file, or directory tree vs directory tree
  if [ -f "$current_src" ]; then
    if ! diff -q "$current_src" "$master_src" &>/dev/null; then
      echo "    ⚠ differs from master — linking to worktree" >&2
      echo "$current_src"
      return
    fi
  elif [ -d "$current_src" ]; then
    if ! diff -rq "$current_src" "$master_src" &>/dev/null; then
      echo "    ⚠ differs from master — linking to worktree" >&2
      echo "$current_src"
      return
    fi
  fi

  echo "$master_src"
}

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
      echo "  ⚠ ${name}: no type in frontmatter, defaulting to \"command\""
      type="command"
    fi

    # Resolve source to match what install would have linked
    file_src="$(resolve_source "${skill_path}/SKILL.md" "skills/${name}/SKILL.md")"
    dir_src="$(resolve_source "${skill_path}" "skills/${name}")"

    case "$type" in
      command|skill)
        unlink_path "$file_src" "${CLAUDE_DIR}/commands/${name}.md" "claude:commands/${name}.md"
        ;;
      agent)
        unlink_path "$file_src" "${CLAUDE_DIR}/agents/${name}.md" "claude:agents/${name}.md"
        ;;
    esac

    # All skills unlink from Codex
    if [ -d "${CODEX_DIR}" ]; then
      unlink_path "$dir_src" "${CODEX_DIR}/skills/${name}" "codex:skills/${name}"
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
    echo "  ⚠ ${name}: no type in frontmatter, defaulting to \"command\""
    type="command"
  fi

  echo "  ${name} (type: ${type})"

  # Resolve source paths (prefer master in worktrees)
  file_src="$(resolve_source "${skill_path}/SKILL.md" "skills/${name}/SKILL.md")"
  dir_src="$(resolve_source "${skill_path}" "skills/${name}")"

  # Claude Code: symlink SKILL.md into commands/ or agents/
  case "$type" in
    command|skill)
      link_file "$file_src" "${CLAUDE_DIR}/commands/${name}.md" "  → claude:commands/${name}.md"
      ;;
    agent)
      link_file "$file_src" "${CLAUDE_DIR}/agents/${name}.md" "  → claude:agents/${name}.md"
      ;;
    *)
      echo "    ⚠ unknown type '${type}', skipping Claude Code install"
      ;;
  esac

  # Codex: symlink entire directory
  if [ -d "${CODEX_DIR}" ]; then
    link_dir "$dir_src" "${CODEX_DIR}/skills/${name}" "  → codex:skills/${name}"
  fi

  echo ""
done

echo "Installed! Run './install.sh --uninstall' to remove."
