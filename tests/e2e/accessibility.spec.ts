import { test, expect } from "@playwright/test";

test.describe("Accessibility Tests", () => {
  test.describe("Chat Page Accessibility", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto("/chat.html");
    });

    test("should have lang attribute on html element", async ({ page }) => {
      const lang = await page.locator("html").getAttribute("lang");
      expect(lang).toBe("en");
    });

    test("should have a meaningful page title", async ({ page }) => {
      const title = await page.title();
      expect(title.length).toBeGreaterThan(0);
      expect(title).toContain("Crohn's Companion");
    });

    test("should have proper heading hierarchy", async ({ page }) => {
      const h1Count = await page.locator("h1").count();
      expect(h1Count).toBe(1);
    });

    test("input should have placeholder text", async ({ page }) => {
      const input = page.locator('input[type="text"]');
      const placeholder = await input.getAttribute("placeholder");
      expect(placeholder).toBeTruthy();
    });

    test("should be keyboard navigable", async ({ page }) => {
      await page.keyboard.press("Tab");
      const focused = page.locator(":focus");
      await expect(focused).toBeVisible();
    });

    test("links should have discernible text or contain elements", async ({
      page,
    }) => {
      const links = page.locator("nav a");
      const count = await links.count();
      for (let i = 0; i < count; i++) {
        const text = await links.nth(i).textContent();
        expect(text!.trim().length).toBeGreaterThan(0);
      }
    });
  });

  test.describe("Insights Page Accessibility", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto("/insights.html");
    });

    test("should have lang attribute", async ({ page }) => {
      expect(await page.locator("html").getAttribute("lang")).toBe("en");
    });

    test("should have one h1 heading", async ({ page }) => {
      expect(await page.locator("h1").count()).toBe(1);
    });

    test("should use semantic heading hierarchy", async ({ page }) => {
      const h3s = page.locator("h3");
      expect(await h3s.count()).toBeGreaterThan(0);
    });

    test("buttons should have text content", async ({ page }) => {
      const buttons = page.locator("button");
      const count = await buttons.count();
      for (let i = 0; i < count; i++) {
        const text = await buttons.nth(i).textContent();
        expect(text!.trim().length).toBeGreaterThan(0);
      }
    });
  });

  test.describe("Supplements Page Accessibility", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto("/supplements.html");
    });

    test("should have lang attribute", async ({ page }) => {
      expect(await page.locator("html").getAttribute("lang")).toBe("en");
    });

    test("should have meaningful section headings", async ({ page }) => {
      await expect(page.locator('h3:has-text("Morning")')).toBeVisible();
      await expect(page.locator('h3:has-text("Afternoon")')).toBeVisible();
      await expect(page.locator('h3:has-text("Evening")')).toBeVisible();
    });

    test("supplement status should be visually distinct", async ({ page }) => {
      // Taken supplements have green badges
      const takenBadges = page.locator(".bg-green-100");
      expect(await takenBadges.count()).toBeGreaterThan(0);

      // Missed supplements have red badges
      const missedBadges = page.locator(".bg-red-100");
      expect(await missedBadges.count()).toBeGreaterThan(0);
    });
  });

  test.describe("Notification Preferences Accessibility", () => {
    test.beforeEach(async ({ page }) => {
      await page.goto("/notification_preferences_preview.html");
    });

    test("should have proper heading", async ({ page }) => {
      expect(await page.locator("h1").count()).toBe(1);
    });

    test("interactive elements should be clickable", async ({ page }) => {
      const timeCards = page.locator(".time-card");
      const count = await timeCards.count();
      for (let i = 0; i < count; i++) {
        await expect(timeCards.nth(i)).toBeVisible();
      }
    });

    test("disabled button should indicate state", async ({ page }) => {
      const btn = page.locator("#continueBtn");
      await expect(btn).toBeDisabled();
    });

    test("should respect prefers-reduced-motion", async ({ page }) => {
      // The page has a @media (prefers-reduced-motion: reduce) rule
      const styles = await page.locator("style").first().textContent();
      expect(styles).toContain("prefers-reduced-motion");
    });
  });
});
