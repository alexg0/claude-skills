---
name: devonthink-mcp
description: Manage DEVONthink content via the MCP server. Use for searching, reading, organizing, renaming, moving, tagging, or auditing DEVONthink records and databases, especially when maintaining inbox organization or applying naming/routing rules.
type: skill
---

# DEVONthink MCP

## Overview
Use DEVONthink MCP tools to inspect and organize records while following local repository rules, especially `structure.md` for naming and routing. Always confirm with the user before making direct changes in DEVONthink.

## Quick Start
1. Verify access: `mcp__devonthink__is_running` and `mcp__devonthink__current_database`.
2. Read repository guidance: load `structure.md` from the repo root.
3. Discover records: use `mcp__devonthink__search` or `mcp__devonthink__list_group_content`.
4. Propose actions: summarize intended renames/moves/tags and ask for approval.
5. Execute changes only after explicit user confirmation.

## Core Tasks
### Inspect and summarize
- Use `mcp__devonthink__get_record_properties` and `mcp__devonthink__get_record_content` for context.
- Provide a short summary and suggested destination/name based on `structure.md`.
- When processing inbox batches, scan OCR for reverse-order pages and flag for manual reordering.

### Organize and rename
- Follow the naming format in `structure.md` (date - entity - doc type - qualifier).
- Suggest a destination group path in `dt_processed` based on routing rules.
- Ask before calling `mcp__devonthink__rename_record`, `mcp__devonthink__move_record`, or `mcp__devonthink__add_tags`.
- If a document requires action (e.g., tax or billing notices), propose flagging and routing to `dt_processed/action-required`.

### Batch workflows
- For multi-record operations, present a clear, numbered plan with per-record actions.
- Execute in small batches and re-confirm if scope changes.

## Approval Rules
- Always ask before any direct change: rename, move, delete, tag, or content update.
- If unsure about a document, route to `needs-review` and ask the user to decide.

## Examples
- "Find all receipts in Inbox and propose names and destinations."
- "Move the latest bank statement to fin/banking after renaming."
- "Show me what is in dt_inbox and suggest next steps."
