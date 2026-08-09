---
name: fly-deploy
description: Create, deploy, and troubleshoot static websites on Fly.io. Use when the user explicitly asks to host a static site on Fly.io, create a Fly application for static output, run `fly deploy`, or diagnose an existing Fly static-site deployment.
---

# Fly.io Static Site

Create or maintain a Fly.io static-site deployment without assuming a framework, branch, region, CI provider, or task runner.

## Discover the project

1. Read repository instructions and existing deployment documentation.
2. Identify the actual build command and static output directory from project files.
3. Inspect an existing `Dockerfile`, `.dockerignore`, and `fly.toml` before adding or changing infrastructure.
4. Build locally and verify the output contains the expected entry page and assets.

## Preflight

- Check `fly version` and `fly auth whoami`. If authentication is missing, ask the user to run `fly auth login`.
- Inspect `git status --short` and preserve unrelated changes. A dirty tree is context to review, not an automatic reason to refuse a requested deployment.
- Never print, commit, or persist Fly tokens.
- Creating an application, allocating resources, changing configuration, and deploying are remote mutations. Perform only the operations the user requested.

## Create a static-site container

Prefer existing project conventions. If no container exists, add the smallest Dockerfile that builds or copies the site's generated output into a static web server. For a site already built before the image step, a minimal shape is:

```dockerfile
FROM nginx:alpine
COPY dist/ /usr/share/nginx/html/
```

Replace `dist/` with the detected output directory. Use a multi-stage Docker build only when the project needs its build toolchain inside the image. Add custom server configuration only for an actual requirement such as SPA fallback, caching, redirects, or security headers.

Exclude development dependencies, source artifacts, credentials, and local build caches from the Docker context when appropriate.

## Create the Fly application

If `fly.toml` is absent, run:

```bash
fly launch --no-deploy
```

Choose the application name, organization, and primary region from user input or existing project context; do not hard-code defaults. Review the generated `fly.toml` before deployment. Ensure the HTTP service's `internal_port` matches the container's listening port and keep the generated resource settings unless the project has a reason to change them.

Do not add CI, Rake tasks, secrets, databases, volumes, or custom domains unless requested. A basic static site does not require them.

## Deploy

Run the project's existing checks and rebuild locally. Then deploy from the repository root:

```bash
fly deploy
```

Stop and report the actual error if the build or deployment fails. Diagnose with the Docker build output, `fly status`, and recent `fly logs --no-tail`; avoid speculative configuration changes.

## Verify and report

1. Run `fly status` and inspect configured health checks when present.
2. Request the public HTTPS URL and verify the expected page, status code, redirects, and key assets. Account for automatic machine start-up when interpreting the first request.
3. If verification fails, inspect `fly logs --no-tail` and confirm the server listens on the port configured in `fly.toml`.
4. Report the application name, region, deployed URL, image/build result, checks performed, and any remote setup still required.
