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
 * Medications ("Meds") tab: a personal medication list with doses plus a
 * per-day log of what was taken (and AM/PM), saved to the backend
 * (`medications` entries) for the date selected in the shared calendar.
 *
 * Each medication in "My Medications" is a checkbox (checked = taken on the
 * selected day); its time chips are checkboxes named "<name> taken AM|PM".
 */

const SUGGESTIONS = [
  "Mesalamine",
  "Prednisone",
  "Azathioprine",
  "Infliximab",
  "Adalimumab",
  "Budesonide",
  "Methotrexate",
  "Vedolizumab",
];

const DISCLAIMER =
  "Always consult your doctor before making medication changes";

function medication(page: Page, name: string): Locator {
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

/** Text of the hint Flutter exposes as the accessible description (dose + description). */
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

async function openMedications(page: Page): Promise<void> {
  await loginToHome(page);
  await openTab(page, "Meds");
  await expectSummary(page, "Nothing logged for today yet");
}

async function addSuggested(page: Page, name: string): Promise<void> {
  await click(page, suggestion(page, name));
  await expect(medication(page, name)).toBeVisible();
}

async function addCustom(
  page: Page,
  name: string,
  dosage?: string,
): Promise<void> {
  await type(page, "Add custom medication", name);
  if (dosage !== undefined) await type(page, "Dosage (optional)", dosage);
  await click(page, addButton(page));
  await expect(medication(page, name)).toBeVisible();
}

async function markTaken(page: Page, name: string): Promise<void> {
  await click(page, medication(page, name));
  await expect(medication(page, name)).toBeChecked();
}

async function reopenMedications(page: Page): Promise<void> {
  await openTab(page, "Home");
  await expect(button(page, /^Home.*Tab 1/)).toBeVisible();
  await openTab(page, "Meds");
}

/** Pick a day in the shared calendar strip ("Today 24 Sep", "Yesterday 23 Sep"). */
async function selectDay(
  page: Page,
  day: "Today" | "Yesterday",
): Promise<void> {
  await button(page, new RegExp(`^${day} \\d+ \\w+$`)).click();
}

test.describe("Medications tab", () => {
  test("a new user sees an empty list, common IBD medications and the talk-to-your-doctor note", async ({
    page,
  }) => {
    await openMedications(page);
    await expect(
      page.getByText(
        "You haven't added any medications yet. Add the ones you take below.",
      ),
    ).toBeVisible();
    await expect(field(page, "Add custom medication")).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    for (const name of SUGGESTIONS) {
      await expect(suggestion(page, name)).toHaveCount(1);
    }
    await scrollUntilVisible(page, page.getByText(DISCLAIMER));
    await expect(page.getByText(DISCLAIMER)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a suggested medication can be added, marked taken with AM/PM, and is kept after leaving the tab", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Mesalamine");
    await expect(medication(page, "Mesalamine")).not.toBeChecked();
    await expect(suggestion(page, "Mesalamine")).toHaveCount(0);
    expect(await description(medication(page, "Mesalamine"))).toContain(
      "Anti-inflammatory for IBD maintenance",
    );

    await markTaken(page, "Mesalamine");
    await click(page, timeChip(page, "Mesalamine", "AM"));
    await click(page, timeChip(page, "Mesalamine", "PM"));
    await expect(timeChip(page, "Mesalamine", "AM")).toBeChecked();
    await expect(timeChip(page, "Mesalamine", "PM")).toBeChecked();
    await expectSummary(page, "Logged for today: 1 of 1 taken");
    await beat(page);

    await reopenMedications(page);
    await expect(medication(page, "Mesalamine")).toBeChecked();
    await expect(timeChip(page, "Mesalamine", "AM")).toBeChecked();
    await expect(timeChip(page, "Mesalamine", "PM")).toBeChecked();
    await expectSummary(page, "Logged for today: 1 of 1 taken");
    expect(pageErrors(page)).toEqual([]);
  });

  test("a custom medication can be added with a dose, or with the Enter key", async ({
    page,
  }) => {
    await openMedications(page);
    await addCustom(page, "Ustekinumab", "90 mg");
    const text = await description(medication(page, "Ustekinumab"));
    expect(text).toContain("90 mg");
    expect(text).toContain("Custom medication");
    await beat(page);

    await type(page, "Add custom medication", "Loperamide");
    await page.keyboard.press("Enter");
    await expect(medication(page, "Loperamide")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("validation: empty and duplicate names show an error", async ({
    page,
  }) => {
    await openMedications(page);
    await click(page, addButton(page));
    // Validation errors are live regions, so Flutter also mirrors them into an
    // aria-live announcement element; assert on the rendered semantics tree.
    await expect(
      onScreen(page).getByText("Enter a medication name to add it."),
    ).toBeVisible();

    await addSuggested(page, "Prednisone");
    await type(page, "Add custom medication", "PREDNISONE");
    await click(page, addButton(page));
    await expect(
      onScreen(page).getByText("Prednisone is already in your list."),
    ).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(1);
    await beat(page);

    await type(page, "Add custom medication", "budesonide");
    await click(page, addButton(page));
    await expect(medication(page, "Budesonide")).toBeVisible();
    await expect(suggestion(page, "Budesonide")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a dose can be edited (for example a steroid taper) and the change is saved", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Prednisone");
    await click(page, editDosageButton(page, "Prednisone"));
    await expect(page.getByText("Prednisone dosage")).toBeVisible();
    const dosageInput = page.getByRole("textbox", {
      name: "Dosage",
      exact: true,
    });
    await dosageInput.click();
    await dosageInput.fill("40 mg");
    await page.getByRole("button", { name: "Save", exact: true }).click();
    await expect
      .poll(() => description(medication(page, "Prednisone")))
      .toContain("40 mg");

    await click(page, editDosageButton(page, "Prednisone"));
    await expect(dosageInput).toHaveValue("40 mg");
    await dosageInput.fill("30 mg");
    await page.keyboard.press("Enter");
    await expect
      .poll(() => description(medication(page, "Prednisone")))
      .toContain("30 mg");
    await beat(page);

    await reopenMedications(page);
    await expect
      .poll(() => description(medication(page, "Prednisone")))
      .toContain("30 mg");
    expect(pageErrors(page)).toEqual([]);
  });

  test("Mark All Taken and Clear All update every medication for the day", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Azathioprine");
    await addSuggested(page, "Budesonide");
    await click(
      page,
      page.getByRole("button", { name: "Mark All Taken", exact: true }),
    );
    await expect(medication(page, "Azathioprine")).toBeChecked();
    await expect(medication(page, "Budesonide")).toBeChecked();
    await expectSummary(page, "Logged for today: 2 of 2 taken");
    await beat(page);

    await click(
      page,
      page.getByRole("button", { name: "Clear All", exact: true }),
    );
    await expect(medication(page, "Azathioprine")).not.toBeChecked();
    await expect(medication(page, "Budesonide")).not.toBeChecked();
    await expectSummary(page, "Logged for today: 0 of 2 taken");
    expect(pageErrors(page)).toEqual([]);
  });

  test("removing medications returns suggested ones to the list and deletes custom ones", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Infliximab");
    await addCustom(page, "Loperamide");
    await click(page, removeButton(page, "Loperamide"));
    await expect(medication(page, "Loperamide")).toHaveCount(0);
    await click(page, removeButton(page, "Infliximab"));
    await expect(medication(page, "Infliximab")).toHaveCount(0);
    await expect(suggestion(page, "Infliximab")).toHaveCount(1);
    await beat(page);

    await reopenMedications(page);
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("each day in the calendar keeps its own record of doses taken", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Methotrexate");
    await addSuggested(page, "Vedolizumab");
    await markTaken(page, "Methotrexate");

    await selectDay(page, "Yesterday");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await expect(medication(page, "Methotrexate")).not.toBeChecked();
    await markTaken(page, "Vedolizumab");
    await expectSummary(page, "Logged for yesterday: 1 of 2 taken");
    await beat(page);

    await selectDay(page, "Today");
    await expectSummary(page, "Logged for today: 1 of 2 taken");
    await expect(medication(page, "Methotrexate")).toBeChecked();
    await expect(medication(page, "Vedolizumab")).not.toBeChecked();
    expect(pageErrors(page)).toEqual([]);
  });

  test("logged medications reach the AI assistant in Chat", async ({
    page,
  }) => {
    await openMedications(page);
    await addSuggested(page, "Mesalamine");
    await markTaken(page, "Mesalamine");
    await openTab(page, "Chat");
    const input = field(page, /Type your message/i).first();
    await input.click();
    await input.fill("Which medications have I logged?");
    await page.keyboard.press("Enter");
    await expect(page.getByText(/Mesalamine/).first()).toBeVisible({
      timeout: 10_000,
    });
    await beat(page, 1200);
    expect(pageErrors(page)).toEqual([]);
  });
});
