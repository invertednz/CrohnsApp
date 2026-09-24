import { test, expect } from "@playwright/test";
import {
  saveVideo,
  pause,
  smoothScroll,
  takeAndVerifyScreenshot,
  takeElementScreenshot,
} from "./helpers";

test("Chat Assistant - Complete Flow", async ({ page }) => {
  await page.goto("/chat.html");
  await page.waitForLoadState("networkidle");
  await pause(page, 1200);

  // Verify page structure
  await expect(page).toHaveTitle("Chat Assistant | Crohn's Companion");
  await expect(page.locator("h1")).toHaveText("Chat Assistant");
  await expect(page.locator("header p")).toHaveText(
    "Get personalized advice and answers",
  );
  await expect(page.locator("header")).toHaveClass(/gradient-bg/);
  await expect(page.locator('header a[href="index.html"]')).toBeVisible();
  await pause(page);

  // Welcome message from assistant
  const welcomeMessage = page.locator(".assistant-message").first();
  await expect(welcomeMessage).toContainText(
    "Hello! I'm your Crohn's Companion assistant",
  );
  await pause(page, 600);

  // User message about food avoidance
  const userMessage = page.locator(".user-message").first();
  await expect(userMessage).toContainText(
    "What foods should I avoid during a flare-up?",
  );
  await pause(page, 600);

  // Assistant response with food list
  const foodResponse = page.locator(".assistant-message").nth(1);
  await expect(foodResponse).toContainText("High-fiber foods");
  await expect(foodResponse).toContainText("Dairy products");
  await expect(foodResponse).toContainText("Spicy foods");
  await expect(foodResponse).toContainText("Fatty or fried foods");
  await expect(foodResponse).toContainText("Caffeine and alcohol");

  // Screenshot: chat conversation with messages
  await takeAndVerifyScreenshot(page, "08-chat-messages.png");
  await pause(page);

  // User message about supplements for fatigue
  const userMsg2 = page.locator(".user-message").nth(1);
  await expect(userMsg2).toContainText(
    "supplements that could help with my fatigue",
  );
  await pause(page, 600);

  // Assistant response with supplement recommendations
  const supplementResponse = page.locator(".assistant-message").nth(2);
  await expect(supplementResponse).toContainText("Iron supplements");
  await expect(supplementResponse).toContainText("Vitamin B12");
  await expect(supplementResponse).toContainText("Vitamin D");
  await expect(supplementResponse).toContainText("CoQ10");
  await expect(supplementResponse).toContainText("Magnesium");
  await pause(page, 600);

  // Healthcare provider disclaimer
  await expect(supplementResponse).toContainText(
    "Always consult with your healthcare provider",
  );
  await pause(page, 600);

  // Message bubble styling
  const userBubbles = page.locator(".user-message");
  const assistantBubbles = page.locator(".assistant-message");
  await expect(userBubbles.first()).toHaveClass(/user-message/);
  await expect(assistantBubbles.first()).toHaveClass(/assistant-message/);

  // Assistant avatars
  const avatars = page.locator(".gradient-bg.flex.items-center.justify-center");
  expect(await avatars.count()).toBeGreaterThanOrEqual(3);
  await pause(page, 600);

  // Message input
  const input = page.locator('input[type="text"]');
  await expect(input).toBeVisible();
  await expect(input).toHaveAttribute(
    "placeholder",
    "Type your message here...",
  );
  await pause(page, 500);

  // Send button
  const sendButton = page.locator("button.bg-primary");
  await expect(sendButton).toBeVisible();

  // Type a message
  await input.fill("What diet is best for Crohn's?");
  await expect(input).toHaveValue("What diet is best for Crohn's?");

  // Screenshot: input area with typed message
  await takeAndVerifyScreenshot(page, "08-chat-input-typed.png");
  await pause(page, 800);

  // Clear and focus input
  await input.clear();
  await input.click();
  await expect(input).toBeFocused();
  await pause(page, 600);

  // Suggested questions
  await expect(page.locator("text=Suggested questions:")).toBeVisible();
  const suggestions = page.locator(".bg-neutral.text-black.text-xs");
  expect(await suggestions.count()).toBe(3);
  await expect(
    page.locator('button:has-text("What can I eat today?")'),
  ).toBeVisible();
  await expect(
    page.locator('button:has-text("Help with abdominal pain")'),
  ).toBeVisible();
  await expect(
    page.locator('button:has-text("Medication reminders")'),
  ).toBeVisible();

  // Screenshot: the welcome message bubble (distinct from the viewport screenshot)
  await takeElementScreenshot(
    page,
    ".message-bubble.assistant-message",
    "08-chat-welcome-bubble.png",
  );
  await pause(page, 600);

  // Click a suggestion
  const suggestion = page.locator('button:has-text("What can I eat today?")');
  await expect(suggestion).toBeEnabled();
  await suggestion.click();
  await pause(page, 800);

  // Navigation
  await expect(page.locator("nav")).toBeVisible();
  const navItems = page.locator("nav a.nav-item");
  expect(await navItems.count()).toBe(4);
  const chatNav = page.locator("a.nav-item.active");
  await expect(chatNav).toContainText("Chat");
  await expect(page.locator("nav >> text=Home")).toBeVisible();
  await expect(page.locator("nav >> text=Track")).toBeVisible();
  await expect(page.locator("nav >> text=Insights")).toBeVisible();
  await expect(page.locator("nav >> text=Chat")).toBeVisible();
  await pause(page);

  // Device frame
  await expect(page.locator(".device-frame")).toBeVisible();
  await expect(page.locator(".page-container")).toBeVisible();
  await pause(page, 1200);

  await saveVideo(page, "08-chat-assistant.webm");
});
