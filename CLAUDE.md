# Skills Repo

Unified skills repo for Claude Code and Codex. Each skill is a directory under `skills/<name>/` with a `SKILL.md` file containing YAML frontmatter (`name`, `description`, `type`).

## Key files

- `install.sh` — symlinks skills into `~/.claude/commands/`, `~/.claude/agents/`, and `~/.dotfiles/codex/skills/` based on `type` field
- `import.sh` — reverse of install: pulls skills from those locations into this repo, adding proper frontmatter
- `skills/` — all skill definitions

## Skill types

- `command` → Claude Code `/command`, Codex skill
- `agent` → Claude Code agent (auto-triggered), Codex skill
- `skill` → Codex only (Claude Code skips)

## Conventions

- One `SKILL.md` per skill, always in `skills/<name>/SKILL.md`
- Frontmatter must have `name`, `description`, and `type` fields
- Supporting files go in subdirs: `references/`, `agents/`
- Both scripts support `--dry-run` for safe previewing
- `install.sh` backs up existing non-symlink files as `.bak` before overwriting
- Shell scripts use `set -euo pipefail`, the `run()` wrapper for dry-run, and consistent emoji status indicators

## Common tasks

```bash
./install.sh              # install all skills
./install.sh --uninstall  # remove symlinks
./import.sh --dry-run     # preview importable skills
./import.sh -f            # import all new skills
```
