import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  scrollToTop,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Supplements Tracker - Complete Flow", async ({ page }) => {
  await page.goto("/supplements.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Supplements Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Supplements");
  await expect(page.locator("header p")).toHaveText(
    "Track your supplement intake",
  );
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page);

  // Date selector
  await expect(page.locator("text=Today, May 15")).toBeVisible();
  const dateButtons = page.locator("main button:has(svg)");
  await expect(dateButtons.first()).toBeVisible();
  const dateSection = page
    .locator(".flex.justify-between.items-center")
    .first();
  const navButtons = dateSection.locator("button:has(svg)");
  expect(await navButtons.count()).toBeGreaterThanOrEqual(2);
  await pause(page, 600);

  // Add Supplement button
  const addButton = page.locator('button:has-text("Add Supplement")');
  await expect(addButton).toBeVisible();
  await expect(addButton).toHaveClass(/bg-primary/);
  const svg = addButton.locator("svg");
  await expect(svg).toBeVisible();
  await pause(page, 600);

  // Morning section
  await expect(page.locator('h3:has-text("Morning")')).toBeVisible();
  await expect(page.locator("text=Vitamin D3")).toBeVisible();
  const vitDCard = page.locator(".supplement-card.taken").first();
  await expect(vitDCard).toBeVisible();
  await expect(
    page.locator("text=2000 IU - Take with breakfast"),
  ).toBeVisible();
  await pause(page, 600);

  // Taken badge
  const takenBadge = page.locator('.bg-green-100:has-text("Taken")').first();
  await expect(takenBadge).toBeVisible();
  await pause(page, 500);

  // Omega-3
  await expect(page.locator("text=Omega-3 Fish Oil")).toBeVisible();
  await expect(page.locator("text=1000mg - Take with breakfast")).toBeVisible();
  await pause(page, 500);

  // Timestamps
  const timestamps = page.locator("text=7:45 AM");
  expect(await timestamps.count()).toBe(2);

  // Green border for taken supplements
  const takenCards = page.locator(".supplement-card.taken");
  expect(await takenCards.count()).toBe(2);

  // Screenshot: morning supplements - taken state with green badges
  await takeAndVerifyScreenshot(page, "06-supplements-morning-taken.png");
  await pause(page);

  // Afternoon section - scroll to top for distinct screenshot
  await scrollToTop(page, 'h3:has-text("Afternoon")');
  await expect(page.locator('h3:has-text("Afternoon")')).toBeVisible();
  await expect(page.locator("text=Probiotic")).toBeVisible();
  await expect(page.locator("text=Scheduled").first()).toBeVisible();
  await expect(
    page.locator("text=50 billion CFU - Take after lunch"),
  ).toBeVisible();
  await expect(page.locator("text=1:00 PM")).toBeVisible();
  await pause(page, 600);

  // Mark as Taken button
  const markButton = page.locator('button:has-text("Mark as Taken")').first();
  await expect(markButton).toBeVisible();
  await expect(markButton).toHaveClass(/bg-primary/);

  // Screenshot: afternoon supplements - scheduled with Mark as Taken button
  await takeAndVerifyScreenshot(page, "06-supplements-afternoon-scheduled.png");
  await pause(page, 600);

  // Evening section - scroll to show missed card
  await scrollToTop(page, 'h3:has-text("Evening")');
  await expect(page.locator('h3:has-text("Evening")')).toBeVisible();
  await expect(page.locator("text=Turmeric Extract")).toBeVisible();
  await expect(page.locator("text=500mg - Take with dinner")).toBeVisible();
  await expect(page.locator("text=6:30 PM")).toBeVisible();
  await pause(page, 600);

  // Magnesium - missed
  await expect(page.locator("text=Magnesium Glycinate")).toBeVisible();
  const missedCard = page.locator(".supplement-card.missed");
  await expect(missedCard).toBeVisible();
  const missedBadge = page.locator('.bg-red-100:has-text("Missed")');
  await expect(missedBadge).toBeVisible();
  await expect(page.locator("text=400mg - Take before bed")).toBeVisible();
  await expect(page.locator("text=Yesterday")).toBeVisible();
  await pause(page, 600);

  // Red border for missed
  const missedCards = page.locator(".supplement-card.missed");
  expect(await missedCards.count()).toBe(1);

  // Screenshot: the missed Magnesium card specifically (distinct from afternoon screenshot)
  await takeElementScreenshot(
    page,
    ".supplement-card.missed",
    "06-supplements-missed-card.png",
  );
  await pause(page, 600);

  // Supplement History
  await scrollToTop(page, "text=Supplement History");
  await expect(page.locator("text=Supplement History")).toBeVisible();
  await pause(page, 600);

  // Card interactions - menu buttons
  const menuButtons = page.locator(".supplement-card button:has(svg)");
  expect(await menuButtons.count()).toBeGreaterThanOrEqual(4);

  // Mark as Taken buttons should be clickable
  const markButtons = page.locator('button:has-text("Mark as Taken")');
  const count = await markButtons.count();
  for (let i = 0; i < count; i++) {
    await expect(markButtons.nth(i)).toBeEnabled();
  }
  await pause(page);

  // Navigation
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "06-supplements-tracker.webm");
});
