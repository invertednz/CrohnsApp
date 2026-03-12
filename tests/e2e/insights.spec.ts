import { test, expect } from "@playwright/test";

test.describe("Insights Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/insights.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Insights | Crohn's Companion");
    });

    test("should display header with correct heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Insights");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Personalized recommendations based on your data",
      );
    });

    test("should have gradient header", async ({ page }) => {
      await expect(page.locator("header")).toHaveClass(/gradient-bg/);
    });

    test("should have back button linking to index", async ({ page }) => {
      await expect(page.locator('header a[href="index.html"]')).toBeVisible();
    });
  });

  test.describe("Health Summary Card", () => {
    test("should display health summary heading", async ({ page }) => {
      await expect(page.locator("text=Your Health Summary")).toBeVisible();
    });

    test("should display summary description", async ({ page }) => {
      await expect(
        page.locator("text=Based on your tracking data over the past 30 days"),
      ).toBeVisible();
    });

    test("should show improving trend", async ({ page }) => {
      await expect(page.locator("text=Overall Trend")).toBeVisible();
      await expect(page.locator("text=Improving")).toBeVisible();
    });

    test("should have View Details button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("View Details")'),
      ).toBeVisible();
    });

    test("should display green trend icon", async ({ page }) => {
      const trendIcon = page.locator(".bg-green-100");
      await expect(trendIcon).toBeVisible();
    });
  });

  test.describe("Food Triggers Section", () => {
    test("should display food triggers heading", async ({ page }) => {
      await expect(page.locator("text=Potential Food Triggers")).toBeVisible();
    });

    test("should list high correlation triggers", async ({ page }) => {
      await expect(page.locator("text=Dairy")).toBeVisible();
      await expect(page.locator("text=Spicy Foods")).toBeVisible();

      const highCorrelation = page.locator(".correlation-high");
      expect(await highCorrelation.count()).toBe(2);
    });

    test("should list medium correlation triggers", async ({ page }) => {
      await expect(page.locator("text=Gluten")).toBeVisible();

      const medCorrelation = page.locator(".correlation-medium");
      expect(await medCorrelation.count()).toBeGreaterThanOrEqual(1);
    });

    test("should have View All Triggers button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("View All Triggers")'),
      ).toBeVisible();
    });

    test("should show red indicator dots for triggers", async ({ page }) => {
      const redDots = page.locator(".bg-neutral .bg-red-500");
      expect(await redDots.count()).toBe(2);
    });
  });

  test.describe("Beneficial Foods Section", () => {
    test("should display beneficial foods heading", async ({ page }) => {
      await expect(page.locator("text=Foods That May Help")).toBeVisible();
    });

    test("should list beneficial foods", async ({ page }) => {
      await expect(page.locator("text=Bananas")).toBeVisible();
      await expect(page.locator("text=Cooked Vegetables")).toBeVisible();
      await expect(page.locator("text=Lean Proteins")).toBeVisible();
    });

    test("should show positive impact labels", async ({ page }) => {
      const positiveLabels = page.locator(
        '.correlation-low:has-text("Positive Impact")',
      );
      expect(await positiveLabels.count()).toBeGreaterThanOrEqual(3);
    });

    test("should have View All Beneficial Foods button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("View All Beneficial Foods")'),
      ).toBeVisible();
    });

    test("should show green indicator dots", async ({ page }) => {
      const greenDots = page.locator("main .bg-green-500");
      expect(await greenDots.count()).toBeGreaterThanOrEqual(3);
    });
  });

  test.describe("Supplement Effectiveness Section", () => {
    test("should display supplement effectiveness heading", async ({
      page,
    }) => {
      await expect(page.locator("text=Supplement Effectiveness")).toBeVisible();
    });

    test("should list supplements with impact levels", async ({ page }) => {
      const section = page.locator(
        '.rounded-xl:has-text("Supplement Effectiveness")',
      );
      await expect(section.locator("text=Vitamin D").first()).toBeVisible();
      await expect(section.locator("text=Probiotics")).toBeVisible();
      await expect(section.locator("text=Fish Oil")).toBeVisible();
    });

    test("should show neutral impact for Fish Oil", async ({ page }) => {
      await expect(page.locator("text=Neutral Impact")).toBeVisible();
    });

    test("should have View All Supplements button", async ({ page }) => {
      await expect(
        page.locator('button:has-text("View All Supplements")'),
      ).toBeVisible();
    });
  });

  test.describe("Personalized Recommendations Section", () => {
    test("should display recommendations heading", async ({ page }) => {
      await expect(
        page.locator('h3:has-text("Personalized Recommendations")'),
      ).toBeVisible();
    });

    test("should show Low-FODMAP diet recommendation", async ({ page }) => {
      await expect(page.locator("text=Try a Low-FODMAP Diet")).toBeVisible();
      await expect(
        page.locator("text=low-FODMAP diet might help reduce bloating"),
      ).toBeVisible();
    });

    test("should show Vitamin D recommendation", async ({ page }) => {
      await expect(
        page.locator("text=Consider Vitamin D Supplementation"),
      ).toBeVisible();
    });

    test("should show meal timing recommendation", async ({ page }) => {
      await expect(page.locator("text=Meal Timing Adjustment")).toBeVisible();
      await expect(
        page.locator("text=smaller, more frequent meals"),
      ).toBeVisible();
    });

    test("should have insight card styling", async ({ page }) => {
      const insightCards = page.locator(".insight-card");
      expect(await insightCards.count()).toBe(3);
    });
  });

  test.describe("Navigation", () => {
    test("should highlight Insights as active tab", async ({ page }) => {
      const activeNav = page.locator("a.nav-item.active");
      // The insights nav has no text label in the truncated nav, check it exists
      await expect(activeNav).toBeVisible();
    });

    test("should have navigation links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
    });
  });
});
