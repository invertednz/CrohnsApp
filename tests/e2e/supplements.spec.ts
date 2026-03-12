import { test, expect } from "@playwright/test";

test.describe("Supplements Tracker Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/supplements.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Supplements Tracker | Crohn's Companion");
    });

    test("should display header with correct heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Supplements");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Track your supplement intake",
      );
    });

    test("should have back button", async ({ page }) => {
      await expect(page.locator('header a[href="index.html"]')).toBeVisible();
    });
  });

  test.describe("Date Selector", () => {
    test("should display current date", async ({ page }) => {
      await expect(page.locator("text=Today, May 15")).toBeVisible();
    });

    test("should have previous day button", async ({ page }) => {
      const buttons = page.locator("main button:has(svg)");
      await expect(buttons.first()).toBeVisible();
    });

    test("should have next day button", async ({ page }) => {
      const dateSection = page
        .locator(".flex.justify-between.items-center")
        .first();
      const buttons = dateSection.locator("button:has(svg)");
      expect(await buttons.count()).toBeGreaterThanOrEqual(2);
    });
  });

  test.describe("Add Supplement Button", () => {
    test("should display Add Supplement button", async ({ page }) => {
      const addButton = page.locator('button:has-text("Add Supplement")');
      await expect(addButton).toBeVisible();
    });

    test("should have primary styling", async ({ page }) => {
      const addButton = page.locator('button:has-text("Add Supplement")');
      await expect(addButton).toHaveClass(/bg-primary/);
    });

    test("should have plus icon", async ({ page }) => {
      const addButton = page.locator('button:has-text("Add Supplement")');
      const svg = addButton.locator("svg");
      await expect(svg).toBeVisible();
    });
  });

  test.describe("Morning Supplements", () => {
    test("should display Morning section heading", async ({ page }) => {
      await expect(page.locator('h3:has-text("Morning")')).toBeVisible();
    });

    test("should show Vitamin D3 as taken", async ({ page }) => {
      await expect(page.locator("text=Vitamin D3")).toBeVisible();
      const vitDCard = page.locator(".supplement-card.taken").first();
      await expect(vitDCard).toBeVisible();
    });

    test("should display Vitamin D3 dosage info", async ({ page }) => {
      await expect(
        page.locator("text=2000 IU - Take with breakfast"),
      ).toBeVisible();
    });

    test("should show taken badge for Vitamin D3", async ({ page }) => {
      const takenBadge = page
        .locator('.bg-green-100:has-text("Taken")')
        .first();
      await expect(takenBadge).toBeVisible();
    });

    test("should show Omega-3 Fish Oil as taken", async ({ page }) => {
      await expect(page.locator("text=Omega-3 Fish Oil")).toBeVisible();
      await expect(
        page.locator("text=1000mg - Take with breakfast"),
      ).toBeVisible();
    });

    test("should display time stamps", async ({ page }) => {
      const timestamps = page.locator("text=7:45 AM");
      expect(await timestamps.count()).toBe(2);
    });

    test("should have green left border for taken supplements", async ({
      page,
    }) => {
      const takenCards = page.locator(".supplement-card.taken");
      expect(await takenCards.count()).toBe(2);
    });
  });

  test.describe("Afternoon Supplements", () => {
    test("should display Afternoon section heading", async ({ page }) => {
      await expect(page.locator('h3:has-text("Afternoon")')).toBeVisible();
    });

    test("should show Probiotic as scheduled", async ({ page }) => {
      await expect(page.locator("text=Probiotic")).toBeVisible();
      await expect(page.locator("text=Scheduled").first()).toBeVisible();
    });

    test("should display Probiotic dosage info", async ({ page }) => {
      await expect(
        page.locator("text=50 billion CFU - Take after lunch"),
      ).toBeVisible();
    });

    test("should show scheduled time", async ({ page }) => {
      await expect(page.locator("text=1:00 PM")).toBeVisible();
    });

    test("should have Mark as Taken button", async ({ page }) => {
      const markButton = page
        .locator('button:has-text("Mark as Taken")')
        .first();
      await expect(markButton).toBeVisible();
      await expect(markButton).toHaveClass(/bg-primary/);
    });
  });

  test.describe("Evening Supplements", () => {
    test("should display Evening section heading", async ({ page }) => {
      await expect(page.locator('h3:has-text("Evening")')).toBeVisible();
    });

    test("should show Turmeric Extract as scheduled", async ({ page }) => {
      await expect(page.locator("text=Turmeric Extract")).toBeVisible();
      await expect(page.locator("text=500mg - Take with dinner")).toBeVisible();
    });

    test("should show scheduled time for Turmeric", async ({ page }) => {
      await expect(page.locator("text=6:30 PM")).toBeVisible();
    });

    test("should show Magnesium Glycinate as missed", async ({ page }) => {
      await expect(page.locator("text=Magnesium Glycinate")).toBeVisible();
      const missedCard = page.locator(".supplement-card.missed");
      await expect(missedCard).toBeVisible();
    });

    test("should display missed badge", async ({ page }) => {
      const missedBadge = page.locator('.bg-red-100:has-text("Missed")');
      await expect(missedBadge).toBeVisible();
    });

    test("should show Magnesium dosage info", async ({ page }) => {
      await expect(page.locator("text=400mg - Take before bed")).toBeVisible();
    });

    test("should show Yesterday for missed supplement", async ({ page }) => {
      await expect(page.locator("text=Yesterday")).toBeVisible();
    });

    test("should have red left border for missed supplements", async ({
      page,
    }) => {
      const missedCards = page.locator(".supplement-card.missed");
      expect(await missedCards.count()).toBe(1);
    });
  });

  test.describe("Supplement History", () => {
    test("should display Supplement History section", async ({ page }) => {
      await expect(page.locator("text=Supplement History")).toBeVisible();
    });
  });

  test.describe("Supplement Card Interactions", () => {
    test("should have menu buttons on each card", async ({ page }) => {
      // Each supplement card has a "..." menu button
      const menuButtons = page.locator(".supplement-card button:has(svg)");
      expect(await menuButtons.count()).toBeGreaterThanOrEqual(4);
    });

    test("Mark as Taken buttons should be clickable", async ({ page }) => {
      const markButtons = page.locator('button:has-text("Mark as Taken")');
      const count = await markButtons.count();
      for (let i = 0; i < count; i++) {
        await expect(markButtons.nth(i)).toBeEnabled();
      }
    });
  });

  test.describe("Navigation", () => {
    test("should have bottom navigation", async ({ page }) => {
      const nav = page.locator("nav");
      await expect(nav).toBeVisible();
    });

    test("should have navigation links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
    });
  });
});
