import { test, expect } from "@playwright/test";

test.describe("Symptoms Tracker Page", () => {
  test.beforeEach(async ({ page }) => {
    await page.goto("/symptoms.html");
  });

  test.describe("Page Structure", () => {
    test("should load with correct title", async ({ page }) => {
      await expect(page).toHaveTitle("Symptoms Tracker | Crohn's Companion");
    });

    test("should display header heading", async ({ page }) => {
      await expect(page.locator("h1")).toHaveText("Symptoms Tracker");
    });

    test("should display header subtitle", async ({ page }) => {
      await expect(page.locator("header p")).toHaveText(
        "Monitor and track your symptoms",
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

  test.describe("Common Symptoms Tags", () => {
    test("should display Common Symptoms heading", async ({ page }) => {
      await expect(page.locator("text=Common Symptoms")).toBeVisible();
    });

    test("should list all common symptom tags", async ({ page }) => {
      const expectedSymptoms = [
        "Abdominal Pain",
        "Diarrhea",
        "Fatigue",
        "Nausea",
        "Bloating",
        "Joint Pain",
        "Fever",
        "Weight Loss",
      ];
      for (const symptom of expectedSymptoms) {
        await expect(
          page.locator(`.symptom-tag:has-text("${symptom}")`),
        ).toBeVisible();
      }
    });

    test("should have Add New tag", async ({ page }) => {
      await expect(
        page.locator('.symptom-tag:has-text("+ Add New")'),
      ).toBeVisible();
    });

    test("should show active symptoms highlighted", async ({ page }) => {
      const activeTags = page.locator(".symptom-tag.active");
      expect(await activeTags.count()).toBe(2);
      await expect(
        page.locator('.symptom-tag.active:has-text("Abdominal Pain")'),
      ).toBeVisible();
      await expect(
        page.locator('.symptom-tag.active:has-text("Fatigue")'),
      ).toBeVisible();
    });
  });

  test.describe("Active Symptoms Section", () => {
    test("should display Active Symptoms heading", async ({ page }) => {
      await expect(page.locator("text=Active Symptoms")).toBeVisible();
    });

    test("should have add symptom button", async ({ page }) => {
      const addBtn = page.locator(".bg-primary.rounded-full");
      expect(await addBtn.count()).toBeGreaterThanOrEqual(1);
    });

    test("should show Abdominal Pain entry", async ({ page }) => {
      await expect(
        page.locator(".bg-neutral >> text=Abdominal Pain"),
      ).toBeVisible();
      await expect(page.locator("text=Moderate")).toBeVisible();
      await expect(
        page.locator("text=Lower right quadrant, worse after eating."),
      ).toBeVisible();
    });

    test("should show severity indicators", async ({ page }) => {
      // Red dot for moderate
      await expect(page.locator(".bg-red-500")).toBeVisible();
      // Yellow dot for mild
      await expect(page.locator(".bg-yellow-500")).toBeVisible();
    });

    test("should show Fatigue entry", async ({ page }) => {
      const fatigueSection = page.locator(".bg-neutral:has-text('Fatigue')");
      await expect(fatigueSection).toBeVisible();
      await expect(page.locator("text=Mild")).toBeVisible();
      await expect(
        page.locator("text=General tiredness throughout the day."),
      ).toBeVisible();
    });

    test("should show start times", async ({ page }) => {
      await expect(page.locator("text=Started: Today, 8:30 AM")).toBeVisible();
      await expect(
        page.locator("text=Started: Yesterday, 6:00 PM"),
      ).toBeVisible();
    });

    test("should have Update buttons", async ({ page }) => {
      const updateButtons = page.locator('button:has-text("Update")');
      expect(await updateButtons.count()).toBe(2);
    });
  });

  test.describe("Symptom History Section", () => {
    test("should display Symptom History heading", async ({ page }) => {
      await expect(page.locator("text=Symptom History")).toBeVisible();
    });

    test("should show past Nausea entry", async ({ page }) => {
      await expect(page.locator("text=May 12-14")).toBeVisible();
      await expect(
        page.locator("text=Morning nausea, resolved after medication."),
      ).toBeVisible();
    });

    test("should show past Joint Pain entry", async ({ page }) => {
      await expect(page.locator("text=May 10-13")).toBeVisible();
      await expect(
        page.locator("text=Knees and ankles, worse in the morning."),
      ).toBeVisible();
    });

    test("should show past Bloating entry", async ({ page }) => {
      await expect(
        page.locator(".bg-white.rounded-xl >> text=Bloating"),
      ).toBeVisible();
      await expect(page.locator("text=May 8-11")).toBeVisible();
      await expect(
        page.locator("text=After meals, especially dairy products."),
      ).toBeVisible();
    });
  });

  test.describe("Navigation", () => {
    test("should have bottom navigation", async ({ page }) => {
      await expect(page.locator("nav")).toBeVisible();
    });

    test("should have nav links", async ({ page }) => {
      await expect(page.locator('nav a[href="index.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="tracking.html"]')).toBeVisible();
      await expect(page.locator('nav a[href="diet.html"]')).toBeVisible();
    });

    test("back button should navigate to home", async ({ page }) => {
      await page.locator('header a[href="index.html"]').click();
      await expect(page).toHaveTitle("Crohn's Companion");
    });
  });
});
