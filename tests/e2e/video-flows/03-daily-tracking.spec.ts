import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  scrollToTop,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Daily Tracking - Complete Flow", async ({ page }) => {
  await page.goto("/tracking.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Daily Tracking | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Daily Tracking");
  await expect(page.locator("header p")).toHaveText(
    "Track your bowel movements and daily feelings",
  );
  await expect(page.locator("header")).toHaveClass(/gradient-bg/);
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page);

  // Date selector
  await expect(page.locator("text=Today, May 15")).toBeVisible();
  const dateSection = page
    .locator(".flex.justify-between.items-center")
    .first();
  const dateButtons = dateSection.locator("button");
  expect(await dateButtons.count()).toBeGreaterThanOrEqual(2);
  await pause(page, 600);

  // Feeling selector
  await expect(page.locator("text=How are you feeling today?")).toBeVisible();
  const emojiButtons = page.locator(
    "h3:has-text('How are you feeling') + div button",
  );
  expect(await emojiButtons.count()).toBeGreaterThanOrEqual(5);
  const selected = page.locator(".emoji-selected");
  await expect(selected).toBeVisible();

  // Screenshot: header, date, and feeling selector
  await takeAndVerifyScreenshot(page, "03-tracking-feelings.png");
  await pause(page);

  // Click different emoji buttons to show interaction
  for (let i = 0; i < Math.min(await emojiButtons.count(), 5); i++) {
    await emojiButtons.nth(i).click();
    await pause(page, 400);
  }
  await pause(page, 600);

  // Bowel Movements section - scroll to top for distinct screenshot
  await scrollToTop(page, 'h3:has-text("Bowel Movements")');
  await expect(page.locator('h3:has-text("Bowel Movements")')).toBeVisible();
  await expect(page.locator("text=8:30 AM")).toBeVisible();
  await expect(page.locator("text=2:15 PM")).toBeVisible();
  await expect(page.locator("text=Bristol Type 4")).toBeVisible();
  await expect(page.locator("text=Bristol Type 3")).toBeVisible();
  await expect(
    page.locator("text=Normal consistency, no pain or discomfort."),
  ).toBeVisible();
  await expect(
    page.locator("text=Slight urgency but otherwise normal."),
  ).toBeVisible();

  // Screenshot: bowel movements entries with Bristol types
  await takeAndVerifyScreenshot(page, "03-tracking-bowel-movements.png");
  await pause(page);

  // Pain Level section - scroll to top for distinct screenshot
  await scrollToTop(page, "text=Pain Level");
  await expect(page.locator("text=Pain Level")).toBeVisible();
  const painSlider = page.locator('input[type="range"]').first();
  await expect(painSlider).toBeVisible();
  await expect(painSlider).toHaveAttribute("min", "0");
  await expect(painSlider).toHaveAttribute("max", "10");
  await expect(page.locator("text=Current: 2/10").first()).toBeVisible();
  await expect(page.locator("text=No Pain").first()).toBeVisible();
  await expect(page.locator("text=Severe").first()).toBeVisible();
  await pause(page);

  // Interact with pain slider
  await painSlider.fill("5");
  await pause(page, 600);
  await painSlider.fill("2");
  await pause(page, 600);

  // Add Note button
  const addNoteButtons = page.locator('button:has-text("Add Note")');
  expect(await addNoteButtons.count()).toBeGreaterThanOrEqual(1);
  await pause(page, 600);

  // Energy Level section
  await scrollToTop(page, "text=Energy Level");
  await expect(page.locator("text=Energy Level")).toBeVisible();
  const sliders = page.locator('input[type="range"]');
  expect(await sliders.count()).toBe(2);
  await expect(page.locator("text=Current: 7/10")).toBeVisible();
  await expect(page.locator("text=Low")).toBeVisible();
  await expect(page.locator("text=High")).toBeVisible();

  // Screenshot: energy level slider section (distinct from bowel movements screenshot)
  await takeElementScreenshot(
    page,
    '.bg-white.rounded-xl.shadow-md:has(h3:has-text("Energy Level"))',
    "03-tracking-energy-level.png",
  );
  await pause(page);

  // Interact with energy slider
  const energySlider = sliders.nth(1);
  await energySlider.fill("4");
  await pause(page, 600);
  await energySlider.fill("7");
  await pause(page, 600);

  // Navigation
  const activeNav = page.locator("a.nav-item.active");
  await expect(activeNav).toContainText("Track");
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "03-daily-tracking.webm");
});
