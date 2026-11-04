---
name: lavish-open
description: Open local HTML, Markdown, or plain-text files in Lavish, converting reports into readable standalone HTML. Use for requests such as "open report.md in lavish" or "show this report in lavish".
---

# Open a file in Lavish

Run the helper from the user's working directory, resolving its path relative
to this skill:

```bash
python3 <skill-directory>/scripts/open_file.py <file-path>
```

HTML opens directly. Markdown (`.md`, `.markdown`) and plain text (`.txt`,
`.text`, or no extension) become standalone HTML under the working directory's
`.lavish/`, with a title from the first Markdown heading or filename and an
embedded light/dark reading stylesheet. The source stays unchanged. The helper
prints the opened HTML path to stderr and passes through Lavish's session URL
on stdout. It requires Python 3, `lavish-axi`, and, for conversion, `pandoc`.
If a dependency is missing, report the error; do not install it automatically.

Return the session URL. Poll feedback with `lavish-axi poll <opened-html-path>`
using the harness's own tracked background mechanism with completion notification
to this agent. Never use shell `&`, `nohup`, or a detached fire-and-forget poll.
If no completion-aware mechanism exists, use a foreground poll. Read delivered
feedback completely and act on it; resume polling while review remains active.

For testing, `LAVISH_AXI` may name a replacement launcher executable (one path,
without shell arguments). Relative images and other local assets in converted
documents are not copied; prepare those separately when the report needs them.
