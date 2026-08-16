---
name: keybase-push-upstream
description: Safely publish and land work in Git repositories whose upstream remote is Keybase, where GitHub integrations and PR tooling are unavailable. Use when the user asks to push, ship, create a PR-equivalent, merge upstream, land changes, or verify publishing for a repo with keybase:// remotes or an explicit "no GitHub integration" constraint.
---

# Keybase Push Upstream

## Overview

Use direct `git` commands to publish Keybase-backed repositories. Do not run `gh` commands for Keybase repos, including `gh pr create`, `gh repo`, `gh auth`, or GitHub check inspection; they cannot provide the source of truth for this workflow.

## Preflight

Run the read-only helper first when a repository is available:

```bash
bash <skill-directory>/scripts/keybase-preflight.sh [repo-path] [keybase-remote] [base-branch]
```

Default `repo-path` is the current directory. When omitted, the helper selects
the only remote whose fetch or push URL uses `keybase://`, then detects that
remote's advertised default branch. Pass the remote or base branch explicitly
when discovery is unavailable or ambiguous. Use the output to confirm:

- At least one fetch or push remote uses `keybase://`.
- The current branch and base branch are what the user expects.
- The worktree is clean except for changes intentionally being shipped.
- A local base-branch worktree exists when the repo uses a separate landing worktree.

If the remote is not Keybase, stop using this skill unless the user explicitly says the repository still follows the Keybase/no-GitHub flow.

## Publishing Workflow

1. Inspect state with direct git commands only:

```bash
git status --short --branch
git remote -v
git branch --show-current
git worktree list
```

2. Commit only the intended work:

```bash
git diff --stat
git diff
git add <intended-files>
git commit -m "<concise message>"
```

If the user did not ask for a commit and there are dirty files, report the files and ask before committing. Never stage unrelated user changes.

3. Push the feature/workspace branch to the selected Keybase remote:

```bash
git push -u <keybase-remote> HEAD
```

4. Land without GitHub by using the detected base-branch worktree when one
exists. Confirm the target branch from the preflight output rather than
assuming `main`, `master`, or a user-specific worktree layout.

In the base worktree:

```bash
git status --short --branch
git fetch <keybase-remote>
git merge --ff-only <feature-branch>
git push <keybase-remote> <base-branch>
```

If fast-forward is not possible, stop and inspect the divergence. Do not force-push or reset unless the user explicitly asks.

5. Verify the landed state:

```bash
git status --short --branch
git log --oneline --decorate -5
git rev-parse <base-branch>
git ls-remote <keybase-remote> refs/heads/<base-branch>
```

The local base-branch SHA should match its remote ref after the push.

## Guardrails

- Do not use GitHub CLI, GitHub MCP, GitHub PR URLs, or GitHub checks as part of this workflow.
- Treat dirty files in the base worktree as user work. Stash only when the user or repo instructions authorize it; otherwise stop and report the conflict.
- Prefer fast-forward merges for landing workspace branches. Use a normal merge commit only when the repo convention allows it and the user approves.
- Never run destructive commands such as `git reset --hard`, `git checkout -- <file>`, or force pushes unless explicitly requested.
- If verification cannot be run, say exactly which command was skipped and why.

## Reporting Back

Report:

- The branch pushed and the Keybase remote used.
- The base branch/worktree merged into.
- The final local and remote SHAs when landing was performed.
- Verification commands run and their outcomes.
