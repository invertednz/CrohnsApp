import { defineConfig, devices } from "@playwright/test";

/** Smoke tests against a deployed build: PREVIEW_URL=https://... npx playwright test -c playwright.live.config.ts */
export default defineConfig({
  testDir: "./tests/e2e/live",
  outputDir: "./test-results/live",
  workers: 1,
  timeout: 180_000,
  expect: { timeout: 20_000 },
  reporter: [["list"]],
  use: {
    baseURL:
      process.env.PREVIEW_URL ?? "https://gutmd-app--preview-7czgn8h6.web.app",
    ...devices["Desktop Chrome"],
    viewport: { width: 390, height: 844 },
    trace: "retain-on-failure",
    video: process.env.VIDEO ? "on" : "retain-on-failure",
  },
});
