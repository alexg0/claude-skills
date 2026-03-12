# Claude Code & Codex Skills

Unified skills repo for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) and [OpenAI Codex](https://openai.com/index/codex/). Each skill is a single source of truth — the install script maps it to the right location for each tool.

## Skills

| Skill | Type | Claude Code | Codex | Description |
|-------|------|:-----------:|:-----:|-------------|
| `generate-pdfs` | command | `/generate-pdfs` | skill | Generate PDFs from markdown via pandoc/xelatex |
| `health-analysis` | command | `/health-analysis` | skill | Analyze DNA/genetic data and lab results |
| `crash-diagnostics` | agent | auto-triggered | skill | Investigate Claude crashes and resource exhaustion |
| `devonthink-mcp` | skill | — | skill | Manage DEVONthink content via MCP server |
| `general-pr-helper` | skill | — | skill | Review, triage, and fix pull requests |

## How it works

Each skill lives in `skills/<name>/SKILL.md` with a `type` field in frontmatter:

| Type | Claude Code | Codex |
|------|-------------|-------|
| `command` | Symlinked as `~/.claude/commands/<name>.md` | Symlinked as skill directory |
| `agent` | Symlinked as `~/.claude/agents/<name>.md` | Symlinked as skill directory |
| `skill` | Skipped (not directly supported yet) | Symlinked as skill directory |

Both tools ignore unknown frontmatter fields, so a single file works for both.

## Install

```bash
git clone https://github.com/alexg0/claude-skills.git
cd claude-skills
./install.sh
```

## Uninstall

```bash
./install.sh --uninstall
```

## Adding a new skill

1. Create `skills/<name>/SKILL.md` with frontmatter:
   ```yaml
   ---
   name: my-skill
   description: What it does.
   type: command  # or agent, or skill
   ---
   ```
2. Optionally add `references/`, `agents/`, or other subdirs
3. Run `./install.sh`

## Structure

```
skills/
  generate-pdfs/SKILL.md
  health-analysis/SKILL.md
  crash-diagnostics/SKILL.md
  devonthink-mcp/SKILL.md
  general-pr-helper/
    SKILL.md
    agents/openai.yaml
    references/pr-workflow.md
install.sh
```
