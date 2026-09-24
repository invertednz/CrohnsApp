import path from "path";
import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  beat,
  button,
  expectText,
  field,
  loginToHome,
  onScreen,
  openTab,
  pageErrors,
  scrollUntilVisible,
  type,
} from "./helpers";

/**
 * Home dashboard: daily check-in (feeling, bowel motions, supplements /
 * medications / diet), stats computed from tracked data, the free-text and
 * meal-photo Daily Log, calendar day switching, section shortcuts and sign out.
 *
 * Everything on Home is saved through the backend, so "persistence" here
 * means: the value survives switching tabs, switching days, and signing out
 * and back in (the offline build keeps its in-memory backend for the page).
 */

const LOG_FIELD = "What did you eat, do, or feel?";
const MEAL_PHOTO = path.join(__dirname, "fixtures", "meal.jpg");

/** A single choice in a radio group (feelings, "Had All" / "Different"). */
function radio(page: Page, name: string): Locator {
  return page.getByRole("radio", { name, exact: true });
}

async function choose(page: Page, name: string): Promise<void> {
  const option = radio(page, name);
  await scrollUntilVisible(page, option);
  await option.click();
  await expect(option).toBeChecked();
}

async function expectChecked(
  page: Page,
  name: string,
  checked = true,
): Promise<void> {
  const option = radio(page, name);
  await scrollUntilVisible(page, option);
  await expect(option).toBeChecked({ checked });
}

/** Calendar day button, e.g. "Today 24 Sep" / "Yesterday 23 Sep". */
function day(page: Page, label: "Today" | "Yesterday"): Locator {
  return page.getByRole("button", { name: new RegExp(`^${label}\\b`) });
}

async function selectDay(
  page: Page,
  label: "Today" | "Yesterday",
): Promise<void> {
  const target = day(page, label);
  await scrollUntilVisible(page, target);
  await target.click();
  await expect(target).toHaveAttribute("aria-current", "true");
}

/**
 * Icon buttons whose name comes from a tooltip. While the mouse rests on one,
 * Flutter shows the tooltip and links it with aria-owns, so the accessible
 * name becomes e.g. "Add bowel motion Add bowel motion". Match the start of
 * the name only, so repeated clicks keep finding the same button.
 */
const ADD_BOWEL = /^Add bowel motion/;
const REMOVE_BOWEL = /^Remove bowel motion/;
const ADD_LOG = /^Add log/;

async function addBowelMotion(page: Page, times = 1): Promise<void> {
  const add = button(page, ADD_BOWEL);
  await scrollUntilVisible(page, add);
  for (let i = 0; i < times; i++) await add.click();
}

async function addLog(page: Page, text: string): Promise<void> {
  await type(page, LOG_FIELD, text);
  await button(page, ADD_LOG).click();
  await expectText(page, text);
}

/**
 * Leave a pushed screen with its on-screen Back button, or the browser/system
 * back button when the screen has no named one, and check Home is showing.
 */
async function goBack(page: Page, screenTitle: string): Promise<void> {
  const back = button(page, /^Back$/).first();
  if ((await back.count()) > 0 && (await back.isVisible())) {
    await back.click();
  } else {
    await page.goBack();
  }
  await expect(page.getByText(screenTitle, { exact: true })).toHaveCount(0);
  await expect(button(page, /^Home.*Tab 1 of 5/)).toBeVisible();
}

async function signOut(page: Page): Promise<void> {
  await button(page, /^Sign out$/).click();
  await expect(
    page.getByText("Are you sure you want to sign out?"),
  ).toBeVisible();
  await beat(page);
  await button(page, /^Sign Out$/).click();
  await expect(field(page, "Email")).toBeVisible({ timeout: 20_000 });
}

async function signIn(page: Page, email: string): Promise<void> {
  await type(page, "Email", email);
  await type(page, "Password", "password123");
  await button(page, /^Sign In$/).click();
  await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 20_000 });
}

test.describe("Home dashboard", () => {
  test("a new user sees every section with honest, empty stats", async ({
    page,
  }) => {
    await loginToHome(page);

    await expect(page.getByText("GutMD", { exact: true })).toBeVisible();
    await expect(
      page.getByRole("heading", { name: "How are you feeling?" }),
    ).toBeVisible();
    await expect(page.getByText("Current streak: 0 days")).toBeVisible();
    for (const feeling of ["Terrible", "Bad", "Okay", "Good", "Great"]) {
      await expect(radio(page, feeling)).not.toBeChecked();
    }
    await expectText(page, "Bowel motions: 0");
    await expect(button(page, REMOVE_BOWEL)).toBeDisabled();
    for (const card of ["Supplements", "Medications", "Diet"]) {
      await expectChecked(page, `${card}: Had All`, false);
      await expectChecked(page, `${card}: Different`, false);
    }
    await beat(page);

    await expectText(page, "Days tracked in the last 30 days: 0");
    await expectText(page, "Average feeling: no entries in the last 30 days");
    await expectText(page, "Streak: 0 days");
    await expectText(
      page,
      "Start tracking today to see your patterns and insights!",
    );
    await expectText(page, "No logs for this day yet.");
    await beat(page);

    // Icon-only controls have accessible names.
    await expect(button(page, /^Sign out$/)).toBeVisible();
    await expect(button(page, /^Add meal photo$/)).toBeVisible();
    await expect(button(page, ADD_LOG)).toBeVisible();
    await expect(field(page, LOG_FIELD)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("choosing how you feel is saved and survives switching tabs", async ({
    page,
  }) => {
    await loginToHome(page);

    await choose(page, "Good");
    await beat(page);
    await choose(page, "Great");
    await expectChecked(page, "Good", false);
    await expect(page.getByText("Current streak: 1 day")).toBeVisible();
    await beat(page);

    await openTab(page, "Symptoms");
    await openTab(page, "Chat");
    await openTab(page, "Home");
    await expectChecked(page, "Great");
    await expectChecked(page, "Good", false);
    expect(pageErrors(page)).toEqual([]);
  });

  test("bowel motion counter adds and removes, never goes below zero, and is kept across tabs", async ({
    page,
  }) => {
    await loginToHome(page);

    await addBowelMotion(page, 3);
    await expectText(page, "Bowel motions: 3");
    await beat(page);
    await button(page, REMOVE_BOWEL).click();
    await expectText(page, "Bowel motions: 2");

    await openTab(page, "Meds");
    await openTab(page, "Home");
    await expectText(page, "Bowel motions: 2");

    const remove = button(page, REMOVE_BOWEL);
    await remove.click();
    await remove.click();
    await expectText(page, "Bowel motions: 0");
    await expect(remove).toBeDisabled();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Had All / Different choices are saved per card and kept across tabs", async ({
    page,
  }) => {
    await loginToHome(page);

    await choose(page, "Medications: Had All");
    await choose(page, "Supplements: Had All");
    // Diet has no tab of its own, so "Different" stays on Home.
    await choose(page, "Diet: Different");
    await expect(button(page, /^Home.*Tab 1 of 5/)).toHaveAttribute(
      "aria-current",
      "true",
    );
    await beat(page);

    // Changing your mind switches the choice within the card only.
    await choose(page, "Diet: Had All");
    await expectChecked(page, "Diet: Different", false);
    await expectChecked(page, "Medications: Had All");

    await openTab(page, "Supps");
    await openTab(page, "Home");
    await expectChecked(page, "Supplements: Had All");
    await expectChecked(page, "Medications: Had All");
    await expectChecked(page, "Diet: Had All");
    expect(pageErrors(page)).toEqual([]);
  });

  test('"Different" for supplements or medications opens that tab to log the details', async ({
    page,
  }) => {
    await loginToHome(page);

    const supplementsDifferent = radio(page, "Supplements: Different");
    await scrollUntilVisible(page, supplementsDifferent);
    await supplementsDifferent.click();
    await expect(button(page, /^Supps.*Tab 3 of 5/)).toHaveAttribute(
      "aria-current",
      "true",
    );
    await beat(page);

    await openTab(page, "Home");
    await expectChecked(page, "Supplements: Different");

    const medicationsDifferent = radio(page, "Medications: Different");
    await scrollUntilVisible(page, medicationsDifferent);
    await medicationsDifferent.click();
    await expect(button(page, /^Meds.*Tab 4 of 5/)).toHaveAttribute(
      "aria-current",
      "true",
    );
    await beat(page);

    await openTab(page, "Home");
    await expectChecked(page, "Medications: Different");
    expect(pageErrors(page)).toEqual([]);
  });

  test("each calendar day keeps its own feeling, bowel motions and logs", async ({
    page,
  }) => {
    await loginToHome(page);
    await expect(day(page, "Today")).toHaveAttribute("aria-current", "true");

    await choose(page, "Great");
    await addBowelMotion(page, 2);
    await expectText(page, "Bowel motions: 2");
    await addLog(page, "Rice and salmon for dinner");
    await beat(page);

    await selectDay(page, "Yesterday");
    await expect(day(page, "Today")).toHaveAttribute("aria-current", "false");
    await expectText(page, "Bowel motions: 0");
    await expectChecked(page, "Great", false);
    await expectText(page, "No logs for this day yet.");
    await choose(page, "Bad");
    await addLog(page, "Takeaway curry");
    await beat(page);

    await selectDay(page, "Today");
    await expectChecked(page, "Great");
    await expectChecked(page, "Bad", false);
    await expectText(page, "Bowel motions: 2");
    await expectText(page, "Rice and salmon for dinner");
    await expect(page.getByText("Takeaway curry")).toHaveCount(0);
    await beat(page);

    await selectDay(page, "Yesterday");
    await expectChecked(page, "Bad");
    await expectText(page, "Takeaway curry");
    await expect(page.getByText("Rice and salmon for dinner")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("streak and 30-day stats are computed from what you actually track", async ({
    page,
  }) => {
    await loginToHome(page);
    await expect(page.getByText("Current streak: 0 days")).toBeVisible();

    await choose(page, "Great");
    await expect(page.getByText("Current streak: 1 day")).toBeVisible();
    await expectText(page, "Days tracked in the last 30 days: 1");
    await expectText(
      page,
      "Average feeling, last 30 days: 5.0 out of 5 (Great)",
    );
    await beat(page);

    await selectDay(page, "Yesterday");
    await choose(page, "Okay");
    await choose(page, "Supplements: Had All");
    await expect(page.getByText("Current streak: 2 days")).toBeVisible();
    await expectText(page, "Days tracked in the last 30 days: 2");
    // (Great = 5 + Okay = 3) / 2 on a 1-5 scale.
    await expectText(
      page,
      "Average feeling, last 30 days: 4.0 out of 5 (Good)",
    );
    await expectText(page, "Streak: 2 days");
    await expectText(page, "had all supplements on 1 day");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a typed log entry is saved with an honest offline analysis (no made-up score)", async ({
    page,
  }) => {
    await loginToHome(page);

    await addLog(page, "Coffee and toast for breakfast");
    await expectText(page, "Possible triggers: Coffee (caffeine)");
    await expectText(page, "Not scored");
    await expectText(
      page,
      "No AI analysis · common-trigger keyword check only",
    );
    await expect(field(page, LOG_FIELD)).toHaveValue("");
    await expect(page.getByText("No logs for this day yet.")).toHaveCount(0);
    await beat(page);

    // Logging counts as tracking.
    await expect(page.getByText("Current streak: 1 day")).toBeVisible();

    await openTab(page, "Symptoms");
    await openTab(page, "Home");
    await expectText(page, "Coffee and toast for breakfast");
    expect(pageErrors(page)).toEqual([]);
  });

  test("symptoms mentioned in a log are picked up and negated ones are ignored", async ({
    page,
  }) => {
    await loginToHome(page);

    await addLog(page, "Bloated and crampy after lunch, no nausea");
    await expectText(page, "Symptoms: Cramping, Bloating");
    await expect(page.getByText(/Nausea/)).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("pressing Enter in the log field adds the entry", async ({ page }) => {
    await loginToHome(page);

    await type(page, LOG_FIELD, "Walked for 30 minutes");
    await field(page, LOG_FIELD).press("Enter");
    await expectText(page, "Walked for 30 minutes");
    await expect(field(page, LOG_FIELD)).toHaveValue("");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("adding an empty log shows a hint instead of saving", async ({
    page,
  }) => {
    await loginToHome(page);

    await button(page, ADD_LOG).click();
    await expect(
      onScreen(page).getByText("Type what you ate, did or felt first."),
    ).toBeVisible();
    await beat(page);
    await expectText(page, "No logs for this day yet.");

    // The hint does not cover the input: a real entry can be added straight away.
    await addLog(page, "Plain porridge");
    expect(pageErrors(page)).toEqual([]);
  });

  test("a meal photo is analysed and added to the Daily Logs", async ({
    page,
  }) => {
    await loginToHome(page);

    const chooser = page.waitForEvent("filechooser");
    await button(page, /^Add meal photo$/).click();
    await (await chooser).setFiles(MEAL_PHOTO);

    // The offline build returns a fixed sample analysis and says so.
    await expectText(
      page,
      "A balanced meal with lean protein, simple carbs, and vegetables",
    );
    await expectText(
      page,
      "Foods: Grilled chicken, White rice, Steamed vegetables",
    );
    await expectText(
      page,
      "Possible triggers: Broccoli (high fiber), Possible seasoning",
    );
    await expectText(page, "Sample analysis (offline mode)");
    await expectText(page, "Not scored");
    await beat(page);

    await selectDay(page, "Yesterday");
    await expectText(page, "No logs for this day yet.");
    await selectDay(page, "Today");
    await expectText(
      page,
      "Foods: Grilled chicken, White rice, Steamed vegetables",
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("everything logged on Home is still there after signing out and back in", async ({
    page,
  }) => {
    await loginToHome(page, "persist@gutmd.app");

    await choose(page, "Good");
    await addBowelMotion(page, 2);
    await expectText(page, "Bowel motions: 2");
    await choose(page, "Diet: Had All");
    await addLog(page, "Banana and oat milk smoothie");
    await beat(page);

    await signOut(page);
    await signIn(page, "persist@gutmd.app");

    await expectChecked(page, "Good");
    await expectText(page, "Bowel motions: 2");
    await expectChecked(page, "Diet: Had All");
    await expectText(page, "Banana and oat milk smoothie");
    await expect(page.getByText("Current streak: 1 day")).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("another account starts with its own empty dashboard", async ({
    page,
  }) => {
    await loginToHome(page, "first@gutmd.app");
    await choose(page, "Terrible");
    await addLog(page, "Stomach ache all afternoon");

    await signOut(page);
    await signIn(page, "second@gutmd.app");

    await expectChecked(page, "Terrible", false);
    await expect(page.getByText("Current streak: 0 days")).toBeVisible();
    await expectText(page, "No logs for this day yet.");
    await expect(page.getByText("Stomach ache all afternoon")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("signing out can be cancelled", async ({ page }) => {
    await loginToHome(page);

    await button(page, /^Sign out$/).click();
    await expect(
      page.getByText("Are you sure you want to sign out?"),
    ).toBeVisible();
    await beat(page);
    await button(page, /^Cancel$/).click();
    await expect(
      page.getByText("Are you sure you want to sign out?"),
    ).toHaveCount(0);
    await expect(button(page, /^Home.*Tab 1 of 5/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test('"Add details" opens Daily Tracking and returns to Home', async ({
    page,
  }) => {
    await loginToHome(page);
    await choose(page, "Great");

    await button(page, /^Add details$/).click();
    await expect(page.getByText("Daily Tracking")).toBeVisible();
    await beat(page);
    await goBack(page, "Daily Tracking");
    await expectChecked(page, "Great");
    expect(pageErrors(page)).toEqual([]);
  });

  test('"AI insights" opens Insights and returns to Home', async ({ page }) => {
    await loginToHome(page);

    const insights = button(page, /^AI insights$/);
    await scrollUntilVisible(page, insights);
    await insights.click();
    await expect(page.getByText("Insights", { exact: true })).toBeVisible();
    await beat(page);
    await goBack(page, "Insights");
    await expect(page.getByText("Your Health Insights")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test('"Meals & triggers" opens the Diet Tracker and returns to Home', async ({
    page,
  }) => {
    await loginToHome(page);

    const meals = button(page, /^Meals & triggers$/);
    await scrollUntilVisible(page, meals);
    await meals.click();
    await expect(page.getByText("Diet Tracker")).toBeVisible();
    await beat(page);
    await goBack(page, "Diet Tracker");
    await expect(
      page.getByRole("button", { name: "Meals & triggers" }),
    ).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });
});
