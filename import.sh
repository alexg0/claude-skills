#!/usr/bin/env bash
set -euo pipefail

# Import one explicitly named, unpublished native skill into this repository.
# Runtime skill roots are not bulk-scanned because they also contain upstream
# and package-managed skills that this repository must not adopt.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
DRY_RUN=false
FORCE=false
TARGET_NAME=""
CANDIDATE_PATH=""
CANDIDATE_SOURCE=""

usage() {
  cat <<'EOF'
Usage: ./import.sh [--dry-run] [-f|--force] skill-name

Looks for one real, unpublished skill directory in increasing precedence:
  ~/.claude/skills
  ~/.codex/skills
  ~/.agents/skills

Symlinked directories, sources containing any symlink, invalid metadata, and
skills already present in this repository are rejected. Imported skills are
not installed automatically; add the skill to skills.manifest after review.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true ;;
    -f|--force) FORCE=true ;;
    -h|--help) usage; exit 0 ;;
    -*) echo "Error: unknown option: $1" >&2; usage >&2; exit 1 ;;
    *)
      [ -z "$TARGET_NAME" ] || { echo "Error: only one skill name is allowed" >&2; exit 1; }
      TARGET_NAME="$1"
      ;;
  esac
  shift
done

[ -n "$TARGET_NAME" ] || { echo "Error: skill-name is required" >&2; usage >&2; exit 1; }
[[ "$TARGET_NAME" =~ ^[a-z0-9-]+$ ]] || { echo "Error: invalid skill name: $TARGET_NAME" >&2; exit 1; }
[ ! -e "$SKILLS_DIR/$TARGET_NAME" ] || { echo "Error: skill already exists in this repository: $TARGET_NAME" >&2; exit 1; }

frontmatter_field() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---$/ { delimiters++; next }
    delimiters == 1 && $0 ~ "^" field ":[[:space:]]*" {
      sub("^[^:]+:[[:space:]]*", "")
      gsub(/^['"'"']|['"'"']$/, "")
      print
      exit
    }
  ' "$file"
}

consider_root() {
  local root="$1" source="$2" dir skill_file first_link
  dir="$root/$TARGET_NAME"
  [ -d "$dir" ] || return 0
  [ ! -L "$dir" ] || { echo "  ! rejecting symlinked skill directory: $dir" >&2; return 0; }

  if [ -f "$dir/SKILL.md" ]; then
    skill_file="$dir/SKILL.md"
  elif [ -f "$dir/skill.md" ]; then
    skill_file="$dir/skill.md"
  else
    echo "  ! rejecting skill without SKILL.md: $dir" >&2
    return 0
  fi

  first_link="$(find "$dir" -type l -print -quit)"
  [ -z "$first_link" ] || { echo "  ! rejecting skill containing symlink: $first_link" >&2; return 0; }
  if [ "$(frontmatter_field "$skill_file" name)" != "$TARGET_NAME" ] || \
     [ -z "$(frontmatter_field "$skill_file" description)" ]; then
    echo "  ! rejecting invalid skill metadata: $dir" >&2
    return 0
  fi

  if [ -n "$CANDIDATE_PATH" ]; then
    echo "  ! $TARGET_NAME: preferring $source over $CANDIDATE_SOURCE"
  fi
  CANDIDATE_PATH="$dir"
  CANDIDATE_SOURCE="$source"
}

consider_root "${HOME}/.claude/skills" "claude"
consider_root "${HOME}/.codex/skills" "codex"
consider_root "${HOME}/.agents/skills" "shared"

[ -n "$CANDIDATE_PATH" ] || { echo "No importable native skill named '$TARGET_NAME' found."; exit 0; }
printf 'Importable skill:\n  %-28s %-8s %s\n' "$TARGET_NAME" "$CANDIDATE_SOURCE" "$CANDIDATE_PATH"
[ "$DRY_RUN" = false ] || { echo "Dry run: no changes made."; exit 0; }

if [ "$FORCE" = false ]; then
  printf 'Import %s? [y/N] ' "$TARGET_NAME"
  read -r answer
  case "$answer" in [yY]*) ;; *) echo "Skipped."; exit 0 ;; esac
fi

first_link="$(find "$CANDIDATE_PATH" -type l -print -quit)"
[ -z "$first_link" ] || { echo "Error: source gained a symlink before import: $first_link" >&2; exit 1; }
cp -R "$CANDIDATE_PATH" "$SKILLS_DIR/$TARGET_NAME"
if [ -f "$SKILLS_DIR/$TARGET_NAME/skill.md" ] && [ ! -f "$SKILLS_DIR/$TARGET_NAME/SKILL.md" ]; then
  mv "$SKILLS_DIR/$TARGET_NAME/skill.md" "$SKILLS_DIR/$TARGET_NAME/SKILL.md"
fi

echo "Imported $TARGET_NAME."
echo "Next: review it, add it to skills.manifest, validate it, then install it."
