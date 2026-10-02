---
name: speed-up-tests
description: Measure and safely reduce automated test-suite runtime without weakening defect detection. Use when profiling slow tests or CI, removing repeated setup or subprocess overhead, consolidating fixtures or scenario matrices, introducing bounded test concurrency or caches, reviewing a test-speedup change, or adding performance regression gates across any language or test framework.
---

# Speed Up Tests

Reduce wall-clock time by removing overhead around tested behavior before removing behavior. Preserve assertions, boundary cases, failure injection, cleanup guarantees, and meaningful coverage.

## Define The Contract

1. Read repository instructions, test configuration, CI, task wrappers, helpers, and recent related changes. Preserve unrelated worktree changes.
2. State a measurable target and a correctness floor. Include the exact suite command, environment, run count, runtime statistic, coverage thresholds, and behaviors that must remain.
3. Measure every coverage dimension the repository supports before editing, including line, branch, function, statement, or language-specific coverage. Require the final result to meet or exceed each baseline and every existing threshold. Never lower or weaken a coverage gate to make a speedup pass.
4. Separate performance measurement from coverage instrumentation. Coverage changes timing and often cannot observe code executed in child processes.
5. Record a clean baseline before editing:
   - Run one or more warm-ups.
   - Measure at least five comparable runs when practical.
   - Record the median and slowest run, not only the best run.
   - Capture a suite profile, per-file inventory, or scenario timings.
   - Run existing coverage, randomized-order, and flake checks.

Use the same machine, runner, formatter, environment, and dependency state for every comparison. Alternate base and head runs when host load may drift.

## Localize The Cost

Classify the dominant hotspot before changing it:

- Framework or task-runner initialization repeated by tests that do not need it.
- Process startup, shell startup, dependency bootstrap, interpreter shims, or executable policy checks.
- Recreated fixtures, executable stand-ins, repositories, databases, or dependency graphs.
- Repeated parsing, discovery, path resolution, network setup, or immutable configuration reads.
- Sleeps, retries, polling, and external-service latency.
- Duplicate end-to-end execution where only pure selection or aggregation logic differs.
- Serial latency-bound scenarios that are genuinely independent.
- Logging, formatting, or cleanup work that dominates the behavior under test.

Confirm the cause with a focused micro-benchmark or command-count trace. Compare CPU time with wall time when deciding whether the hotspot is compute-bound or latency-bound. Revert experiments that do not improve the representative measurement.

## Optimize One Hotspot At A Time

Prefer these approaches in order.

### Remove Repeated Harness Work

- Load expensive framework or task definitions only in examples that use them.
- Resolve stable interpreters, executables, and toolchain paths once instead of through a shim per operation.
- Use the toolchain's supported clean-child environment when a child process would otherwise repeat dependency resolution.
- Replace helper subprocesses with language or shell built-ins when they only transform a small value or reproduce an already-known exit status.
- Parse immutable repository configuration once. Guard caches with a reliable invalidation key, share frozen values, and give mutation paths an explicit fresh mutable copy.

Do not add a cache unless invalidation and shared-mutation behavior have focused regression coverage.

### Reuse Deterministic Fixtures

- Commit stable fake executables or fixture trees when every scenario-specific input can arrive through arguments, stdin, or environment variables.
- Keep shared fixtures immutable and give each scenario separate output, state, and temporary directories.
- Avoid rewriting and first-executing identical helper programs in every example; some operating systems serialize security or metadata work for newly created executables.
- Preserve exact command logs, stdout, stderr, status, ordering, and failure-injection semantics.

### Split Decision Logic From Expensive Execution

- Exercise pure parsing, ranking, selection, and aggregation with recorded or constructed results.
- Retain representative end-to-end cases for every distinct integration boundary, failure mode, cleanup path, and side effect.
- Consolidate examples only when the resulting assertion matrix still proves every prior behavior. Aggregate line coverage alone does not justify deleting subprocess or shell scenarios.

### Amortize Scenario Startup

- Run compatible cases through one imported driver, sourced shell, interpreter, or service fixture when process isolation is not itself under test.
- Reset globals, constants, environment variables, current directories, signals, and temporary state between cases.
- When capturing a shell scenario's status, re-enable strict failure behavior inside that scenario's subshell; a parent harness may have disabled it to inspect the status.
- Make deliberate EOF reads, traps, and cleanup semantics explicit. Add a named mid-scenario failure case so an early error cannot fall through to a later successful command.

### Add Bounded Concurrency Last

- Parallelize only independent, latency-bound work after isolation is proven.
- Avoid concurrent code that mutates process-global current directory, environment, framework registries, ports, or shared fixtures.
- Bound worker count and keep outputs deterministic.
- Consume worker results so failures propagate, and join every worker before its fixture or temporary directory leaves scope—even when another assertion fails.
- Prefer completing one concurrent group before starting unrelated assertions. Do not overlap workloads when the small timing gain requires complicated error precedence or resource lifetimes.

## Preserve Validation Integrity

For every speedup, add or retain a correctness companion that proves the optimization seam:

- Cache hit, invalidation, and attempted mutation.
- Fake-command arguments, output, status, and injected failure.
- Imported or sourced scenario isolation and early failure.
- Worker failure propagation, cleanup, and fixture lifetime.
- Replay equivalence with retained end-to-end cases.
- Platform-specific behavior on the platform where the saving exists.

Run focused tests first, then the complete suite, randomized order with recorded seeds, coverage, syntax or lint checks, and repository diff checks. Re-run coverage after each meaningful increment and at the end; reject any unexplained regression in any measured dimension. For subprocess-heavy behavior, compare exact assertions and command traces because in-process coverage may not see child execution.

## Add Performance Gates

Keep ordinary test runs fast; expose performance measurement as an explicit local or CI task.

- Warm up before measuring and fail fast if the test command fails.
- Report individual durations, median, maximum, command, environment, and revision.
- Use same-runner base-versus-head comparisons in CI. Flag a regression only when it exceeds both a relative threshold and a meaningful absolute delta so noise does not dominate small suites.
- Use absolute median and maximum budgets only in a stable environment. Keep platform-specific budgets on that platform.
- Ratchet budgets after a stable post-change distribution while retaining realistic headroom. Do not tune a threshold around one unusually fast run.
- Test the performance runner and gate logic themselves, including invalid input, child failure, comparison thresholds, and machine-readable output.

## Review Speedup Changes

Reject or revise a change when it:

- Deletes distinct behavior because line coverage stayed flat.
- Lowers a coverage result, exclusion, or threshold to claim success.
- Replaces an integration boundary entirely with mocks.
- Removes waits without proving the awaited state.
- Adds concurrency before isolating global state or cleanup.
- Shares mutable fixtures or caches without invalidation.
- Changes shell error, trap, status, or signal behavior accidentally.
- Measures base and head under different conditions.
- Moves time outside the measured command instead of removing it.
- Adds more machinery than the measured saving warrants.

## Finish And Report

Stop when the stated target is met or the next change carries disproportionate correctness risk. Report:

1. Baseline and final distributions, including median, maximum, absolute delta, percentage, and run count.
2. The localized root cause and why the selected change removes it.
3. Behavioral assertions, scenarios, and coverage retained or added.
4. Exact focused, full, randomized, coverage, lint, syntax, and performance commands that passed.
5. Platform dependence, remaining timing variance, unverified environments, and the next measured hotspot.

Leave the repository with a faster suite and an explicit guard against giving the saving back.
