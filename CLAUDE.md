# Skills repository maintenance contract

This repository is the source of truth for reusable personal skills used by
Claude Code and Codex. A workflow inseparable from one project's private data
or conventions belongs in that project's `.agents/skills` directory. Preserve
these boundaries whenever adding, changing, importing, installing, or removing
a skill.

## Before editing

1. Read `README.md`, `skills.manifest`, `tasks/todo.md`, and
   `tasks/lessons.md` when present.
2. Inspect the target skill and its directly referenced resources before
   changing it.
3. Preserve unrelated worktree changes and never install from a disposable
   Conductor worktree.

## Ownership rules

- Keep canonical reusable personal source only under `skills/<name>/` in this
  repo.
- Treat `~/.claude/skills` and `~/.codex/skills` as generated runtime locations.
- A project `.agents/skills` directory may contain either installer-created
  links to centrally managed skills or source owned by that project. Never keep
  both a project-owned source skill and a central copy.
- Keep skill files, generated commands/agents, gstack, and GSD out of dotfiles.
  Dotfiles may own only client-specific global instruction/configuration files.
- Do not vendor skills supplied by an application, official plugin, package,
  marketplace, or upstream repository. Use and document the upstream installer.
- Before adding a skill, check for an existing bundled or upstream capability.
  Prefer removing a redundant local substitute.

## Skill rules

- Use lowercase hyphenated folder names under 64 characters.
- Match the folder name to the frontmatter `name` exactly.
- Limit YAML frontmatter to `name` and `description`. The description must say
  what the skill does and when it should trigger.
- Keep `SKILL.md` concise, imperative, client-neutral, and under 500 lines when
  practical. Assume the agent already knows general software practices.
- Put reusable scripts in `scripts/`, details loaded only when needed in
  `references/`, and output resources in `assets/`. Do not duplicate content
  between `SKILL.md` and references.
- `agents/openai.yaml` is optional product-facing UI metadata. When present,
  keep its display name, short description, and default prompt aligned with the
  skill and validate it using the current skill-creator guidance.
- Do not add a README, changelog, install guide, or other auxiliary prose inside
  an individual skill directory.
- Avoid absolute workspace paths, client-specific tool names, forced subagent
  strategies, unsupported frontmatter, credentials, and private identifiers.
- Treat secrets, health data, and other sensitive records as private. Never
  print, commit, or copy them into this repository.
- Keep medical skills informational: preserve source ranges, cite evidence,
  state uncertainty, and defer diagnosis, treatment, and dosing to clinicians.

## Manifest and scope

Every retained skill must appear once in `skills.manifest`:

```text
skill-name  global
skill-name  project
```

- `global`: reusable across repositories; installed into both client skill roots.
- `project`: is centrally maintained but opt-in for a named project target.

Do not list a project-owned source skill in this manifest. Keep private data
assumptions with the owning project rather than generalizing them into this
repository.

Do not add client-specific installation modes. If a workflow cannot remain
client-neutral, keep the adapter outside the canonical skill or reconsider
whether it belongs in this shared repository.

## Workflow orchestration

- Use gstack as the default project workflow for planning, review, QA, and
  shipping.
- Treat GSD as disabled unless the current project's checked-in instructions
  explicitly enable it or the user explicitly invokes a GSD workflow for that
  project. Global installation makes GSD available; it does not enable it.
- Do not create `.planning/` state or invoke `gsd-*` automatically based only
  on project size or task complexity.
- In a GSD-enabled project, let GSD own roadmap, phase, execution,
  verification, review, and shipping state. Do not mix in the equivalent
  gstack lifecycle unless the user asks. Explicitly requested gstack
  specialist tools remain available when they do not duplicate that state.

## Required workflow

1. Find and remove redundant or obsolete skills before adding new ones.
2. Make the smallest coherent change to canonical source and the manifest.
3. Update `README.md` and this file if the ownership or maintenance contract
   changes.
4. Validate all retained skills, not only the edited one.
5. Run shell syntax checks, dry-run installers, and `git diff --check`.
6. Merge first; install live links from the stable checkout afterward.
7. Record a result and verification story in `tasks/todo.md` for non-trivial work.

## Verification commands

```bash
/bin/bash -n install.sh import.sh install-upstream.sh tests/test-tooling.sh
/bin/bash tests/test-tooling.sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
for skill in skills/*; do
  [ -f "$skill/SKILL.md" ] || continue
  python3 "${CODEX_HOME:-$HOME/.codex}/skills/.system/skill-creator/scripts/quick_validate.py" "$skill"
done
git diff --check
./install.sh --dry-run --source-root /path/to/stable/checkout
./import.sh --dry-run skill-name
./install-upstream.sh --dry-run
```

Do not report completion without naming the checks run and any live-state work
that remains intentionally deferred.
