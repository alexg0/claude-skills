#!/usr/bin/env bash
set -euo pipefail

# Install or update upstream-managed skill packages without copying them into
# this repository. Network and package-manager changes happen only when this
# script is run without --dry-run.

DRY_RUN=false
ONLY="all"
GSTACK_DIR="${GSTACK_DIR:-${HOME}/.claude/skills/gstack}"

usage() {
  cat <<'EOF'
Usage: ./install-upstream.sh [--dry-run] [--only gstack|gsd]

Installs or updates:
  gstack  https://github.com/garrytan/gstack
  GSD     https://github.com/glittercowboy/get-shit-done

Set GSTACK_DIR to override the upstream clone location. The default follows
gstack's global Claude installation convention; its setup command generates
the Codex runtime adapters from the same upstream-owned clone.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --only)
      [ "$#" -ge 2 ] || { echo "Error: --only requires gstack or gsd" >&2; exit 1; }
      ONLY="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$ONLY" in all|gstack|gsd) ;; *) echo "Error: --only must be gstack or gsd" >&2; exit 1 ;; esac

run() {
  if [ "$DRY_RUN" = true ]; then
    printf '  (dry-run)'
    printf ' %q' "$@"
    printf '\n'
  else
    "$@"
  fi
}

run_in() {
  local directory="$1"
  shift
  if [ "$DRY_RUN" = true ]; then
    printf '  (dry-run) cd %q &&' "$directory"
    printf ' %q' "$@"
    printf '\n'
  else
    (cd "$directory" && "$@")
  fi
}

install_gstack() {
  echo "gstack"
  if [ -e "$GSTACK_DIR" ] && [ ! -d "$GSTACK_DIR/.git" ]; then
    echo "Error: refusing to replace non-git path: $GSTACK_DIR" >&2
    exit 1
  fi

  if [ -d "$GSTACK_DIR/.git" ]; then
    run git -C "$GSTACK_DIR" pull --ff-only
  else
    run git clone https://github.com/garrytan/gstack.git "$GSTACK_DIR"
  fi
  run_in "$GSTACK_DIR" ./setup
  run_in "$GSTACK_DIR" ./setup --host codex
}

install_gsd() {
  echo "GSD"
  run npx -y get-shit-done-cc@latest --claude --global
  run npx -y get-shit-done-cc@latest --codex --global
}

case "$ONLY" in
  all) install_gstack; install_gsd ;;
  gstack) install_gstack ;;
  gsd) install_gsd ;;
esac

echo "Done. Upstream packages remain owned by their installers."
