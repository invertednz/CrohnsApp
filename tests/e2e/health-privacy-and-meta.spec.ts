import { test, expect } from "@playwright/test";

const ALL_PAGES = [
  { name: "Home", path: "/index.html", title: "Crohn's Companion" },
  {
    name: "Tracking",
    path: "/tracking.html",
    title: "Daily Tracking | Crohn's Companion",
  },
  {
    name: "Symptoms",
    path: "/symptoms.html",
    title: "Symptoms Tracker | Crohn's Companion",
  },
  {
    name: "Diet",
    path: "/diet.html",
    title: "Diet Tracker | Crohn's Companion",
  },
  {
    name: "Supplements",
    path: "/supplements.html",
    title: "Supplements Tracker | Crohn's Companion",
  },
  {
    name: "Insights",
    path: "/insights.html",
    title: "Insights | Crohn's Companion",
  },
  {
    name: "Chat",
    path: "/chat.html",
    title: "Chat Assistant | Crohn's Companion",
  },
  {
    name: "Notifications",
    path: "/notification_preferences_preview.html",
    title: "Crohn's Companion – Notification Preferences",
  },
];

test.describe("Meta Tags and Accessibility Across All Pages", () => {
  for (const pg of ALL_PAGES) {
    test.describe(`${pg.name} page`, () => {
      test(`should have lang="en" on html element`, async ({ page }) => {
        await page.goto(pg.path);
        expect(await page.locator("html").getAttribute("lang")).toBe("en");
      });

      test("should have a non-empty page title", async ({ page }) => {
        await page.goto(pg.path);
        const title = await page.title();
        expect(title.length).toBeGreaterThan(0);
      });

      test("should have meta viewport tag", async ({ page }) => {
        await page.goto(pg.path);
        const viewport = page.locator('meta[name="viewport"]');
        await expect(viewport).toHaveAttribute("content", /width=device-width/);
      });

      test("should have meta charset", async ({ page }) => {
        await page.goto(pg.path);
        const charset = page.locator('meta[charset="UTF-8"]');
        expect(await charset.count()).toBe(1);
      });

      test("should have exactly one h1 heading", async ({ page }) => {
        await page.goto(pg.path);
        expect(await page.locator("h1").count()).toBe(1);
      });

      // Notification preferences is a standalone page without nav
      if (pg.name !== "Notifications") {
        test("nav links should exist", async ({ page }) => {
          await page.goto(pg.path);
          const nav = page.locator("nav");
          await expect(nav).toBeAttached();
        });
      }
    });
  }
});

test.describe("Health Data Privacy - Apple Review Compliance", () => {
  test("Chat page should display healthcare provider disclaimer", async ({
    page,
  }) => {
    await page.goto("/chat.html");
    await expect(
      page.locator("text=Always consult with your healthcare provider"),
    ).toBeVisible();
  });

  test("Insights page should not collect personal identifiers", async ({
    page,
  }) => {
    await page.goto("/insights.html");
    // Insights should display health data without asking for PII
    await expect(page.locator("text=Your Health Summary")).toBeVisible();
    // No login/email/phone fields on health data pages
    expect(await page.locator('input[type="email"]').count()).toBe(0);
    expect(await page.locator('input[type="tel"]').count()).toBe(0);
  });

  test("Tracking page should not expose data in URL", async ({ page }) => {
    await page.goto("/tracking.html");
    expect(page.url()).not.toContain("userId");
    expect(page.url()).not.toContain("token");
    expect(page.url()).not.toContain("session");
  });

  test("Symptoms page should not expose health data in query params", async ({
    page,
  }) => {
    await page.goto("/symptoms.html");
    // URL path name is fine, check that no query params leak health data
    const url = new URL(page.url());
    expect(url.search).toBe("");
    expect(page.url()).not.toContain("userId");
    expect(page.url()).not.toContain("diagnosis");
  });
});

test.describe("Keyboard Navigation Across Pages", () => {
  const pagesToTest = [
    { name: "Chat", path: "/chat.html" },
    { name: "Insights", path: "/insights.html" },
    { name: "Supplements", path: "/supplements.html" },
    { name: "Notifications", path: "/notification_preferences_preview.html" },
  ];

  for (const pg of pagesToTest) {
    test(`${pg.name}: Tab key should move focus to visible elements`, async ({
      page,
    }) => {
      await page.goto(pg.path);
      await page.keyboard.press("Tab");
      const focused = page.locator(":focus");
      await expect(focused).toBeVisible();
    });
  }
});

test.describe("Landscape Orientation", () => {
  test.use({ viewport: { width: 812, height: 375 } });

  const pages = [
    { name: "Home", path: "/index.html" },
    { name: "Chat", path: "/chat.html" },
    { name: "Tracking", path: "/tracking.html" },
    { name: "Diet", path: "/diet.html" },
  ];

  for (const pg of pages) {
    test(`${pg.name} should render in landscape without horizontal overflow`, async ({
      page,
    }) => {
      await page.goto(pg.path);
      await expect(page.locator("h1")).toBeVisible();
      const bodyWidth = await page.evaluate(() => document.body.scrollWidth);
      const viewportWidth = await page.evaluate(() => window.innerWidth);
      expect(bodyWidth).toBeLessThanOrEqual(viewportWidth + 1);
    });
  }
});

test.describe("Responsive - All Pages", () => {
  const viewports = [
    { name: "iPhone SE", width: 375, height: 667 },
    { name: "iPad", width: 768, height: 1024 },
    { name: "Desktop", width: 1280, height: 720 },
  ];

  const newPages = [
    { name: "Home", path: "/index.html" },
    { name: "Tracking", path: "/tracking.html" },
    { name: "Diet", path: "/diet.html" },
    { name: "Symptoms", path: "/symptoms.html" },
  ];

  for (const viewport of viewports) {
    test.describe(`${viewport.name} (${viewport.width}x${viewport.height})`, () => {
      test.use({
        viewport: { width: viewport.width, height: viewport.height },
      });

      for (const pg of newPages) {
        test(`${pg.name} page should render correctly`, async ({ page }) => {
          await page.goto(pg.path);
          await expect(page.locator("h1")).toBeVisible();
          await expect(page.locator("nav")).toBeAttached();
        });
      }
    });
  }
});
