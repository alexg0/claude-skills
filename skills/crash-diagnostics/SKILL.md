---
name: crash-diagnostics
description: Diagnose crashes, process exhaustion, resource-limit failures, severe performance degradation, and unresponsive local agent sessions. Use when Claude Code, Codex, or a related process crashes or becomes unstable and the user wants an evidence-backed cause and prevention steps.
---

# Crash diagnostics

Diagnose first; do not mutate system configuration or terminate processes unless the user also asks for remediation.

## Protect private state

- Do not inspect shell history. It can contain credentials, private commands, and unrelated activity.
- Inspect only logs and crash reports relevant to the named process and time window. List candidate paths before reading content, redact sensitive values, and avoid copying private logs into chat or repositories.
- Prefer process names and resource counters over full command lines, which may contain secrets.
- Do not persist diagnostic output in memory or project files unless the user explicitly requests a report artifact.

## Establish the failure window

Ask for the approximate failure time and symptom only when they cannot be inferred from the current session. Record the OS, client, client version, project, and whether the failure was a crash, hang, forced termination, or resource-limit error.

## Collect focused evidence

Use platform-appropriate, read-only checks:

1. Resource limits: `ulimit -a`; relevant process and file-descriptor limits.
2. Process state: counts, parent/child relationships, zombie state, elapsed time, CPU, and memory. Avoid broad `ps aux` dumps.
3. Memory and disk pressure: `vm_stat` and `df -h` on macOS; `free -h` and `df -h` on Linux.
4. Open files only for the affected PID when file-descriptor exhaustion is plausible.
5. OS crash or OOM evidence in the narrow failure window.
6. Client logs or crash reports only after identifying the smallest relevant files by name and modification time.
7. Project watchers, test runners, browser daemons, or build processes only when their relationship to the affected process is visible.

Capture concrete numbers and timestamps. Compare the observed process's usage with its applicable limit rather than assuming a low limit caused the failure.

## Determine the cause

Evaluate evidence for:

- runaway or recursive child-process creation;
- excessive concurrent agent/tool work;
- orphaned watchers or browser/build processes;
- file-descriptor exhaustion;
- memory pressure or an OS OOM kill;
- disk exhaustion or oversized logs;
- a client crash independent of system pressure;
- restrictive per-process, container, or host limits.

Label conclusions as confirmed, likely, or suspected. Do not recommend raising limits when the evidence instead shows a leak or runaway workload.

## Recommend remediation

Start with the smallest reversible action. Provide exact commands only for processes, files, and settings proven relevant to this incident. Before any kill, deletion, persistent limit change, or client configuration edit:

1. identify the exact target and current state;
2. explain the impact and rollback;
3. obtain authorization if the user's request was diagnosis-only.

Do not generate a generic cleanup script. If repeated cleanup is genuinely needed, implement a narrowly scoped, reviewable script only when requested and include a dry-run mode.

## Report

Summarize:

- symptom and failure window;
- evidence with concrete values;
- root cause and confidence;
- immediate reversible remediation;
- prevention or configuration changes supported by evidence;
- checks that could not be performed and remaining uncertainty.
