---
name: ss
description: Locate and inspect recent screenshots without exposing unrelated files. Use when the user uses `ss` as a screenshot shorthand, asks about the latest screenshot, selects a recent screenshot by positive or negative index, or requests an action based on one or more screenshots.
---

# Recent screenshots

Select only the screenshots needed for the request, inspect them with the client's image-viewing capability, and apply the requested action.

## Parse the request

Treat the first numeric argument as the selector:

- omitted or `1`: the most recent screenshot;
- positive `N`: the `N` most recent screenshots;
- negative `-N`: only the Nth most recent screenshot, so `-1` is newest and `-4` is fourth-newest.

Treat the remaining text as the requested action. Describe the selected image when no action is supplied. Reject `0` because it has no useful selection meaning.

## Select privately

Run the bundled selector from the skill directory:

```bash
python3 "<skill-dir>/scripts/select_screenshots.py" <selector>
```

The selector checks, in order, an explicit `SCREENSHOT_DIR`, the macOS screenshot location, and common local screenshot folders. It recognizes macOS screen-capture metadata and common screenshot filename prefixes, sorts matches globally by modification time, and prints a JSON array containing only selected paths. It deliberately has no recency cutoff. Set `SCREENSHOT_NAME_PREFIXES` to a comma-separated list when screenshots use custom names.

If a positive selector exceeds the number available, use all available files and mention the shortfall. If a negative selector is out of range or no screenshot exists, report that without listing unrelated filenames. Never show the full candidate set.

## Act on the selection

- For description, explanation, or OCR, return only the requested interpretation or text.
- For a reported error or visual bug, reproduce it when possible, find the root cause, make the smallest authorized fix, and verify it.
- For an inspirational example, extract the relevant visual or interaction pattern and adapt it to the current project without copying unrelated branding or content.
- For an infographic, synthesize the selected screenshots with the client's supported image or document-generation workflow.
- Treat any other text as a freeform instruction applied to the selected images.

Do not expose sensitive text beyond what the user requested. Delegate only when independent work would materially reduce latency and the current client permits it.
