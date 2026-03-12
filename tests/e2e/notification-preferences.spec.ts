import { test, expect } from "@playwright/test";

test.describe("Notification Preferences Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/notification_preferences_preview.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle(
        "Crohn's Companion – Notification Preferences",
      );
    });

    test("should display main heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Notification Preferences");
    });

    test("should display subtitle question", async ({ page }) => {
      await expect(
        page.locator("text=When would you like to receive reminders?"),
      ).toBeVisible();
    });

    test("should have dark gradient background", async ({ page }) => {
      const body = page.locator("body");
      await expect(body).toHaveClass(/text-white/);
    });

    test("should have back button", async ({ page }) => {
      const backButton = page.locator("header button");
      await expect(backButton).toBeVisible();
    });
  });

  test.describe("Info Card", () => {
    test("should display Stay on Track heading", async ({ page }) => {
      await expect(page.locator("text=Stay on Track")).toBeVisible();
    });

    test("should display info text", async ({ page }) => {
      await expect(
        page.locator(
          "text=Choose one or more times for daily tracking reminders",
        ),
      ).toBeVisible();
    });

    test("should have notification bell icon", async ({ page }) => {
      const infoCard = page.locator(".card-glow");
      await expect(infoCard).toBeVisible();
    });
  });

  test.describe("Time Selection Cards", () => {
    test("should display four time options", async ({ page }) => {
      const timeCards = page.locator(".time-card");
      expect(await timeCards.count()).toBe(4);
    });

    test("should show Morning option with correct time", async ({ page }) => {
      await expect(page.locator("#morning h3")).toHaveText("Morning");
      await expect(
        page.locator("#morning >> text=7:00 AM - 11:00 AM"),
      ).toBeVisible();
      await expect(
        page.locator("#morning >> text=Start your day with a gentle reminder"),
      ).toBeVisible();
    });

    test("should show Midday option with correct time", async ({ page }) => {
      await expect(page.locator("#midday h3")).toHaveText("Midday");
      await expect(
        page.locator("#midday >> text=11:00 AM - 2:00 PM"),
      ).toBeVisible();
      await expect(
        page.locator("#midday >> text=Perfect for lunch tracking"),
      ).toBeVisible();
    });

    test("should show Afternoon option with correct time", async ({ page }) => {
      await expect(page.locator("#afternoon h3")).toHaveText("Afternoon");
      await expect(
        page.locator("#afternoon >> text=2:00 PM - 6:00 PM"),
      ).toBeVisible();
      await expect(
        page.locator("#afternoon >> text=Track your afternoon progress"),
      ).toBeVisible();
    });

    test("should show Evening option with correct time", async ({ page }) => {
      await expect(page.locator("#evening h3")).toHaveText("Evening");
      await expect(
        page.locator("#evening >> text=6:00 PM - 10:00 PM"),
      ).toBeVisible();
      await expect(
        page.locator("#evening >> text=End of day reflection"),
      ).toBeVisible();
    });

    test("should have hidden checkmarks initially", async ({ page }) => {
      await expect(page.locator("#morning-check")).toHaveClass(/hidden/);
      await expect(page.locator("#midday-check")).toHaveClass(/hidden/);
      await expect(page.locator("#afternoon-check")).toHaveClass(/hidden/);
      await expect(page.locator("#evening-check")).toHaveClass(/hidden/);
    });
  });

  test.describe("Time Selection Interactions", () => {
    test("should select Morning when clicked", async ({ page }) => {
      await page.locator("#morning").click();

      await expect(page.locator("#morning")).toHaveClass(/selected/);
      await expect(page.locator("#morning-check")).not.toHaveClass(/hidden/);
    });

    test("should deselect Morning when clicked again", async ({ page }) => {
      await page.locator("#morning").click();
      await expect(page.locator("#morning")).toHaveClass(/selected/);

      await page.locator("#morning").click();
      await expect(page.locator("#morning")).not.toHaveClass(/selected/);
      await expect(page.locator("#morning-check")).toHaveClass(/hidden/);
    });

    test("should allow multiple selections", async ({ page }) => {
      await page.locator("#morning").click();
      await page.locator("#evening").click();

      await expect(page.locator("#morning")).toHaveClass(/selected/);
      await expect(page.locator("#evening")).toHaveClass(/selected/);
      await expect(page.locator("#midday")).not.toHaveClass(/selected/);
    });

    test("should select all four options", async ({ page }) => {
      await page.locator("#morning").click();
      await page.locator("#midday").click();
      await page.locator("#afternoon").click();
      await page.locator("#evening").click();

      await expect(page.locator("#morning")).toHaveClass(/selected/);
      await expect(page.locator("#midday")).toHaveClass(/selected/);
      await expect(page.locator("#afternoon")).toHaveClass(/selected/);
      await expect(page.locator("#evening")).toHaveClass(/selected/);
    });

    test("should show checkmark when selected", async ({ page }) => {
      await page.locator("#midday").click();
      await expect(page.locator("#midday-check")).not.toHaveClass(/hidden/);
    });

    test("should hide checkmark when deselected", async ({ page }) => {
      await page.locator("#afternoon").click();
      await page.locator("#afternoon").click();
      await expect(page.locator("#afternoon-check")).toHaveClass(/hidden/);
    });
  });

  test.describe("Continue Button", () => {
    test("should be disabled initially", async ({ page }) => {
      const continueBtn = page.locator("#continueBtn");
      await expect(continueBtn).toBeDisabled();
    });

    test('should show "Select at least one" text initially', async ({
      page,
    }) => {
      await expect(page.locator("#btnText")).toHaveText("Select at least one");
    });

    test("should enable when a time is selected", async ({ page }) => {
      await page.locator("#morning").click();
      await expect(page.locator("#continueBtn")).toBeEnabled();
    });

    test('should change text to "Continue" when enabled', async ({ page }) => {
      await page.locator("#evening").click();
      await expect(page.locator("#btnText")).toHaveText("Continue");
    });

    test("should disable again when all selections removed", async ({
      page,
    }) => {
      await page.locator("#morning").click();
      await expect(page.locator("#continueBtn")).toBeEnabled();

      await page.locator("#morning").click();
      await expect(page.locator("#continueBtn")).toBeDisabled();
      await expect(page.locator("#btnText")).toHaveText("Select at least one");
    });

    test("should show alert with selected times on click", async ({ page }) => {
      await page.locator("#morning").click();
      await page.locator("#evening").click();

      let dialogMessage = "";
      page.on("dialog", async (dialog) => {
        dialogMessage = dialog.message();
        await dialog.accept();
      });

      await page.locator("#continueBtn").click();
      await page.waitForTimeout(500);

      expect(dialogMessage).toContain("morning");
      expect(dialogMessage).toContain("evening");
    });

    test("should have primary button styling", async ({ page }) => {
      const btn = page.locator("#continueBtn");
      await expect(btn).toHaveClass(/btn-primary/);
    });
  });

  test.describe("Skip Button", () => {
    test("should display Skip button", async ({ page }) => {
      const skipBtn = page.locator('button:has-text("Skip")');
      await expect(skipBtn).toBeVisible();
    });

    test("should have secondary styling", async ({ page }) => {
      const skipBtn = page.locator('button:has-text("Skip")');
      await expect(skipBtn).toHaveClass(/btn-secondary/);
    });

    test("should show alert when clicked", async ({ page }) => {
      let dialogMessage = "";
      page.on("dialog", async (dialog) => {
        dialogMessage = dialog.message();
        await dialog.accept();
      });

      await page.locator('button:has-text("Skip")').click();
      await page.waitForTimeout(500);

      expect(dialogMessage).toBe("Skipped notifications");
    });
  });

  test.describe("Info Note", () => {
    test("should display settings change info", async ({ page }) => {
      await expect(
        page.locator(
          "text=You can change these settings anytime in your profile",
        ),
      ).toBeVisible();
    });
  });

  test.describe("Back Button", () => {
    test("should show alert when clicked", async ({ page }) => {
      let dialogMessage = "";
      page.on("dialog", async (dialog) => {
        dialogMessage = dialog.message();
        await dialog.accept();
      });

      await page.locator("header button").click();
      await page.waitForTimeout(500);

      expect(dialogMessage).toBe("Back button clicked");
    });
  });
});
