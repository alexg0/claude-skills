---
name: jekyll-singlepage
description: "Scaffold a Jekyll single-page website from the t413/SinglePaged theme with a modern dark design system. Use when the user wants to create a new single-page Jekyll site."
disable-model-invocation: true
argument-hint: "[site-name]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep]
type: agent
---

# Jekyll SinglePaged Site Scaffold

Scaffold a single-page Jekyll website from the upstream [t413/SinglePaged](https://github.com/t413/SinglePaged) theme, then apply a modern dark design system with responsive layout, cards, FAQ accordion, process steps, and hero sections.

## Arguments

$ARGUMENTS

If an argument is provided, use it as the site name. Otherwise, ask.

## Step 1: Gather Info

Ask the user for the following. Show defaults in parentheses and accept Enter to keep them.

| Field | Default | Used in |
|-------|---------|---------|
| Site name / title | from argument or ask | _config.yml `title`, footer, README |
| Short name | derived from title | OG, Schema.org, footer |
| Domain URL | `https://example.com` | _config.yml `url` |
| Description | `"A modern single-page website."` | meta description, OG |
| Keywords | `""` | meta keywords |
| Accent color hex | `#0d9488` (teal) | _includes/css/main.css, buttons, links |
| Section names | `home, about, services, contact` | _posts/ filenames and content |
| Google Analytics key | `""` (empty = disabled) | _config.yml |

## Step 2: Clone Upstream Theme

Run these commands in the target directory (current working directory, or a new subdirectory named after the site):

```bash
git clone https://github.com/t413/SinglePaged.git .
rm -rf .git
git init
```

If the directory is not empty, ask the user for confirmation before proceeding.

## Step 3: Apply Modifications

Apply each modification below in order. Use the Write tool for full replacements and Edit for targeted changes.

### 3.1: `_config.yml`

Replace entirely with:

```yaml
---

port: 4000
host: 0.0.0.0
safe: false
future: true


### site serving configuration ###
exclude: [CNAME, README.md, .gitignore, .jekyll-cache, .sass-cache, Gemfile, Gemfile.lock, Rakefile, node_modules, docs]
permalink: /:title ## disables post output
timezone: null
lsi: false
markdown: kramdown


### content configuration ###
title:       "{{SITE_TITLE}}"
keywords:    "{{KEYWORDS}}"
description: "{{DESCRIPTION}}"
baseurl:     ""
url:         "{{SITE_URL}}"
source_link: ""
favicon:     "img/favicon.ico"
touch_icon:  "img/apple-touch-icon.png"
google_analytics_key: "{{GA_KEY}}"

### open graph / social sharing ###
og_image:    "img/og-image.png"
og_site_name: "{{SHORT_NAME}}"


### template colors, used site-wide via css ###
colors:
  navy:      '#0f172a'
  darkblue:  '#1e293b'
  charcoal:  '#1e1e2e'
  slate:     '#334155'
  teal:      '{{ACCENT_COLOR}}'
  cyan:      '#06b6d4'
  white:     '#f8fafc'
  muted:     '#94a3b8'
  black:     '#0f0f0f'
  green:     '#22c55e'
  amber:     '#f59e0b'
  red:       '#ef4444'

kramdown:
  auto_ids:  false
```

Replace all `{{PLACEHOLDER}}` values with user input from Step 1.

### 3.2: `Gemfile`

Replace entirely with:

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.4.1"
gem "minima", "~> 2.5"

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.17b"
end

platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

gem "wdm", "~> 0.1", :platforms => [:mingw, :x64_mingw, :mswin]
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]
```

### 3.3: `.ruby-version`

Write: `4.0.1`

### 3.4: `index.html`

Replace entirely with:

```html
---
---
<!DOCTYPE html>
<html dir="ltr" lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{{ site.title }}</title>
  <meta name="keywords" content="{{ site.keywords }}">
  <meta name="description" content="{{ site.description }}">

  <!-- Open Graph -->
  <meta property="og:title" content="{{ site.title }}">
  <meta property="og:description" content="{{ site.description }}">
  <meta property="og:type" content="website">
  <meta property="og:url" content="{{ site.url }}{{ site.baseurl }}">
  {% if site.og_image %}<meta property="og:image" content="{{ site.url }}{{ site.baseurl }}/{{ site.og_image }}">{% endif %}
  {% if site.og_site_name %}<meta property="og:site_name" content="{{ site.og_site_name }}">{% endif %}

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="{{ site.title }}">
  <meta name="twitter:description" content="{{ site.description }}">
  {% if site.og_image %}<meta name="twitter:image" content="{{ site.url }}{{ site.baseurl }}/{{ site.og_image }}">{% endif %}

  <link rel="stylesheet" href="combo.css">
  <link href='https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap' rel='stylesheet' type='text/css'>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
  {% if site.favicon %}<link rel="shortcut icon" href="{{ site.favicon }}" type="image/x-icon">{% endif %}
  {% if site.touch_icon %}<link rel="apple-touch-icon" href="{{ site.touch_icon }}">{% endif %}

  <!-- Schema.org -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Organization",
    "name": "{{SHORT_NAME}}",
    "url": "{{ site.url }}",
    "description": "{{ site.description }}"
  }
  </script>
</head>
<body>
  <div id="main">

    <nav><ul>
      {% for node in site.posts reversed %}
        {% capture id %}{{ node.id | remove:'/' | downcase }}{% endcapture %}
        <li class="p-{{id}}"><a href="#{{id}}">{{node.title}}</a></li>
      {% endfor %}
    </ul></nav>


    {% for page in site.posts reversed %}
      {% capture id %}{{ page.id | remove:'/' | downcase }}{% endcapture %}
      <div id="{{id}}" class="section p-{{id}}">
        {% if page.icon %}
        <div class="subtlecircle sectiondivider imaged">
          <img src="{{page.icon}}" alt="section icon" />
          <h5 class="icon-title">{{ page.title }}</h5>
        </div>
        {% elsif page.fa-icon %}
        <div class="subtlecircle sectiondivider faicon">
          <span class="fa-stack">
            <i class="fa fa-circle fa-stack-2x"></i>
            <i class="fa fa-{{ page.fa-icon }} fa-stack-1x"></i>
          </span>
          <h5 class="icon-title">{{ page.title }}</h5>
        </div>
        {% endif %}
        <div class="container {{ page.style }}">
          {{ page.content }}
        </div>
      </div>
    {% endfor %}


    <div id="footer" class="section text-white">
      <div class="container">
        {% capture foottext %} {% include footer.md %} {% endcapture %}
        {{ foottext | markdownify }}
      </div>
    </div>
  </div>

{% include analytics.html %}
</body>
<script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
<script src="site.js"></script>
</html>
```

**Important:** The `{{SHORT_NAME}}` in the Schema.org block is a literal string you must substitute with the user's short name before writing the file. All `{{ site.* }}` and `{% %}` tags are Jekyll/Liquid and must be preserved as-is.

### 3.5: `combo.css`

Replace entirely with:

```css
---
---
{% include css/base.css %}
{% include css/skeleton.css %}
{% include css/main.css %}
```

### 3.6: `_includes/css/main.css`

Replace entirely. This is the design system. Copy the full content from the reference project at `/Users/alexg/conductor/workspaces/storagedispatch-website/denver/_includes/css/main.css`.

After copying, if the user specified a custom accent color different from `#0d9488`, do a find-and-replace of `#0d9488` with their accent color throughout the file. Also replace the hover variant `#0f766e` with a darker shade of their accent color.

### 3.7: `site.js`

Replace entirely. Copy from the reference project at `/Users/alexg/conductor/workspaces/storagedispatch-website/denver/site.js`.

### 3.8: `_includes/footer.md`

```markdown

&copy; {{YEAR}} {{SHORT_NAME}}
```

Replace `{{YEAR}}` with the current year and `{{SHORT_NAME}}` with the user's short name.

### 3.9: `_includes/analytics.html`

```html
{% if site.google_analytics_key %}
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', '{{ site.google_analytics_key }}']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
{% endif %}
```

### 3.10: `404.html`

```html
---
permalink: /404.html
---

<style type="text/css" media="screen">
  .container {
    margin: 10px auto;
    max-width: 600px;
    text-align: center;
  }
  h1 {
    margin: 30px 0;
    font-size: 4em;
    line-height: 1;
    letter-spacing: -1px;
  }
</style>

<div class="container">
  <h1>404</h1>

  <p><strong>Page not found :(</strong></p>
  <p>The requested page could not be found.</p>
</div>
```

### 3.11: Generate `_posts/`

Remove any existing files in `_posts/`. Generate one markdown file per section the user specified. Use ascending dates starting from `2020-01-01` to control display order.

**Front matter pattern for each post:**

```yaml
---
title: "{{section_title}}"
bg: {{bg_color_name}}
color: white
style: {{style}}
---
```

**Color rotation for backgrounds:** cycle through `navy`, `darkblue`, `charcoal`, `slate` for successive sections.

**Style rules:**
- First section (home/hero): `style: hero`
- Last section (contact/CTA): `style: center`
- All others: `style: left`

**Starter content per section type:**

For **home/hero** sections, generate:
```markdown
# {{SITE_TITLE_SHORT}}

{{DESCRIPTION}}

<div class="hero-ctas">
<a href="#contact" class="btn-primary">Get Started</a>
<a href="#about" class="btn-secondary">Learn More</a>
</div>
```

For **about** sections, generate:
```markdown
## About Us

Tell your story here. What problem do you solve? Who do you serve?

Replace this placeholder content with your own.
```

For **services** sections, generate:
```markdown
## Our Services

<div class="card-grid thirds">
<div class="card">

### Service One

Describe your first service or offering.

</div>
<div class="card">

### Service Two

Describe your second service or offering.

</div>
<div class="card">

### Service Three

Describe your third service or offering.

</div>
</div>
```

For **contact** sections, generate:
```markdown
## Get in Touch

We'd love to hear from you. Reach out to start a conversation.

<div class="hero-ctas">
<a href="mailto:hello@example.com" class="btn-primary">Email Us</a>
</div>
```

For any other section name, generate a generic placeholder:
```markdown
## {{Section Title}}

Add your content for this section here.
```

### 3.12: `img/` directory

Create the directory if it doesn't exist:
```bash
mkdir -p img
```

### 3.13: `CLAUDE.md`

Generate a project-specific CLAUDE.md:

```markdown
# {{SHORT_NAME}} Website

Single-page Jekyll site for {{SITE_URL}}, built on the SinglePaged theme pattern.

## Architecture

- **Jekyll 4.4.x** static site generator
- Single-page scrolling layout: each section is a markdown file in `_posts/`
- Post date controls section order (ascending dates display top-to-bottom via `reversed` loop)
- Colors defined in `_config.yml` and auto-generated into CSS classes
- Skeleton CSS grid (960px max) + Inter font + Font Awesome 6 icons
- Dark design: navy/charcoal backgrounds, accent color, off-white text

## Content Sections (`_posts/`)

Display order (controlled by date ascending):
{{SECTION_LIST}}

Each post uses YAML front matter:
- `title`: nav label and section heading
- `bg`: background color key (from `_config.yml` colors)
- `color`: text color key
- `fa-icon`: (optional) FontAwesome icon name for section divider
- `style`: container class — `hero`, `center`, or `left`

## Key Files

- `_config.yml` — site metadata, colors, OG tags, build config
- `index.html` — main template with nav + sections + Open Graph + schema.org
- `combo.css` — aggregates `_includes/css/{base,skeleton,main}.css`
- `_includes/css/main.css` — design system (colors, cards, process steps, FAQ, buttons)
- `site.js` — jQuery smooth-scroll navigation
- `_includes/footer.md` — footer content

## Commands

- `bundle exec jekyll serve --watch` — local preview at localhost:4000
```

Replace `{{SECTION_LIST}}` with a numbered list of the generated post files and their titles.

### 3.14: `README.md`

Generate a README:

```markdown
# {{SHORT_NAME}}

Single-page Jekyll site for [{{SITE_URL}}]({{SITE_URL}}).

## Quick Start

\`\`\`sh
bundle install
bundle exec jekyll serve --watch
# Open http://localhost:4000
\`\`\`

## Project Structure

\`\`\`text
_posts/           # Content sections (date controls display order)
_includes/css/    # Design system (base, skeleton, main)
_config.yml       # Site metadata, colors, OG tags
index.html        # Main template with nav + sections
\`\`\`

## Content Editing

Each section is a markdown file in `_posts/`. Display order is controlled by the date in the filename (ascending).

Front matter options: `title`, `bg`, `color`, `fa-icon`, `style` (`hero`, `center`, or `left`).
```

## Step 4: Install & Verify

Run:
```bash
bundle install
bundle exec jekyll build
```

If the build fails, diagnose and fix the issue before reporting success.

## Step 5: Report

Tell the user:
1. What was created (list of files)
2. How to preview: `bundle exec jekyll serve --watch` then open http://localhost:4000
3. How to add sections: create new `.md` files in `_posts/` with incrementing dates
4. Suggest running `/jekyll-infra` to add CI, deployment, and linting infrastructure
