import { defineConfig, devices } from "@playwright/test";

/**
 * E2E suite for the real Flutter web app (offline build with the in-memory
 * mock backend and deterministic AI). Build it first:
 *   npm run build:web:test
 * Record every test on video with:
 *   npm run test:flutter:video
 */
const PORT = 3400;
const recordVideo = !!process.env.VIDEO;

export default defineConfig({
  testDir: "./tests/e2e/flutter",
  outputDir: "./test-results/flutter",
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI || recordVideo ? 1 : 0,
  workers: process.env.PW_WORKERS ? Number(process.env.PW_WORKERS) : 4,
  timeout: 90_000,
  expect: { timeout: 15_000 },
  reporter: [
    ["list"],
    ["html", { open: "never", outputFolder: "playwright-report/flutter" }],
  ],

  use: {
    baseURL: `http://localhost:${PORT}`,
    trace: "retain-on-failure",
    screenshot: "only-on-failure",
    video: recordVideo
      ? { mode: "on", size: { width: 390, height: 844 } }
      : "retain-on-failure",
    launchOptions: recordVideo ? { slowMo: 150 } : undefined,
  },

  projects: [
    {
      name: "mobile",
      use: {
        ...devices["Desktop Chrome"],
        viewport: { width: 390, height: 844 },
        deviceScaleFactor: 2,
        hasTouch: false,
      },
      testIgnore: /responsive\.spec\.ts/,
    },
    {
      name: "responsive",
      use: { ...devices["Desktop Chrome"] },
      testMatch: /responsive\.spec\.ts/,
    },
  ],

  webServer: {
    command: `npx serve build/web-test -l ${PORT} -s --no-clipboard`,
    port: PORT,
    reuseExistingServer: true,
    timeout: 60_000,
  },
});
