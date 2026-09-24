import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Home Dashboard - Complete Flow", async ({ page }) => {
  await page.goto("/index.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Crohn's Companion");
  await expect(page.locator("header p")).toHaveText(
    "Your personal health tracker",
  );
  await expect(page.locator("header")).toHaveClass(/gradient-bg/);
  await pause(page);

  // Verify device frame
  await expect(page.locator(".device-frame")).toBeVisible();
  await expect(page.locator(".page-container")).toBeVisible();
  await pause(page, 600);

  // Verify feature cards grid - first row
  await expect(page.locator("text=Daily Tracking")).toBeVisible();
  await expect(page.locator("text=Symptoms")).toBeVisible();
  await pause(page, 600);

  // Second row
  await expect(page.locator("text=Diet Tracker")).toBeVisible();
  await expect(page.locator("text=Supplements")).toBeVisible();
  await pause(page, 600);

  // Verify feature card links
  await expect(
    page.locator('a[href="tracking.html"]:has-text("Daily Tracking")'),
  ).toBeVisible();
  await expect(
    page.locator('a[href="symptoms.html"]:has-text("Symptoms")'),
  ).toBeVisible();
  await expect(
    page.locator('a[href="diet.html"]:has-text("Diet Tracker")'),
  ).toBeVisible();
  await expect(
    page.locator('a[href="supplements.html"]:has-text("Supplements")'),
  ).toBeVisible();
  await pause(page, 600);

  // Insights and Chat cards
  await expect(page.locator('main a[href="insights.html"]')).toBeVisible();
  await expect(page.locator('main a[href="chat.html"]')).toBeVisible();
  await expect(page.locator("text=Chat with Assistant")).toBeVisible();
  await pause(page);

  // Screenshot: full home dashboard with all feature cards
  await takeAndVerifyScreenshot(page, "02-home-feature-cards.png");
  await pause(page, 400);

  // Today's Summary section
  await expect(page.locator("text=Today's Summary")).toBeVisible();
  await expect(
    page.locator("text=You've logged 2 meals and 1 bowel movement today"),
  ).toBeVisible();
  await expect(page.locator("text=Last updated: Today, 2:30 PM")).toBeVisible();
  await expect(page.locator('button:has-text("View Details")')).toBeVisible();
  await pause(page);

  // Navigation bar
  await expect(page.locator("nav")).toBeVisible();
  const activeNav = page.locator("a.nav-item.active");
  await expect(activeNav).toContainText("Home");
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  await pause(page);

  // Screenshot: Today's Summary card (distinct from the feature cards screenshot)
  await takeElementScreenshot(
    page,
    ".bg-neutral.rounded-xl",
    "02-home-todays-summary.png",
  );
  await pause(page, 400);

  // Hover over feature cards for visual effect
  await page
    .locator('a[href="tracking.html"]:has-text("Daily Tracking")')
    .hover();
  await pause(page, 500);
  await page.locator('a[href="symptoms.html"]:has-text("Symptoms")').hover();
  await pause(page, 500);
  await page.locator('a[href="diet.html"]:has-text("Diet Tracker")').hover();
  await pause(page, 500);
  await page
    .locator('a[href="supplements.html"]:has-text("Supplements")')
    .hover();
  await pause(page, 500);
  await page.locator('main a[href="insights.html"]').hover();
  await pause(page, 500);
  await page.locator('main a[href="chat.html"]').hover();
  await pause(page, 1200);

  await saveVideo(page, "02-home-dashboard.webm");
});
