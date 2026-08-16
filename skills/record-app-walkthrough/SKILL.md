---
name: record-app-walkthrough
description: Record and verify polished, repeatable walkthrough videos of local web apps, Electron apps, or other interactive products. Use when asked to create, capture, re-record, or update a product walkthrough, demo video, narrated screencast, captioned tour, feature preview, or release video; or when adding a reusable Playwright walkthrough-recording command to an app repository.
---

# Record App Walkthrough

Produce an actual, inspectable video artifact. Prefer a deterministic automated
recording over manual pointer choreography so the walkthrough can be re-recorded
after future UI changes.

## 1. Discover the existing path

Read the repository instructions and inspect only the relevant app, test, seed,
and run files. Search for existing recording infrastructure first:

```bash
rg -n -i 'walkthrough|screencast|record.*video|video.*record' .
rg -n '"scripts"|\[scripts\]|playwright|cypress' package.json \
  playwright*.{js,cjs,mjs,ts} .conductor/*.toml 2>/dev/null
```

If the repository already exposes a walkthrough command, run and repair that
path instead of creating a competing stack. Preserve its output contract unless
the user asks to change it.

Choose the recording route:

- Use Playwright for browser apps and Electron apps that it already launches.
- Use the project's existing native/mobile capture tooling when present.
- Use interactive desktop screen capture only when automation cannot represent
  the product. Keep notifications, unrelated windows, and private data off
  screen, and confirm screen-recording permission before starting.

Read [references/playwright-recording.md](references/playwright-recording.md)
when adding or repairing a Playwright recording harness.

## 2. Define the walkthrough

Derive a short scene plan from the product's real user journey. Default to
60–120 seconds and 5–10 scenes:

1. Show the starting state and product promise.
2. Demonstrate the primary user task end to end.
3. Show the output or payoff.
4. Include one supporting or trust-building feature when it matters.
5. Return to a stable closing state.

Use synthetic but realistic data that puts every intended state on screen.
Prefer direct API/database seed helpers over slow UI setup. Make the seed
idempotent so reruns begin from the same state.

Add concise on-screen captions when there is no voiceover. State user value,
not click mechanics. Use a consistent bottom caption bar, a high z-index,
`pointer-events: none`, and readable contrast. Pause roughly 1–1.5 seconds after
actions and 2–3 seconds for explanatory scenes. Spotlight only the few elements
that deserve attention.

If the user explicitly asks for spoken narration, do not silently substitute
captions. Write the voiceover from the same scene plan, use an approved human or
TTS voice, mux it only after the visual cut is stable, and verify that the final
file has an audible audio stream. Never clone a person's voice without their
permission.

## 3. Isolate the recording

Never record against production or a developer's live data.

- Run a dedicated local server and disposable database/state directory.
- Derive ports and fixture paths from the worktree's real path, or use the
  workspace's assigned ports, so parallel workspaces cannot collide.
- Set `reuseExistingServer: false` unless reuse is explicitly known to be safe.
- Use fictional accounts and local/sentinel provider settings. Do not inject
  production secret vaults into a recording.
- Disable or stub outbound email, SMS, billing, analytics, calendar, and AI
  calls unless the scene explicitly requires a safe local fake.
- Fix the viewport and browser; default to Chromium at 1280×800.
- Run serially with one worker. Keep the walkthrough separate from normal E2E
  assertions and exclude it from the default test suite.

Critical steps must fail loudly when expected UI is absent. Use conditional
locators only for genuinely optional scenes. Handle first-run tours, consent
dialogs, and confirmation overlays deliberately rather than letting them cover
the interface. Immediately before each caption, assert that the visible product
state matches what the caption claims; navigation success alone is insufficient.

## 4. Record and persist

Create one obvious project command such as `npm run walkthrough` that:

1. Starts the isolated app.
2. Seeds deterministic state.
3. Runs the walkthrough with video recording always enabled.
4. Copies the recording out of Playwright's ephemeral output directory.
5. Converts it to H.264 MP4 when `ffmpeg` is available.

Playwright clears its `outputDir` on later runs. Do not report a video from that
directory as the final artifact.

Use the bundled finalizer after recording:

```bash
node <skill-directory>/scripts/finalize-video.mjs \
  --source walkthrough-output \
  --output walkthrough/app-walkthrough.mp4 \
  --min-seconds 20 \
  --force
```

The finalizer recursively selects the newest video, preserves the source,
converts WebM/MOV to QuickTime-compatible H.264/YUV420p MP4 when possible, and
checks duration and dimensions with `ffprobe`. If `ffmpeg` is unavailable, it
preserves a stable WebM fallback and reports the actual path.

Add both the temporary and durable recording directories to `.gitignore` unless
the repository intentionally versions demo media.

## 5. Verify before finishing

Run the project's relevant tests because recording setup often touches seed,
server, or E2E infrastructure. Then verify the artifact itself:

```bash
ffprobe -v error \
  -show_entries format=duration:stream=codec_name,width,height,pix_fmt \
  -of default=noprint_wrappers=1 walkthrough/app-walkthrough.mp4
node <skill-directory>/scripts/sample-video-frames.mjs \
  --input walkthrough/app-walkthrough.mp4 \
  --output-dir walkthrough/review-frames \
  --count 9 \
  --force
```

Inspect every storyboard PNG with the available local image viewer. Open the
full video when possible and inspect every transition. Confirm:

- the file exists at the durable path and has nonzero duration;
- no secrets, personal data, browser chrome, notifications, loaders, or broken
  states appear;
- captions are fully visible and remain long enough to read;
- each caption describes the state that is actually visible behind it;
- the cursor/actions are understandable and critical scenes actually rendered;
- the output plays in the user's expected player.

If visual inspection is unavailable, say so explicitly; metadata alone is not
proof of a good walkthrough.

Finish with the artifact path, duration/resolution, command to re-record it,
tests run, and any unmet visual or audio limitation.
