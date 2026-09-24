import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  scrollToTop,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Diet Tracker - Complete Flow", async ({ page }) => {
  await page.goto("/diet.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Diet Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Diet Tracker");
  await expect(page.locator("header p")).toHaveText(
    "Monitor your food intake and identify triggers",
  );
  await expect(page.locator("header")).toHaveClass(/gradient-bg/);
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page);

  // Date selector
  await expect(page.locator("text=Today, May 15")).toBeVisible();
  const dateSection = page
    .locator(".flex.justify-between.items-center")
    .first();
  const buttons = dateSection.locator("button");
  expect(await buttons.count()).toBeGreaterThanOrEqual(2);
  await pause(page, 600);

  // Add Meal button
  const addMealBtn = page.locator('button:has-text("Add Meal")');
  await expect(addMealBtn).toBeVisible();
  await expect(addMealBtn).toHaveClass(/bg-primary/);
  await pause(page, 600);

  // Today's Meals section
  await expect(page.locator("text=Today's Meals")).toBeVisible();
  await pause(page, 500);

  // Breakfast entry
  await expect(page.locator("text=Breakfast")).toBeVisible();
  await expect(page.locator("text=7:30 AM")).toBeVisible();
  await expect(
    page.locator("text=Oatmeal with banana and honey"),
  ).toBeVisible();
  await pause(page, 600);

  // Lunch entry
  await expect(page.locator("text=Lunch")).toBeVisible();
  await expect(page.locator("text=12:15 PM")).toBeVisible();
  await expect(
    page.locator("text=Grilled chicken sandwich with avocado"),
  ).toBeVisible();
  await pause(page, 600);

  // Safe food tags
  const safeTags = page.locator(".food-tag.safe");
  expect(await safeTags.count()).toBeGreaterThanOrEqual(3);
  await pause(page, 500);

  // Trigger food tags
  const triggerTags = page.locator(".food-tag.trigger");
  expect(await triggerTags.count()).toBeGreaterThanOrEqual(1);
  await expect(
    page.locator('.food-tag.trigger:has-text("Wheat Bread")'),
  ).toBeVisible();
  await pause(page, 500);

  // Reaction info
  await expect(page.locator("text=Reaction: None")).toBeVisible();
  await expect(page.locator("text=Reaction: Mild bloating")).toBeVisible();

  // Screenshot: today's meals with food tags and reactions
  await takeAndVerifyScreenshot(page, "05-diet-todays-meals.png");
  await pause(page, 600);

  // Edit buttons
  const editButtons = page.locator('button:has-text("Edit")');
  expect(await editButtons.count()).toBe(2);
  await pause(page, 500);

  // Food Triggers section - scroll to top for distinct screenshot
  await scrollToTop(page, "text=Your Food Triggers");
  await expect(page.locator("text=Your Food Triggers")).toBeVisible();
  await expect(
    page.locator('.food-tag.trigger:has-text("Dairy")'),
  ).toBeVisible();
  await expect(
    page.locator('.food-tag.trigger:has-text("Spicy Foods")'),
  ).toBeVisible();
  await expect(
    page.locator('.food-tag.trigger:has-text("Fried Foods")'),
  ).toBeVisible();
  await expect(
    page.locator('.food-tag.trigger:has-text("Caffeine")'),
  ).toBeVisible();
  await expect(
    page.locator('button:has-text("Manage Triggers")'),
  ).toBeVisible();

  // Screenshot: food triggers section
  await takeAndVerifyScreenshot(page, "05-diet-food-triggers.png");
  await pause(page);

  // Safe Foods section - scroll to top for distinct screenshot
  await scrollToTop(page, "text=Your Safe Foods");
  await expect(page.locator("text=Your Safe Foods")).toBeVisible();
  const safeFoodsSection = page.locator(
    '.rounded-xl:has(h3:has-text("Your Safe Foods"))',
  );
  await expect(
    safeFoodsSection.locator('.food-tag.safe:has-text("Rice")'),
  ).toBeVisible();
  await expect(
    safeFoodsSection.locator('.food-tag.safe:has-text("Chicken")'),
  ).toBeVisible();
  await expect(
    safeFoodsSection.locator('.food-tag.safe:has-text("Bananas")'),
  ).toBeVisible();
  await expect(
    safeFoodsSection.locator('.food-tag.safe:has-text("Oatmeal")'),
  ).toBeVisible();
  await expect(
    safeFoodsSection.locator('.food-tag.safe:has-text("Avocado")'),
  ).toBeVisible();
  await expect(
    page.locator('button:has-text("Manage Safe Foods")'),
  ).toBeVisible();

  // Screenshot: safe foods section card (distinct element capture)
  await takeElementScreenshot(
    page,
    '.rounded-xl:has(h3:has-text("Your Safe Foods"))',
    "05-diet-safe-foods-card.png",
  );
  await pause(page);

  // Navigation
  const activeNav = page.locator("a.nav-item.active");
  await expect(activeNav).toContainText("Diet");
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "05-diet-tracker.webm");
});
