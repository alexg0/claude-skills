---
name: jekyll-infra
description: Add or repair continuous integration, generated-output verification, linting, and dependency conventions for an existing static Jekyll site. Use only when the repository already builds static pages with Jekyll and the user asks to establish or repair its automated build and quality checks. Do not use for dynamic web applications or non-Jekyll frontend projects.
---

# Jekyll static-site infrastructure

Add the smallest CI and quality setup that matches the existing project instead of imposing a fixed Rakefile, deployment method, branch, Ruby version, or lint configuration.

## Discover existing conventions

1. Confirm `_config.yml` and a Bundler-managed `Gemfile` exist.
2. Read repository instructions, `Gemfile.lock`, `.ruby-version`, existing scripts or Rake tasks, CI workflows, lint configuration, and deployment documentation.
3. Detect the default branch from Git metadata or the remote. Do not assume `main` or `master`.
4. Run the current local build before editing to distinguish pre-existing failures from CI problems.

## Choose the checks

Prefer existing project commands. A useful baseline is:

- reproducible dependency installation with Bundler;
- `bundle exec jekyll build` using the same configuration as production;
- Markdown, YAML, and link checks only when their scope and rules fit the repository;
- caching supplied by the CI platform's maintained language setup action;
- least-privilege workflow permissions and concurrency appropriate to the repository.

Do not add deployment, SSH/rsync configuration, Rake wrappers, analytics, or broad lint-rule suppression unless requested. Use the dedicated deployment skill when the user names a hosting provider.

## Implement safely

- Preserve an existing compatible Ruby constraint. For an unpinned project, determine a current version supported by the locked Jekyll and plugin dependencies before adding `.ruby-version`.
- Extend existing workflow files when coherent; otherwise add one clearly named CI workflow.
- Pin third-party actions according to the repository's security convention and use current maintained releases.
- Make workflow triggers match the detected default branch and pull-request policy.
- Exclude generated and vendored paths narrowly. Fix actual lint failures instead of disabling large groups of rules by default.
- Do not overwrite existing configuration without reviewing and reconciling it.

## Verify and report

Run every command the workflow will run, including the production-equivalent Jekyll build and configured linters. Validate workflow YAML and inspect the diff for unintended deployment or permission changes.

Report:

- files and checks added or repaired;
- local command results;
- detected Ruby/Jekyll and default-branch assumptions;
- CI checks that require a push to verify;
- any pre-existing build or content failures left unresolved.
