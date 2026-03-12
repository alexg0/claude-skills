# Claude Code Skills & Agents

Custom commands and agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code).

## Contents

### Commands (`/slash-commands`)

| Command | Description |
|---------|-------------|
| `/generate-pdfs` | Generate PDFs from markdown via pandoc/xelatex, with Rakefile scaffolding |
| `/health-analysis` | Analyze DNA/genetic data and lab results for personalized health recommendations |

### Agents (auto-triggered)

| Agent | Description |
|-------|-------------|
| `crash-diagnostics` | Investigates Claude crashes, resource exhaustion, and recommends configuration fixes |

## Install

```bash
git clone https://github.com/alexg0/claude-skills.git
cd claude-skills
./install.sh
```

This symlinks the commands and agents into `~/.claude/commands/` and `~/.claude/agents/`. Updates to the repo are picked up automatically since they're symlinked.

## Uninstall

```bash
./install.sh --uninstall
```

## Adding new commands/agents

1. Add a `.md` file to `commands/` or `agents/`
2. Add the filename to the appropriate array in `install.sh`
3. Re-run `./install.sh`

## Structure

```
commands/       # Slash commands (invoked with /command-name)
agents/         # Subagents (auto-triggered by Claude based on context)
install.sh      # Symlink installer
```
