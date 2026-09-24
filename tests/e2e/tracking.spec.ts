import { test, expect } from "@playwright/test";

test.describe("Daily Tracking Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/tracking.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Daily Tracking | Crohn's Companion");
    });

    test("should display header heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Daily Tracking");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Track your bowel movements and daily feelings",
      );
    });

    test("should have gradient header", async ({ page }) => {
      await expect(page.locator("header")).toHaveClass(/gradient-bg/);
    });

    test("should have back button linking to home", async ({ page }) => {
      await expect(page.locator('header a[href="index.html"]')).toBeVisible();
    });

    test("should have device frame", async ({ page }) => {
      await expect(page.locator(".device-frame")).toBeVisible();
    });
  });

  test.describe("Date Selector", () => {
    test("should display current date", async ({ page }) => {
      await expect(page.locator("text=Today, May 15")).toBeVisible();
    });

    test("should have previous and next day buttons", async ({ page }) => {
      const dateSection = page
        .locator(".flex.justify-between.items-center")
        .first();
      const buttons = dateSection.locator("button");
      expect(await buttons.count()).toBeGreaterThanOrEqual(2);
    });
  });

  test.describe("Feeling Selector", () => {
    test("should display How are you feeling heading", async ({ page }) => {
      await expect(
        page.locator("text=How are you feeling today?"),
      ).toBeVisible();
    });

    test("should display five emoji options", async ({ page }) => {
      const emojiButtons = page.locator(
        "h3:has-text('How are you feeling') + div button",
      );
      expect(await emojiButtons.count()).toBeGreaterThanOrEqual(5);
    });

    test("should have one emoji pre-selected", async ({ page }) => {
      const selected = page.locator(".emoji-selected");
      await expect(selected).toBeVisible();
    });
  });

  test.describe("Bowel Movements Section", () => {
    test("should display Bowel Movements heading", async ({ page }) => {
      await expect(
        page.locator('h3:has-text("Bowel Movements")'),
      ).toBeVisible();
    });

    test("should have add button", async ({ page }) => {
      const addBtn = page.locator(
        "h3:has-text('Bowel Movements') + button, .bg-primary.rounded-full",
      );
      expect(await addBtn.count()).toBeGreaterThanOrEqual(1);
    });

    test("should display bowel movement entries", async ({ page }) => {
      await expect(page.locator("text=8:30 AM")).toBeVisible();
      await expect(page.locator("text=2:15 PM")).toBeVisible();
    });

    test("should show Bristol type for entries", async ({ page }) => {
      await expect(page.locator("text=Bristol Type 4")).toBeVisible();
      await expect(page.locator("text=Bristol Type 3")).toBeVisible();
    });

    test("should display entry descriptions", async ({ page }) => {
      await expect(
        page.locator("text=Normal consistency, no pain or discomfort."),
      ).toBeVisible();
      await expect(
        page.locator("text=Slight urgency but otherwise normal."),
      ).toBeVisible();
    });
  });

  test.describe("Pain Level Section", () => {
    test("should display Pain Level heading", async ({ page }) => {
      await expect(page.locator("text=Pain Level")).toBeVisible();
    });

    test("should have range slider", async ({ page }) => {
      const slider = page.locator('input[type="range"]').first();
      await expect(slider).toBeVisible();
      await expect(slider).toHaveAttribute("min", "0");
      await expect(slider).toHaveAttribute("max", "10");
    });

    test("should show current pain value", async ({ page }) => {
      await expect(page.locator("text=Current: 2/10").first()).toBeVisible();
    });

    test("should show No Pain and Severe labels", async ({ page }) => {
      await expect(page.locator("text=No Pain").first()).toBeVisible();
      await expect(page.locator("text=Severe").first()).toBeVisible();
    });

    test("should have Add Note button", async ({ page }) => {
      const addNoteButtons = page.locator('button:has-text("Add Note")');
      expect(await addNoteButtons.count()).toBeGreaterThanOrEqual(1);
    });
  });

  test.describe("Energy Level Section", () => {
    test("should display Energy Level heading", async ({ page }) => {
      await expect(page.locator("text=Energy Level")).toBeVisible();
    });

    test("should have range slider", async ({ page }) => {
      const sliders = page.locator('input[type="range"]');
      expect(await sliders.count()).toBe(2);
    });

    test("should show current energy value", async ({ page }) => {
      await expect(page.locator("text=Current: 7/10")).toBeVisible();
    });

    test("should show Low and High labels", async ({ page }) => {
      await expect(page.locator("text=Low")).toBeVisible();
      await expect(page.locator("text=High")).toBeVisible();
    });
  });

  test.describe("Navigation", () => {
    test("should highlight Track as active tab", async ({ page }) => {
      const activeNav = page.locator("a.nav-item.active");
      await expect(activeNav).toContainText("Track");
    });

    test("should have all navigation links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
    });

    test("back button should navigate to home", async ({ page }) => {
      await page.locator('header a[href="index.html"]').click();
      await expect(page).toHaveTitle("Crohn's Companion");
    });
  });
});
