import { test, expect } from "@playwright/test";

test.describe("Chat Assistant Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/chat.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Chat Assistant | Crohn's Companion");
    });

    test("should display header with correct heading", async ({ page }) => {
      const heading = page.locator("h1");
      await expect(heading).toHaveText("Chat Assistant");
    });

    test("should display header subtitle", async ({ page }) => {
      const subtitle = page.locator("header p");
      await expect(subtitle).toHaveText("Get personalized advice and answers");
    });

    test("should have a gradient background header", async ({ page }) => {
      const header = page.locator("header");
      await expect(header).toHaveClass(/gradient-bg/);
    });

    test("should have back button in header", async ({ page }) => {
      const backLink = page.locator('header a[href="index.html"]');
      await expect(backLink).toBeVisible();
    });
  });

  test.describe("Chat Messages", () => {
    test("should display welcome message from assistant", async ({ page }) => {
      const welcomeMessage = page.locator(".assistant-message").first();
      await expect(welcomeMessage).toContainText(
        "Hello! I'm your Crohn's Companion assistant",
      );
    });

    test("should display user message about food avoidance", async ({
      page,
    }) => {
      const userMessage = page.locator(".user-message").first();
      await expect(userMessage).toContainText(
        "What foods should I avoid during a flare-up?",
      );
    });

    test("should display assistant response with food list", async ({
      page,
    }) => {
      const foodResponse = page.locator(".assistant-message").nth(1);
      await expect(foodResponse).toContainText("High-fiber foods");
      await expect(foodResponse).toContainText("Dairy products");
      await expect(foodResponse).toContainText("Spicy foods");
      await expect(foodResponse).toContainText("Fatty or fried foods");
      await expect(foodResponse).toContainText("Caffeine and alcohol");
    });

    test("should display user message about supplements for fatigue", async ({
      page,
    }) => {
      const userMessage = page.locator(".user-message").nth(1);
      await expect(userMessage).toContainText(
        "supplements that could help with my fatigue",
      );
    });

    test("should display assistant response with supplement recommendations", async ({
      page,
    }) => {
      const supplementResponse = page.locator(".assistant-message").nth(2);
      await expect(supplementResponse).toContainText("Iron supplements");
      await expect(supplementResponse).toContainText("Vitamin B12");
      await expect(supplementResponse).toContainText("Vitamin D");
      await expect(supplementResponse).toContainText("CoQ10");
      await expect(supplementResponse).toContainText("Magnesium");
    });

    test("should display healthcare provider disclaimer", async ({ page }) => {
      const disclaimer = page.locator(".assistant-message").nth(2);
      await expect(disclaimer).toContainText(
        "Always consult with your healthcare provider",
      );
    });

    test("should have correct message bubble styling", async ({ page }) => {
      const userBubbles = page.locator(".user-message");
      const assistantBubbles = page.locator(".assistant-message");

      await expect(userBubbles.first()).toHaveClass(/user-message/);
      await expect(assistantBubbles.first()).toHaveClass(/assistant-message/);
    });

    test("should have assistant avatar icons", async ({ page }) => {
      const avatars = page.locator(
        ".gradient-bg.flex.items-center.justify-center",
      );
      expect(await avatars.count()).toBeGreaterThanOrEqual(3);
    });
  });

  test.describe("Message Input", () => {
    test("should have message input field", async ({ page }) => {
      const input = page.locator('input[type="text"]');
      await expect(input).toBeVisible();
      await expect(input).toHaveAttribute(
        "placeholder",
        "Type your message here...",
      );
    });

    test("should have send button", async ({ page }) => {
      const sendButton = page.locator("button.bg-primary");
      await expect(sendButton).toBeVisible();
    });

    test("should accept text input", async ({ page }) => {
      const input = page.locator('input[type="text"]');
      await input.fill("What diet is best for Crohn's?");
      await expect(input).toHaveValue("What diet is best for Crohn's?");
    });

    test("should clear input on focus", async ({ page }) => {
      const input = page.locator('input[type="text"]');
      await input.click();
      await expect(input).toBeFocused();
    });
  });

  test.describe("Suggested Questions", () => {
    test("should display suggested questions section", async ({ page }) => {
      const label = page.locator("text=Suggested questions:");
      await expect(label).toBeVisible();
    });

    test("should have three suggestion buttons", async ({ page }) => {
      const suggestions = page.locator(".bg-neutral.text-black.text-xs");
      expect(await suggestions.count()).toBe(3);
    });

    test("should display correct suggestion texts", async ({ page }) => {
      await expect(
        page.locator('button:has-text("What can I eat today?")'),
      ).toBeVisible();
      await expect(
        page.locator('button:has-text("Help with abdominal pain")'),
      ).toBeVisible();
      await expect(
        page.locator('button:has-text("Medication reminders")'),
      ).toBeVisible();
    });

    test("suggestion buttons should be clickable", async ({ page }) => {
      const suggestion = page.locator(
        'button:has-text("What can I eat today?")',
      );
      await expect(suggestion).toBeEnabled();
    });
  });

  test.describe("Navigation Bar", () => {
    test("should display bottom navigation", async ({ page }) => {
      const nav = page.locator("nav");
      await expect(nav).toBeVisible();
    });

    test("should have four navigation items", async ({ page }) => {
      const navItems = page.locator("nav a.nav-item");
      expect(await navItems.count()).toBe(4);
    });

    test("should highlight Chat as active tab", async ({ page }) => {
      const chatNav = page.locator("a.nav-item.active");
      await expect(chatNav).toContainText("Chat");
    });

    test("should have correct nav labels", async ({ page }) => {
      await expect(page.locator("nav >> text=Home")).toBeVisible();
      await expect(page.locator("nav >> text=Track")).toBeVisible();
      await expect(page.locator("nav >> text=Insights")).toBeVisible();
      await expect(page.locator("nav >> text=Chat")).toBeVisible();
    });

    test("should link to correct pages", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="insights.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="chat.html"]')).toBeVisible();
    });
  });

  test.describe("Device Frame", () => {
    test("should render within device frame", async ({ page }) => {
      const frame = page.locator(".device-frame");
      await expect(frame).toBeVisible();
    });

    test("should have page container", async ({ page }) => {
      const container = page.locator(".page-container");
      await expect(container).toBeVisible();
    });
  });
});
