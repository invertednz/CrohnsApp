import { expect, test, type Locator, type Page } from "@playwright/test";
import { beat, button, field, loginToHome, pageErrors } from "./helpers";

/*
 * Insights (InsightsScreen), opened from Home's "AI insights" button.
 * The offline build computes insights on-device (InsightsGenerator.localInsights);
 * production asks Gemini through Firebase AI Logic with the same data.
 * Covers the getting-started state, refresh, back navigation, and that
 * insights reflect what was logged on the Diet and Daily Tracking screens.
 */

// ---------- area helpers ----------

const CONTENT_TOP = 170;

/**
 * Text as Flutter exposes it: either DOM text of a leaf node or part of a
 * container's aria-label (cards that also hold buttons put their text there).
 */
function shown(page: Page, text: string): Locator {
  return page
    .getByText(text)
    .or(page.locator(`[aria-label*=${JSON.stringify(text)}]`))
    .first();
}

async function reveal(
  page: Page,
  target: Locator,
  bottomInset = 8,
): Promise<void> {
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  await page.mouse.move(vp.width / 2, vp.height / 2 + 100);
  for (const fallback of [1, -1]) {
    for (let i = 0; i < 16; i++) {
      const box =
        (await target.count()) > 0 ? await target.first().boundingBox() : null;
      if (
        box &&
        box.height > 0 &&
        box.y >= CONTENT_TOP &&
        box.y + box.height <= vp.height - bottomInset
      )
        return;
      const direction = box ? (box.y < CONTENT_TOP ? -1 : 1) : fallback;
      await page.mouse.wheel(0, direction * 220);
      await page.waitForTimeout(250);
    }
  }
  await expect(target.first()).toBeVisible();
}

/** A Home button by its exact name (other Home widgets may mention the same words). */
function homeButton(page: Page, name: string): Locator {
  return page.getByRole("button", { name, exact: true });
}

/** Home's buttons: keep clear of its bottom input bar and tab bar. */
async function pressOnHome(page: Page, name: string): Promise<void> {
  const target = homeButton(page, name);
  await reveal(page, target, 170);
  await target.first().click();
}

async function press(page: Page, target: Locator): Promise<void> {
  await reveal(page, target);
  await target.first().click();
}

async function expectShown(page: Page, text: string): Promise<void> {
  const target = shown(page, text);
  await reveal(page, target);
  await expect(target).toBeVisible();
}

/** Snackbars are not in the scrolling list, so just wait for them. */
async function expectNow(page: Page, text: string): Promise<void> {
  await expect(shown(page, text)).toBeVisible();
}

function dayLabel(offsetDays: number): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const monthDay = d.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  if (offsetDays === 0) return `Today, ${monthDay}`;
  return `${d.toLocaleDateString("en-US", { weekday: "long" })}, ${monthDay}`;
}

async function openInsights(page: Page): Promise<void> {
  await pressOnHome(page, "AI insights");
  await expect(button(page, /^Refresh insights/)).toBeVisible();
}

/** Diet screen: add one meal made of typed foods and save it for the shown day. */
async function logMeal(
  page: Page,
  name: string,
  food: string,
  dayText: string,
): Promise<void> {
  await press(page, button(page, /^Add Meal$/));
  const mealName = field(page, /Meal name/).first();
  await mealName.click();
  await mealName.fill(name);
  const foodInput = field(page, /Add a food/).first();
  await foodInput.click();
  await foodInput.fill(food);
  await button(page, /^Add food/).click();
  await button(page, /^Add Meal$/).click();
  await expect(field(page, /Meal name/)).toHaveCount(0);
  await press(page, button(page, /^Save diet log$/));
  await expectNow(page, `Saved your diet log for ${dayText}`);
}

/** Daily Tracking: rate the shown day and save it. */
async function rateDay(
  page: Page,
  feeling: "Terrible" | "Great",
  dayText: string,
): Promise<void> {
  await press(page, page.getByRole("button", { name: feeling, exact: true }));
  if (feeling === "Terrible") {
    // Worst pain: tap the far right end of the pain slider.
    const slider = page
      .getByRole("group", { name: /^Pain level/ })
      .getByRole("slider")
      .locator("..");
    await reveal(page, slider);
    const box = await slider.boundingBox();
    if (!box) throw new Error("Pain slider not rendered");
    await page.mouse.click(box.x + box.width - 2, box.y + box.height / 2);
    await expect(
      page.getByRole("group", { name: /^Pain level\s+10\/10/ }),
    ).toBeVisible();
  }
  await press(page, button(page, /^Save$/));
  await expectNow(page, `Saved your entry for ${dayText}`);
}

async function back(page: Page): Promise<void> {
  await button(page, /^Back\b/).click();
}

// ---------- tests ----------

test.describe("Insights", () => {
  test("AI insights opens a getting-started state when nothing is tracked", async ({
    page,
  }) => {
    await loginToHome(page);
    await openInsights(page);
    await expect(shown(page, "Insights")).toBeVisible();
    await expectShown(page, "Patterns found in the data you have tracked");
    await expectShown(page, "No insights yet");
    await expect(button(page, /^Log how you feel$/)).toBeVisible();
    await expect(button(page, /^Log meals$/)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Back returns to Home", async ({ page }) => {
    await loginToHome(page);
    await openInsights(page);
    await back(page);
    await expect(homeButton(page, "AI insights")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Refresh insights rebuilds them and confirms", async ({ page }) => {
    await loginToHome(page);
    await openInsights(page);
    await button(page, /^Refresh insights/).click();
    await expectNow(page, "Insights refreshed");
    await expect(button(page, /^Refresh insights/)).toBeEnabled();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("logging a day from the empty state turns it into a health summary", async ({
    page,
  }) => {
    await loginToHome(page);
    await openInsights(page);
    await press(page, button(page, /^Log how you feel$/));
    await expect(button(page, "Previous day")).toBeVisible();
    await press(page, page.getByRole("button", { name: "Great", exact: true }));
    await press(page, button(page, /^Save$/));
    await expectNow(page, "Saved your entry for today");
    await back(page);

    await expectShown(page, "Health Summary");
    await expectShown(
      page,
      "Based on 1 rated day: 1 good, 0 okay and 0 tough.",
    );
    await expectShown(page, "Trend: not enough data yet");
    await expectShown(page, "Calculated on your device from your logs");
    await expectShown(page, "Build your baseline");
    await expectShown(
      page,
      "Insights only reflect what you have logged and are not medical advice.",
    );
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a food marked as a trigger appears in insights with honest evidence", async ({
    page,
  }) => {
    await loginToHome(page);
    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await press(page, button(page, /^Add trigger$/));
    const food = field(page, /Food name/).first();
    await food.click();
    await food.fill("Dairy");
    await button(page, /^Add$/).click();
    await press(page, button(page, /^Save diet log$/));
    await expectNow(page, "Saved your diet log for today");
    await back(page);

    await openInsights(page);
    await expectShown(page, "Possible Food Triggers");
    await expectShown(page, "Dairy");
    await expectShown(page, "You marked this as a trigger");
    // No days rated yet, so there is no score or trend rather than a made-up one.
    await expectShown(page, "Wellbeing score not available yet");
    await expectShown(page, "Trend: not enough data yet");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("after a bad day with one food and a good day with another, refreshed insights reflect both", async ({
    page,
  }) => {
    test.setTimeout(240_000);
    await loginToHome(page);
    await openInsights(page);
    await expectShown(page, "No insights yet");
    await back(page);

    // Yesterday: chili for dinner, then a terrible day with the worst pain.
    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await press(page, button(page, "Previous day"));
    await expectShown(page, dayLabel(-1));
    await logMeal(page, "Dinner", "Chili", dayLabel(-1).split(", ")[1]);
    await back(page);
    // Daily Tracking follows the day chosen on the Diet screen.
    await pressOnHome(page, "Add details");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, dayLabel(-1));
    await rateDay(page, "Terrible", dayLabel(-1).split(", ")[1]);

    // Today: a great day.
    await press(page, button(page, "Next day"));
    await expectShown(page, dayLabel(0));
    await rateDay(page, "Great", "today");
    await back(page);
    // ...with oatmeal for lunch.
    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, dayLabel(0));
    await logMeal(page, "Lunch", "Oatmeal", "today");
    await back(page);

    await openInsights(page);
    await button(page, /^Refresh insights/).click();
    await expectNow(page, "Insights refreshed");
    await beat(page);

    await expectShown(
      page,
      "Based on 2 rated days: 1 good, 0 okay and 1 tough. Recent average pain: 5.0/10.",
    );
    await expectShown(page, "Wellbeing score 50 out of 100");
    await expectShown(page, "Chili");
    await expectShown(page, "Eaten on 1 of 1 tough day and 0 of 1 good day");
    await beat(page);
    await expectShown(page, "Oatmeal");
    await expectShown(page, "Eaten on 0 of 1 tough day and 1 of 1 good day");
    await expectShown(page, "Test a possible trigger");
    await expectShown(page, "Chili was eaten on 1 of your 1 tough day.");
    await expectShown(page, "Talk to your care team");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});
