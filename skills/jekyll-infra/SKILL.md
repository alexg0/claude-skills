---
name: jekyll-infra
description: "Add CI pipeline and linting infrastructure to an existing Jekyll project. Use when the user wants to add build/CI/lint to a Jekyll site."
disable-model-invocation: true
argument-hint: ""
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
type: agent
---

# Jekyll Infrastructure Setup

Add CI pipeline and linting to an existing Jekyll project.

## Arguments

$ARGUMENTS

## Step 1: Detect Project

Verify this is a Jekyll project:
1. Check `_config.yml` exists — abort if missing
2. Check `Gemfile` exists — abort if missing
3. Read `_config.yml` to extract `title`, `url`, and other defaults

## Step 2: Gather Info

Ask the user for the following. Show defaults in parentheses.

| Field | Default | Used in |
|-------|---------|---------|
| GitHub repo URL | auto-detect from `git remote -v` if available | README |
| Default branch name | `master` | ci.yml trigger |

## Step 3: Generate Infrastructure Files

Create each file below. If a file already exists, warn the user and ask before overwriting.

### 3.1: `.gitignore`

    _site
    .sass-cache
    .jekyll-cache
    .jekyll-metadata
    # Bundler folders
    vendor/
    .bundle/

### 3.2: `.ruby-version`

Write `4.0.1` (or match existing `.ruby-version` if present).

### 3.3: `_rake-configuration.rb`

    # this file can be used to override the Rakefile's default, but it is not needed
    
    # launch compass
    $compass = false
    
    # default extension for posts
    $post_ext = ".md"
    
    # default location for posts
    $post_dir = "_posts/"
    
    # check and warn before deploying if there are remote changes (if git is used)
    $git_check = true
    
    # commit and push after deploying
    $git_autopush = false

### 3.4: `_config_deploy.yml`

    # put here any directive needed only when deploying
    # a special deploy_dir variable specifies the deployment location using rsync
    
    baseurl: {{SITE_URL}}
    deploy_dir: user@example.com:/some/location/where/to/deploy

Replace `{{SITE_URL}}` with the URL from `_config.yml`.

### 3.5: `Rakefile`

Write the full Rakefile. This is a self-contained template — do not read from external files.

The Rakefile must include these sections in order:
1. Configuration variable loading (`_rake-configuration.rb`)
2. Default variable values
3. Core tasks: clean, preview/serve, build, deploy, deploy_github, create_post, post_changes, list_changes
4. Support functions: list_file_changed, user_visible, file_change_ext
5. check_links task (anemone-based)
6. `install:deps` namespace — installs markdownlint-cli2, yamllint, lychee
7. `ci` namespace — ci:build, ci:lint, ci:links tasks
8. Top-level `ci` task combining all ci:* tasks
9. General support functions: command_available?, cleanup, jekyll, compass, rake_running, git helpers

Key details for ci:links task: use `lychee --offline --root-dir _site --config .lychee.toml "_site/**/*.html" README.md`

### 3.6: `.github/workflows/ci.yml`

GitHub Actions CI workflow with 3 jobs: Build, Lint, Links.

- Triggers on: pull_request + push to {{DEFAULT_BRANCH}}
- Build job: checkout, setup-ruby with .ruby-version, bundler-cache, jekyll build with deploy config
- Lint job: checkout, markdownlint-cli2-action@v20, setup-python, install yamllint, run yamllint
- Links job: checkout, setup-ruby, jekyll build, lychee-action@v2 with `--offline --root-dir _site --config .lychee.toml`

**Important:** All `${{ }}` expressions are GitHub Actions syntax and must be preserved literally. Do NOT treat them as placeholders.

### 3.7: `.markdownlint-cli2.jsonc`

JSON config with these rules disabled: MD001, MD003, MD004, MD007, MD013, MD022, MD024, MD025, MD026, MD029, MD032, MD033, MD036, MD041, MD051, MD060.

Globs: README.md, .github/**/*.md, _posts/**/*.md, _includes/**/*.md, *.md, !vendor/**, !_site/**

### 3.8: `.yamllint.yml`

Extends default. Ignores _site/, .jekyll-cache/, vendor/. Disables: document-start, colons, comments, indentation, trailing-spaces, truthy. Line-length max 160 (warning). Empty-lines max 3.

### 3.9: `.lychee.toml`

    verbose = "info"
    no_progress = true
    include_mail = false
    root_dir = "_site"
    max_concurrency = 8
    max_retries = 2
    retry_wait_time = 2
    timeout = 20
    
    accept = [200, 429]
    
    exclude = [
      "^https?://localhost",
      "^mailto:",
      "^tel:"
    ]

## Step 4: Update CLAUDE.md

If a `CLAUDE.md` exists, append commands and CI sections. If not, skip this step.

## Step 5: Update README.md

If a `README.md` exists, append development and CI sections if they don't already exist.

## Step 6: Install Dependencies

Run `bundle install`. Check availability of linting tools and report what is missing.

## Step 7: Verify

Run `bundle exec jekyll build --config _config.yml,_config_deploy.yml`. If linting tools are available, also run `rake ci:lint` and `rake ci:links`. Report pass/fail for each check.

## Step 8: Report

Tell the user:
1. **Files created** — list all new files
2. **Available commands:** rake preview, rake ci, rake install:deps
3. **GitHub setup needed:** push to GitHub to activate CI workflow
