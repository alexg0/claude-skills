---
name: jekyll-singlepage
description: Create or modernize a one-page static Jekyll site with responsive sections, anchor navigation, accessible styling, and verified generated HTML. Use only when the user explicitly wants Jekyll for a single-page marketing, portfolio, brochure, event, or informational site. Do not use for blogs, documentation portals, multi-page sites, dynamic web applications, or general frontend work.
---

# Jekyll single-page static site

Build a maintainable static page that Jekyll renders to HTML, CSS, and assets. Do not introduce server-side application logic, authentication, databases, runtime rendering, or an API backend. Use another workflow when the requested site needs multiple routed pages or application behavior.

Do not pin a theme, visual style, analytics provider, Ruby version, or JavaScript library unless the project requires it.

## Inspect the target

1. Read repository instructions and existing design/deployment documentation.
2. Check whether the target directory is empty before creating files. Never clone over content, delete `.git`, or replace existing files without explicit authorization.
3. For an existing site, inspect `_config.yml`, `Gemfile`, `Gemfile.lock`, layouts, includes, assets, and content conventions. Preserve useful architecture and dependencies.
4. For a new site, obtain only decisions that materially shape the result: site purpose, title, audience, sections, primary action, and visual direction. Derive reasonable copy and design defaults from the user's context.

## Establish the scaffold

- Use the project's existing Jekyll and Ruby constraints. For a new project, select current mutually compatible stable versions and lock them with Bundler; do not hard-code a system Ruby version.
- Start in an empty target with Jekyll's blank scaffold or an explicitly requested, currently maintained theme. If the user names an upstream theme, inspect its current structure and license before adapting it.
- Keep configuration minimal: title, description, canonical URL when known, base URL, collections or content directories, and required plugins only.
- Use semantic section data or a dedicated collection rather than fake dated blog posts solely to control section order, unless preserving an existing theme requires that pattern.

## Build the page

Create a clear hierarchy appropriate to the site, normally including:

- skip link and semantic header/navigation;
- focused hero with one primary action;
- requested content sections with stable anchor IDs;
- contact or closing action when appropriate;
- accessible footer and a useful 404 page.

Implement a responsive design system in project assets using CSS custom properties for color, type, spacing, width, radii, and motion. Meet contrast and keyboard-navigation requirements, respect reduced-motion preferences, and provide visible focus states. Reuse an existing project design system when present.

Use vanilla JavaScript only for interactions that require it. Native anchor navigation and CSS smooth scrolling need no jQuery. Add analytics only when requested, using the provider's current supported integration and consent requirements.

Keep content editable through Markdown, data files, or established includes. Do not fill the site with generic placeholder sections when the repository or user provides real content.

## Document and verify

Update existing user-facing project documentation when the generated architecture or commands changed. Do not create or modify agent-governance or instruction files unless the user asks.

Run the repository's checks, at minimum:

```bash
bundle install
bundle exec jekyll build
```

Then verify the generated page, navigation anchors, key assets, responsive layout, keyboard flow, browser console, and broken links using the available browser workflow. Report files changed, commands run, results, and any content or deployment work still needed.
