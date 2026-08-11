# Container Lifecycle Contract

Use this contract as a review matrix. Adapt syntax to the repository; keep the observable behavior consistent.

## Runtime selection

| Concern | Required behavior |
|---|---|
| Plain Docker | Permit a non-Dory engine where the repository supports it. |
| Dory | Require a Dory installation at version 0.4.3 or newer that passes its passive health check whenever the selected Docker context is Dory. |
| Compose command | Preserve the repository's established `docker compose` or `dory compose` wrapper; do not conflate the engine/context with the executable used to invoke Compose. |
| Broken Dory context | Fail clearly when Docker's active context is Dory but no compatible, healthy Dory installation is available. |
| Discovery | Prefer an explicit Dory override, then the managed Dory location, then `PATH`. Reject an unrelated executable with the same name. |
| Setup | Detect installed state and install or upgrade idempotently; keep first-run UI prompts visible and documented. |

Version and health probes must not mutate runtime state. Keep selection injectable so tests do not depend on the host installation.

## Project identity

Derive an exact, Compose-safe project name from:

1. A fixed application prefix.
2. A stable workspace identity, preferring `CONDUCTOR_WORKSPACE_ID`.
3. A short digest of the stable identity to prevent slug collisions.
4. A final scope such as `dev` or `test`.

Normalize to lowercase ASCII letters, digits, hyphens, and underscores as supported by the repository. Bound the complete name to Compose's practical limit without truncating the digest or scope. When no workspace ID exists, hash a canonical repository path and use a readable directory slug.

Use exact label or project-name equality for ownership checks. Never clean projects through a loose prefix alone.

## Start and replacement

Use one lock per exact development project. A start must:

1. Open the lifecycle lock and identify any process that currently owns that same lock.
2. Ask that exact owner to shut down, wait for its cleanup, and escalate only after bounded timeouts.
3. Acquire the lock before starting any replacement services.
4. Install `HUP`, `INT`, and `TERM` handlers before launching Compose.
5. Print and flush the URL before a slow pull or build.
6. Start dependencies, perform required schema preparation or migrations, and then start the app processes.
7. Poll a real HTTP readiness endpoint on the loopback-published port with a bounded timeout.
8. Run the lifecycle-owned Compose command in a tracked process group, stay attached, and return its status.

Do not run `compose down` before every start. Dory 0.4.3 reconciles published ports; a pre-start teardown destroys useful state and does not solve Compose-process replacement races.

## Shutdown

Normal shutdown must be safe whether initiated by Conductor, a terminal, an explicit task, or process replacement.

- On `HUP`, `INT`, or `TERM`, signal the tracked Compose process group, then spawn cleanup detached from the interrupted owner and disconnect its standard streams.
- Keep the inherited lifecycle lock while detached cleanup waits for the tracked Compose process group to exit. This prevents an interrupted pull or build from outliving the lock and racing its replacement.
- Run `compose down --remove-orphans` for the exact project without `--volumes` only after that wait.
- Wait for cleanup before releasing the lifecycle lock.
- Return conventional statuses: 129 for `HUP`, 130 for `INT`, and 143 for `TERM`.
- Make explicit `container:stop` acquire the same project lock and exact-owner protocol. A direct `compose down` task can race an active start and leave ambiguous ownership.
- Keep cleanup idempotent so a normal exit and signal path cannot cause harmful double work.

Do not search for or kill arbitrary listeners on the published port. Do not invoke automatic Dory repair from project scripts. Surface a readiness or runtime error with a diagnostic command instead.

## Volumes and archive

| Operation | Containers/networks | Volumes |
|---|---:|---:|
| Replace active start | Remove exact project | Preserve |
| Normal stop | Remove exact project and orphans | Preserve |
| Explicit reset | Remove exact project | Remove, with clear naming and intent |
| Workspace archive | Remove exact workspace development and test projects | Remove |

Archive cleanup must tolerate an unavailable runtime only when the workspace product explicitly expects best-effort archive behavior. Otherwise fail visibly. Never use `docker system prune`, a global volume prune, or an unresolved wildcard.

## Ports and readiness

- Require numeric ports in the range 1 through 65535.
- Publish development ports on `127.0.0.1` by default.
- Ensure development and test allocations cannot collide.
- Treat a TCP listener as transport availability only. Use the application's readiness endpoint to prove boot, dependencies, and routing.
- Give dependencies their own health checks and use conditional startup where supported.
- Keep timeouts bounded and errors actionable; include the URL, project, and next diagnostic command.

## Conductor integration

Follow the bundled Conductor skill for the current settings schema. In addition:

- Keep one multi-process development run coordinated under the lifecycle runner.
- Mark host-only runs `available_in = ["local"]`.
- Use `CONDUCTOR_PORT` for the app port and a deterministic non-colliding strategy for auxiliary ports.
- Keep setup noninteractive except for unavoidable application-owned first-run UI.
- Route archive cleanup through the exact workspace cleanup command.
- Prefer `container` as the canonical development run mode while retaining documented aliases during migration.

## Compatibility migration

When renaming interfaces, add aliases first:

- `docker:*` task names to `container:*`.
- `inline` to `native`.
- `docker` to `container` when the value denotes a development mode rather than the executable.

Keep aliases at argument or task boundaries, emit a concise deprecation notice only when the repository already has a deprecation convention, and remove aliases in a separately authorized change.
