---
name: general-pr-helper
description: Review, triage, and fix pull requests with a read-first workflow. Use when asked to inspect a PR, identify failing checks or root cause, prepare a minimal fix, run verification, and optionally amend or push only after explicit user request.
---

# General PR Helper

## Overview
Use this skill to handle pull-request-focused debugging and correction work with minimal blast radius. Prefer repository-native checks and concise evidence.

## Core Workflow
1. Establish branch and remote context before touching anything.
2. Prefer the original contributor branch for edits; fetch PR refs for context or fallback.
3. Inspect commits and diff to isolate likely breakage.
4. Run the smallest relevant verification command to reproduce or confirm.
5. Identify the root cause and choose the smallest safe fix.
6. Re-run focused verification, then broader checks if risk warrants.
7. Perform write actions only when explicitly requested.
8. Report outcome with changed files, verification evidence, and residual risk.

## Read-First Safety Rules
- Default to analysis and verification before editing.
- Do not commit, amend, or push unless the user explicitly asks.
- If push is requested after history rewrite, use `--force-with-lease`.
- Never use destructive resets or checkout-revert flows unless explicitly requested.
- Stop and ask if unrelated unexpected changes appear.

## Investigation Rules
- Prefer authoritative local signals: diff, tests, lint, CI scripts, and workflow config.
- Prefer working on the source branch that backs the PR (for example `fork/feature-branch`) instead of a temporary `pr-<id>` branch.
- Reproduce failures with the narrowest command first.
- Confirm assumptions against files in the repo before asking the user.
- Keep fixes scoped to the reported PR problem unless a linked issue is required for correctness.

## Verification Rules
- Reuse the repo's own verification entrypoints when available.
- For narrow changes, run targeted checks first.
- For risky or cross-cutting changes, run broader validation before declaring done.
- If any check cannot be run, state why and provide the exact command.

## Communication Contract
- Lead with findings and impact.
- Reference concrete artifacts: commit IDs, file paths, and command outcomes.
- Keep summaries concise; avoid dumping raw logs unless needed.
- Distinguish facts from inference.

## Command Patterns
Use `references/pr-workflow.md` for concrete command patterns covering PR ref fetch, branch setup, verification sequencing, amend/push flows, and failure handling.

## Example Triggers
- "Look at PR 2996 and fix the problem."
- "Check this PR branch and amend the existing commit."
- "Investigate failing PR checks and propose the smallest patch."
