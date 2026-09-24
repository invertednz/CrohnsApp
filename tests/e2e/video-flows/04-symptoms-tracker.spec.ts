import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  scrollToTop,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Symptoms Tracker - Complete Flow", async ({ page }) => {
  await page.goto("/symptoms.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Symptoms Tracker | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Symptoms Tracker");
  await expect(page.locator("header p")).toHaveText(
    "Monitor and track your symptoms",
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

  // Common Symptoms section
  await expect(page.locator("text=Common Symptoms")).toBeVisible();
  const expectedSymptoms = [
    "Abdominal Pain",
    "Diarrhea",
    "Fatigue",
    "Nausea",
    "Bloating",
    "Joint Pain",
    "Fever",
    "Weight Loss",
  ];
  for (const symptom of expectedSymptoms) {
    await expect(
      page.locator(`.symptom-tag:has-text("${symptom}")`),
    ).toBeVisible();
  }
  await pause(page, 600);

  // Add New tag
  await expect(
    page.locator('.symptom-tag:has-text("+ Add New")'),
  ).toBeVisible();

  // Active symptoms highlighted
  const activeTags = page.locator(".symptom-tag.active");
  expect(await activeTags.count()).toBe(2);
  await expect(
    page.locator('.symptom-tag.active:has-text("Abdominal Pain")'),
  ).toBeVisible();
  await expect(
    page.locator('.symptom-tag.active:has-text("Fatigue")'),
  ).toBeVisible();

  // Screenshot: common symptoms tags with active highlights
  await takeAndVerifyScreenshot(page, "04-symptoms-common-tags.png");
  await pause(page);

  // Click on some symptom tags to show interaction
  await page.locator('.symptom-tag:has-text("Nausea")').click();
  await pause(page, 500);
  await page.locator('.symptom-tag:has-text("Bloating")').click();
  await pause(page, 500);
  await page.locator('.symptom-tag:has-text("Nausea")').click();
  await pause(page, 600);

  // Active Symptoms section - scroll to put it at top for distinct screenshot
  await scrollToTop(page, "text=Active Symptoms");
  await expect(page.locator("text=Active Symptoms")).toBeVisible();
  const addBtn = page.locator(".bg-primary.rounded-full");
  expect(await addBtn.count()).toBeGreaterThanOrEqual(1);
  await pause(page, 600);

  // Abdominal Pain entry details
  await expect(
    page.locator(".bg-neutral >> text=Abdominal Pain"),
  ).toBeVisible();
  await expect(page.locator("text=Moderate")).toBeVisible();
  await expect(
    page.locator("text=Lower right quadrant, worse after eating."),
  ).toBeVisible();
  await expect(page.locator(".bg-red-500")).toBeVisible();
  await pause(page, 600);

  // Fatigue entry details
  const fatigueSection = page.locator(".bg-neutral:has-text('Fatigue')");
  await expect(fatigueSection).toBeVisible();
  await expect(page.locator("text=Mild")).toBeVisible();
  await expect(
    page.locator("text=General tiredness throughout the day."),
  ).toBeVisible();
  await expect(page.locator(".bg-yellow-500")).toBeVisible();
  await pause(page, 600);

  // Start times
  await expect(page.locator("text=Started: Today, 8:30 AM")).toBeVisible();
  await expect(page.locator("text=Started: Yesterday, 6:00 PM")).toBeVisible();

  // Update buttons
  const updateButtons = page.locator('button:has-text("Update")');
  expect(await updateButtons.count()).toBe(2);

  // Screenshot: Abdominal Pain entry card showing severity and details
  await takeElementScreenshot(
    page,
    '.bg-neutral:has-text("Abdominal Pain")',
    "04-symptoms-abdominal-pain-card.png",
  );
  await pause(page);

  // Symptom History section - scroll to put it at top for distinct screenshot
  await scrollToTop(page, "text=Symptom History");
  await expect(page.locator("text=Symptom History")).toBeVisible();
  await pause(page, 600);

  // Past entries
  await expect(page.locator("text=May 12-14")).toBeVisible();
  await expect(
    page.locator("text=Morning nausea, resolved after medication."),
  ).toBeVisible();
  await pause(page, 500);

  await expect(page.locator("text=May 10-13")).toBeVisible();
  await expect(
    page.locator("text=Knees and ankles, worse in the morning."),
  ).toBeVisible();
  await pause(page, 500);

  await expect(
    page.locator(".bg-white.rounded-xl >> text=Bloating"),
  ).toBeVisible();
  await expect(page.locator("text=May 8-11")).toBeVisible();
  await expect(
    page.locator("text=After meals, especially dairy products."),
  ).toBeVisible();

  // Screenshot: symptom history with past entries
  await takeAndVerifyScreenshot(page, "04-symptoms-history.png");
  await pause(page);

  // Navigation
  await expect(page.locator("nav")).toBeVisible();
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "04-symptoms-tracker.webm");
});
