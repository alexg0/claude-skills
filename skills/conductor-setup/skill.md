---
name: conductor-setup
version: 1.0.0
description: |
  Set up a Conductor workspace for the LLM Wiki system. Registers the Obsidian
  vault, checks dependencies, and ensures the workspace is ready to use.
  Use when: "setup conductor", "set up workspace", "conductor setup",
  "register vault", "initialize workspace", "get started".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Conductor Workspace Setup

This skill sets up a Conductor workspace for the Honolulu LLM Wiki system.

## How Conductor workspaces work

Conductor creates each workspace as a **git worktree** — an isolated working copy
of the repo with its own branch and directory path. For this repo:

- **Main repo**: `~/Dropbox (Personal)/work/cowork/personal/alexg-wiki` (master)
- **Workspaces**: `~/conductor/workspaces/alexg-wiki/<workspace-name>/` (each on its own branch)

Each worktree shares the same git history but has independent files on disk.
This means:

- **Each workspace gets its own Obsidian vault** — because Obsidian registers
  vaults by absolute path, and each worktree has a unique path. You can have
  multiple workspaces open in Obsidian simultaneously as separate vaults.
- **Wiki content diverges per branch** — each workspace/branch can have different
  projects and wiki state. Changes merge back to master via PRs.
- **`.obsidian/` config is per-worktree** — each workspace gets its own Obsidian
  state (open tabs, workspace layout) while sharing committed config (app.json,
  core-plugins.json) through git.
- **`conductor.json`** defines lifecycle hooks:
  - `setup` runs `rake vault:register` when a workspace is created
  - `archive` runs `rake vault:unregister` when a workspace is archived
  - This keeps Obsidian's vault list clean as workspaces come and go

Use `rake vault:cleanup` periodically to remove vaults for worktrees that were
deleted outside of Conductor's archive flow.

## Steps

Run these steps in order:

### 1. Register Obsidian vault

```bash
rake vault:register
```

This registers the current workspace directory as an Obsidian vault. If Obsidian
is running, it will be restarted to pick up the new vault.

### 2. Check dependencies

```bash
rake setup
```

Verifies that Obsidian and optional tools (qmd) are installed.

### 3. Open in Obsidian

```bash
rake obsidian
```

Opens the vault in Obsidian. The vault name will match the workspace folder name.

### 4. Report status

After running the above, report to the user:
- Whether the vault was newly registered or already existed
- Which dependencies are installed and which are missing
- The current git branch (for awareness of which branch the vault reflects)
- List existing projects with `rake projects`

### Troubleshooting

If vault registration fails:
- Check that Obsidian is installed at `/Applications/Obsidian.app`
- Check the vault registry: `rake vault:list`
- Clean up stale vaults: `rake vault:cleanup`

If Obsidian doesn't show the vault after registration:
- Obsidian must be restarted after modifying its config
- The `vault:register` task handles this automatically
- If it still doesn't work, manually quit and reopen Obsidian

## Teardown

When archiving a workspace, run:

```bash
rake vault:unregister
```

This is configured automatically in `conductor.json` as the archive script.
