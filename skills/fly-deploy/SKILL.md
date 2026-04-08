---
name: fly-deploy
description: "Deploy to fly.io or set up fly.io infrastructure. Use when the user says 'deploy', 'fly deploy', 'push to fly', 'ship it to fly.io', 'add fly.io', or '/fly-deploy'. Handles infrastructure setup, pre-flight checks, deployment, and post-deploy verification."
disable-model-invocation: true
argument-hint: "[setup|status|logs]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
type: agent
---

# Fly.io Deploy

Deploy the current project to fly.io with pre-flight safety checks and post-deploy verification. Can also set up fly.io infrastructure from scratch.

## Arguments

$ARGUMENTS

## Subcommands

Parse the arguments to determine which subcommand to run:

- **(no args)** — Full deploy workflow (see below)
- **setup** — Set up fly.io infrastructure files (see Setup section)
- **status** — Run `fly status` and report app health
- **logs** — Run `fly logs --no-tail` to show recent logs

---

## Setup Workflow

Use this when the project does not yet have fly.io infrastructure. Ask the user for:

| Field | Default | Used in |
|-------|---------|---------|
| Fly.io app name | from argument, or directory name slugified | fly.toml |
| Fly.io region | `ord` (Chicago) | fly.toml |
| Default branch name | `master` | ci.yml deploy job |

### Setup Step 1: Create `Dockerfile`

```dockerfile
FROM ruby:3.3-slim AS build

RUN apt-get update && apt-get install -y build-essential && rm -rf /var/lib/apt/lists/*

WORKDIR /site
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3
COPY . .
RUN bundle exec jekyll build --config _config.yml,_config_deploy.yml

FROM nginx:alpine
COPY --from=build /site/_site /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
```

### Setup Step 2: Create `nginx.conf`

```nginx
server {
    listen 8080;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|webp|avif|woff2?)$ {
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    # SPA-style: serve index.html for unknown routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Custom 404
    error_page 404 /404.html;
    location = /404.html {
        internal;
    }

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 256;
}
```

### Setup Step 3: Create `fly.toml`

```toml
app = '{{FLY_APP_NAME}}'
primary_region = '{{FLY_REGION}}'

[build]

[http_service]
  internal_port = 8080
  force_https = true
  auto_stop_machines = 'stop'
  auto_start_machines = true
  min_machines_running = 0

[[vm]]
  memory = '256mb'
  cpu_kind = 'shared'
  cpus = 1
```

Replace `{{FLY_APP_NAME}}` and `{{FLY_REGION}}` with user input.

### Setup Step 4: Add fly rake tasks to Rakefile

If a Rakefile exists, append a `fly` namespace with these tasks:

```ruby
namespace :fly do
  desc 'Check that flyctl is installed and authenticated'
  task :check do
    unless command_available?('fly')
      abort "flyctl is not installed.\nInstall: curl -L https://fly.io/install.sh | sh"
    end
    sh 'fly auth whoami'
    puts 'flyctl is installed and authenticated.'
  end

  desc 'Deploy to fly.io (runs lint + build first)'
  task :deploy => [:check] do
    Rake::Task['ci:lint'].invoke
    Rake::Task['ci:build'].invoke
    sh 'fly deploy'
  end

  desc 'Show fly.io app status'
  task :status => [:check] do
    sh 'fly status'
  end
end
```

### Setup Step 5: Add CI deploy job

If `.github/workflows/ci.yml` exists, append a deploy job:

```yaml

  deploy:
    name: Deploy
    if: github.event_name == 'push' && github.ref == 'refs/heads/{{DEFAULT_BRANCH}}'
    needs: [build, lint]
    runs-on: ubuntu-latest
    concurrency:
      group: deploy-production
      cancel-in-progress: false
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up flyctl
        uses: superfly/flyctl-actions/setup-flyctl@master

      - name: Deploy to fly.io
        run: flyctl deploy
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

**Important:** All `${{ }}` expressions are GitHub Actions syntax and must be preserved literally.

### Setup Step 6: Report

Tell the user:
1. **Files created** — list all new/modified files
2. **Available commands:** `rake fly:deploy`, `rake fly:status`
3. **GitHub setup needed:** add `FLY_API_TOKEN` secret (`fly tokens create deploy -x 999999h`)

---

## Full Deploy Workflow

Execute these steps in order. Stop and report if any step fails.

### Step 1: Pre-flight Checks

1. **flyctl installed?** — Run `command -v fly`. If missing, tell the user:
   `curl -L https://fly.io/install.sh | sh`
2. **flyctl authenticated?** — Run `fly auth whoami`. If it fails, tell the user to run `fly auth login`.
3. **fly.toml exists?** — Check that `fly.toml` is in the project root. If missing, abort — suggest running `/fly-deploy setup` first.
4. **Clean working tree?** — Run `git status --porcelain`. If there are uncommitted changes, **warn the user** and list the changed files. Ask for confirmation before continuing. Do NOT proceed without explicit approval.
5. **Branch check** — Run `git branch --show-current`. If the branch is not `master` or `main`, **warn the user** that auto-deploy from CI typically only runs on the default branch. Ask if they want to continue with a manual deploy from this branch.

### Step 2: Local CI Checks

1. Check if a `Rakefile` exists with CI tasks:
   - If `rake ci` is available, run it (covers build + lint + links)
   - Otherwise, check for a Jekyll project and run `bundle exec jekyll build`
2. If local CI fails, **stop and report the errors**. Do not deploy.

### Step 3: Deploy

Run `fly deploy` and stream the output. If deployment fails, report the error and suggest checking `fly logs`.

### Step 4: Post-Deploy Verification

After a successful deploy, verify everything is healthy:

#### 4a. Fly.io Status
- Run `fly status` to confirm machines are running
- Report: app name, status, region, machine count and health

#### 4b. GitHub CI Status (if applicable)
- Check if `gh` CLI is available (`command -v gh`)
- Check if this is a GitHub-hosted repo (`gh repo view --json url 2>/dev/null`)
- If both are available:
  - Get the deployed commit: `git rev-parse HEAD`
  - Check CI status: `gh run list --commit $(git rev-parse HEAD) --limit 5`
  - If a run exists, get its details: `gh run view <run-id>`
  - Report: workflow name, status (pass/fail/in-progress), and a link to the run
- If `gh` is not available or not a GitHub repo, skip this step silently

### Step 5: Summary

Print a deployment summary:

```
Deploy complete:
  App:    <app name from fly.toml>
  Commit: <short SHA> (<branch>)
  Status: <fly status summary>
  CI:     <GitHub CI status or "n/a">
```

## Error Handling

- If `fly deploy` fails, suggest: `fly logs`, `fly status`, and checking the Dockerfile
- If GitHub CI is failing, show the failing checks and link to the run
- If the user is on a non-default branch, remind them that CI auto-deploy only triggers on pushes to master/main
