import { test, expect } from "@playwright/test";
import { saveVideo, pause, takeAndVerifyScreenshot } from "./helpers";

test("Cross-Page Navigation - Complete Flow", async ({ page }) => {
  // Start at Home
  await page.goto("/index.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  await expect(page).toHaveTitle("Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Crohn's Companion");
  await expect(page.locator(".device-frame")).toBeVisible();

  // Screenshot: starting at home page
  await takeAndVerifyScreenshot(page, "09-nav-start-home.png");
  await pause(page);

  // Navigate Home -> Tracking via feature card
  await page
    .locator('a[href="tracking.html"]:has-text("Daily Tracking")')
    .click();
  await expect(page).toHaveTitle("Daily Tracking | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Daily Tracking");
  await expect(page.locator(".device-frame")).toBeVisible();
  const trackActive = page.locator("a.nav-item.active");
  await expect(trackActive).toContainText("Track");

  // Screenshot: arrived at tracking page
  await takeAndVerifyScreenshot(page, "09-nav-tracking-page.png");
  await pause(page);

  // Navigate Tracking -> Home via back button
  await page.locator('header a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  await pause(page);

  // Navigate Home -> Symptoms via feature card
  await page.locator('a[href="symptoms.html"]:has-text("Symptoms")').click();
  await expect(page).toHaveTitle("Symptoms Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Symptoms Tracker");

  // Screenshot: arrived at symptoms page
  await takeAndVerifyScreenshot(page, "09-nav-symptoms-page.png");
  await pause(page);

  // Navigate Symptoms -> Home via back button
  await page.locator('header a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  await pause(page);

  // Navigate Home -> Diet via feature card
  await page.locator('a[href="diet.html"]:has-text("Diet Tracker")').click();
  await expect(page).toHaveTitle("Diet Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Diet Tracker");
  const dietActive = page.locator("a.nav-item.active");
  await expect(dietActive).toContainText("Diet");
  await pause(page);

  // Navigate Diet -> Home via back button
  await page.locator('header a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  await pause(page);

  // Navigate Home -> Supplements via feature card
  await page
    .locator('a[href="supplements.html"]:has-text("Supplements")')
    .click();
  await expect(page).toHaveTitle("Supplements Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Supplements");
  await expect(page.locator(".device-frame")).toBeVisible();
  await pause(page);

  // Navigate Supplements -> Home via back button
  await page.locator('header a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  await pause(page);

  // Navigate Home -> Insights via feature card
  await page.locator('main a[href="insights.html"]').click();
  await expect(page).toHaveTitle("Insights | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Insights");
  await expect(page.locator(".device-frame")).toBeVisible();
  await pause(page);

  // Navigate Insights -> Home via nav bar (insights nav has Home, Track, Diet, Insights)
  await page.locator('nav a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  await pause(page);

  // Navigate Home -> Chat via feature card
  await page.locator('main a[href="chat.html"]').click();
  await expect(page).toHaveTitle("Chat Assistant | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Chat Assistant");
  const chatActive = page.locator("a.nav-item.active");
  await expect(chatActive).toContainText("Chat");

  // Screenshot: arrived at chat page via navigation
  await takeAndVerifyScreenshot(page, "09-nav-chat-page.png");
  await pause(page);

  // Navigate Chat -> Insights via nav bar
  await page.locator('nav a[href="insights.html"]').click();
  await expect(page).toHaveTitle("Insights | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Insights");
  await pause(page);

  // Navigate Insights -> Track via nav bar
  await page.locator('nav a[href="tracking.html"]').click();
  await expect(page).toHaveTitle("Daily Tracking | Crohn's Companion");
  await pause(page);

  // Navigate Track -> Home via nav bar
  await page.locator('nav a[href="index.html"]').click();
  await expect(page).toHaveTitle("Crohn's Companion");
  const homeActive = page.locator("a.nav-item.active");
  await expect(homeActive).toContainText("Home");

  // Screenshot: back at home after full navigation cycle
  await takeAndVerifyScreenshot(page, "09-nav-back-at-home.png");
  await pause(page);

  // Back button verification on multiple pages
  await page.goto("/chat.html");
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page, 500);

  await page.goto("/insights.html");
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page, 500);

  await page.goto("/supplements.html");
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page, 500);

  // Supplements nav links
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "09-cross-page-navigation.webm");
});
