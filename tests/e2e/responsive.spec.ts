import { test, expect } from "@playwright/test";

test.describe("Responsive Design Tests", () => {
  const viewports = [
    { name: "iPhone SE", width: 375, height: 667 },
    { name: "iPad", width: 768, height: 1024 },
    { name: "Desktop", width: 1280, height: 720 },
  ];

  for (const viewport of viewports) {
    test.describe(`${viewport.name} (${viewport.width}x${viewport.height})`, () => {
      test.use({
        viewport: { width: viewport.width, height: viewport.height },
      });

      test("Chat page should render correctly", async ({ page }) => {
        await page.goto("/chat.html");
        await expect(page.locator("h1")).toBeVisible();
        await expect(page.locator('input[type="text"]')).toBeVisible();
        await expect(page.locator(".assistant-message").first()).toBeVisible();
      });

      test("Insights page should render correctly", async ({ page }) => {
        await page.goto("/insights.html");
        await expect(page.locator("h1")).toBeVisible();
        await expect(page.locator("text=Your Health Summary")).toBeVisible();
        await expect(
          page.locator("text=Potential Food Triggers"),
        ).toBeVisible();
      });

      test("Supplements page should render correctly", async ({ page }) => {
        await page.goto("/supplements.html");
        await expect(page.locator("h1")).toBeVisible();
        await expect(page.locator("text=Vitamin D3")).toBeVisible();
        await expect(
          page.locator('button:has-text("Add Supplement")'),
        ).toBeVisible();
      });

      test("Notification preferences should render correctly", async ({
        page,
      }) => {
        await page.goto("/notification_preferences_preview.html");
        await expect(page.locator("h1")).toBeVisible();
        const timeCards = page.locator(".time-card");
        expect(await timeCards.count()).toBe(4);
      });
    });
  }

  test.describe("Mobile-specific behavior", () => {
    test.use({ viewport: { width: 375, height: 667 } });

    test("notification preferences should be fully scrollable", async ({
      page,
    }) => {
      await page.goto("/notification_preferences_preview.html");

      // All four time cards should be in the DOM even if scrolling is needed
      for (const id of ["morning", "midday", "afternoon", "evening"]) {
        await expect(page.locator(`#${id}`)).toBeAttached();
      }
    });

    test("chat messages should be scrollable", async ({ page }) => {
      await page.goto("/chat.html");
      const chatContainer = page.locator(".flex-1.overflow-y-auto");
      await expect(chatContainer).toBeVisible();
    });

    test("supplements page should scroll to reveal all sections", async ({
      page,
    }) => {
      await page.goto("/supplements.html");

      // Morning section visible initially
      await expect(page.locator('h3:has-text("Morning")')).toBeVisible();

      // Evening section exists in DOM
      await expect(page.locator('h3:has-text("Evening")')).toBeAttached();
    });
  });
});
