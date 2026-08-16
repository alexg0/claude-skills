# Keybase generalization and walkthrough review

## Acceptance criteria

- The Keybase workflow contains no user-specific repository or worktree
  assumptions.
- The Keybase remote and its default branch are discovered or supplied
  explicitly rather than guessed.
- Walkthrough helpers are exercised before any complexity is removed.
- Historically settled container, provider, and Jekyll decisions remain
  unchanged.

## Results

- Replaced `origin` and `master` assumptions with deterministic Keybase remote
  and advertised-default-branch discovery, with explicit overrides for
  ambiguous repositories.
- Added a regression fixture using a Keybase push URL and a `trunk` default
  branch.
- Exercised walkthrough conversion, metadata validation, evenly spaced frame
  sampling, visual frame output, minimum-duration rejection, and collision
  protection. The focused Ponytail review found no safe deletion that retained
  those behaviors, so the walkthrough skill remains unchanged.

# Demote Gemini Computer Use

## Acceptance criteria

- Gemini Computer Use is absent from the maintained global installation set.
- Its upstream source remains documented for explicit project-local use.
- Existing global links and shared source-lock state are removed without
  disturbing Frontend Responsive Design Standards from the same repository.

## Results

- Removed Gemini Computer Use from the canonical global installer group.
- Documented a project-local upstream installation command without `-g`.
- Added regression coverage that rejects Gemini Computer Use in the canonical
  global installer output.

# Workflow orchestration policy

## Acceptance criteria

- gstack is documented as the default project workflow.
- Global GSD installation is distinguished from project-level enablement.
- GSD is used only when project instructions enable it or the user explicitly
  invokes it for that project.
- A GSD-enabled project has one lifecycle owner rather than duplicate gstack
  planning, review, and shipping state.

## Results

- Documented gstack as the default workflow in both the operator README and
  repository maintenance contract.
- Kept GSD upstream-installed but disabled by default at project scope.
- Defined explicit project instructions or direct user invocation as the GSD
  enablement boundary, and prohibited automatic `.planning/` creation.

# Upstream skill installer reconciliation

## Acceptance criteria

- Ponytail and Unlazy have reproducible upstream-owned install commands for
  both Claude Code and Codex.
- The repository manifest is compared with live native skill roots without
  adopting bundled, plugin-managed, or unrelated skills.
- Installer syntax, dry runs, and tooling regression tests pass.
- Remaining ownership or installation differences are presented for explicit
  reconciliation rather than changed implicitly.

## Plan

- [x] Review repository ownership rules, prior lessons, and installer tests.
- [x] Compare `skills.manifest` with live Claude, Codex, and shared skill roots.
- [x] Add Ponytail and Unlazy to the upstream installer and documentation.
- [x] Run syntax, dry-run, regression, and diff verification.
- [x] Record results and present remaining reconciliation choices.

## Results

- Added Ponytail, Unlazy, and a canonical public-skill group to the upstream
  installer, with focused package selectors and dry-run regression coverage.
- Imported `keybase-push-upstream` and `record-app-walkthrough` as global
  personal skills and installed all twelve manifest entries into Claude Code
  and Codex.
- Replaced untracked public copies with source-locked upstream installations.
  Removed retired am-will skills, older duplicate frontend/OpenAI docs skills,
  the OPP-OS-specific PRD helper, and the obsolete Claude-only Jekyll builder
  from active roots.
- Preserved every replaced directory under
  `/tmp/skills-reconcile-20260816.hDwWIb` for recovery.
- Verification passed: Bash syntax, tooling regression tests, seven Python
  tests, all twelve skill validators, personal and upstream dry runs, live link
  and upstream lock checks, and `git diff --check`.
- The upstream security scan rated Gemini Computer Use as critical risk because
  it controls a browser and uses an API key. It remained installed at this
  point and was later demoted to explicit project-local use.

# Container deployment skill

## Acceptance criteria

- A reusable global skill guides consistent Docker Compose, Dory, and Conductor
  lifecycle implementations without duplicating Conductor's settings reference.
- The contract requires Dory 0.4.3 or newer and removes only obsolete port-proxy
  workarounds while retaining lock-based process coordination.
- Start, replacement, signal shutdown, explicit stop, archive, ports, readiness,
  project identity, volume retention, naming migration, and verification have
  explicit acceptance checks.
- The skill is client-neutral, listed in the manifest, and passes repository
  validation.

## Plan

- [x] Review existing container, deployment, Conductor, and skill-authoring guidance.
- [x] Define the reusable lifecycle contract from the three project implementations.
- [x] Create the skill, detailed lifecycle reference, UI metadata, and manifest entry.
- [x] Run skill validation and repository checks.
- [x] Record verification results and remaining installation step.

## Results

- Added the global `container-deployment` skill with concise operating guidance,
  aligned Codex UI metadata, and a detailed review matrix for runtime selection,
  stable project identity, lock-based replacement and stop, detached signal
  cleanup, volume retention, archive, loopback ports, HTTP readiness, Conductor
  integration, compatibility aliases, and layered verification.
- Kept Conductor schema guidance delegated to the bundled Conductor skill and
  kept remote Rake/SSH and provider-specific deployment operations delegated to
  their existing skills.
- An independent read-only forward test applied the skill to BetterTrip and
  correctly identified the Dory version/context gate, HTTP readiness,
  lock-aware explicit stop, workspace ID, Conductor availability, and signal
  coverage gaps without modifying the repository.
- A live cold-build smoke test then exposed an interrupted Compose child that
  could outlive its lock-owning parent. The contract now explicitly requires a
  tracked Compose process group and keeps the inherited lock through child exit
  and exact-project teardown.
- Verification passed: all ten skill validators, Bash syntax, tooling regression
  tests, seven Python tests, stable-checkout installer dry run, upstream installer
  dry run, and `git diff --check`. The importer behavior is covered by the
  tooling regression suite; a standalone import dry run requires an unpublished
  native skill and was therefore not applicable. Live installation remains
  intentionally deferred until this worktree is merged into the stable checkout.

# Skill ownership cleanup

## Acceptance criteria

- Reusable personal skill source exists only in this repository; private,
  project-owned skills live only with their owning projects.
- Dotfiles does not own skill files, links, generated agents, or upstream runtimes.
- Global installation contains only reusable personal skills.
- Centrally maintained project-scoped skills require explicit installation;
  project-owned skills are omitted from this manifest.
- gstack and GSD remain upstream-managed with documented install/update commands.
- Retained `SKILL.md` files pass the current Codex validator.
- Claude and Codex receive client-appropriate global instructions and the same canonical personal skills.
- Installer/importer dry runs are safe from disposable Conductor worktrees.
- Active links are readable and no symlink cycles remain.

## Plan

- [x] Audit current ownership, installed sources, and upstream installers.
- [x] Classify retained skills as global or project-only.
- [x] Redact tracked credentials and repair Git attributes configuration.
- [x] Remove dotfiles-owned skill links and exclude runtime roots from rcm.
- [x] Refactor personal install/import scripts around `skills.manifest`.
- [x] Add upstream gstack/GSD installation workflow.
- [x] Remove direct duplicate personal skills.
- [x] Normalize retained skill metadata for shared native installation.
- [x] Fix project-skill portability, trigger scope, privacy, and safety issues.
- [x] Split Claude and Codex global instruction files.
- [x] Run syntax, validation, dry-run, and active-link verification.
- [x] Summarize results and remaining manual security action.

## Working notes

- Never install global links to an unmerged Conductor workspace.
- Install from the stable main checkout after merging this worktree.

## Results

- Reduced the manifest to a client-neutral `name scope` contract: nine global
  personal skills and no centrally owned project-only skills.
- Generalized `cloudflare-pages` for framework-neutral static-site creation,
  deployment, domains, and troubleshooting, and reduced `fly-deploy` to the
  generally applicable static-site container, launch, deploy, and verification
  flow. Both are now global skills.
- Transferred the private `health-analysis` workflow to the health project's
  `.agents/skills` directory after confirming that no equivalent existed there;
  aligned it with the project's actual layout and removed the central duplicate.
- Transferred `function-health-partials` to the same private health project and
  `llm-wiki-conductor-setup` to the wiki project. Added a private, uniquely
  named payload-transfer helper with cleanup on success, failure, or interruption,
  and made unknown Function Health dates fail instead of silently selecting the
  latest visit. Migrated the wiki's ignored legacy `conductor.json` hooks into
  the current tracked `.conductor/settings.toml` format.
- Replaced stale Jekyll scaffolding and infrastructure templates with concise,
  global workflows that detect current project versions and conventions; removed
  obsolete jQuery, analytics, destructive clone, and client-specific guidance.
- Removed local substitutes for Conductor and generic PR help. Transferred the
  specialized PDF-generation workflow to the md2pdf repository so it evolves
  with the CLI; the official general PDF skill remains complementary.
- Reworked installation and import around native skill roots. The installer now
  survives source-checkout relocation, validates manifest parity under Bash 3.2,
  records exact link ownership, refuses both live and broken unrelated links,
  offers an explicit repair path for pre-marker broken links, preserves unrelated
  paths, and no longer creates an unused Claude agents directory. The importer
  requires an explicit name and rejects symlink-bearing sources instead of
  maintaining a drifting upstream ignore list.
- Added a dry-run-capable upstream gstack/GSD installer and documented the
  ownership/install rules in `README.md` and `CLAUDE.md`.
- Verification: Bash 3.2 syntax passed; all nine central skill validators and
  all three project-owned skill validators passed. Tooling regression tests
  covered install, checkout relocation, uninstall, live and broken
  non-personal-link protection, manifest parity, named import, and symlink
  rejection. Seven private screenshot-selection tests covered global ordering,
  spaced paths, case-insensitive formats, negative selection, filtering of
  unrelated images, custom prefixes, explicit directory selection, and candidate
  privacy. Three Function Health selection tests passed, including the unknown
  date regression; its transfer-helper test also verified temporary cleanup on
  success and error. Python and JavaScript syntax checks passed. Installer,
  importer, and upstream dry runs plus Git diff checks passed. Cloudflare Pages
  commands were checked against current official Wrangler documentation, and
  Fly commands against local flyctl v0.4.71 plus current official documentation.
  ShellCheck was unavailable.
