import { expect, test, type Locator, type Page } from "@playwright/test";
import { beat, button, field, loginToHome, pageErrors } from "./helpers";

/*
 * Diet Tracker (DietScreen), opened from Home's "Meals & triggers" button.
 * Covers adding meals (meal-type chips, common foods, typed foods), dialog
 * validation, removing meals, food triggers / safe foods, saving to the
 * backend, persistence across navigation and days, and the unsaved-changes
 * prompt.
 */

// ---------- area helpers ----------

/** Visible content under the gradient header (px from the top of the viewport). */
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

/** Wheel-scroll the diet list until `target` sits fully inside the visible content area. */
async function reveal(
  page: Page,
  target: Locator,
  bottomInset = 8,
): Promise<void> {
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  await page.mouse.move(vp.width / 2, vp.height / 2 + 100);
  for (const fallback of [1, -1]) {
    for (let i = 0; i < 14; i++) {
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

/** Snackbars and dialogs are not in the scrolling list, so just wait for them. */
async function expectNow(page: Page, text: string): Promise<void> {
  await expect(shown(page, text)).toBeVisible();
}

async function expectShown(page: Page, text: string): Promise<void> {
  const target = shown(page, text);
  await reveal(page, target);
  await expect(target).toBeVisible();
}

/** Flutter chips are exposed as checkboxes named by their label (exact word match). */
function chip(page: Page, name: string): Locator {
  const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return page.getByRole("checkbox", { name: new RegExp(`^${escaped}(\\s|$)`) });
}

/** Controls inside an open dialog (dialogs are centred, so no list scrolling is needed). */
async function dialogFill(
  page: Page,
  label: RegExp,
  value: string,
): Promise<void> {
  const input = field(page, label).first();
  await input.click();
  await input.fill(value);
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

async function openDiet(page: Page): Promise<void> {
  await loginToHome(page);
  await pressOnHome(page, "Meals & triggers");
  await expect(shown(page, "Diet Tracker")).toBeVisible();
  await expect(button(page, "Previous day")).toBeVisible();
}

/** Adds a meal through the dialog: meal name, then typed foods and common-food chips. */
async function addMeal(
  page: Page,
  name: string,
  typed: string[],
  common: string[] = [],
): Promise<void> {
  await press(page, button(page, /^Add Meal$/));
  await expect(
    page.getByRole("dialog").or(page.getByRole("alertdialog")).first(),
  ).toBeVisible();
  await dialogFill(page, /Meal name/, name);
  for (const food of typed) {
    await dialogFill(page, /Add a food/, food);
    await button(page, /^Add food/).click();
    await expect(chip(page, food)).toBeVisible();
  }
  for (const food of common) {
    await chip(page, food).click();
    // The common-food chip (listed after the selected foods) is now ticked.
    await expect(chip(page, food).last()).toBeChecked();
  }
  await beat(page);
  await button(page, /^Add Meal$/).click();
  await expect(field(page, /Meal name/)).toHaveCount(0);
}

async function tagFood(
  page: Page,
  kind: "trigger" | "safe food",
  typed: string,
): Promise<void> {
  await press(
    page,
    button(page, kind === "trigger" ? /^Add trigger$/ : /^Add safe food$/),
  );
  await expectNow(
    page,
    kind === "trigger" ? "Add Food Trigger" : "Add Safe Food",
  );
  await dialogFill(page, /Food name/, typed);
  await button(page, /^Add$/).click();
  await expect(field(page, /Food name/)).toHaveCount(0);
}

async function saveDiet(page: Page, dayText = "today"): Promise<void> {
  await press(page, button(page, /^Save diet log$/));
  await expectNow(page, `Saved your diet log for ${dayText}`);
}

async function backToHome(page: Page): Promise<void> {
  await button(page, /^Back\b/).click();
  await expect(homeButton(page, "Meals & triggers")).toBeVisible();
}

// ---------- tests ----------

test.describe("Diet tracker", () => {
  test("Meals & triggers opens today's diet log with helpful empty states", async ({
    page,
  }) => {
    await openDiet(page);
    await expectShown(page, dayLabel(0));
    await expect(button(page, /^Back\b/)).toBeVisible();
    await expect(button(page, "Next day")).toBeDisabled();
    await expect(button(page, /^Add Meal$/)).toBeVisible();
    await expectShown(page, "No meals logged for this day");
    await expectShown(page, 'Tap "Add Meal" to log what you ate');
    await expectShown(
      page,
      "No trigger foods yet. Add foods that seem to upset your gut.",
    );
    await expectShown(page, "No safe foods yet. Add foods you tolerate well.");
    await reveal(page, button(page, /^Add trigger$/));
    await reveal(page, button(page, /^Add safe food$/));
    await reveal(page, button(page, /^Save diet log$/));
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Add Meal dialog explains what is missing and Cancel adds nothing", async ({
    page,
  }) => {
    await openDiet(page);
    await press(page, button(page, /^Add Meal$/));
    await expect(field(page, /Meal name/)).toBeVisible();
    await button(page, /^Add Meal$/).click();
    await expectNow(page, "Enter a meal name");
    await expectNow(page, "Add at least one food");
    await beat(page);
    await button(page, /^Cancel$/).click();
    await expect(field(page, /Meal name/)).toHaveCount(0);
    await expectShown(page, "No meals logged for this day");
    expect(pageErrors(page)).toEqual([]);
  });

  test("builds a meal from a meal-type chip, common foods and typed foods", async ({
    page,
  }) => {
    await openDiet(page);
    await press(page, button(page, /^Add Meal$/));
    await chip(page, "Breakfast").click();
    await expect(chip(page, "Breakfast")).toBeChecked();
    await chip(page, "Eggs").click();
    await chip(page, "Bread").click();
    await expect(chip(page, "Eggs").last()).toBeChecked();
    await dialogFill(page, /Add a food/, "Avocado");
    await button(page, /^Add food/).click();
    // A selected food can be taken back out before adding the meal.
    await button(page, /^Remove Bread/).click();
    await expect(chip(page, "Bread")).not.toBeChecked();
    // A food typed but not yet added with + is still included.
    await dialogFill(page, /Add a food/, "Tea with oat milk");
    await beat(page);
    await button(page, /^Add Meal$/).click();

    await expectShown(page, "Today's Meals");
    await expectShown(page, "Breakfast");
    for (const food of ["Eggs", "Avocado", "Tea with oat milk"]) {
      await expect(chip(page, food)).toBeVisible();
    }
    await expect(chip(page, "Bread")).toHaveCount(0);
    await expect(button(page, /^Remove Breakfast/)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("saved meals, triggers and safe foods reload after going back to Home", async ({
    page,
  }) => {
    await openDiet(page);
    await addMeal(page, "Lunch", ["Chicken soup"], ["Rice"]);
    await tagFood(page, "trigger", "Dairy");
    await tagFood(page, "safe food", "Rice");
    await expect(chip(page, "Dairy")).toBeVisible();
    await expect(button(page, /^Remove Dairy from triggers/)).toBeVisible();
    await expect(button(page, /^Remove Rice from safe foods/)).toBeVisible();
    await saveDiet(page);
    await beat(page);

    await backToHome(page);
    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, "Lunch");
    await expect(chip(page, "Chicken soup")).toBeVisible();
    await reveal(page, button(page, /^Remove Dairy from triggers/));
    await reveal(page, button(page, /^Remove Rice from safe foods/));
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("removing a meal and a trigger is saved", async ({ page }) => {
    await openDiet(page);
    await addMeal(page, "Dinner", ["Pasta bake"]);
    await tagFood(page, "trigger", "Garlic");
    await saveDiet(page);

    await press(page, button(page, /^Remove Dinner/));
    await expectShown(page, "No meals logged for this day");
    await press(page, button(page, /^Remove Garlic from triggers/));
    await expectShown(
      page,
      "No trigger foods yet. Add foods that seem to upset your gut.",
    );
    await beat(page);
    await saveDiet(page);

    await backToHome(page);
    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, "No meals logged for this day");
    await expectShown(
      page,
      "No trigger foods yet. Add foods that seem to upset your gut.",
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("a food can't be both a trigger and a safe food", async ({ page }) => {
    await openDiet(page);
    await tagFood(page, "safe food", "Coffee");
    await expect(button(page, /^Remove Coffee from safe foods/)).toBeVisible();
    await press(page, button(page, /^Add trigger$/));
    // Picking an already-listed food chip also works.
    await chip(page, "Coffee").click();
    await button(page, /^Add$/).click();
    await expectNow(page, "Coffee moved to food triggers");
    await expect(button(page, /^Remove Coffee from triggers/)).toBeVisible();
    await expectShown(page, "No safe foods yet. Add foods you tolerate well.");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the add-trigger dialog asks for a food when nothing is chosen", async ({
    page,
  }) => {
    await openDiet(page);
    await press(page, button(page, /^Add trigger$/));
    await button(page, /^Add$/).click();
    await expectNow(page, "Type a food or pick one below");
    await beat(page);
    await button(page, /^Cancel$/).click();
    await expectShown(
      page,
      "No trigger foods yet. Add foods that seem to upset your gut.",
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("meals belong to a day while triggers carry across days", async ({
    page,
  }) => {
    await openDiet(page);
    await addMeal(page, "Snack", ["Crackers"]);
    await tagFood(page, "trigger", "Onion");
    await saveDiet(page);

    await press(page, button(page, "Previous day"));
    await expectShown(page, dayLabel(-1));
    await expectShown(page, "No meals logged for this day");
    await reveal(page, button(page, /^Remove Onion from triggers/));
    await beat(page);
    await addMeal(page, "Dinner", ["Stew"]);
    await saveDiet(page, dayLabel(-1).split(", ")[1]);

    await press(page, button(page, "Next day"));
    await expectShown(page, dayLabel(0));
    await expectShown(page, "Snack");
    await expect(chip(page, "Crackers")).toBeVisible();
    await expect(chip(page, "Stew")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("leaving with unsaved changes asks first; Discard drops them", async ({
    page,
  }) => {
    await openDiet(page);
    await addMeal(page, "Brunch", ["Pancakes"]);
    await button(page, /^Back\b/).click();
    await expectNow(page, "Save your changes?");
    await beat(page);
    await button(page, /^Discard$/).click();
    await expect(homeButton(page, "Meals & triggers")).toBeVisible();

    await pressOnHome(page, "Meals & triggers");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, "No meals logged for this day");
    expect(pageErrors(page)).toEqual([]);
  });

  test("Save changes in the leave prompt keeps the new meal", async ({
    page,
  }) => {
    await openDiet(page);
    await addMeal(page, "Supper", ["Toast"]);
    await press(page, button(page, "Previous day"));
    await expectNow(page, "Save your changes?");
    await button(page, /^Save changes$/).click();
    await expectShown(page, dayLabel(-1));
    await beat(page);
    await press(page, button(page, "Next day"));
    await expectShown(page, "Supper");
    await expect(chip(page, "Toast")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });
});
