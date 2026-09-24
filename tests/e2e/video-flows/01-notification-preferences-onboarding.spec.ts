import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Onboarding - Notification Preferences Flow", async ({ page }) => {
  await page.goto("/notification_preferences_preview.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page loaded correctly
  await expect(page).toHaveTitle(
    "Crohn's Companion – Notification Preferences",
  );
  await expect(page.locator("h1")).toHaveText("Notification Preferences");
  await expect(
    page.locator("text=When would you like to receive reminders?"),
  ).toBeVisible();
  await pause(page);

  // Verify info card
  await expect(page.locator("text=Stay on Track")).toBeVisible();
  await expect(
    page.locator("text=Choose one or more times for daily tracking reminders"),
  ).toBeVisible();
  await pause(page);

  // Verify all four time cards are present
  const timeCards = page.locator(".time-card");
  expect(await timeCards.count()).toBe(4);

  await expect(page.locator("#morning h3")).toHaveText("Morning");
  await expect(
    page.locator("#morning >> text=7:00 AM - 11:00 AM"),
  ).toBeVisible();
  await pause(page, 500);

  await expect(page.locator("#midday h3")).toHaveText("Midday");
  await expect(
    page.locator("#midday >> text=11:00 AM - 2:00 PM"),
  ).toBeVisible();
  await pause(page, 500);

  await expect(page.locator("#afternoon h3")).toHaveText("Afternoon");
  await expect(
    page.locator("#afternoon >> text=2:00 PM - 6:00 PM"),
  ).toBeVisible();
  await pause(page, 500);

  await expect(page.locator("#evening h3")).toHaveText("Evening");
  await expect(
    page.locator("#evening >> text=6:00 PM - 10:00 PM"),
  ).toBeVisible();
  await pause(page);

  // Verify all checkmarks hidden initially
  await expect(page.locator("#morning-check")).toHaveClass(/hidden/);
  await expect(page.locator("#midday-check")).toHaveClass(/hidden/);
  await expect(page.locator("#afternoon-check")).toHaveClass(/hidden/);
  await expect(page.locator("#evening-check")).toHaveClass(/hidden/);

  // Verify continue button is disabled initially
  const continueBtn = page.locator("#continueBtn");
  await expect(continueBtn).toBeDisabled();
  await expect(page.locator("#btnText")).toHaveText("Select at least one");

  // Screenshot: initial state with all time cards unselected
  await takeAndVerifyScreenshot(page, "01-onboarding-initial-state.png", {
    fullPage: true,
  });
  await pause(page);

  // Select Morning
  await page.locator("#morning").click();
  await pause(page, 600);
  await expect(page.locator("#morning")).toHaveClass(/selected/);
  await expect(page.locator("#morning-check")).not.toHaveClass(/hidden/);
  await expect(continueBtn).toBeEnabled();
  await expect(page.locator("#btnText")).toHaveText("Continue");
  await pause(page);

  // Select Evening too
  await page.locator("#evening").click();
  await pause(page, 600);
  await expect(page.locator("#evening")).toHaveClass(/selected/);
  await expect(page.locator("#evening-check")).not.toHaveClass(/hidden/);
  await pause(page);

  // Deselect Morning to show toggle behavior
  await page.locator("#morning").click();
  await pause(page, 600);
  await expect(page.locator("#morning")).not.toHaveClass(/selected/);
  await expect(page.locator("#morning-check")).toHaveClass(/hidden/);
  await pause(page);

  // Re-select Morning and also select Midday
  await page.locator("#morning").click();
  await pause(page, 400);
  await page.locator("#midday").click();
  await pause(page, 400);
  await expect(page.locator("#morning")).toHaveClass(/selected/);
  await expect(page.locator("#midday")).toHaveClass(/selected/);
  await expect(page.locator("#evening")).toHaveClass(/selected/);

  // Screenshot: multiple selections active with checkmarks visible
  await takeAndVerifyScreenshot(page, "01-onboarding-selections-active.png", {
    fullPage: true,
  });
  await pause(page);

  // Verify info note
  await expect(
    page.locator("text=You can change these settings anytime in your profile"),
  ).toBeVisible();
  await pause(page);

  // Click continue
  page.on("dialog", async (dialog) => {
    await dialog.accept();
  });
  await continueBtn.click();
  await pause(page, 1000);

  // Verify skip button exists with proper styling
  const skipBtn = page.locator('button:has-text("Skip")');
  await expect(skipBtn).toBeVisible();
  await expect(skipBtn).toHaveClass(/btn-secondary/);

  // Screenshot: the Continue/Skip button area showing enabled Continue state
  await takeElementScreenshot(
    page,
    "#continueBtn",
    "01-onboarding-continue-button.png",
  );
  await pause(page, 1200);

  await saveVideo(page, "01-notification-preferences-onboarding.webm");
});
