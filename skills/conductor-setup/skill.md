---
name: conductor-setup
type: command
version: 1.0.0
description: |
  Create or update conductor.json with setup, archive, and run lifecycle hooks.
  Use when: "setup conductor", "conductor setup", "initialize workspace",
  "add conductor hooks", "configure workspace lifecycle".
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Glob
  - Grep
---

# Conductor Workspace Setup

Create or update the `conductor.json` lifecycle config for this project.

## How Conductor workspaces work

Conductor creates each workspace as a **git worktree** — an isolated working copy
of the repo with its own branch and directory path.

Each worktree shares the same git history but has independent files on disk.

**`conductor.json`** defines lifecycle hooks that Conductor runs automatically:

| Hook      | When it runs                          | Purpose                                |
|-----------|---------------------------------------|----------------------------------------|
| `setup`   | Workspace is created                  | Install deps, register tools, etc.     |
| `archive` | Workspace is archived                 | Kill servers, clean up registrations    |
| `run`     | User triggers "Run" in Conductor      | Start dev server, build, open app, etc.|

### Port allocation

Conductor sets `$CONDUCTOR_PORT` for each workspace. The workspace owns ports
`$CONDUCTOR_PORT` through `$CONDUCTOR_PORT+9` (10 ports total). Servers started
by `setup` or `run` should bind to `$CONDUCTOR_PORT` (or an offset within the range)
instead of hardcoded ports. This avoids collisions between concurrent workspaces.

The `run` hook should kill any leftover processes on its ports before starting.
The `archive` hook should kill any servers still running on the workspace's ports.

## Steps

### 1. Detect project type and existing config

- Check if `conductor.json` already exists. If so, read it and offer to update.
- Look at the project to determine sensible defaults:
  - **Package manager**: `package.json` → npm/yarn/pnpm; `Gemfile` → bundler; `Rakefile` → rake; `Makefile` → make; `pyproject.toml` → pip/poetry
  - **Dev server**: common scripts like `dev`, `start`, `serve` in package.json; `Procfile`; `docker-compose.yml`
  - **Setup tasks**: dependency install commands, database setup, code generation

### 2. Create `conductor.json`

Write `conductor.json` to the project root with this structure:

```json
{
  "setup": "<command to run when workspace is created>",
  "archive": "<command to run when workspace is archived>",
  "run": "<command to start the project>"
}
```

All three fields are optional — omit any that don't apply. Values are shell commands
that Conductor executes in the workspace directory.

**Examples by project type:**

Node.js:
```json
{
  "setup": "npm install",
  "archive": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; true",
  "run": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; PORT=$CONDUCTOR_PORT npm run dev"
}
```

Ruby:
```json
{
  "setup": "bundle install",
  "archive": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; true",
  "run": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; bundle exec rails server -p $CONDUCTOR_PORT"
}
```

Python:
```json
{
  "setup": "pip install -e '.[dev]'",
  "archive": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; true",
  "run": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; flask run --port $CONDUCTOR_PORT"
}
```

Multi-step setup (use `&&` to chain):
```json
{
  "setup": "npm install && npm run db:migrate",
  "archive": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; npm run db:drop",
  "run": "lsof -ti :$CONDUCTOR_PORT | xargs kill 2>/dev/null; PORT=$CONDUCTOR_PORT npm run dev"
}
```

### 3. Report to the user

After writing `conductor.json`, report:
- What hooks were configured and why
- Any hooks that were left out and why
- The current git branch for context

### Troubleshooting

- If you can't determine the project type, ask the user what commands they use to set up and run the project.
- If `conductor.json` already exists, show the current config and ask what to change rather than overwriting blindly.
