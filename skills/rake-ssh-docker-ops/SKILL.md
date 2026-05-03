---
name: rake-ssh-docker-ops
description: Operate Docker or Docker Compose deployments through project Rake tasks that wrap SSH. Use when restarting, recreating, deploying, checking, logging, or debugging remote Docker services via Rake; when shell quoting around Rake/SSH is risky; or when designing verification for Rake-over-SSH operations.
---

# Rake SSH Docker Ops

## Overview

Use this skill when a repository exposes remote Docker operations through Rake tasks. Prefer the repo's wrapper tasks over raw SSH so sync, templates, project names, environment, and verification stay consistent.

## Operating Workflow

1. Locate the authoritative tasks with `rake -T`, `rakelib/`, `Rakefile`, README/runbooks, and existing tests.
2. Baseline state before changing anything: current branch, diff, target stack/service, remote status, recent logs, and known health checks.
3. Run the smallest wrapper task that performs the intended operation.
4. Verify through the wrapper's status/check/log tasks, then through direct endpoints only when the repo expects that.
5. Record the exact commands and outcomes in the final verification story.

## Command Rules

- Quote all Rake task invocations with bracket arguments in zsh:

```bash
rake 'stack:restart[admin,portainer]'
rake 'docker:logs[hermes,200]'
```

- Prefer Rake wrappers over direct SSH or direct `docker compose` unless investigating the wrapper itself.
- If a remote stack directory may not exist yet, run the repo's status/sync/bootstrap task before direct SSH inspection.
- For first-time split-stack or moved-service startup, prefer a recreate/up task over restart; `docker compose restart SERVICE` does not create a missing container.
- Keep operations scoped to one service or stack unless the user explicitly requests broad impact.
- Avoid broad orphan cleanup across unrelated Compose projects. Confirm project names and compose files before using cleanup flags.

## Shell And SSH Safety

- Keep display strings and execution strings separate in code. Human-readable plans can be lightly quoted; commands passed to `sh` must use proper escaping.
- Avoid nesting single-quoted programs, such as `awk '...'`, inside single-quoted SSH payloads. Prefer simpler quote-free commands, uploaded scripts, or language helpers such as `Shellwords`.
- Do not put Markdown snippets with backticks, `$()`, or bracket expressions inside double-quoted shell commands. Use single quotes, fixed-string searches, or file reads.
- Force complex remote wrappers through a known shell when needed, and avoid shell-reserved variable names such as `status`.
- Fail fast on password prompts by using non-interactive sudo where the task expects passwordless privilege.

## Docker Compose Checks

- Validate every affected Compose project before deployment:

```bash
docker compose -f docker-compose.yml -p project-name config --quiet
```

- Match the repo's Compose binary convention (`docker compose` vs `docker-compose`), especially on older or appliance-like hosts.
- Preserve explicit project names, container names, networks, and data roots. Do not infer service ownership when the repo has a stack manifest or service matrix.
- When stack files are split, keep docs, service matrices, health checks, and task aliases in sync with the actual Compose service keys.

## Verification Pattern

Use a layered verification story:

1. Local static check: syntax, Compose config, lint, or tests relevant to the changed task.
2. Remote operation result: the Rake task completed and targeted the intended stack/service.
3. Runtime state: status or `ps` shows the expected container state.
4. Logs: recent logs do not show startup, permission, bind, auth, or health-check errors.
5. Endpoint or app check: HTTP/TCP/app-specific probe passes when the service exposes one.

If any layer fails, stop adding changes and diagnose that layer before continuing.

## Reporting

Report:

- What stack/service changed.
- The wrapper commands used.
- The verification commands and outcomes.
- Any direct SSH/Docker command used and why the wrapper was insufficient.
- Residual risk, especially unverified endpoints, skipped tests, or operations that were not safe to run live.
