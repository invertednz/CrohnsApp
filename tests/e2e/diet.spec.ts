import { test, expect } from "@playwright/test";

test.describe("Diet Tracker Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/diet.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Diet Tracker | Crohn's Companion");
    });

    test("should display header heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Diet Tracker");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Monitor your food intake and identify triggers",
      );
    });

    test("should have gradient header", async ({ page }) => {
      await expect(page.locator("header")).toHaveClass(/gradient-bg/);
    });

    test("should have back button linking to home", async ({ page }) => {
      await expect(page.locator('header a[href="index.html"]')).toBeVisible();
    });
  });

  test.describe("Date Selector", () => {
    test("should display current date", async ({ page }) => {
      await expect(page.locator("text=Today, May 15")).toBeVisible();
    });

    test("should have navigation buttons", async ({ page }) => {
      const dateSection = page
        .locator(".flex.justify-between.items-center")
        .first();
      const buttons = dateSection.locator("button");
      expect(await buttons.count()).toBeGreaterThanOrEqual(2);
    });
  });

  test.describe("Add Meal Button", () => {
    test("should display Add Meal button", async ({ page }) => {
      await expect(page.locator('button:has-text("Add Meal")')).toBeVisible();
    });

    test("should have primary styling", async ({ page }) => {
      await expect(page.locator('button:has-text("Add Meal")')).toHaveClass(
        /bg-primary/,
      );
    });
  });

  test.describe("Today's Meals", () => {
    test("should display Today's Meals heading", async ({ page }) => {
      await expect(page.locator("text=Today's Meals")).toBeVisible();
    });

    test("should show Breakfast entry", async ({ page }) => {
      await expect(page.locator("text=Breakfast")).toBeVisible();
      await expect(page.locator("text=7:30 AM")).toBeVisible();
      await expect(
        page.locator("text=Oatmeal with banana and honey"),
      ).toBeVisible();
    });

    test("should show Lunch entry", async ({ page }) => {
      await expect(page.locator("text=Lunch")).toBeVisible();
      await expect(page.locator("text=12:15 PM")).toBeVisible();
      await expect(
        page.locator("text=Grilled chicken sandwich with avocado"),
      ).toBeVisible();
    });

    test("should display safe food tags", async ({ page }) => {
      const safeTags = page.locator(".food-tag.safe");
      expect(await safeTags.count()).toBeGreaterThanOrEqual(3);
    });

    test("should display trigger food tags", async ({ page }) => {
      const triggerTags = page.locator(".food-tag.trigger");
      expect(await triggerTags.count()).toBeGreaterThanOrEqual(1);
      await expect(
        page.locator('.food-tag.trigger:has-text("Wheat Bread")'),
      ).toBeVisible();
    });

    test("should show reaction info", async ({ page }) => {
      await expect(page.locator("text=Reaction: None")).toBeVisible();
      await expect(page.locator("text=Reaction: Mild bloating")).toBeVisible();
    });

    test("should have Edit buttons", async ({ page }) => {
      const editButtons = page.locator('button:has-text("Edit")');
      expect(await editButtons.count()).toBe(2);
    });
  });

  test.describe("Food Triggers Section", () => {
    test("should display Your Food Triggers heading", async ({ page }) => {
      await expect(page.locator("text=Your Food Triggers")).toBeVisible();
    });

    test("should list known triggers", async ({ page }) => {
      await expect(
        page.locator('.food-tag.trigger:has-text("Dairy")'),
      ).toBeVisible();
      await expect(
        page.locator('.food-tag.trigger:has-text("Wheat")').last(),
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
    });

    test("should have Manage Triggers button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("Manage Triggers")'),
      ).toBeVisible();
    });
  });

  test.describe("Safe Foods Section", () => {
    test("should display Your Safe Foods heading", async ({ page }) => {
      await expect(page.locator("text=Your Safe Foods")).toBeVisible();
    });

    test("should list safe foods", async ({ page }) => {
      const section = page.locator(
        '.rounded-xl:has(h3:has-text("Your Safe Foods"))',
      );
      await expect(
        section.locator('.food-tag.safe:has-text("Rice")'),
      ).toBeVisible();
      await expect(
        section.locator('.food-tag.safe:has-text("Chicken")'),
      ).toBeVisible();
      await expect(
        section.locator('.food-tag.safe:has-text("Bananas")'),
      ).toBeVisible();
      await expect(
        section.locator('.food-tag.safe:has-text("Oatmeal")'),
      ).toBeVisible();
      await expect(
        section.locator('.food-tag.safe:has-text("Avocado")'),
      ).toBeVisible();
    });

    test("should have Manage Safe Foods button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("Manage Safe Foods")'),
      ).toBeVisible();
    });
  });

  test.describe("Navigation", () => {
    test("should highlight Diet as active tab", async ({ page }) => {
      const activeNav = page.locator("a.nav-item.active");
      await expect(activeNav).toContainText("Diet");
    });

    test("should have all navigation links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
    });

    test("back button should navigate to home", async ({ page }) => {
      await page.locator('header a[href="index.html"]').click();
      await expect(page).toHaveTitle("Crohn's Companion");
    });
  });
});
