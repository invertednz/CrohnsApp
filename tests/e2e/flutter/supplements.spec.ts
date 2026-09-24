import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  beat,
  button,
  field,
  loginToHome,
  onScreen,
  openTab,
  pageErrors,
  scrollUntilVisible,
  type,
} from "./helpers";

/**
 * Supplements ("Supps") tab: a personal supplement list with dosages plus a
 * per-day log of what was taken (and AM/PM), saved to the backend
 * (`supplements` entries) for the date selected in the shared calendar.
 *
 * Each supplement in "My Supplements" is a checkbox (checked = taken on the
 * selected day); its time chips are checkboxes named "<name> taken AM|PM".
 */

const SUGGESTIONS = [
  "Vitamin D",
  "Probiotics",
  "Omega-3",
  "Iron",
  "B12",
  "Calcium",
  "Zinc",
  "Magnesium",
  "Folic Acid",
  "Multivitamin",
];

function supplement(page: Page, name: string): Locator {
  return page.getByRole("checkbox", { name, exact: true });
}

function timeChip(page: Page, name: string, time: "AM" | "PM"): Locator {
  return page.getByRole("checkbox", {
    name: `${name} taken ${time}`,
    exact: true,
  });
}

function suggestion(page: Page, name: string): Locator {
  return page.getByRole("button", { name: `Add ${name}`, exact: true });
}

function addButton(page: Page): Locator {
  return page.getByRole("button", { name: "Add", exact: true });
}

function removeButton(page: Page, name: string): Locator {
  return page.getByRole("button", { name: `Remove ${name}`, exact: true });
}

function editDosageButton(page: Page, name: string): Locator {
  return page.getByRole("button", {
    name: `Edit dosage for ${name}`,
    exact: true,
  });
}

async function click(page: Page, target: Locator): Promise<void> {
  await scrollUntilVisible(page, target);
  await target.click();
}

/** Text of the hint Flutter exposes as the accessible description (dosage + description). */
async function description(target: Locator): Promise<string> {
  return target.evaluate((el) => {
    const direct = el.getAttribute("aria-description");
    if (direct) return direct;
    const ids = (el.getAttribute("aria-describedby") ?? "")
      .split(/\s+/)
      .filter(Boolean);
    return ids
      .map((id) => document.getElementById(id)?.textContent ?? "")
      .join(" ");
  });
}

async function expectSummary(page: Page, text: string): Promise<void> {
  await expect(page.getByText(text, { exact: true })).toBeVisible();
}

async function openSupplements(page: Page): Promise<void> {
  await loginToHome(page);
  await openTab(page, "Supps");
  await expectSummary(page, "Nothing logged for today yet");
}

async function addSuggested(page: Page, name: string): Promise<void> {
  await click(page, suggestion(page, name));
  await expect(supplement(page, name)).toBeVisible();
}

async function addCustom(
  page: Page,
  name: string,
  dosage?: string,
): Promise<void> {
  await type(page, "Add custom supplement", name);
  if (dosage !== undefined) await type(page, "Dosage (optional)", dosage);
  await click(page, addButton(page));
  await expect(supplement(page, name)).toBeVisible();
}

async function markTaken(page: Page, name: string): Promise<void> {
  await click(page, supplement(page, name));
  await expect(supplement(page, name)).toBeChecked();
}

async function reopenSupplements(page: Page): Promise<void> {
  await openTab(page, "Home");
  await expect(button(page, /^Home.*Tab 1/)).toBeVisible();
  await openTab(page, "Supps");
}

/** Pick a day in the shared calendar strip ("Today 24 Sep", "Yesterday 23 Sep"). */
async function selectDay(
  page: Page,
  day: "Today" | "Yesterday",
): Promise<void> {
  await button(page, new RegExp(`^${day} \\d+ \\w+$`)).click();
}

test.describe("Supplements tab", () => {
  test("a new user sees an empty list, nothing logged today and the common supplements", async ({
    page,
  }) => {
    await openSupplements(page);
    await expect(
      page.getByText(
        "You haven't added any supplements yet. Add the ones you take below.",
      ),
    ).toBeVisible();
    await expect(field(page, "Add custom supplement")).toBeVisible();
    await expect(field(page, "Dosage (optional)")).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    await expect(
      page.getByRole("button", { name: "Mark All Taken", exact: true }),
    ).toHaveCount(0);
    for (const name of SUGGESTIONS) {
      await expect(suggestion(page, name)).toHaveCount(1);
    }
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("adding a suggested supplement puts it in My Supplements, not yet taken", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Vitamin D");
    await expect(supplement(page, "Vitamin D")).not.toBeChecked();
    await expect(suggestion(page, "Vitamin D")).toHaveCount(0);
    await expect(
      page.getByText("My Supplements - tap to mark taken"),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: "Mark All Taken", exact: true }),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: "Clear All", exact: true }),
    ).toBeVisible();
    expect(await description(supplement(page, "Vitamin D"))).toContain(
      "Fat-soluble vitamin",
    );
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("tapping a supplement marks it taken today and shows AM/PM time chips", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Probiotics");
    await markTaken(page, "Probiotics");
    await expect(page.getByText("When taken:")).toBeVisible();
    await expect(timeChip(page, "Probiotics", "AM")).not.toBeChecked();
    await expect(timeChip(page, "Probiotics", "PM")).not.toBeChecked();
    await expectSummary(page, "Logged for today: 1 of 1 taken");
    await beat(page);

    await click(page, supplement(page, "Probiotics"));
    await expect(supplement(page, "Probiotics")).not.toBeChecked();
    await expect(timeChip(page, "Probiotics", "AM")).toHaveCount(0);
    await expectSummary(page, "Logged for today: 0 of 1 taken");
    expect(pageErrors(page)).toEqual([]);
  });

  test("AM and PM toggle independently and are kept after leaving the tab", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Iron");
    await markTaken(page, "Iron");
    await click(page, timeChip(page, "Iron", "AM"));
    await expect(timeChip(page, "Iron", "AM")).toBeChecked();
    await click(page, timeChip(page, "Iron", "PM"));
    await expect(timeChip(page, "Iron", "PM")).toBeChecked();
    await click(page, timeChip(page, "Iron", "PM"));
    await expect(timeChip(page, "Iron", "PM")).not.toBeChecked();
    await beat(page);

    await reopenSupplements(page);
    await expect(supplement(page, "Iron")).toBeChecked();
    await expect(timeChip(page, "Iron", "AM")).toBeChecked();
    await expect(timeChip(page, "Iron", "PM")).not.toBeChecked();
    expect(pageErrors(page)).toEqual([]);
  });

  test("a custom supplement can be added with a dosage, or with the Enter key", async ({
    page,
  }) => {
    await openSupplements(page);
    await addCustom(page, "Turmeric", "500 mg");
    const turmeric = description(supplement(page, "Turmeric"));
    expect(await turmeric).toContain("500 mg");
    expect(await turmeric).toContain("Custom supplement");
    await beat(page);

    await type(page, "Add custom supplement", "Collagen");
    await page.keyboard.press("Enter");
    await expect(supplement(page, "Collagen")).toBeVisible();
    expect(await description(supplement(page, "Collagen"))).toBe(
      "Custom supplement",
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("validation: empty and duplicate names show an error, and a suggestion's name adds that suggestion", async ({
    page,
  }) => {
    await openSupplements(page);
    await click(page, addButton(page));
    // Validation errors are live regions, so Flutter also mirrors them into an
    // aria-live announcement element; assert on the rendered semantics tree.
    await expect(
      onScreen(page).getByText("Enter a supplement name to add it."),
    ).toBeVisible();
    await beat(page);

    await addSuggested(page, "Vitamin D");
    await type(page, "Add custom supplement", "vitamin d");
    await click(page, addButton(page));
    await expect(
      onScreen(page).getByText("Vitamin D is already in your list."),
    ).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(1);
    await beat(page);

    await type(page, "Add custom supplement", "zinc");
    await expect(
      onScreen(page).getByText("Vitamin D is already in your list."),
    ).toHaveCount(0);
    await click(page, addButton(page));
    await expect(supplement(page, "Zinc")).toBeVisible();
    await expect(suggestion(page, "Zinc")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("editing a dosage: Cancel keeps the old one, Save updates it everywhere", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Vitamin D");
    await click(page, editDosageButton(page, "Vitamin D"));
    await expect(page.getByText("Vitamin D dosage")).toBeVisible();
    const dosageInput = page.getByRole("textbox", {
      name: "Dosage",
      exact: true,
    });
    await dosageInput.click();
    await dosageInput.fill("2000 IU");
    await page.getByRole("button", { name: "Cancel", exact: true }).click();
    await expect(page.getByText("Vitamin D dosage")).toHaveCount(0);
    expect(await description(supplement(page, "Vitamin D"))).not.toContain(
      "2000 IU",
    );

    await click(page, editDosageButton(page, "Vitamin D"));
    await dosageInput.click();
    await dosageInput.fill("1000 IU");
    await beat(page);
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await expect(page.getByText("Vitamin D dosage")).toHaveCount(0);
    await expect
      .poll(() => description(supplement(page, "Vitamin D")))
      .toContain("1000 IU");

    await reopenSupplements(page);
    await expect
      .poll(() => description(supplement(page, "Vitamin D")))
      .toContain("1000 IU");
    expect(pageErrors(page)).toEqual([]);
  });

  test("Mark All Taken and Clear All update every supplement for the day", async ({
    page,
  }) => {
    await openSupplements(page);
    for (const name of ["Vitamin D", "Iron", "Omega-3"])
      await addSuggested(page, name);
    await click(
      page,
      page.getByRole("button", { name: "Mark All Taken", exact: true }),
    );
    for (const name of ["Vitamin D", "Iron", "Omega-3"])
      await expect(supplement(page, name)).toBeChecked();
    await expectSummary(page, "Logged for today: 3 of 3 taken");
    await beat(page);

    await click(
      page,
      page.getByRole("button", { name: "Clear All", exact: true }),
    );
    for (const name of ["Vitamin D", "Iron", "Omega-3"])
      await expect(supplement(page, name)).not.toBeChecked();
    await expectSummary(page, "Logged for today: 0 of 3 taken");
    expect(pageErrors(page)).toEqual([]);
  });

  test("removing supplements: custom ones disappear and suggested ones go back to the suggestions", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Calcium");
    await addCustom(page, "Turmeric", "500 mg");
    await markTaken(page, "Turmeric");
    await expectSummary(page, "Logged for today: 1 of 2 taken");

    await click(page, removeButton(page, "Turmeric"));
    await expect(supplement(page, "Turmeric")).toHaveCount(0);
    await expectSummary(page, "Logged for today: 0 of 1 taken");
    await click(page, removeButton(page, "Calcium"));
    await expect(supplement(page, "Calcium")).toHaveCount(0);
    await expect(suggestion(page, "Calcium")).toHaveCount(1);
    await beat(page);

    await reopenSupplements(page);
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    await expect(
      page.getByText(
        "You haven't added any supplements yet. Add the ones you take below.",
      ),
    ).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("each day in the calendar keeps its own record of what was taken", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Vitamin D");
    await addSuggested(page, "B12");
    await markTaken(page, "Vitamin D");
    await expectSummary(page, "Logged for today: 1 of 2 taken");

    await selectDay(page, "Yesterday");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await expect(supplement(page, "Vitamin D")).not.toBeChecked();
    await markTaken(page, "B12");
    await expectSummary(page, "Logged for yesterday: 1 of 2 taken");
    await beat(page);

    await selectDay(page, "Today");
    await expectSummary(page, "Logged for today: 1 of 2 taken");
    await expect(supplement(page, "Vitamin D")).toBeChecked();
    await expect(supplement(page, "B12")).not.toBeChecked();
    expect(pageErrors(page)).toEqual([]);
  });

  test("the supplement list and today's log are reloaded after leaving the tab", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Magnesium");
    await addCustom(page, "Collagen", "10 g");
    await markTaken(page, "Collagen");
    await beat(page);

    await reopenSupplements(page);
    await expectSummary(page, "Logged for today: 1 of 2 taken");
    await expect(supplement(page, "Magnesium")).not.toBeChecked();
    await expect(supplement(page, "Collagen")).toBeChecked();
    expect(await description(supplement(page, "Collagen"))).toContain("10 g");
    expect(pageErrors(page)).toEqual([]);
  });

  test("tracked supplements reach the AI assistant in Chat", async ({
    page,
  }) => {
    await openSupplements(page);
    await addSuggested(page, "Vitamin D");
    await markTaken(page, "Vitamin D");
    await openTab(page, "Chat");
    const input = field(page, /Type your message/i).first();
    await input.click();
    await input.fill("Which supplements am I tracking?");
    await page.keyboard.press("Enter");
    await expect(page.getByText(/tracking:? Vitamin D/).first()).toBeVisible({
      timeout: 10_000,
    });
    await beat(page, 1200);
    expect(pageErrors(page)).toEqual([]);
  });
});
