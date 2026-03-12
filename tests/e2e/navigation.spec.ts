import { test, expect } from "@playwright/test";

test.describe("Cross-Page Navigation", () => {
  test("should navigate from Chat to Insights via nav bar", async ({
    page,
  }) => {
    await page.goto("/chat.html");
    await page.locator('nav a[href="insights.html"]').click();
    await expect(page).toHaveTitle("Insights | Crohn's Companion");
  });

  test("should navigate from Insights to Home via nav bar", async ({
    page,
  }) => {
    await page.goto("/insights.html");
    // Insights nav has: Home, Track, Diet, Insights
    await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
  });

  test("should navigate from Chat page through nav links", async ({ page }) => {
    await page.goto("/chat.html");
    // Chat nav has: Home, Track, Insights, Chat
    await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  });

  test("should navigate from Chat to Insights and verify content", async ({
    page,
  }) => {
    await page.goto("/chat.html");
    await expect(page.locator("h1")).toHaveText("Chat Assistant");

    await page.locator('nav a[href="insights.html"]').click();
    await expect(page.locator("h1")).toHaveText("Insights");
  });

  test("should maintain device frame across pages", async ({ page }) => {
    await page.goto("/chat.html");
    await expect(page.locator(".device-frame")).toBeVisible();

    await page.goto("/insights.html");
    await expect(page.locator(".device-frame")).toBeVisible();

    await page.goto("/supplements.html");
    await expect(page.locator(".device-frame")).toBeVisible();
  });

  test("should highlight correct active nav on each page", async ({ page }) => {
    await page.goto("/chat.html");
    const chatActive = page.locator("a.nav-item.active");
    await expect(chatActive).toContainText("Chat");

    await page.goto("/insights.html");
    const insightsActive = page.locator("a.nav-item.active");
    await expect(insightsActive).toBeVisible();
  });

  test("back buttons should link to index.html", async ({ page }) => {
    await page.goto("/chat.html");
    await expect(page.locator('header a[href="index.html"]')).toBeVisible();

    await page.goto("/insights.html");
    await expect(page.locator('header a[href="index.html"]')).toBeVisible();

    await page.goto("/supplements.html");
    await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  });

  test("supplements page should have working nav links", async ({ page }) => {
    await page.goto("/supplements.html");
    // Supplements nav has: Home, Track, Diet, Insights, Chat
    await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
    await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
  });
});
