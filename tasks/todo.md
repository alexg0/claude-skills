- [x] Restate goal + acceptance criteria
- [x] Locate existing implementation / patterns
- [x] Design: minimal approach + key decisions
- [x] Implement smallest safe slice
- [x] Add/adjust tests
- [x] Run verification (lint/tests/build/manual repro)
- [x] Summarize changes + verification story
- [x] Record lessons (if any)

## Acceptance Criteria
- Produce a high-signal review of the workspace diff only.
- Validate any reported issue against the code and applicable repo instructions.
- Include file/line references and keep findings focused on concrete bugs or rule violations.

## Working Notes
- Review target is the uncommitted diff in `import.sh`, `install.sh`, and `skills/conductor-setup/skill.md`.
- Applicable repo guidance is from the root `CLAUDE.md`.
- No GitHub PR is associated with the current branch.

## Results
- No high-signal findings survived validation for the current workspace diff.
- The lowercase `skills/conductor-setup/skill.md` path is a pre-existing repo compliance/portability concern, not introduced by this patch.
- The new missing-type fallback in `install.sh` can misroute malformed skills in isolation, but the repo contract requires `type`, all tracked skills currently satisfy it, and `import.sh` now backfills missing types before writing imported skills.

## Verification
- Read and applied `/Users/alexg/conductor/workspaces/skills/bordeaux/CLAUDE.md`.
- Reviewed the uncommitted diff for `import.sh`, `install.sh`, and `skills/conductor-setup/skill.md`.
- Checked for associated PR context with `gh pr view` and found none.
- Ran independent review/validation passes via subagents.
- Ran `git diff --check` with no diff formatting issues.
- Reproduced `install.sh` behavior in temporary sandboxes to test the missing-type fallback and compared it against current repo invariants.
