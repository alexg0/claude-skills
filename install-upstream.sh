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
Usage: ./install-upstream.sh [--dry-run] [--only PACKAGE]

Installs or updates:
  gstack, GSD, Ponytail, Unlazy
  agent-browser, context7, frontend-responsive-ui
  gh-address-comments, gh-fix-ci, vercel-react-best-practices

PACKAGE is one of:
  gstack, gsd, ponytail, unlazy, agent-browser, context7, codex-skills,
  github-workflows, vercel-react, canonical

Set GSTACK_DIR to override the upstream clone location. The default follows
gstack's global Claude installation convention; its setup command generates
the Codex runtime adapters from the same upstream-owned clone.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --only)
      [ "$#" -ge 2 ] || { echo "Error: --only requires a package name" >&2; exit 1; }
      ONLY="$2"
      shift 2
      ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

case "$ONLY" in
  all|gstack|gsd|ponytail|unlazy|agent-browser|context7|codex-skills|github-workflows|vercel-react|canonical) ;;
  *) echo "Error: invalid --only package: $ONLY" >&2; exit 1 ;;
esac

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

install_skill_repo() {
  local label="$1" repository="$2"
  echo "$label"
  run npx -y skills add "$repository" --skill '*' -g \
    -a claude-code -a codex -y
}

install_selected_skill_repo() {
  local label="$1" repository="$2"
  local -a command
  shift 2
  command=(npx -y skills add "$repository" -g -a claude-code -a codex -y)
  while [ "$#" -gt 0 ]; do
    command+=(--skill "$1")
    shift
  done
  echo "$label"
  run "${command[@]}"
}

install_ponytail() {
  install_skill_repo "Ponytail" DietrichGebert/ponytail
}

install_unlazy() {
  install_skill_repo "Unlazy" Leonxlnx/unlazy
}

install_agent_browser() {
  install_selected_skill_repo "Agent Browser" vercel-labs/agent-browser agent-browser
}

install_context7() {
  install_selected_skill_repo "Context7" netresearch/context7-skill context7
}

install_codex_skills() {
  install_selected_skill_repo "Codex skills" am-will/codex-skills \
    "Frontend Responsive Design Standards"
}

install_github_workflows() {
  install_selected_skill_repo "GitHub workflows" openai/skills \
    gh-address-comments gh-fix-ci
}

install_vercel_react() {
  install_selected_skill_repo "Vercel React guidance" vercel-labs/agent-skills \
    vercel-react-best-practices
}

install_canonical_skills() {
  install_agent_browser
  install_context7
  install_codex_skills
  install_github_workflows
  install_vercel_react
}

case "$ONLY" in
  all) install_gstack; install_gsd; install_ponytail; install_unlazy; install_canonical_skills ;;
  gstack) install_gstack ;;
  gsd) install_gsd ;;
  ponytail) install_ponytail ;;
  unlazy) install_unlazy ;;
  agent-browser) install_agent_browser ;;
  context7) install_context7 ;;
  codex-skills) install_codex_skills ;;
  github-workflows) install_github_workflows ;;
  vercel-react) install_vercel_react ;;
  canonical) install_canonical_skills ;;
esac

echo "Done. Upstream packages remain owned by their installers."
