---
name: container-deployment
description: Design, implement, migrate, or review repository-owned Docker Compose container workflows for local development, tests, builds, CI, and deployment. Use when adding or standardizing container scripts and task names; integrating Compose with Conductor workspaces or Dory; fixing start, replacement, stop, archive, port, readiness, project-identity, or volume-lifecycle behavior; or removing obsolete Dory port-proxy workarounds after requiring Dory 0.4.3 or newer.
---

# Container Deployment

Build one explicit container contract across scripts, task wrappers, Compose files, workspace configuration, tests, and documentation. Prefer the repository's existing language and task runner over introducing another control layer.

## Start With Evidence

1. Read repository instructions, the worktree status, container scripts, Compose files, task definitions, workspace settings, CI, deployment configuration, tests, and operator documentation.
2. Identify unrelated changes and preserve them.
3. Run the smallest existing static or behavioral check that establishes a baseline.
4. Read [references/lifecycle-contract.md](references/lifecycle-contract.md) before implementing or reviewing a local Compose, Conductor, or Dory workflow.
5. Write acceptance criteria for runtime selection, project identity, start, replacement, explicit stop, interruption, archive, readiness, and data retention.

## Choose The Smallest Architecture

- Keep one authoritative Compose wrapper that resolves the runtime, project name, compose files, ports, and environment.
- Route task-runner commands, Conductor run entries, tests, cleanup, and documentation through that wrapper.
- Keep orchestration in a small lifecycle runner when start/stop ownership requires locks or signal handling; do not spread lifecycle decisions across Rake, shell, Compose, and workspace hooks.
- Preserve compatibility aliases at the boundary while making `container:*` tasks and `native|container` runtime values canonical.
- Keep production deployment separate from local Dory concerns. Reuse image definitions where practical, but do not make production depend on Dory or Conductor.

## Implement Safely

- Validate ports, runtime modes, paths, and project identifiers at their input boundary.
- Prefer `CONDUCTOR_WORKSPACE_ID` for stable workspace identity; use a deterministic, bounded fallback when it is absent. Give development and test stacks distinct Compose project scopes.
- Bind published development ports to loopback unless external access is intentional.
- Require Dory 0.4.3 or newer when a Dory-backed context is selected. Install or upgrade it idempotently. Keep the engine/context choice distinct from the wrapper executable: follow the repository's established `docker compose` or `dory compose` convention. If the active Docker context is Dory but the Dory installation is missing, old, or unhealthy, fail with an actionable error instead of silently continuing through the same broken engine.
- Remove port-proxy workarounds made obsolete by Dory 0.4.3: pre-start teardown, automatic proxy repair, ad hoc listener discovery, and listener killing. Do not remove unrelated compatibility behavior without reproducing the original issue.
- Serialize starts per project and replace only the exact owner. Track lifecycle-owned Compose commands in their own process group; on `HUP`, `INT`, or `TERM`, terminate that group and make detached cleanup wait for it before teardown and lock release.
- Preserve development volumes on normal replacement and stop. Remove volumes only for explicit reset or archive behavior whose scope has been resolved exactly.
- Print and flush the user-facing URL before slow pulls or builds, then prove readiness with an application-level HTTP check rather than only a listening socket.
- Start dependencies and run required database preparation before reporting the application ready.

## Verify The Lifecycle

Add focused regression coverage for each changed invariant. Prefer fake runtime binaries and temporary lock directories for deterministic tests, then run a real smoke test when the local runtime is available.

Verify at least:

1. Runtime selection, version rejection, and actionable failure under an active Dory context.
2. Stable, isolated, length-bounded project names across development and test scopes.
3. URL output before a blocked build and successful HTTP readiness afterward.
4. Concurrent starts: the second waits for exact-owner cleanup and never overlaps the first project.
5. `HUP`, `INT`, and `TERM`: the foreground parent exits promptly, detached cleanup retains the lock until the tracked Compose process group exits, cleanup runs once, conventional signal status is returned, and volumes survive.
6. Explicit stop follows the same lock and ownership protocol.
7. Archive removes only projects belonging to the exact workspace and removes their volumes.
8. Compose config, unit/integration tests, lint or typecheck, task discovery, and documentation examples.

When safe, finish with a disposable real-runtime smoke test: start, wait for HTTP readiness, replace, stop, confirm no matching containers remain, confirm normal volumes remain, and confirm the published port is released. Never use a broad project-name pattern or global Docker cleanup.

## Report

Lead with the behavior now guaranteed. Name the files or interfaces changed, the exact checks that passed, live-runtime checks intentionally skipped, compatibility aliases retained, and any remaining migration risk such as old project-scoped volumes.
