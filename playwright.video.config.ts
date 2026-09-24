import { defineConfig, devices } from "@playwright/test";
import path from "path";

export default defineConfig({
  testDir: "./tests/e2e/video-flows",
  fullyParallel: false,
  workers: 1,
  reporter: [["list"]],
  timeout: 120000,

  use: {
    ...devices["Desktop Chrome"],
    viewport: { width: 430, height: 932 },
    video: {
      mode: "on",
      size: { width: 430, height: 932 },
    },
    launchOptions: {
      slowMo: 400,
    },
  },

  webServer: {
    command: "npx serve . -l 3300 --no-clipboard",
    port: 3300,
    reuseExistingServer: true,
  },
});
