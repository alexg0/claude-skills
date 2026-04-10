---
name: ss
description: Grab recent screenshots from ~/Dropbox/Screenshots and act on them. Supports count arg, negative index, and freeform action after the number.
type: command
---

# /ss - Screenshot Grabber

Grab recent screenshots from `~/Dropbox/Screenshots` and act on them visually.

## Argument Parsing

The user invokes `/ss [count] [action...]`. Parse the arguments as follows:

1. **First argument** (optional): a number controlling which screenshots to grab.
   - No number or `1` → grab the **1 most recent** screenshot
   - Positive `N` (e.g. `3`) → grab the **N most recent** screenshots
   - Negative `-N` (e.g. `-4`) → grab **only the Nth most recent** screenshot (1-indexed, so `-1` = most recent, `-4` = 4th most recent)
2. **Remaining arguments** (optional): the action/instruction to perform on the screenshots.
   - If no action is given, default to describing what's in the screenshot(s).

## Execution Steps

### Step 1: List recent screenshots

Run this command to find screenshots from the last 10 hours, newest first:

```bash
find ~/Dropbox/Screenshots -maxdepth 1 -type f \( -name "*.png" -o -name "*.jpg" -o -name "*.jpeg" -o -name "*.gif" -o -name "*.webp" -o -name "*.heic" \) -mmin -600 | xargs ls -t
```

Display the list to the user so they can see what's available.

### Step 2: Select screenshots

Based on the parsed count argument, select the appropriate screenshot(s) from the sorted list.

- If there are no screenshots in the last 10 hours, tell the user.
- If the user asked for more screenshots than exist, grab all available and note it.

### Step 3: Act on the screenshots

Interpret the action and decide the execution strategy. The goal is to **offload screenshot reading to a subagent** whenever possible to avoid consuming tokens in the parent context for large image payloads.

#### Action table

| Action | Meaning |
|--------|---------|
| *(none)* | Describe what's in the screenshot(s) |
| `huh` / `explain` / `what` | Explain the content in detail |
| `fix` | The screenshot shows an error or visual bug. Understand it, find the root cause in the codebase, and fix the code. |
| `do this` / `do` | The screenshot shows something inspirational. Analyze it, extract the pattern, and implement a version tailored to the current project. |
| `make infographic` / `infographic` | Combine the content from multiple screenshots into a unified infographic |
| `ocr` / `text` / `copy` | Extract all text from the screenshot(s) |
| Any other text | Treat as a freeform instruction applied to the screenshot content |

#### Execution strategy

**Self-contained actions** — actions where the result is purely derived from the screenshot(s) with no codebase interaction needed:
- `describe` (default), `huh`/`explain`/`what`, `ocr`/`text`/`copy`, `make infographic`

→ Launch a **subagent** (using the Agent tool, `subagent_type: "general-purpose"`) with a prompt that:
  1. Lists the screenshot file path(s) to read
  2. Instructs it to use the Read tool to view the images
  3. Specifies the action to perform (describe, extract text, etc.)
  4. Asks it to return the result as text

Then relay the subagent's response to the user.

**Codebase actions** — actions that require reading the screenshot AND then acting on the codebase:
- `fix`, `do this`/`do`, freeform instructions that imply code changes

→ Launch a **subagent** to read and analyze the screenshot(s), with a prompt that:
  1. Lists the screenshot file path(s) to read
  2. Instructs it to describe the content in detail — extract all visible text, error messages, UI elements, layout structure, colors, or whatever is relevant to the action
  3. Asks it to return a structured analysis (NOT to make code changes)

Then use the subagent's analysis to perform the codebase action yourself, without ever reading the image files directly.

**Context matters.** Use your knowledge of the current project and conversation to interpret ambiguous actions. For example, `fix` during a frontend design project means fix a visual issue, while `fix` during backend work means fix the error shown in the screenshot.

## Important

- Always show the file list first so the user has context.
- **Never read image files directly in the parent context** — always delegate to a subagent via the Agent tool.
- For self-contained actions, the subagent does all the work and you relay results.
- For codebase actions, the subagent extracts information and you act on it.
- When fixing code based on screenshot analysis, follow standard debugging workflow: understand error → locate root cause → fix → verify.
