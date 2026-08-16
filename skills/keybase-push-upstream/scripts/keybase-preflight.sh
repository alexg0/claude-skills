#!/usr/bin/env bash
set -euo pipefail

repo_path="${1:-.}"
remote_name="${2:-}"
base_branch="${3:-}"

cd "$repo_path"

if ! git rev-parse --show-toplevel >/dev/null 2>&1; then
  echo "error: not inside a git repository: $repo_path" >&2
  exit 2
fi

top_level="$(git rev-parse --show-toplevel)"
current_branch="$(git branch --show-current || true)"

remote_uses_keybase() {
  local remote="$1" urls
  urls="$(
    git remote get-url --all "$remote" 2>/dev/null || true
    git remote get-url --push --all "$remote" 2>/dev/null || true
  )"
  case "$urls" in
    *keybase://*) return 0 ;;
    *) return 1 ;;
  esac
}

if [ -n "$remote_name" ]; then
  if ! git remote get-url "$remote_name" >/dev/null 2>&1; then
    echo "error: remote does not exist: $remote_name" >&2
    exit 2
  fi
  if ! remote_uses_keybase "$remote_name"; then
    echo "error: remote does not use keybase://: $remote_name" >&2
    exit 2
  fi
else
  keybase_remotes=()
  while IFS= read -r candidate; do
    if remote_uses_keybase "$candidate"; then
      keybase_remotes+=("$candidate")
    fi
  done < <(git remote)

  if [ "${#keybase_remotes[@]}" -ne 1 ]; then
    echo "error: expected one Keybase remote, found ${#keybase_remotes[@]}; pass its name explicitly" >&2
    exit 2
  fi
  remote_name="${keybase_remotes[0]}"
fi

if [ -z "$base_branch" ]; then
  remote_head="$(
    (git ls-remote --symref "$remote_name" HEAD 2>/dev/null || true) |
      awk '$1 == "ref:" { sub("refs/heads/", "", $2); print $2; exit }'
  )"
  if [ -n "$remote_head" ]; then
    base_branch="$remote_head"
  else
    local_head="$(git symbolic-ref --quiet --short "refs/remotes/$remote_name/HEAD" 2>/dev/null || true)"
    base_branch="${local_head#"$remote_name"/}"
  fi
fi

if [ -z "$base_branch" ]; then
  echo "error: could not detect the default branch for $remote_name; pass it explicitly" >&2
  exit 2
fi

echo "Repository: $top_level"
echo "Current branch: ${current_branch:-DETACHED}"
echo "Keybase remote: $remote_name"
echo "Base branch: $base_branch"
echo

echo "Remotes:"
git remote -v || true
echo

echo "Status:"
git status --short --branch
echo

echo "Worktrees:"
git worktree list
echo

if [ -n "$current_branch" ]; then
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null || true)"
  echo "Current branch upstream: ${upstream:-none}"
  if [ -n "$upstream" ]; then
    echo "Ahead/behind upstream:"
    git rev-list --left-right --count "HEAD...$upstream" || true
  fi
  echo
fi

if git show-ref --verify --quiet "refs/heads/$base_branch"; then
  echo "Ahead/behind $base_branch:"
  git rev-list --left-right --count "HEAD...$base_branch" || true
else
  echo "Local base branch missing: $base_branch"
fi
echo

remote_line="$(git ls-remote --exit-code "$remote_name" "refs/heads/$base_branch" 2>/dev/null || true)"
if [ -n "$remote_line" ]; then
  remote_sha="$(printf '%s\n' "$remote_line" | awk '{print $1}' | head -n 1)"
  echo "$remote_name/$base_branch SHA: $remote_sha"
else
  echo "$remote_name/$base_branch SHA: unavailable"
fi
