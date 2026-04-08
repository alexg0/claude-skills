---
description: "Diagnose and fix Cloudflare Pages deployment issues. Use when a Pages deploy fails, build config is wrong, custom domains serve the wrong branch, or wrangler commands error."
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent, WebSearch, WebFetch]
type: command
---

# Cloudflare Pages Troubleshooting

Diagnose and resolve Cloudflare Pages deployment issues for this Jekyll site.

## Context

- This is a Jekyll site deployed to Cloudflare Pages
- Build output goes to `_site/`
- Config lives in `wrangler.toml` (repo) and Cloudflare dashboard (remote)
- Rake tasks in `Rakefile` wrap wrangler commands
- Intended branch/domain mapping is `master` -> `healthbrief.dev` and `prod` -> `healthbrief.app`
- See `DEPLOYMENT.md` for full architecture

## Arguments

$ARGUMENTS

If arguments are provided, treat them as an error message or description of the problem.

## Step 1: Gather State

Read these files to understand current config:
1. `wrangler.toml` — project name, pages_build_output_dir
2. `DEPLOYMENT.md` — architecture, known issues
3. `Rakefile` — deploy task definitions
4. `.github/workflows/build.yml` — CI config

## Step 2: Diagnose

Common failure modes and fixes:

### "Missing entry-point to Worker script or to assets directory"
- **Cause:** Deploy command is `npx wrangler deploy` (Workers) instead of Pages deploy
- **Fix:** Clear the deploy command in Cloudflare dashboard, or change to `npx wrangler pages deploy _site`
- Pages handles deployment from the build output dir automatically — no deploy command needed

### "wrangler deploy on a Pages project" warning
- **Cause:** Same as above — `wrangler deploy` is for Workers, `wrangler pages deploy` is for Pages
- **Fix:** Same as above

### Build succeeds but deploy fails
- Check if deploy command is set (it should be empty for Pages)
- Check if `pages_build_output_dir` in wrangler.toml matches actual output dir (`_site`)
- Check if project name in wrangler.toml matches the Cloudflare Pages project name

### Build fails
- Check Ruby version: `.ruby-version` should match what Cloudflare installs
- Check env vars: `RUBY_VERSION` and `BUNDLE_FORCE_RUBY_PLATFORM` should be set in Pages settings
- Try building locally: `bundle exec jekyll build`

### DNS / domain issues
- Production: `healthbrief.app` should CNAME to `healthbrief-website.pages.dev`
- Preview: `healthbrief.dev` should target `master.healthbrief-website.pages.dev`
- A custom domain will only follow a non-production branch if the DNS record is proxied by Cloudflare
- If `healthbrief.dev` uses external DNS or an unproxied record, expect it to resolve to the Pages production branch instead
- Branch deployment controls decide whether `master` gets preview builds; they do not map `healthbrief.dev` to `master`
- Confirm `master` has at least one successful preview deployment before diagnosing DNS
- Branch aliases are lowercased and non-alphanumeric characters are converted to `-`

## Step 3: Fix

Apply the fix. If it requires a Cloudflare dashboard change, provide:
1. The exact navigation path in the dashboard
2. The API curl command as an alternative (uses `PATCH /accounts/{account_id}/pages/projects/{project_name}`)

For `healthbrief.dev` serving production instead of preview, the usual dashboard/DNS fix is:
1. Workers & Pages -> project -> Custom domains -> confirm `healthbrief.dev` is active
2. DNS -> `healthbrief.dev` zone -> edit the Pages CNAME target from `healthbrief-website.pages.dev` to `master.healthbrief-website.pages.dev`
3. Confirm the record remains proxied through Cloudflare
4. Confirm the Pages production branch is `prod`, not `master`

If it requires a repo change, make the edit and verify with a local build:

```bash
bundle exec jekyll build
```

## Step 4: Verify

1. If repo change: confirm local build succeeds
2. If domain issue: verify the custom domain is active in Pages and the DNS target/proxy status match the intended branch
3. Provide the user with steps to verify the deploy (push, check Cloudflare dashboard, or manual deploy via `rake cloudflare:deploy_preview`)

## Step 5: Report

Summarize:
- **Root cause** — what was wrong
- **Fix applied** — what changed (repo and/or dashboard)
- **Verification** — how to confirm it's working
