import { test, expect } from "@playwright/test";

test.describe("Visual Snapshot Tests", () => {
  test.describe("Chat Page Snapshots", () => {
    test("chat page full view", async ({ page }) => {
      await page.goto("/chat.html");
      await page.waitForLoadState("networkidle");
      await expect(page).toHaveScreenshot("chat-full.png", {
        maxDiffPixelRatio: 0.05,
      });
    });

    test("chat header section", async ({ page }) => {
      await page.goto("/chat.html");
      const header = page.locator("header");
      await expect(header).toHaveScreenshot("chat-header.png");
    });

    test("chat message bubbles", async ({ page }) => {
      await page.goto("/chat.html");
      const messages = page.locator(".flex-1.overflow-y-auto");
      await expect(messages).toHaveScreenshot("chat-messages.png", {
        maxDiffPixelRatio: 0.05,
      });
    });
  });

  test.describe("Insights Page Snapshots", () => {
    test("insights page full view", async ({ page }) => {
      await page.goto("/insights.html");
      await page.waitForLoadState("networkidle");
      await expect(page).toHaveScreenshot("insights-full.png", {
        maxDiffPixelRatio: 0.05,
      });
    });

    test("food triggers section", async ({ page }) => {
      await page.goto("/insights.html");
      const triggers = page.locator(
        ':has-text("Potential Food Triggers") >> ..',
      );
      await triggers.first().scrollIntoViewIfNeeded();
      await expect(triggers.first()).toHaveScreenshot("insights-triggers.png", {
        maxDiffPixelRatio: 0.05,
      });
    });
  });

  test.describe("Supplements Page Snapshots", () => {
    test("supplements page full view", async ({ page }) => {
      await page.goto("/supplements.html");
      await page.waitForLoadState("networkidle");
      await expect(page).toHaveScreenshot("supplements-full.png", {
        maxDiffPixelRatio: 0.05,
      });
    });

    test("supplement card taken state", async ({ page }) => {
      await page.goto("/supplements.html");
      const takenCard = page.locator(".supplement-card.taken").first();
      await expect(takenCard).toHaveScreenshot("supplement-taken.png");
    });

    test("supplement card missed state", async ({ page }) => {
      await page.goto("/supplements.html");
      const missedCard = page.locator(".supplement-card.missed");
      await missedCard.scrollIntoViewIfNeeded();
      await expect(missedCard).toHaveScreenshot("supplement-missed.png");
    });
  });

  test.describe("Notification Preferences Snapshots", () => {
    test("notification preferences default state", async ({ page }) => {
      await page.goto("/notification_preferences_preview.html");
      await page.waitForLoadState("networkidle");
      await expect(page).toHaveScreenshot("notifications-default.png", {
        maxDiffPixelRatio: 0.05,
      });
    });

    test("notification preferences with selections", async ({ page }) => {
      await page.goto("/notification_preferences_preview.html");
      await page.locator("#morning").click();
      await page.locator("#evening").click();
      await expect(page).toHaveScreenshot("notifications-selected.png", {
        maxDiffPixelRatio: 0.05,
      });
    });
  });
});
