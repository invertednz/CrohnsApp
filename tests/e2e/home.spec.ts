import { test, expect } from "@playwright/test";

test.describe("Home Page (index.html)", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/index.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Crohn's Companion");
    });

    test("should display header with app name", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Crohn's Companion");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Your personal health tracker",
      );
    });

    test("should have gradient header", async ({ page }) => {
      await expect(page.locator("header")).toHaveClass(/gradient-bg/);
    });

    test("should have device frame wrapper", async ({ page }) => {
      await expect(page.locator(".device-frame")).toBeVisible();
    });

    test("should have page container", async ({ page }) => {
      await expect(page.locator(".page-container")).toBeVisible();
    });
  });

  test.describe("Feature Cards Grid", () => {
    test("should display Daily Tracking card", async ({ page }) => {
      await expect(page.locator("text=Daily Tracking")).toBeVisible();
    });

    test("should display Symptoms card", async ({ page }) => {
      await expect(page.locator("text=Symptoms")).toBeVisible();
    });

    test("should display Diet Tracker card", async ({ page }) => {
      await expect(page.locator("text=Diet Tracker")).toBeVisible();
    });

    test("should display Supplements card", async ({ page }) => {
      await expect(page.locator("text=Supplements")).toBeVisible();
    });

    test("should display Insights card", async ({ page }) => {
      await expect(page.locator('main a[href="insights.html"]')).toBeVisible();
    });

    test("should display Chat with Assistant card", async ({ page }) => {
      await expect(page.locator("text=Chat with Assistant")).toBeVisible();
    });

    test("should link to tracking page", async ({ page }) => {
      await expect(
        page.locator('a[href="tracking.html"]:has-text("Daily Tracking")'),
      ).toBeVisible();
    });

    test("should link to symptoms page", async ({ page }) => {
      await expect(
        page.locator('a[href="symptoms.html"]:has-text("Symptoms")'),
      ).toBeVisible();
    });

    test("should link to diet page", async ({ page }) => {
      await expect(
        page.locator('a[href="diet.html"]:has-text("Diet Tracker")'),
      ).toBeVisible();
    });

    test("should link to supplements page", async ({ page }) => {
      await expect(
        page.locator('a[href="supplements.html"]:has-text("Supplements")'),
      ).toBeVisible();
    });

    test("should link to insights page", async ({ page }) => {
      await expect(page.locator('main a[href="insights.html"]')).toBeVisible();
    });

    test("should link to chat page", async ({ page }) => {
      await expect(page.locator('main a[href="chat.html"]')).toBeVisible();
    });
  });

  test.describe("Today's Summary", () => {
    test("should display Today's Summary heading", async ({ page }) => {
      await expect(page.locator("text=Today's Summary")).toBeVisible();
    });

    test("should show logged data summary", async ({ page }) => {
      await expect(
        page.locator("text=You've logged 2 meals and 1 bowel movement today"),
      ).toBeVisible();
    });

    test("should display last updated timestamp", async ({ page }) => {
      await expect(
        page.locator("text=Last updated: Today, 2:30 PM"),
      ).toBeVisible();
    });

    test("should have View Details button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("View Details")'),
      ).toBeVisible();
    });
  });

  test.describe("Navigation Bar", () => {
    test("should have bottom navigation", async ({ page }) => {
      await expect(page.locator("nav")).toBeVisible();
    });

    test("should highlight Home as active tab", async ({ page }) => {
      const activeNav = page.locator("a.nav-item.active");
      await expect(activeNav).toContainText("Home");
    });

    test("should have all nav links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
    });
  });

  test.describe("Feature Card Navigation", () => {
    test("should navigate to tracking page on click", async ({ page }) => {
      await page
        .locator('a[href="tracking.html"]:has-text("Daily Tracking")')
        .click();
      await expect(page).toHaveTitle("Daily Tracking | Crohn's Companion");
    });

    test("should navigate to symptoms page on click", async ({ page }) => {
      await page
        .locator('a[href="symptoms.html"]:has-text("Symptoms")')
        .click();
      await expect(page).toHaveTitle("Symptoms Tracker | Crohn's Companion");
    });

    test("should navigate to diet page on click", async ({ page }) => {
      await page
        .locator('a[href="diet.html"]:has-text("Diet Tracker")')
        .click();
      await expect(page).toHaveTitle("Diet Tracker | Crohn's Companion");
    });

    test("should navigate to supplements page on click", async ({ page }) => {
      await page
        .locator('a[href="supplements.html"]:has-text("Supplements")')
        .click();
      await expect(page).toHaveTitle("Supplements Tracker | Crohn's Companion");
    });
  });
});
