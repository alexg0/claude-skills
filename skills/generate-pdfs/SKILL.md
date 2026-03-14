---
name: generate-pdfs
description: Generate PDFs from markdown files, or create/update a Rakefile for PDF generation.
type: command
---

Generate PDFs from markdown files, or create/update a Rakefile for PDF generation.

When using XeLaTeX, prefer a Unicode-capable main font such as `Noto Serif` or `STIX Two Text` so body-text Greek characters render correctly. Keep lightweight text replacements only for symbols that still warn in the chosen font (for example emoji or arrows).

## Modes

### 1. Build PDFs (default, no arguments or target name as argument)

Look for a Rakefile in the current working directory or project root.

- If Rakefile exists and has no arguments: run `rake pdf:all`
- If Rakefile exists with a target argument: run `rake 'pdf:build[$ARGUMENTS]'` so zsh does not treat brackets as globs
- If no Rakefile exists: offer to create one (see mode 2), or use pandoc directly for a one-off:
  ```
  pandoc <file>.md --toc --number-sections --pdf-engine=xelatex -V geometry:margin=1in -V fontsize:11pt -V mainfont:"Noto Serif" -o <file>.pdf
  ```

After building, report which PDFs were generated and their file sizes.

### 2. Create or update Rakefile (`setup` or `add` as argument)

If argument is `setup` — create a new Rakefile for PDF generation in the current directory:

1. Ask the user which directory contains markdown source files (e.g. `analysis/`)
2. Ask for author name
3. Generate a Rakefile following this pattern:

```ruby
# frozen_string_literal: true

require "date"
require "digest"
require "fileutils"
require "rake/clean"

BUILD_DIR = "build"
PDF_DIR = "pdfs"
MERMAID_BUILD_DIR = File.join(BUILD_DIR, "diagrams")
MMDC_PUPPETEER_CONFIG = ENV["MMDC_PUPPETEER_CONFIG"]

# Auto-discover all markdown files in the source directory
ANALYSIS_DIR = "analysis"
DOCS = Dir.glob("#{ANALYSIS_DIR}/*.md").sort.each_with_object({}) do |path, h|
  h[File.basename(path, ".md")] = [path]
end.freeze

# Optional: override auto-extracted titles (from first # H1 line)
TITLE_OVERRIDES = {
  # "doc-name" => "Custom Title",
}.freeze

# Optional: override default geometry (margin=1in)
GEOMETRY_OVERRIDES = {
  # "doc-name" => "margin=0.75in",
}.freeze

def title_for(name)
  return TITLE_OVERRIDES[name] if TITLE_OVERRIDES.key?(name)
  first_file = DOCS[name]&.first
  return name unless first_file
  File.foreach(first_file) do |line|
    return line.sub(/\A#\s+/, "").strip if line.match?(/\A#\s+/)
  end
  name
end

AUTHOR = "Author Name"

CLEAN.include(BUILD_DIR)
```

Include these standard helper functions:
- `cmd!(*args)` — run shell command, raise on failure
- `which!(cmd, install_hint:)` — check for binary on PATH
- `document_date_for(files)` — newest mtime formatted as date
- `render_mermaid(markdown)` — render mermaid code blocks to PNG via mmdc (only if mermaid blocks exist)
- `pdf_path(name)` — returns `pdfs/<name>.pdf`
- `build_pdf!(name)` — combines markdown files, replaces emoji for LaTeX, renders mermaid, runs pandoc

The `build_pdf!` function should:
- Prepend pandoc title block (`% Title`, `% Author`, `% Date`)
- Use `title_for(name)` to get the title (auto-extracted from H1, with optional override)
- Use `GEOMETRY_OVERRIDES.fetch(name, "margin=1in")` for geometry
- Replace emoji with text equivalents for LaTeX compatibility, and only add narrow symbol fallbacks (for example `->` for `→`) if the selected Unicode font still warns
- Call `render_mermaid` to convert any mermaid code blocks to inline PNGs
- Run pandoc with: `--toc --number-sections --pdf-engine=xelatex -V geometry:<geometry> -V fontsize:11pt -V mainfont:"Noto Serif" -V linkcolor:blue -V urlcolor:blue`

Include these rake tasks using **proper Rake file-task dependencies** (not manual `invoke` in blocks):

```ruby
directory BUILD_DIR
directory PDF_DIR

# File tasks with dependency tracking — only rebuilds when source .md or Rakefile changes
DOCS.each do |name, files|
  file pdf_path(name) => [BUILD_DIR, PDF_DIR] + files + ["Rakefile"] do
    build_pdf!(name)
  end
end

all_pdfs = DOCS.keys.map { |name| pdf_path(name) }

namespace :pdf do
  task :deps do ... end

  # Use Rake prerequisites — NOT Rake::Task[...].invoke in a block
  desc "Build all PDFs"
  task all: [:deps] + all_pdfs

  desc "Build just the cheatsheet"
  task cheatsheet: [:deps, pdf_path("daily-cheatsheet")]

  desc "Build a single PDF: rake pdf:build[name]"
  task :build, [:name] => [:deps] do |_, args|
    name = args[:name] || "daily-cheatsheet"
    Rake::Task[pdf_path(name)].invoke
  end

  task :open, [:name] do ... end
  task :list do ... end
end

task default: all_pdfs
```

Key design principles:
- **Auto-discovery**: `Dir.glob` finds all `.md` files — no manual list to maintain
- **Auto-titles**: First `# H1` line is extracted as the PDF title; `TITLE_OVERRIDES` for exceptions
- **Unicode-safe PDFs**: Prefer a Unicode-capable XeLaTeX main font before transliterating source text
- **Proper dependencies**: Use Rake file tasks with prerequisites so unchanged files are never rebuilt
- **Directory tasks**: Use `directory` task instead of `FileUtils.mkdir_p` in build functions

If argument is `add` — no longer needed since files are auto-discovered. If the user asks to add a file, just tell them to put it in the analysis directory and run `rake pdf:all`.

### 3. Check dependencies (`deps` as argument)

Run `rake pdf:deps` if Rakefile exists, or manually check for pandoc and xelatex and report install commands if missing:
- `brew install pandoc`
- `brew install --cask basictex` then `eval "$(/usr/libexec/path_helper)"`
- `npm i -g @mermaid-js/mermaid-cli` (only if project has mermaid diagrams)
