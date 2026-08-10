#!/usr/bin/env bash
set -euo pipefail

# Install personal skills from this repository.
#
# Global reusable skills:
#   ./install.sh [--dry-run] [--source-root PATH]
#
# Project-only skills:
#   ./install.sh --project /path/to/repo skill-name [skill-name ...]
#
# Uninstall uses the same scope selection:
#   ./install.sh --uninstall
#   ./install.sh --uninstall --project /path/to/repo skill-name

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MANIFEST=""
CLAUDE_DIR="${HOME}/.claude"
CODEX_DIR="${HOME}/.codex"

MODE="install"
DRY_RUN=false
PROJECT_ROOT=""
SOURCE_ROOT=""
REPAIR_BROKEN_LINKS=false
declare -a REQUESTED_SKILLS=()

usage() {
  cat <<'EOF'
Usage:
  ./install.sh [--dry-run] [--source-root PATH]
  ./install.sh --project PATH skill [skill ...] [--dry-run]
  ./install.sh --uninstall [--project PATH skill [skill ...]] [--dry-run]

Options:
  --uninstall         Remove links owned by this repository.
  --dry-run           Print actions without changing files.
  --project PATH      Install named project-only skills into PATH/.agents/skills.
  --source-root PATH  Use a stable checkout as the link source.
  --repair-broken-links
                      Adopt matching broken skill links left by a moved checkout.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --uninstall)
      MODE="uninstall"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --project)
      [ "$#" -ge 2 ] || { echo "Error: --project requires a path" >&2; exit 1; }
      PROJECT_ROOT="$2"
      shift 2
      ;;
    --source-root)
      [ "$#" -ge 2 ] || { echo "Error: --source-root requires a path" >&2; exit 1; }
      SOURCE_ROOT="$2"
      shift 2
      ;;
    --repair-broken-links)
      REPAIR_BROKEN_LINKS=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      REQUESTED_SKILLS+=("$1")
      shift
      ;;
  esac
done

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '    (dry-run)'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

canonical_dir() {
  (cd "$1" 2>/dev/null && pwd -P)
}

if [ -z "$SOURCE_ROOT" ]; then
  SOURCE_ROOT="$SCRIPT_DIR"
  if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    current_root="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
    main_line="$(git -C "$SCRIPT_DIR" worktree list --porcelain | sed -n '1s/^worktree //p')"
    if [ -n "$main_line" ] && [ "$current_root" != "$main_line" ]; then
      echo "Error: refusing to install links from a disposable worktree." >&2
      echo "Merge the changes first, then run from the stable checkout, or pass:" >&2
      echo "  --source-root '$main_line'" >&2
      exit 1
    fi
  fi
fi

[ -d "$SOURCE_ROOT/skills" ] || { echo "Error: source root has no skills directory: $SOURCE_ROOT" >&2; exit 1; }
SOURCE_ROOT="$(canonical_dir "$SOURCE_ROOT")"
MANIFEST="${SOURCE_ROOT}/skills.manifest"
[ -f "$MANIFEST" ] || { echo "Error: source root has no skills manifest: $MANIFEST" >&2; exit 1; }

if [ -n "$PROJECT_ROOT" ]; then
  [ ${#REQUESTED_SKILLS[@]} -gt 0 ] || {
    echo "Error: --project requires at least one named project-only skill" >&2
    exit 1
  }
  [ -d "$PROJECT_ROOT" ] || { echo "Error: project path does not exist: $PROJECT_ROOT" >&2; exit 1; }
  PROJECT_ROOT="$(canonical_dir "$PROJECT_ROOT")"
elif [ ${#REQUESTED_SKILLS[@]} -gt 0 ]; then
  echo "Error: skill names are accepted only with --project" >&2
  exit 1
fi

is_requested() {
  local candidate="$1" requested
  [ ${#REQUESTED_SKILLS[@]} -gt 0 ] || return 0
  for requested in "${REQUESTED_SKILLS[@]}"; do
    [ "$candidate" = "$requested" ] && return 0
  done
  return 1
}

is_same_repository() {
  local candidate_root="$1" current_common candidate_common current_remote candidate_remote
  current_common="$(git -C "$SOURCE_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  candidate_common="$(git -C "$candidate_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)"
  if [ -n "$current_common" ] && [ "$current_common" = "$candidate_common" ]; then
    return 0
  fi

  current_remote="$(git -C "$SOURCE_ROOT" config --get remote.origin.url 2>/dev/null || true)"
  candidate_remote="$(git -C "$candidate_root" config --get remote.origin.url 2>/dev/null || true)"
  [ -n "$current_remote" ] && [ "$current_remote" = "$candidate_remote" ]
}

ownership_marker() {
  local path="$1" name="$2" collection
  collection="$(dirname "$path")"
  printf '%s/.personal-skills-owned/%s/%s\n' \
    "$(dirname "$collection")" "$(basename "$collection")" "$name"
}

marker_matches() {
  local path="$1" name="$2" target="$3" marker recorded
  marker="$(ownership_marker "$path" "$name")"
  [ -f "$marker" ] && [ ! -L "$marker" ] || return 1
  recorded="$(cat "$marker")"
  [ "$recorded" = "$target" ]
}

validate_marker_location() {
  local path="$1" name="$2" marker marker_dir marker_root
  marker="$(ownership_marker "$path" "$name")"
  marker_dir="$(dirname "$marker")"
  marker_root="$(dirname "$marker_dir")"
  if [ -L "$marker_root" ] || [ -L "$marker_dir" ] || \
     { [ -e "$marker_dir" ] && [ ! -d "$marker_dir" ]; }; then
    echo "Error: unsafe ownership marker directory: $marker_dir" >&2
    exit 1
  fi
}

mark_owned() {
  local path="$1" name="$2" target="$3" marker marker_dir marker_tmp
  marker="$(ownership_marker "$path" "$name")"
  marker_dir="$(dirname "$marker")"
  validate_marker_location "$path" "$name"
  if [ "$DRY_RUN" = true ]; then
    printf '    (dry-run) record ownership: %s -> %s\n' "$marker" "$target"
    return
  fi
  mkdir -p "$marker_dir"
  marker_tmp="$(mktemp "$marker_dir/.${name}.XXXXXX")"
  printf '%s\n' "$target" > "$marker_tmp"
  mv -f "$marker_tmp" "$marker"
}

unmark_owned() {
  local path="$1" name="$2" marker marker_dir marker_root
  marker="$(ownership_marker "$path" "$name")"
  marker_dir="$(dirname "$marker")"
  marker_root="$(dirname "$marker_dir")"
  if [ -f "$marker" ] && [ ! -L "$marker" ]; then
    run unlink "$marker"
    if [ "$DRY_RUN" = false ]; then
      rmdir "$marker_dir" 2>/dev/null || true
      rmdir "$marker_root" 2>/dev/null || true
    fi
  fi
}

is_personal_target() {
  local path="$1" name="$2" target resolved candidate source_root
  [ -L "$path" ] || return 1
  target="$(readlink "$path")"
  marker_matches "$path" "$name" "$target" && return 0
  resolved="$(realpath "$path" 2>/dev/null || true)"
  for candidate in "$target" "$resolved"; do
    case "$candidate" in
      */skills/"$name"|*/skills/"$name"/SKILL.md)
        if [ "$candidate" = "$SOURCE_ROOT/skills/$name" ] || \
           [ "$candidate" = "$SOURCE_ROOT/skills/$name/SKILL.md" ]; then
          return 0
        fi
        if [ "$REPAIR_BROKEN_LINKS" = true ] && [ ! -e "$path" ]; then
          return 0
        fi
        candidate="${candidate%/SKILL.md}"
        source_root="${candidate%/skills/$name}"
        is_same_repository "$source_root" && return 0
        ;;
    esac
  done
  return 1
}

link_owned() {
  local src="$1" dest="$2" label="$3" name="$4" current
  validate_marker_location "$dest" "$name"
  if [ -L "$dest" ]; then
    current="$(readlink "$dest")"
    if [ "$current" = "$src" ]; then
      echo "  ✓ already linked: $label"
      mark_owned "$dest" "$name" "$src"
      return
    fi
    if ! is_personal_target "$dest" "$name"; then
      echo "Error: refusing to replace non-personal link: $dest -> $current" >&2
      exit 1
    fi
    echo "  ↻ updating: $label"
    run ln -sfn "$src" "$dest"
  elif [ -e "$dest" ]; then
    echo "Error: refusing to replace existing non-link path: $dest" >&2
    exit 1
  else
    echo "  + linking: $label"
    run ln -s "$src" "$dest"
  fi
  mark_owned "$dest" "$name" "$src"
}

unlink_owned() {
  local dest="$1" label="$2" name="$3"
  if [ -L "$dest" ]; then
    if is_personal_target "$dest" "$name"; then
      echo "  - removing: $label"
      run unlink "$dest"
      unmark_owned "$dest" "$name"
    else
      echo "  · preserved non-personal link: $label"
    fi
  elif [ -e "$dest" ]; then
    echo "  · preserved non-link path: $label"
  fi
}

cleanup_global_name() {
  local name="$1"
  unlink_owned "${CLAUDE_DIR}/skills/${name}" "claude:skills/${name}" "$name"
  unlink_owned "${CLAUDE_DIR}/commands/${name}.md" "claude:commands/${name}.md" "$name"
  unlink_owned "${CLAUDE_DIR}/agents/${name}.md" "claude:agents/${name}.md" "$name"
  unlink_owned "${CODEX_DIR}/skills/${name}" "codex:skills/${name}" "$name"
}

validate_manifest() {
  local name scope extra line=0 seen_names="" requested
  while read -r name scope extra; do
    line=$((line + 1))
    [ -n "${name:-}" ] || continue
    [[ "$name" = \#* ]] && continue
    [ -z "${extra:-}" ] || { echo "Error: too many fields in manifest line $line" >&2; exit 1; }
    [[ "$name" =~ ^[a-z0-9-]+$ ]] || { echo "Error: invalid skill name: $name" >&2; exit 1; }
    case " $seen_names " in
      *" $name "*) echo "Error: duplicate manifest skill: $name" >&2; exit 1 ;;
    esac
    seen_names="$seen_names $name"
    case "$scope" in global|project) ;; *) echo "Error: invalid scope for $name: $scope" >&2; exit 1 ;; esac
    [ -f "$SOURCE_ROOT/skills/$name/SKILL.md" ] || { echo "Error: missing source skill: $name" >&2; exit 1; }
  done < "$MANIFEST"

  if [ ${#REQUESTED_SKILLS[@]} -gt 0 ]; then
    for requested in "${REQUESTED_SKILLS[@]}"; do
      case " $seen_names " in
        *" $requested "*) ;;
        *) echo "Error: unknown skill: $requested" >&2; exit 1 ;;
      esac
    done
  fi

  for skill_dir in "$SOURCE_ROOT"/skills/*; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    name="$(basename "$skill_dir")"
    case " $seen_names " in
      *" $name "*) ;;
      *) echo "Error: source skill missing from manifest: $name" >&2; exit 1 ;;
    esac
  done
}

validate_manifest

if [ -z "$PROJECT_ROOT" ]; then
  run mkdir -p "${CLAUDE_DIR}/skills" "${CODEX_DIR}/skills"

  # Remove retired, relocated, and old command-based installations.
  for retired in conductor general-pr-helper generate-pdfs health-analysis function-health-partials llm-wiki-conductor-setup; do
    cleanup_global_name "$retired"
  done

  while read -r name scope _; do
    [ -n "${name:-}" ] || continue
    [[ "$name" = \#* ]] && continue

    if [ "$MODE" = uninstall ] || [ "$scope" = project ]; then
      cleanup_global_name "$name"
      continue
    fi

    source_dir="$SOURCE_ROOT/skills/$name"
    unlink_owned "${CLAUDE_DIR}/commands/${name}.md" "legacy claude:commands/${name}.md" "$name"
    unlink_owned "${CLAUDE_DIR}/agents/${name}.md" "legacy claude:agents/${name}.md" "$name"
    link_owned "$source_dir" "${CLAUDE_DIR}/skills/${name}" "claude:skills/${name}" "$name"
    link_owned "$source_dir" "${CODEX_DIR}/skills/${name}" "codex:skills/${name}" "$name"
  done < "$MANIFEST"
else
  project_skills="${PROJECT_ROOT}/.agents/skills"
  run mkdir -p "$project_skills"

  while read -r name scope _; do
    [ -n "${name:-}" ] || continue
    [[ "$name" = \#* ]] && continue
    is_requested "$name" || continue
    [ "$scope" = project ] || { echo "Error: $name is not project-only" >&2; exit 1; }

    dest="$project_skills/$name"
    if [ "$MODE" = uninstall ]; then
      unlink_owned "$dest" "project:${name}" "$name"
    else
      link_owned "$SOURCE_ROOT/skills/$name" "$dest" "project:${name}" "$name"
    fi
  done < "$MANIFEST"
fi

echo "Done."
