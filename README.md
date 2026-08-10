# Personal skills

This repository is the source of truth for Alex's reusable personal Claude Code
and Codex skills. The same `skills/<name>/` directory is linked into both
clients. Workflows inseparable from one project's private data or conventions
live in that project's `.agents/skills` directory instead.

## Ownership model

| Content | Owner |
|---|---|
| Reusable personal skill source | This repository |
| Project-owned skill source | The owning project's `.agents/skills` directory |
| `~/.claude/skills`, `~/.codex/skills` | Generated links only |
| Project links for centrally managed skills | The target project's `.agents/skills` directory |
| Claude/Codex instruction files | Dotfiles |
| gstack and GSD | Their upstream installers |
| Bundled, official, marketplace, and plugin skills | Their package or application |
| Tool-specific skills such as `pdf-generation` | The tool's upstream repository |

Do not copy upstream or official skills here. In particular, use Conductor's
bundled skill, the official general PDF plugin, md2pdf's own PDF-generation
skill, and gstack's review/ship workflows instead of maintaining local copies.

## Repository layout

```text
skills/<name>/SKILL.md   canonical skill source
skills/<name>/agents/openai.yaml  optional Codex UI metadata
skills.manifest         installation scope: global or project
install.sh              install/remove personal skill links
import.sh               copy unpublished native skills into this repo
install-upstream.sh     install/update gstack and GSD from upstream
```

Every `SKILL.md` has exactly two YAML frontmatter fields:

```yaml
---
name: my-skill
description: What it does and the requests that should trigger it.
---
```

The folder name and frontmatter `name` must match. Put detailed documentation
in `references/`, deterministic utilities in `scripts/`, and output resources
in `assets/`. Do not add per-skill README or installation files.

## Install personal skills

Run the installer from the stable checkout, not a disposable Conductor
worktree:

```bash
./install.sh --dry-run
./install.sh
```

This installs only `global` entries from `skills.manifest` into both
`~/.claude/skills` and `~/.codex/skills`. It also removes legacy personal
command/agent links and retired substitutes that this repository used to own.
Exact link targets are recorded under each client root's
`.personal-skills-owned/` state directory so a moved checkout can be repaired
without claiming unrelated live or broken links.

For a link created by an older installer whose original checkout has already
disappeared, preview and explicitly authorize one-time adoption:

```bash
./install.sh --dry-run --repair-broken-links
./install.sh --repair-broken-links
```

This flag adopts only broken links whose target has the expected
`skills/<manifest-name>` shape. Inspect the dry run first because the old source
and its ownership evidence are no longer available.

The manifest supports centrally maintained, opt-in project skills when a
workflow is reusable but should not load globally. Install one into a target's
shared `.agents/skills` directory with:

```bash
./install.sh --project /path/to/project project-skill-name
./install.sh --uninstall --project /path/to/project project-skill-name
```

A workflow containing one project's private assumptions instead belongs
directly under that project's `.agents/skills/<name>/` directory and must be
omitted from this manifest. The current manifest contains only global skills.

Remove all global personal links with:

```bash
./install.sh --uninstall
```

## Add or import a personal skill

For a new skill:

1. Create `skills/<name>/SKILL.md` using the two-field frontmatter above.
2. Add one line to `skills.manifest`: `<name> global` or `<name> project`.
3. Keep instructions client-neutral and avoid hard-coded workspace paths.
4. Validate every skill and run the checks below.
5. Merge the change, then install from the stable checkout.

To recover an unpublished real directory from a native live skill root:

```bash
./import.sh --dry-run my-skill
./import.sh my-skill
```

The importer requires an explicit name, rejects sources containing symlinks,
and never bulk-adopts upstream-managed packages. It does not edit the manifest
or install automatically; review and classify the imported skill first.

## Install or update upstream packages

Preview or run the maintained upstream installation commands:

```bash
./install-upstream.sh --dry-run
./install-upstream.sh
./install-upstream.sh --only gstack
./install-upstream.sh --only gsd
```

The script clones or fast-forwards gstack and runs its Claude and Codex setup.
It installs GSD globally for each client through `get-shit-done-cc`. Their files
remain outside this repository and must not be added to `skills.manifest`.
By default gstack's upstream clone lives at `~/.claude/skills/gstack`, following
its global installation convention, and its setup generates Codex runtime
adapters from that clone. Set `GSTACK_DIR` to use another upstream-owned clone.

The `pdf-generation` skill is owned and documented by the md2pdf repository.
Install it from a stable md2pdf clone using that repository's README; do not
copy it into this manifest.

## Verification

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

See [CLAUDE.md](CLAUDE.md) for the maintenance contract agents must follow.
