---
name: cloudflare-pages
description: Create, configure, deploy, and troubleshoot static websites on Cloudflare Pages. Use when the user explicitly asks to publish a static site with Cloudflare Pages, configure a Pages project or custom domain, deploy with Wrangler, or diagnose a Pages build or deployment failure.
---

# Cloudflare Pages

Create or maintain a Cloudflare Pages deployment without assuming a framework, branch name, output directory, domain, or CI provider.

## Discover the project

1. Read the repository instructions and existing deployment documentation.
2. Identify the package manager, build command, static output directory, and default branch from project files. Do not guess these values.
3. Inspect `wrangler.toml`, `wrangler.json`, or `wrangler.jsonc` when present. Preserve unrelated Workers configuration.
4. Determine whether the project uses Git integration or Direct Upload. Do not mix the two workflows without explaining the change.
5. Build locally and confirm the output directory contains the expected entry page and assets before configuring Cloudflare.

## Preflight

- Prefer the project's pinned Wrangler command, such as `npx wrangler`, over a global installation.
- Check the Wrangler version and authentication with `wrangler --version` and `wrangler whoami`.
- Never print or persist API tokens. If authentication is missing, ask the user to authenticate or provide credentials through the environment configured for their workflow.
- Treat project creation, deployment, DNS changes, and custom-domain changes as remote mutations. Perform only the changes the user requested.

## Configure

For a Direct Upload project, configure the real output directory when repository-managed Wrangler configuration is useful:

```toml
name = "project-name"
pages_build_output_dir = "dist"
```

Keep build commands in the project's build tooling or Cloudflare Git-integration settings. Do not add framework-specific environment variables, branch mappings, or DNS targets unless the project requires them.

If the Pages project does not exist, create it with the detected project name and production branch:

```bash
wrangler pages project create PROJECT_NAME --production-branch BRANCH
```

Use `wrangler pages project list --json` to inspect existing projects before changing remote configuration. Inspect project-specific settings in the dashboard or through an authorized API request when the list output is insufficient.

## Deploy

Re-run the local build, then deploy the generated directory:

```bash
wrangler pages deploy OUTPUT_DIRECTORY --project-name PROJECT_NAME --branch BRANCH
```

Use the production branch only for an intentional production deployment. Use a feature branch for a preview deployment. `wrangler deploy` targets Workers, not Pages.

For Git-integrated projects, prefer a normal commit-and-push workflow when that is how the repository deploys. Do not add a redundant manual deployment path by default.

## Custom domains

Before changing a domain, inspect the current Pages custom-domain state and Cloudflare DNS record. Confirm the intended project and environment with the user. Do not assume a preview branch should own a production hostname.

When a dashboard-only change is required, give the exact setting and value instead of inventing an API call. Use an API or browser workflow only when the user authorizes the remote change.

## Verify and report

1. Confirm the deployment command completed and capture the resulting Pages URL.
2. Request the deployed URL and verify the expected page, status code, redirects, and key assets.
3. For a custom domain, verify DNS and HTTPS after propagation without claiming immediate convergence.
4. Report the project, branch/environment, build command, output directory, deployed URL, changes made, and any dashboard or DNS work still required.
