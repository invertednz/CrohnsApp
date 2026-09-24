import { expect, test } from "@playwright/test";
import {
  button,
  field,
  onScreen,
  openTab,
  scrollUntilVisible,
  tap,
} from "../flutter/helpers";

/**
 * Real-backend smoke test against a deployed build (Firebase Auth, Firestore
 * and Gemini via Firebase AI Logic). Run with:
 *   PREVIEW_URL=https://gutmd-app--preview-xxxx.web.app npx playwright test -c playwright.live.config.ts
 */

test.describe("Live Firebase + Gemini", () => {
  test("guest can check in, data persists in Firestore, and chat replies with Gemini", async ({
    page,
  }) => {
    const consoleLines: string[] = [];
    page.on("console", (msg) => consoleLines.push(msg.text()));

    await page.goto("/");
    await expect(button(page, "Get Started")).toBeVisible({ timeout: 45_000 });
    expect(consoleLines.join("\n")).not.toContain("Firebase unavailable");

    // Welcome -> Log In -> Sign Up -> Continue as guest (Firebase anonymous auth).
    await tap(page, "Log In");
    await tap(page, /^Sign Up$/);
    await tap(page, /Continue as guest/);
    await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 30_000 });

    // Check in for today; the choice is written to Firestore.
    const good = page.getByRole("radio", { name: "Good" });
    await scrollUntilVisible(page, good);
    await good.click();
    await expect(good).toBeChecked();
    await page.waitForTimeout(2_000);

    // Reload: the offline mock would forget this, Firestore must not.
    await page.reload();
    await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 45_000 });
    const goodAfterReload = page.getByRole("radio", { name: "Good" });
    await scrollUntilVisible(page, goodAfterReload);
    await expect(goodAfterReload).toBeChecked({ timeout: 20_000 });

    // Chat: a real Gemini reply, not the offline fallback.
    await openTab(page, "Chat");
    const box = field(page, /message/i).first();
    await box.click();
    await box.fill(
      "I checked in feeling good today. What is one gentle breakfast idea?",
    );
    await page.keyboard.press("Enter");
    await expect
      .poll(
        async () =>
          (await onScreen(page)
            .getByText(/breakfast|oat|rice|egg|banana|toast/i)
            .count()) > 1,
        {
          timeout: 90_000,
        },
      )
      .toBe(true);
    const log = consoleLines.join("\n");
    expect(log).not.toContain("Gemini request failed");
    expect(log).not.toContain("offline mock");
  });
});
