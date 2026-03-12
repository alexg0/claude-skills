# Claude Code Skills & Agents

Custom commands, agents, and skills for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenAI Codex](https://openai.com/index/codex/).

## Contents

### Claude Code Commands (`/slash-commands`)

| Command | Description |
|---------|-------------|
| `/generate-pdfs` | Generate PDFs from markdown via pandoc/xelatex, with Rakefile scaffolding |
| `/health-analysis` | Analyze DNA/genetic data and lab results for personalized health recommendations |

### Claude Code Agents (auto-triggered)

| Agent | Description |
|-------|-------------|
| `crash-diagnostics` | Investigates Claude crashes, resource exhaustion, and recommends configuration fixes |

### Codex Skills

| Skill | Description |
|-------|-------------|
| `devonthink-mcp` | Manage DEVONthink content via MCP — search, organize, rename, tag records |
| `general-pr-helper` | Review, triage, and fix pull requests with a read-first workflow |

## Install

```bash
git clone https://github.com/alexg0/claude-skills.git
cd claude-skills
./install.sh
```

This symlinks everything into the right locations:
- Claude Code commands/agents → `~/.claude/commands/` and `~/.claude/agents/`
- Codex skills → `~/.dotfiles/codex/skills/`

Updates to the repo are picked up automatically since they're symlinked.

## Uninstall

```bash
./install.sh --uninstall
```

## Adding new extensions

1. Add files to the appropriate directory (`commands/`, `agents/`, or `codex-skills/`)
2. Add the name to the corresponding array in `install.sh`
3. Re-run `./install.sh`

## Structure

```
commands/           # Claude Code slash commands (invoked with /command-name)
agents/             # Claude Code subagents (auto-triggered by context)
codex-skills/       # OpenAI Codex skills (directory-based with SKILL.md)
install.sh          # Symlink installer
```
