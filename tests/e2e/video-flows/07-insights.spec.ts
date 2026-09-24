import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  scrollToTop,
  takeAndVerifyScreenshot,
} from "./helpers";

test("Insights - Complete Flow", async ({ page }) => {
  await page.goto("/insights.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Insights | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Insights");
  await expect(page.locator("header p")).toHaveText(
    "Personalized recommendations based on your data",
  );
  await expect(page.locator("header")).toHaveClass(/gradient-bg/);
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page);

  // Health Summary Card
  await expect(page.locator("text=Your Health Summary")).toBeVisible();
  await expect(
    page.locator("text=Based on your tracking data over the past 30 days"),
  ).toBeVisible();
  await expect(page.locator("text=Overall Trend")).toBeVisible();
  await expect(page.locator("text=Improving")).toBeVisible();
  await expect(page.locator('button:has-text("View Details")')).toBeVisible();
  const trendIcon = page.locator(".bg-green-100");
  await expect(trendIcon).toBeVisible();

  // Screenshot: health summary card with improving trend
  await takeAndVerifyScreenshot(page, "07-insights-health-summary.png");
  await pause(page);

  // Food Triggers Section - scroll to top for distinct screenshot
  await scrollToTop(page, "text=Potential Food Triggers");
  await expect(page.locator("text=Potential Food Triggers")).toBeVisible();
  await expect(page.locator("text=Dairy")).toBeVisible();
  await expect(page.locator("text=Spicy Foods")).toBeVisible();
  const highCorrelation = page.locator(".correlation-high");
  expect(await highCorrelation.count()).toBe(2);
  await pause(page, 600);

  // Medium correlation
  await expect(page.locator("text=Gluten")).toBeVisible();
  const medCorrelation = page.locator(".correlation-medium");
  expect(await medCorrelation.count()).toBeGreaterThanOrEqual(1);
  await expect(
    page.locator('button:has-text("View All Triggers")'),
  ).toBeVisible();
  const redDots = page.locator(".bg-neutral .bg-red-500");
  expect(await redDots.count()).toBe(2);

  // Screenshot: food triggers with high/medium correlation
  await takeAndVerifyScreenshot(page, "07-insights-food-triggers.png");
  await pause(page);

  // Beneficial Foods Section - scroll to top for distinct screenshot
  await scrollToTop(page, "text=Foods That May Help");
  await expect(page.locator("text=Foods That May Help")).toBeVisible();
  await expect(page.locator("text=Bananas")).toBeVisible();
  await expect(page.locator("text=Cooked Vegetables")).toBeVisible();
  await expect(page.locator("text=Lean Proteins")).toBeVisible();
  const positiveLabels = page.locator(
    '.correlation-low:has-text("Positive Impact")',
  );
  expect(await positiveLabels.count()).toBeGreaterThanOrEqual(3);
  await expect(
    page.locator('button:has-text("View All Beneficial Foods")'),
  ).toBeVisible();
  const greenDots = page.locator("main .bg-green-500");
  expect(await greenDots.count()).toBeGreaterThanOrEqual(3);

  // Screenshot: beneficial foods section
  await takeAndVerifyScreenshot(page, "07-insights-beneficial-foods.png");
  await pause(page);

  // Supplement Effectiveness Section
  await scrollToTop(page, "text=Supplement Effectiveness");
  await expect(page.locator("text=Supplement Effectiveness")).toBeVisible();
  const section = page.locator(
    '.rounded-xl:has-text("Supplement Effectiveness")',
  );
  await expect(section.locator("text=Vitamin D").first()).toBeVisible();
  await expect(section.locator("text=Probiotics")).toBeVisible();
  await expect(section.locator("text=Fish Oil")).toBeVisible();
  await expect(page.locator("text=Neutral Impact")).toBeVisible();
  await expect(
    page.locator('button:has-text("View All Supplements")'),
  ).toBeVisible();
  await pause(page);

  // Personalized Recommendations Section
  await scrollToTop(page, 'h3:has-text("Personalized Recommendations")');
  await expect(
    page.locator('h3:has-text("Personalized Recommendations")'),
  ).toBeVisible();
  await expect(page.locator("text=Try a Low-FODMAP Diet")).toBeVisible();
  await expect(
    page.locator("text=low-FODMAP diet might help reduce bloating"),
  ).toBeVisible();
  await pause(page, 600);

  await expect(
    page.locator("text=Consider Vitamin D Supplementation"),
  ).toBeVisible();
  await pause(page, 600);

  await expect(page.locator("text=Meal Timing Adjustment")).toBeVisible();
  await expect(page.locator("text=smaller, more frequent meals")).toBeVisible();
  const insightCards = page.locator(".insight-card");
  expect(await insightCards.count()).toBe(3);

  // Screenshot: personalized recommendations
  await takeAndVerifyScreenshot(page, "07-insights-recommendations.png");
  await pause(page);

  // Navigation
  const activeNav = page.locator("a.nav-item.active");
  await expect(activeNav).toBeVisible();
  await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
  await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "07-insights.webm");
});
