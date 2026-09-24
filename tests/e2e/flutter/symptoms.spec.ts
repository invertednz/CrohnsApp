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
 * Symptoms tab: a personal symptom list plus a per-day log with a 1-5
 * severity, saved to the backend (`symptoms` entries) for the date selected in
 * the shared calendar. Logged symptoms feed the AI assistant.
 *
 * Each symptom in "My Symptoms" is a checkbox (checked = experienced on the
 * selected day); its severity chips are radios named "<symptom> severity N of 5".
 */

const SUGGESTIONS = [
  "Abdominal Pain",
  "Diarrhea",
  "Bloating",
  "Gas",
  "Fatigue",
  "Nausea",
  "Loss of Appetite",
  "Constipation",
  "Joint Pain",
  "Fever",
];

function symptom(page: Page, name: string): Locator {
  return page.getByRole("checkbox", { name, exact: true });
}

function severity(page: Page, name: string, level: number): Locator {
  return page.getByRole("radio", {
    name: new RegExp(`^${name} severity ${level} of 5`),
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

function customField(page: Page): Locator {
  return field(page, "Add custom symptom").first();
}

async function click(page: Page, target: Locator): Promise<void> {
  await scrollUntilVisible(page, target);
  await target.click();
}

/** Text of the hint Flutter exposes as the accessible description. */
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

async function openSymptoms(page: Page): Promise<void> {
  await loginToHome(page);
  await openTab(page, "Symptoms");
  await expectSummary(page, "Nothing logged for today yet");
}

async function addSuggested(page: Page, name: string): Promise<void> {
  await click(page, suggestion(page, name));
  await expect(symptom(page, name)).toBeVisible();
}

async function addCustom(page: Page, name: string): Promise<void> {
  await type(page, "Add custom symptom", name);
  await click(page, addButton(page));
}

async function logSymptom(
  page: Page,
  name: string,
  level?: number,
): Promise<void> {
  await click(page, symptom(page, name));
  await expect(symptom(page, name)).toBeChecked();
  if (level !== undefined) {
    await click(page, severity(page, name, level));
    await expect(severity(page, name, level)).toBeChecked();
  }
}

/** Leave the tab and come back, which rebuilds the screen from the backend. */
async function reopenSymptoms(page: Page): Promise<void> {
  await openTab(page, "Home");
  await expect(button(page, /^Home.*Tab 1/)).toBeVisible();
  await openTab(page, "Symptoms");
}

/** Pick a day in the shared calendar strip ("Today 24 Sep", "Yesterday 23 Sep"). */
async function selectDay(
  page: Page,
  day: "Today" | "Yesterday",
): Promise<void> {
  await button(page, new RegExp(`^${day} \\d+ \\w+$`)).click();
}

test.describe("Symptoms tab", () => {
  test("a new user sees an empty list, nothing logged today and every suggested symptom", async ({
    page,
  }) => {
    await openSymptoms(page);
    await expect(
      page.getByText(
        "You're not tracking any symptoms yet. Add the ones you want to track below.",
      ),
    ).toBeVisible();
    await expect(customField(page)).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    await expect(
      page.getByRole("button", { name: "Had All", exact: true }),
    ).toHaveCount(0);
    await expect(
      page.getByRole("button", { name: "Had None", exact: true }),
    ).toBeVisible();
    for (const name of SUGGESTIONS) {
      await expect(suggestion(page, name)).toHaveCount(1);
    }
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("adding a suggested symptom moves it into My Symptoms, not yet logged", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Nausea");
    await expect(symptom(page, "Nausea")).not.toBeChecked();
    await expect(suggestion(page, "Nausea")).toHaveCount(0);
    await expect(
      page.getByText("My Symptoms - tap the ones you experienced"),
    ).toBeVisible();
    await expect(
      page.getByRole("button", { name: "Had All", exact: true }),
    ).toBeVisible();
    expect(await description(symptom(page, "Nausea"))).toContain(
      "Feeling sick or queasy",
    );
    await expectSummary(page, "Nothing logged for today yet");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("tapping a symptom logs it for today with a default Moderate (3/5) severity", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Nausea");
    await logSymptom(page, "Nausea");
    await expect(severity(page, "Nausea", 3)).toBeChecked();
    for (const level of [1, 2, 4, 5]) {
      await expect(severity(page, "Nausea", level)).not.toBeChecked();
    }
    await expect(page.getByText("Severity: Moderate (3/5)")).toBeVisible();
    await expectSummary(page, "Logged for today: 1 symptom");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("severity can be set on the 1-5 scale and is kept after leaving the tab", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Abdominal Pain");
    await logSymptom(page, "Abdominal Pain", 5);
    await expect(page.getByText("Severity: Very severe (5/5)")).toBeVisible();
    await expect(severity(page, "Abdominal Pain", 3)).not.toBeChecked();
    await click(page, severity(page, "Abdominal Pain", 1));
    await expect(page.getByText("Severity: Very mild (1/5)")).toBeVisible();
    await click(page, severity(page, "Abdominal Pain", 4));
    await expect(page.getByText("Severity: Severe (4/5)")).toBeVisible();
    await beat(page);

    await reopenSymptoms(page);
    await expect(symptom(page, "Abdominal Pain")).toBeChecked();
    await expect(severity(page, "Abdominal Pain", 4)).toBeChecked();
    await expect(page.getByText("Severity: Severe (4/5)")).toBeVisible();
    await expectSummary(page, "Logged for today: 1 symptom");
    expect(pageErrors(page)).toEqual([]);
  });

  test("tapping a logged symptom again un-logs it and records a symptom-free day", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Bloating");
    await logSymptom(page, "Bloating");
    await click(page, symptom(page, "Bloating"));
    await expect(symptom(page, "Bloating")).not.toBeChecked();
    await expect(page.getByRole("radio")).toHaveCount(0);
    await expectSummary(page, "Logged for today: no symptoms");
    await beat(page);

    await reopenSymptoms(page);
    await expect(symptom(page, "Bloating")).not.toBeChecked();
    await expectSummary(page, "Logged for today: no symptoms");
    expect(pageErrors(page)).toEqual([]);
  });

  test("custom symptoms can be added with the Add button or the Enter key", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addCustom(page, "Brain fog");
    await expect(symptom(page, "Brain fog")).toBeVisible();
    expect(await description(symptom(page, "Brain fog"))).toContain(
      "Custom symptom",
    );

    await type(page, "Add custom symptom", "Night sweats");
    await page.keyboard.press("Enter");
    await expect(symptom(page, "Night sweats")).toBeVisible();
    await logSymptom(page, "Night sweats", 2);
    await expect(page.getByText("Severity: Mild (2/5)")).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("validation: empty and duplicate names show an error, and a suggestion's name adds that suggestion", async ({
    page,
  }) => {
    await openSymptoms(page);
    await click(page, addButton(page));
    // Validation errors are live regions, so Flutter also mirrors them into an
    // aria-live announcement element; assert on the rendered semantics tree.
    await expect(
      onScreen(page).getByText("Enter a symptom name to add it."),
    ).toBeVisible();
    await beat(page);

    await type(page, "Add custom symptom", "Brain fog");
    await expect(
      onScreen(page).getByText("Enter a symptom name to add it."),
    ).toHaveCount(0);
    await click(page, addButton(page));
    await expect(symptom(page, "Brain fog")).toBeVisible();

    await type(page, "Add custom symptom", "brain FOG");
    await click(page, addButton(page));
    await expect(
      onScreen(page).getByText("Brain fog is already in your list."),
    ).toBeVisible();
    await expect(page.getByRole("checkbox")).toHaveCount(1);
    await beat(page);

    await type(page, "Add custom symptom", "bloating");
    await click(page, addButton(page));
    await expect(symptom(page, "Bloating")).toBeVisible();
    await expect(symptom(page, "bloating")).toHaveCount(0);
    await expect(suggestion(page, "Bloating")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("removing symptoms: custom ones disappear and suggested ones go back to the suggestions", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Gas");
    await addCustom(page, "Brain fog");
    await expect(symptom(page, "Brain fog")).toBeVisible();
    await logSymptom(page, "Brain fog");
    await beat(page);

    await click(page, removeButton(page, "Brain fog"));
    await expect(symptom(page, "Brain fog")).toHaveCount(0);
    await expectSummary(page, "Logged for today: no symptoms");
    await click(page, removeButton(page, "Gas"));
    await expect(symptom(page, "Gas")).toHaveCount(0);
    await expect(suggestion(page, "Gas")).toHaveCount(1);
    await expect(
      page.getByText(
        "You're not tracking any symptoms yet. Add the ones you want to track below.",
      ),
    ).toBeVisible();
    await beat(page);

    await reopenSymptoms(page);
    await expect(page.getByRole("checkbox")).toHaveCount(0);
    await expect(suggestion(page, "Gas")).toHaveCount(1);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Had All logs every tracked symptom and Had None clears the day", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Gas");
    await addSuggested(page, "Fever");
    await addSuggested(page, "Fatigue");
    await click(
      page,
      page.getByRole("button", { name: "Had All", exact: true }),
    );
    for (const name of ["Gas", "Fever", "Fatigue"]) {
      await expect(symptom(page, name)).toBeChecked();
      await expect(severity(page, name, 3)).toBeChecked();
    }
    await expectSummary(page, "Logged for today: 3 symptoms");
    await beat(page);

    await click(
      page,
      page.getByRole("button", { name: "Had None", exact: true }),
    );
    for (const name of ["Gas", "Fever", "Fatigue"]) {
      await expect(symptom(page, name)).not.toBeChecked();
    }
    await expectSummary(page, "Logged for today: no symptoms");
    expect(pageErrors(page)).toEqual([]);
  });

  test("Had None records a symptom-free day even before any symptoms are tracked", async ({
    page,
  }) => {
    await openSymptoms(page);
    await click(
      page,
      page.getByRole("button", { name: "Had None", exact: true }),
    );
    await expectSummary(page, "Logged for today: no symptoms");
    await beat(page);
    await reopenSymptoms(page);
    await expectSummary(page, "Logged for today: no symptoms");
    expect(pageErrors(page)).toEqual([]);
  });

  test("each day in the calendar keeps its own symptom log", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Nausea");
    await addSuggested(page, "Fatigue");
    await logSymptom(page, "Nausea", 4);
    await expectSummary(page, "Logged for today: 1 symptom");

    await selectDay(page, "Yesterday");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await expect(symptom(page, "Nausea")).not.toBeChecked();
    await expect(symptom(page, "Fatigue")).not.toBeChecked();
    await logSymptom(page, "Fatigue", 2);
    await expectSummary(page, "Logged for yesterday: 1 symptom");
    await beat(page);

    await selectDay(page, "Today");
    await expectSummary(page, "Logged for today: 1 symptom");
    await expect(symptom(page, "Nausea")).toBeChecked();
    await expect(severity(page, "Nausea", 4)).toBeChecked();
    await expect(symptom(page, "Fatigue")).not.toBeChecked();

    await selectDay(page, "Yesterday");
    await expectSummary(page, "Logged for yesterday: 1 symptom");
    await expect(symptom(page, "Fatigue")).toBeChecked();
    await expect(severity(page, "Fatigue", 2)).toBeChecked();
    await expect(symptom(page, "Nausea")).not.toBeChecked();
    expect(pageErrors(page)).toEqual([]);
  });

  test("the symptom list and today's log are reloaded after leaving the tab", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Joint Pain");
    await addCustom(page, "Mouth ulcers");
    await expect(symptom(page, "Mouth ulcers")).toBeVisible();
    await logSymptom(page, "Mouth ulcers", 3);
    await beat(page);

    await reopenSymptoms(page);
    await expectSummary(page, "Logged for today: 1 symptom");
    await expect(symptom(page, "Joint Pain")).not.toBeChecked();
    await expect(symptom(page, "Mouth ulcers")).toBeChecked();
    await expect(suggestion(page, "Joint Pain")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the date picked on Symptoms is shared with the Supplements and Medications tabs", async ({
    page,
  }) => {
    await openSymptoms(page);
    await selectDay(page, "Yesterday");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await openTab(page, "Supps");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await openTab(page, "Meds");
    await expectSummary(page, "Nothing logged for yesterday yet");
    await beat(page);
    await openTab(page, "Symptoms");
    await expectSummary(page, "Nothing logged for yesterday yet");
    expect(pageErrors(page)).toEqual([]);
  });

  test("logged symptoms and their severity reach the AI assistant in Chat", async ({
    page,
  }) => {
    await openSymptoms(page);
    await addSuggested(page, "Nausea");
    await logSymptom(page, "Nausea", 4);
    await openTab(page, "Chat");
    const input = field(page, /Type your message/i).first();
    await input.click();
    await input.fill("What symptoms have I logged?");
    await page.keyboard.press("Enter");
    await expect(page.getByText(/Nausea/).first()).toBeVisible({
      timeout: 10_000,
    });
    await beat(page, 1200);
    expect(pageErrors(page)).toEqual([]);
  });
});
