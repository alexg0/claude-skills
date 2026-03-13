#!/usr/bin/env bash
set -euo pipefail

# Import skills from Claude Code and Codex into this repo.
#
# Scans ~/.claude/commands/, ~/.claude/agents/, and ~/.dotfiles/codex/skills/
# for non-symlink skills that don't already exist in skills/, copies them in
# with proper SKILL.md frontmatter, then runs install.sh to symlink back.
#
# Usage: ./import.sh [--dry-run] [-f|--force] [--help] [name]

CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${HOME}/.dotfiles/codex"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"

DRY_RUN=false
FORCE=false
TARGET_NAME=""

for arg in "$@"; do
  case "$arg" in
    --dry-run)   DRY_RUN=true ;;
    -f|--force)  FORCE=true ;;
    -h|--help)
      echo "Usage: $0 [--dry-run] [-f|--force] [name]"
      echo "  --dry-run  Show what would happen without making changes"
      echo "  -f/--force Import all without prompting per skill"
      echo "  name       Import only the named skill"
      exit 0
      ;;
    -*)
      echo "Unknown option: $arg"
      echo "Usage: $0 [--dry-run] [-f|--force] [name]"
      exit 1
      ;;
    *)
      if [ -n "$TARGET_NAME" ]; then
        echo "Error: only one skill name allowed"
        exit 1
      fi
      TARGET_NAME="$arg"
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

# Extract type from frontmatter
get_type() {
  local skill_md="$1"
  awk '/^---$/{n++; next} n==1 && /^type:/{print $2; exit}' "$skill_md"
}

# Extract name from frontmatter
get_fm_field() {
  local file="$1" field="$2"
  awk -v f="$field" '/^---$/{n++; next} n==1 && $0 ~ "^"f":"{sub(/^[^:]+:[[:space:]]*/, ""); print; exit}' "$file"
}

# Check if file has YAML frontmatter
has_frontmatter() {
  head -1 "$1" | grep -q '^---$'
}

# Get first non-empty content line (for auto-description)
first_content_line() {
  awk '/^---$/{n++; next} n==2 && /[^ ]/{print; exit} n==0 && /[^ ]/{print; exit}' "$1"
}

# Ensure description is properly quoted if it contains special chars
quote_description() {
  local desc="$1"
  if echo "$desc" | grep -qE '[:"{}]'; then
    echo "\"${desc//\"/\\\"}\""
  else
    echo "$desc"
  fi
}

# ── Discovery ──────────────────────────────────────────────────────────

# Associative arrays: name → source path, name → source type, name → inferred type
declare -A CANDIDATES_PATH=()
declare -A CANDIDATES_SOURCE=()
declare -A CANDIDATES_TYPE=()

# Scan commands
if [ -d "${CLAUDE_DIR}/commands" ]; then
  for f in "${CLAUDE_DIR}/commands"/*.md; do
    [ -f "$f" ] || continue
    [ -L "$f" ] && continue
    [[ "$f" == *.bak ]] && continue
    name="$(basename "$f" .md)"
    [ -d "${SKILLS_DIR}/${name}" ] && continue
    CANDIDATES_PATH["$name"]="$f"
    CANDIDATES_SOURCE["$name"]="command"
    CANDIDATES_TYPE["$name"]="command"
  done
fi

# Scan agents (overrides command if duplicate)
if [ -d "${CLAUDE_DIR}/agents" ]; then
  for f in "${CLAUDE_DIR}/agents"/*.md; do
    [ -f "$f" ] || continue
    [ -L "$f" ] && continue
    [[ "$f" == *.bak ]] && continue
    name="$(basename "$f" .md)"
    [ -d "${SKILLS_DIR}/${name}" ] && continue
    if [ -n "${CANDIDATES_PATH[$name]+x}" ]; then
      echo "  ⚠ ${name}: found in both commands/ and agents/, preferring agents/"
    fi
    CANDIDATES_PATH["$name"]="$f"
    CANDIDATES_SOURCE["$name"]="agent"
    CANDIDATES_TYPE["$name"]="agent"
  done
fi

# Scan codex (overrides all if duplicate)
if [ -d "${CODEX_DIR}/skills" ]; then
  for d in "${CODEX_DIR}/skills"/*/; do
    [ -d "$d" ] || continue
    [ -L "${d%/}" ] && continue
    [[ "$(basename "$d")" == *.bak ]] && continue
    [ -f "${d}SKILL.md" ] || continue
    name="$(basename "$d")"
    [ -d "${SKILLS_DIR}/${name}" ] && continue
    local_type="$(get_type "${d}SKILL.md")"
    if [ -n "${CANDIDATES_PATH[$name]+x}" ]; then
      echo "  ⚠ ${name}: found in codex/ and ${CANDIDATES_SOURCE[$name]}/, preferring codex/"
    fi
    CANDIDATES_PATH["$name"]="$d"
    CANDIDATES_SOURCE["$name"]="codex"
    CANDIDATES_TYPE["$name"]="${local_type:-skill}"
  done
fi

# Filter by target name if specified
if [ -n "$TARGET_NAME" ]; then
  if [ -z "${CANDIDATES_PATH[$TARGET_NAME]+x}" ]; then
    echo "No importable skill named '${TARGET_NAME}' found."
    echo ""
    echo "Checked:"
    echo "  ${CLAUDE_DIR}/commands/${TARGET_NAME}.md"
    echo "  ${CLAUDE_DIR}/agents/${TARGET_NAME}.md"
    echo "  ${CODEX_DIR}/skills/${TARGET_NAME}/"
    exit 0
  fi
  # Remove all other entries
  for key in "${!CANDIDATES_PATH[@]}"; do
    if [ "$key" != "$TARGET_NAME" ]; then
      unset "CANDIDATES_PATH[$key]"
      unset "CANDIDATES_SOURCE[$key]"
      unset "CANDIDATES_TYPE[$key]"
    fi
  done
fi

# Check if anything to import
if [ ${#CANDIDATES_PATH[@]} -eq 0 ]; then
  echo "No importable skills found."
  exit 0
fi

# ── Display candidates ─────────────────────────────────────────────────

echo ""
echo "Importable skills:"
echo ""
printf "  %-25s %-10s %-10s %s\n" "NAME" "SOURCE" "TYPE" "PATH"
printf "  %-25s %-10s %-10s %s\n" "----" "------" "----" "----"
for name in $(echo "${!CANDIDATES_PATH[@]}" | tr ' ' '\n' | sort); do
  printf "  %-25s %-10s %-10s %s\n" \
    "$name" \
    "${CANDIDATES_SOURCE[$name]}" \
    "${CANDIDATES_TYPE[$name]}" \
    "${CANDIDATES_PATH[$name]}"
done
echo ""

if [ "$DRY_RUN" = true ]; then
  echo "Dry run — no changes made."
  exit 0
fi

# ── Import ─────────────────────────────────────────────────────────────

imported=0

for name in $(echo "${!CANDIDATES_PATH[@]}" | tr ' ' '\n' | sort); do
  source_path="${CANDIDATES_PATH[$name]}"
  source_type="${CANDIDATES_SOURCE[$name]}"
  inferred_type="${CANDIDATES_TYPE[$name]}"

  # Prompt unless forced
  if [ "$FORCE" != true ]; then
    printf "Import %s? [y/N] " "$name"
    read -r answer
    case "$answer" in
      [yY]*) ;;
      *) echo "  · skipped"; continue ;;
    esac
  fi

  echo "  + importing ${name} (${source_type} → type: ${inferred_type})"

  case "$source_type" in
    codex)
      # Copy entire directory
      run cp -R "$source_path" "${SKILLS_DIR}/${name}"
      ;;

    command|agent)
      dest_dir="${SKILLS_DIR}/${name}"
      dest_file="${dest_dir}/SKILL.md"
      run mkdir -p "$dest_dir"

      if [ "$DRY_RUN" = true ]; then
        run cp "$source_path" "$dest_file"
      else
        if has_frontmatter "$source_path"; then
          existing_type="$(get_type "$source_path")"
          if [ -n "$existing_type" ]; then
            # Has type already — copy as-is
            cp "$source_path" "$dest_file"
          else
            # Has frontmatter but no type — inject type before closing ---
            awk -v t="$inferred_type" '
              BEGIN {n=0}
              /^---$/ {
                n++
                if (n == 2) { print "type: " t }
                print
                next
              }
              { print }
            ' "$source_path" > "$dest_file"
          fi
        else
          # No frontmatter — generate one
          desc="$(first_content_line "$source_path")"
          # Strip leading # and whitespace from markdown headings
          desc="${desc#\#* }"
          desc="$(quote_description "$desc")"
          {
            echo "---"
            echo "name: ${name}"
            echo "description: ${desc}"
            echo "type: ${inferred_type}"
            echo "---"
            echo ""
            cat "$source_path"
          } > "$dest_file"
        fi
      fi
      ;;
  esac

  imported=$((imported + 1))
done

echo ""

if [ "$imported" -eq 0 ]; then
  echo "No skills imported."
  exit 0
fi

echo "Imported ${imported} skill(s)."
echo ""

# ── Post-import: run install.sh to create symlinks back ────────────────

echo "Running install.sh to create symlinks..."
echo ""
if [ "$DRY_RUN" = true ]; then
  "${SCRIPT_DIR}/install.sh" --dry-run
else
  "${SCRIPT_DIR}/install.sh"
fi
