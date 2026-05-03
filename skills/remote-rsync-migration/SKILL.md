---
name: remote-rsync-migration
description: Plan, execute, debug, or review remote data migrations that use rsync over SSH between hosts. Use when moving Docker/app data between servers, preparing migration runbooks, fixing rsync/SSH/sudo failures, validating cutover steps, or designing safe sync/dry-run/rollback flows.
---

# Remote Rsync Migration

## Overview

Use this skill for host-to-host data moves where correctness, permissions, and cutover safety matter. Prefer explicit preflight, dry-run, staged sync, final sync, validation, and rollback steps over ad hoc copy commands.

## Core Workflow

1. Identify source host, target host, source paths, target paths, service owners, and the command runner.
2. Baseline source state before copying: running services, expected data paths, disk space, ownership, and health checks.
3. Preflight target access before stopping anything: SSH, writable parent directories, sudo permissions, Docker/Compose availability if services will start there, and endpoint reachability.
4. Run a dry-run sync with the same transport, sudo, excludes, and delete behavior intended for the live sync.
5. Run an initial sync while source services remain up when the application tolerates it.
6. Stop or quiesce source services only for the final sync window.
7. Run final sync, start target services, validate, then promote DNS/config/state.
8. Keep rollback steps concrete: stop target, restart source, and undo only reversible routing changes.

## Rsync Rules

- Do not ask local `rsync` to copy from one remote host directly to another remote host. Run `rsync` on one participating host, usually the source host, so only one side of each transfer is remote.
- Treat old rsync versions as normal. Prefer broadly compatible flags such as `--archive`, `--delete`, `--dry-run`, `--itemize-changes`, and `--progress`; avoid newer flags unless both ends are known to support them.
- Preserve ownership and permissions intentionally. If container-owned files are unreadable by the deploy user, use explicit privileged rsync, not partial unprivileged copies.
- Scope paths narrowly. Prefer explicit data paths over syncing a whole shared data root.
- Use trailing slashes deliberately and document whether the directory itself or its contents are being copied.
- Use `--delete` only after confirming the target path is dedicated to this migration. Never point a delete sync at a shared parent.

## SSH And Sudo

- Seed or verify target host keys before the live sync. If the source host will initiate SSH to the target, make sure the source host trusts the target key before rsync runs.
- Run discovery tools such as `ssh-keyscan` from the controlling machine when source hosts are minimal appliances.
- When source-side `sudo rsync` launches SSH, preserve the deploy user's agent and known-hosts assumptions explicitly:
  - Capture `SSH_AUTH_SOCK` before sudo.
  - Pass an rsync SSH command with `-o IdentityAgent=<captured-sock>` when agent forwarding is required.
  - Pass `-o UserKnownHostsFile=<deploy-user-known-hosts>` when sudo would otherwise use root's `known_hosts`.
- Use non-interactive sudo (`sudo -n`) in migration commands so missing privileges fail before the cutover window.
- Preflight target directory creation with the same user/sudo mode the final rsync will use.

## Cutover Safety

- Validate target runtime configuration before stopping source services. For Docker Compose targets, run the target's `docker compose ... config --quiet` equivalent first.
- Make final sync commands deterministic and repeatable. Re-running final sync should converge, not duplicate or fan out data.
- Separate operator-facing plan output from shell-escaped execution strings. Plans should be readable; execution paths should be correctly escaped.
- Capture every command needed for rollback before cutover starts.
- Stop the line on unexpected rsync code, host-key prompt, password prompt, missing Compose binary, or permission-denied output. Diagnose before continuing.

## Verification Story

Report the migration as done only after recording:

- Baseline source check.
- Dry-run command and result.
- Initial and final sync command outcomes.
- Target startup/config validation.
- App or service health checks, including endpoint URLs when relevant.
- Rollback path and whether it was exercised or only prepared.

If any verification could not run, state the missing access or prerequisite and the safest exact next command to run.
