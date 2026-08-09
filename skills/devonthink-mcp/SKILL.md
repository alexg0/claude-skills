---
name: devonthink-mcp
description: Safely inspect, search, triage, and organize DEVONthink records through the DEVONthink MCP server. Use for reviewing inboxes, proposing names and destinations, finding duplicates, managing action-item state, or applying approved record operations.
---

# DEVONthink MCP

Use DEVONthink MCP for record operations. Never modify DEVONthink database package files directly.

## Safety

- Inspect records read-only before proposing or applying changes.
- Wait for explicit user approval before renaming, moving, tagging, flagging, deleting, merging, running OCR, or updating content or comments unless the user clearly authorizes automatic processing for the current run.
- For bulk operations, present the proposed per-record actions first, use a dry run when the available tooling supports one, and execute in small batches.
- Reconfirm when the scope, destination, or destructive impact changes.
- If evidence is insufficient, leave the record unchanged and identify what needs review.

## Workflow

1. Verify that DEVONthink is running and identify the current database.
2. Read applicable repository guidance, such as `structure.md`, when present. Treat local naming and routing rules as authoritative.
3. Discover candidate records, then inspect their properties and extracted content.
4. Search for similar records and existing destination patterns. List the intended parent folder's direct children before proposing a new child folder.
5. Propose a normalized name, destination, duplicate status, and action-item state with concise evidence.
6. Apply only the approved operations.
7. Re-read the affected records and destination to verify the final name, location, tags, flags, and comments.
8. Update the repository's operation log or task record when local guidance requires it.

## Routing and duplicates

- Prefer an existing suitable destination over creating a near-duplicate folder, even when adjacent folders use inconsistent naming.
- When the exact destination does not exist, identify the closest existing parent and state the child folder that would need to be created.
- For filesystem-backed indexed destinations, create the real folder and index or import it through DEVONthink instead of creating only an internal group.
- Treat duplicate-search results as one signal, not proof. Also compare source URL, file size, page count, word count, dates, and the presence of an existing durable record.
- For scanned documents, inspect extracted text for missing or reverse-ordered pages and flag uncertain page order for review.

## Action-item state

- Distinguish approval to create or preserve an action item from confirmation that the underlying action is complete.
- Add or preserve flags and comments only for approved action items.
- Clear flags, comments, or action tags only when completion is confirmed; do not infer completion from filing approval alone.
- If the user confirms that no action is required, leave the record unflagged and its comment empty unless another approved reason applies.

## Reporting

- Link records with `x-devonthink-item://UUID` when their UUIDs are available.
- Separate proposed operations from completed operations.
- Report the records inspected, changes applied, verification performed, and anything left unchanged for review.
