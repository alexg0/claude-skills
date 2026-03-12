# PR Workflow Reference

## Branch Selection Policy
Use this order when deciding where to apply fixes:

1. Original contributor branch (preferred): `refs/remotes/<fork-remote>/<branch>`.
2. Local branch tracking the original contributor branch.
3. `pr-<pr>` fetched ref only when contributor branch is unavailable.

When the contributor branch exists, do edits, amend, and push there. Treat `pr-<pr>` as inspection/fallback context.

## GitHub PR Ref Mapping
Use these when you have a PR number and remote name.

```bash
git fetch <remote> pull/<pr>/head:pr-<pr>
git fetch <remote> pull/<pr>/merge:pr-<pr>-merge
```

Read-only inspection commands:

```bash
git log --oneline -n 10 pr-<pr>
git diff --stat <base>...pr-<pr>
git diff <base>...pr-<pr>
```

## Branch Setup Patterns
Create or reset a local branch to a remote-tracking branch:

```bash
git checkout -B <local-branch> refs/remotes/<remote>/<branch>
```

Fallback switch to fetched PR head (when original branch is unavailable):

```bash
git checkout pr-<pr>
```

Confirm branch state:

```bash
git status --short --branch
git branch -vv
```

## Verification Sequence
Run narrow checks first, then broaden only when needed.

1. Single-file or targeted checker.
2. Repo CI-equivalent check script.
3. Full test suite only if risk surface is broad.

Record exact command and success or failure summary.

## Amend and Push Flow
Only after explicit user request.

```bash
git add <paths>
git commit --amend --no-edit
git push --force-with-lease <remote> <branch>
```

If no rewrite is needed:

```bash
git add <paths>
git commit -m "<message>"
git push <remote> <branch>
```

## Failure Handling
If network or auth blocks push, capture the concrete error and stop mutation retries until user confirms next step.

Useful diagnostic retries:

```bash
git status --short --branch
git log --oneline -n 3
```

For SSH hangs, run a bounded check:

```bash
GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=10' git push <args>
```

## Reporting Checklist
Include these in final output:

1. What changed and why.
2. What verification ran and outcomes.
3. Current branch sync state.
4. Any residual risk or unrun checks.
