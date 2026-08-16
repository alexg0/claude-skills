# Playwright recording pattern

Use this reference only when an app lacks a working recording harness or its
existing Playwright walkthrough needs repair. Adapt names and commands to the
repository's conventions; do not paste a second Playwright stack into a project
that already has one.

## Configuration

Keep the demo config separate from the assertion suite:

```js
const { defineConfig } = require("@playwright/test");

module.exports = defineConfig({
  testDir: "./e2e",
  testMatch: "walkthrough.spec.js",
  outputDir: "./walkthrough-output",
  timeout: 180_000,
  fullyParallel: false,
  workers: 1,
  reporter: [["list"]],
  use: {
    baseURL: "http://127.0.0.1:4174",
    browserName: "chromium",
    headless: true,
    viewport: { width: 1280, height: 800 },
    video: { mode: "on", size: { width: 1280, height: 800 } },
  },
  webServer: {
    command: "npm run dev -- --port 4174",
    url: "http://127.0.0.1:4174",
    reuseExistingServer: false,
    timeout: 30_000,
  },
});
```

Replace fixed ports with existing worktree-scoped helpers or `CONDUCTOR_PORT`
when multiple workspaces can run concurrently. If frontend and backend require
separate servers, configure both under `webServer` and give each isolated state.

Exclude the walkthrough from the normal config:

```js
module.exports = defineConfig({
  testDir: "./e2e",
  testIgnore: "walkthrough.spec.js",
});
```

## Captions and spotlights

DOM overlays render directly into Playwright's video and remain deterministic:

```js
async function caption(page, title, detail = "") {
  await page.evaluate(({ title, detail }) => {
    let bar = document.getElementById("__walkthroughCaption");
    if (!bar) {
      bar = document.createElement("div");
      bar.id = "__walkthroughCaption";
      Object.assign(bar.style, {
        position: "fixed",
        inset: "auto 0 0 0",
        zIndex: "2147483647",
        padding: "14px 22px",
        background: "rgba(15, 23, 42, .94)",
        color: "#f8fafc",
        font: "500 15px/1.45 system-ui, sans-serif",
        borderTop: "3px solid #38bdf8",
        pointerEvents: "none",
      });
      document.body.appendChild(bar);
    }
    bar.replaceChildren();
    const heading = document.createElement("div");
    heading.style.fontWeight = "700";
    heading.textContent = title;
    bar.appendChild(heading);
    if (detail) {
      const body = document.createElement("div");
      body.style.cssText = "opacity:.8;font-size:13.5px;margin-top:3px";
      body.textContent = detail;
      bar.appendChild(body);
    }
  }, { title, detail });
  await page.waitForTimeout(1400);
}

async function spotlight(page, locator) {
  await locator.scrollIntoViewIfNeeded();
  await locator.evaluate((element) => {
    const previous = element.style.boxShadow;
    element.style.boxShadow =
      "0 0 0 3px #38bdf8, 0 0 22px rgba(56,189,248,.55)";
    setTimeout(() => {
      element.style.boxShadow = previous;
    }, 2200);
  });
  await page.waitForTimeout(900);
}
```

Use DOM construction and `textContent` for captions so product or seed text
cannot become injected HTML.

## Walkthrough structure

Seed before navigating whenever the app exposes a local API:

```js
const { test, expect } = require("@playwright/test");

test.describe.configure({ mode: "serial" });

test("product walkthrough", async ({ page, request }) => {
  const seeded = await request.post("/api/test/seed", {
    data: { scenario: "walkthrough" },
  });
  expect(seeded.ok()).toBeTruthy();

  await page.goto("/");
  await caption(page, "Start with the user's goal", "One sentence of context.");

  await page.getByRole("button", { name: "Primary action" }).click();
  await expect(page.getByRole("heading", { name: "Result" })).toBeVisible();
  await caption(page, "Show the payoff", "Explain why this result matters.");
});
```

Prefer accessible role/name locators. Assert every critical transition before
showing the caption that describes it; otherwise a successful navigation click
can leave narration describing a state that never rendered. Avoid arbitrary
timeouts for application readiness; use timeouts only for intentional
human-readable pacing.

## Command and artifact

Wire one command that records and then persists the file:

```json
{
  "scripts": {
    "walkthrough": "playwright test --config playwright.walkthrough.config.js && node scripts/finalize-walkthrough-video.mjs --source walkthrough-output --output walkthrough/app-walkthrough.mp4 --min-seconds 20 --force"
  }
}
```

Do not put `$HOME` in a package script that must work for a team or in CI.
Instead, copy the finalizer's small logic into the repository or add a
repository-local equivalent following existing script conventions.

Keep these ignored by default:

```gitignore
walkthrough-output/
walkthrough/
```

Use the repository's package manager and current Playwright dependency. Add a
new dependency only if the existing stack cannot record the app.
