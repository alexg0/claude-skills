---
name: generate-pdfs
description: Generate PDFs from markdown files, or create/update a thin Rakefile that calls md2pdf for PDF generation.
type: command
---

Generate PDFs from markdown files, or create/update a Rakefile for PDF generation.

PDF rendering is delegated to [md2pdf](https://github.com/alexg0/md2pdf). The Rakefile should be thin: glob source files, declare file tasks, shell out to `md2pdf`. Per-document options (title, margin, fontsize, font, page numbers) live in YAML frontmatter inside the source markdown files — not in Ruby hashes inside the Rakefile.

`md2pdf` defaults to its `pandoc-xelatex` backend with `Noto Serif`. It auto-creates the output directory, renders fenced ` ```mermaid ` blocks via `mmdc`, reads frontmatter, defaults the author to `git config user.name`, and accepts multiple input files (concat) when given `-o output.pdf`.

## Modes

### 1. Build PDFs (default, no arguments or target name as argument)

Look for a Rakefile in the current working directory or project root.

- If Rakefile exists and no argument: run `rake pdf:all`
- If Rakefile exists with a target argument: run `rake 'pdf:build[$ARGUMENTS]'` so zsh does not treat brackets as globs
- If no Rakefile exists: offer to create one (see mode 2), or invoke md2pdf directly:
  ```
  md2pdf <file>.md -o <file>.pdf
  md2pdf chapter1.md chapter2.md -o book.pdf
  ```

After building, report which PDFs were generated and their file sizes.

### 2. Create or update Rakefile (`setup` as argument)

If argument is `setup` — create a new Rakefile in the current directory:

1. Ask which directories contain markdown source files (e.g. `analysis/`, or multiple)
2. Ask for the project's author label (or accept the `git config user.name` default by saying so)
3. Generate the following Rakefile pattern (verbatim — keep it thin):

```ruby
# frozen_string_literal: true

require "rake/clean"

PDF_DIR = "pdfs"
SOURCE_DIRS = ["analysis"]

DOCS = SOURCE_DIRS.flat_map { |d| Dir.glob("#{d}/**/*.md") }.sort.each_with_object({}) do |path, h|
  key = File.basename(path, ".md")
  if h.key?(key)
    raise "PDF name collision: #{key}.pdf claimed by both #{h[key].first} and #{path}"
  end
  h[key] = [path]
end.freeze

# Project-wide author label (override md2pdf's git-config default).
# Per-doc title/margin/etc. live in YAML frontmatter in the source files.
AUTHOR = "Author Name"
DEFAULT_FONT_SIZE = "11pt"

def cmd!(*args)
  ok = system(*args)
  raise "Command failed: #{args.join(' ')}" unless ok
end

def on_path?(cmd)
  system("command -v #{cmd} >/dev/null 2>&1")
end

def which!(cmd, install_hint:)
  return if on_path?(cmd)
  raise "#{cmd} not found on PATH. Install: #{install_hint}"
end

def pdf_path(name)
  File.join(PDF_DIR, "#{name}.pdf")
end

def build_pdf!(name)
  files = DOCS[name]
  raise "Unknown target: #{name}" unless files
  cmd!("md2pdf", "-a", AUTHOR, "-s", DEFAULT_FONT_SIZE, *files, "-o", pdf_path(name))
  puts "  #{pdf_path(name)}"
end

DOCS.each do |name, files|
  file pdf_path(name) => files + ["Rakefile"] do
    build_pdf!(name)
  end
end

all_pdfs = DOCS.keys.map { |name| pdf_path(name) }

namespace :pdf do
  desc "Install/check PDF dependencies (md2pdf and its rendering engine)"
  task :deps do
    which!("md2pdf", install_hint: "brew install alexg0/tap/md2pdf")
    cmd!("md2pdf", "--install-deps")
  end

  desc "Build all PDFs"
  task all: [:deps] + all_pdfs

  desc "Build a single PDF: rake pdf:build[name]"
  task :build, [:name] => [:deps] do |_, args|
    name = args[:name] || DOCS.keys.first
    Rake::Task[pdf_path(name)].invoke
  end

  desc "Open a PDF (macOS): rake pdf:open[name]"
  task :open, [:name] do |_, args|
    name = args[:name] || DOCS.keys.first
    cmd!("open", pdf_path(name))
  end

  desc "List available targets"
  task :list do
    puts "Available PDF targets:"
    DOCS.each { |name, files| puts "  #{name.ljust(25)} => #{files.join(', ')}" }
  end
end

task default: all_pdfs
```

### 3. Per-document overrides — use YAML frontmatter

Anything that varies by document lives at the top of the markdown source, not in the Rakefile:

```yaml
---
title: "Custom Title — overrides H1 detection"
author: "Specific Author"
margin: 0.75in
fontsize: 12pt
font: "EB Garamond"
toc: false
numbersections: false
page_numbers: false
---
```

Precedence: CLI flag > frontmatter > built-in default. So a Rakefile passing `-s 10pt` overrides any frontmatter `fontsize:` in source files. Per-doc overrides should set only what differs from the project default.

### 4. Mermaid diagrams

Just write fenced ` ```mermaid ` blocks. md2pdf renders them via `mmdc` and caches by content hash. No Rakefile preprocessing needed. To disable for a one-off, pass `--no-mermaid` to md2pdf.

If `mmdc` is not installed, `md2pdf --install-deps` will install it.

### 5. Check or install dependencies (`deps` as argument)

- If a Rakefile exists: run `rake pdf:deps`.
- Otherwise: ensure md2pdf itself is on PATH (`brew install alexg0/tap/md2pdf` if missing), then run `md2pdf --install-deps` (or `--check-deps`) to verify pandoc / xelatex / Noto Serif / mmdc.

## Key design principles

- **Thin Rakefile**: glob, declare file tasks, shell out. No preprocessing, no per-doc Ruby hashes, no temp build directory, no install bootstrap.
- **md2pdf owns rendering**: title block, Unicode normalization, link colors, mermaid, output-dir creation, frontmatter, multi-input concat — all on the md2pdf side.
- **Per-doc options in frontmatter**: title/margin/fontsize/font/toc/numbersections/page_numbers — never in Ruby hashes.
- **Auto-discovery**: `Dir.glob` finds all `.md` files. No manual list to maintain.
- **Proper Rake file dependencies**: declare prerequisites so unchanged sources are skipped.
- **Install via brew tap**: `brew install alexg0/tap/md2pdf` — no clone-and-make-install bootstrap inside Rakefiles.
