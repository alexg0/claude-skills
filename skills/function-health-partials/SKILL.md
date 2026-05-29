---
name: function-health-partials
description: Scrape partial (in-progress) lab results from the Function Health member portal and write them into the health repo as an interim record until the official Lab Results of Record PDF posts. Use when a Function Health draw has resulted only some of its biomarkers ("partial results", "additional results came in", "pull the latest Function Health draw", "grab partials before the PDF is ready").
type: command
---

Pull the **most recent Function Health draw's results** — including drafts where only some biomarkers have resulted — and record them in the repo. Function Health posts results incrementally; the official combined PDF can lag the portal by days to weeks. This skill captures the portal state in the meantime.

The portal is a React SPA backed by a JSON API. You do **not** scrape the rendered DOM — you read the member API directly using the logged-in session's Firebase token. That is faster, complete, and gives per-marker dates, reference ranges, and out-of-range flags.

## Arguments

- No args / `latest`: pull the most recent draw (default).
- `all`: dump every requisition/visit, not just the latest.
- A date like `2026-05-28`: pull the visit collected on that date.

## What you need to know first (hard-won gotchas)

1. **Auth is a Firebase ID token in localStorage, not a cookie.** Read it from `JSON.parse(localStorage.getItem('userData')).idToken` and send it as `Authorization: Bearer <token>`. A plain `fetch(..., {credentials:'include'})` returns **401** — the API is on a different subdomain (`member-app-mid.functionhealth.com`) and does not rely on the portal cookie.
2. **The browse `eval` command does NOT await promises.** An async IIFE returns `'fired'` immediately. Pattern: have the script assign its result to a `window.__GLOBAL`, then read it back with `$B js "window.__GLOBAL"` after a short `sleep`.
3. **The headed browser is reaped when a Bash call returns.** If you `$B connect` and then need the window to stay open across turns (e.g. while the user logs in), you MUST hold it with a long-running background process — `$B connect; $B goto ...; sleep 2400` launched with `run_in_background: true`. Do **not** run `pkill`/`$B stop` between steps; that is what kills the session. For a quick same-turn scripted pull, a single foreground block (connect + navigate + eval + read, all in one Bash call) works without a holder.
4. **Login can't be automated** (email + magic-link/password, possibly 1Password). Hand off to the user via the visible window; the persistent Chromium profile saves the session to disk so it survives reconnects. Tell the user 1Password autofill won't fire in this Chromium — they should copy/paste credentials.
5. **"Pending" tests are not in the API results.** The API only returns resulted biomarkers. To list what's still pending, diff the resulted set against the **order-request PDF** in the lab folder (`pdftotext -layout`).

## Procedure

### 1. Resolve the browse binary

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/.claude/skills/gstack/browse/dist/browse" ] && B="$_ROOT/.claude/skills/gstack/browse/dist/browse"
[ -z "$B" ] && B=~/.claude/skills/gstack/browse/dist/browse
[ -x "$B" ] && echo "READY: $B" || echo "NEEDS_SETUP (run gstack-browse setup)"
```

### 2. Connect a headed browser and confirm login

Clear stale profile locks, connect, and navigate to Function Health — **held open in the background** so it survives the login wait:

```bash
# launch with run_in_background: true
B=~/.claude/skills/gstack/browse/dist/browse
for f in SingletonLock SingletonSocket SingletonCookie; do rm -f "$HOME/.gstack/chromium-profile/$f" 2>/dev/null; done
$B connect
sleep 4
$B goto https://my.functionhealth.com/login
$B focus
sleep 2400   # holds the session open across turns
```

Then check login state in a separate (foreground) call:

```bash
B=~/.claude/skills/gstack/browse/dist/browse
$B url   # if it ends in /login, the user is not logged in
```

If not logged in, **stop and ask the user to log in** in the visible window (remind them about 1Password copy/paste), then continue when they confirm. The background holder keeps the window alive.

### 3. Pull the requisitions JSON

Fire the bundled fetch script into a global, then read it back. **`eval` only runs files under `/tmp` or the cwd**, so copy the bundled script to `/tmp` first (running it straight from the skill's Dropbox path fails silently — `window.__FH_REQS` stays `undef`):

```bash
B=~/.claude/skills/gstack/browse/dist/browse
cp "<skill-dir>/scripts/fetch_requisitions.js" /tmp/fh_fetch.js
$B goto https://my.functionhealth.com/biomarkers   # any logged-in page
sleep 2
$B eval /tmp/fh_fetch.js
sleep 3
$B js "window.__FH_REQS ? window.__FH_REQS.slice(0,80) : 'pending'"   # sanity: should start with status=200
```

If the readback is `undef`, the eval did not run (wrong path — must be under `/tmp` or cwd). If it is `pending`, the fetch is slow or the page had not settled — wait and re-read, or re-`eval`.

`fetch_requisitions.js` reads the idToken from `userData`, calls `requisitions?pending=false`, and stores the raw JSON to `window.__FH_REQS` (prefixed with `status=<code>|`). If status is **401**, the token expired — reload the page (`$B reload`) so the SDK refreshes it, then re-run.

Read the full payload out in chunks (the `js` command truncates very long strings) into a temp file, then strip the inter-chunk newlines and validate JSON:

```bash
B=~/.claude/skills/gstack/browse/dist/browse
RAW=/tmp/fh_reqs.json; : > "$RAW"
LEN=$($B js "window.__FH_REQS.length")
for off in $(seq 0 9000 "$LEN"); do $B js "window.__FH_REQS.slice($off,$off+9000)" >> "$RAW"; done
python3 - "$RAW" <<'PY'
import sys; p=sys.argv[1]; t=open(p).read().replace('\n','')
t=t.split('|',1)[1] if t.startswith('status=') else t
import json; json.dump(json.loads(t), open(p,'w'), indent=2); print("ok")
PY
```

### 4. Render the partial-results record

```bash
python3 "<skill>/scripts/render_partials.py" /tmp/fh_reqs.json --which latest \
  --out labs/alexg/<order-folder>/<collection-date>_partial_results.md \
  --raw labs/alexg/<order-folder>/<collection-date>_partial_results_raw.json
```

`render_partials.py` picks the visit (latest / by date / all), writes the grouped markdown table (value, units, reference range, flag) + an out-of-range summary + metadata, and saves the raw visit JSON. It marks the file **PARTIAL** when `allResultsAvailable` is false.

### 5. Fill in the "still pending" list

The API only knows what resulted. Extract the ordered test lines from the order-request PDF in the same lab folder and diff:

```bash
pdftotext -layout labs/alexg/<order-folder>/Lab\ Order\ Request-*.pdf - | grep -E '^\s*[0-9]{3,}'
```

List every ordered test that is **not** in the resulted set under a "Still pending" section. Note that several biomarkers may show carried-forward values from older draws in the portal's cumulative view — those are not this draw.

### 6. Clean up and report

```bash
$B disconnect   # also stops the background holder's browser
```

Report: collection date, requisition status, N resulted / N ordered, the out-of-range markers, and the pending list. If the repo tracks this draw across analysis docs (e.g. `research/raw-data-report-alex.md`, `programs/alexg/retatrutide-monitoring.md`), offer to backfill — but keep factual data and dose/clinical guidance separate, and supersede the interim file with the official Lab Results of Record PDF when it posts.

## Reference: the Function Health member API

Base: `https://member-app-mid.functionhealth.com/api/v1/` (Bearer the `userData.idToken`).

- `requisitions?pending=false` — array; each requisition has `status`, `reviewed`, `allResultsAvailable`, `reviewingPhysician`, and `visits[]`. Each visit has `visitDate`, `streetAddress/city/state/zip`, `confirmationCode`, `packages`, and `biomarkerResults[]`.
- Each biomarker result: `biomarkerName`, `testResult`, `measurementUnits`, `questReferenceRange`, `testResultOutOfRange` (bool), `dateOfService`, `questBiomarkerId`.
- `results`, `results-report`, `biomarkers`, `biomarker-details`, `notes`, `member-overview` — other endpoints seen in the network log if you need them.

The same physical Quest draw may be split across **multiple order channels** (Function Health + direct-order vendors like Jason Health or Grassroots Labs). Those vendor add-ons are separate requisitions on separate portals and won't appear in the Function Health API — track them from their own PDFs in their own lab folders.
