# Lessons

## 2026-08-08 — Do not print whole configuration files during audits

- Failure mode: Reading an entire user configuration file exposed credential values in tool output.
- Detection signal: A configuration section contained token-shaped fields.
- Prevention rule: Inspect configuration keys and selected non-sensitive values only. Before printing configuration content, search for secret-bearing key names and redact or omit their values. Use filename- and commit-level history checks instead of content dumps when assessing secret exposure.

## 2026-08-08 — Compare workflow depth before declaring a skill redundant

- Failure mode: A specialized personal skill was removed because an official skill covered the same file type at a high level.
- Detection signal: The personal skill encoded project automation, dependency management, and domain-specific tooling that the official skill did not mention.
- Prevention rule: Compare supported inputs, outputs, automation, verification, and operational conventions before pruning. Treat a narrow workflow skill as complementary when it adds meaningful behavior beneath a broad upstream capability; rename and narrow its trigger instead of deleting it.
