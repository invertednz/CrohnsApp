import { expect, test, type Locator, type Page } from "@playwright/test";
import { beat, boot, field, pageErrors, scrollUntilVisible } from "./helpers";

/**
 * Onboarding steps 7-12: Diet flags, Supplements, Lifestyle, Medications,
 * Current Symptoms and Thank You.
 *
 * Selectable cards are exposed as checkboxes (aria-checked), supplement AM/PM
 * toggles as checkboxes named "Take <name> in the AM|PM", symptom severities
 * as radios named "<symptom> severity: <level>", and icon-only buttons carry
 * tooltips ("Back", "Remove <item>").
 */

type Step =
  "diet" | "supplements" | "lifestyle" | "medications" | "symptoms" | "thanks";

const HEADINGS: Record<Step, string> = {
  diet: "Diet Considerations",
  supplements: "Supplements",
  lifestyle: "Lifestyle Factors",
  medications: "Current Medications",
  symptoms: "Current Symptoms",
  thanks: "Thank You!",
};

const ORDER: Step[] = [
  "diet",
  "supplements",
  "lifestyle",
  "medications",
  "symptoms",
  "thanks",
];

function esc(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** Tappable by name whether it is exposed as a button, checkbox or radio. */
function tappable(page: Page, name: RegExp): Locator {
  return page
    .getByRole("button", { name })
    .or(page.getByRole("checkbox", { name }))
    .or(page.getByRole("radio", { name }));
}

/** Click the only control matching `name`, then let the screen transition finish. */
async function advance(page: Page, name: RegExp): Promise<void> {
  const target = tappable(page, name);
  await expect(target).toHaveCount(1);
  await target.click();
  await page.waitForTimeout(600);
}

async function expectHeading(page: Page, step: Step): Promise<void> {
  await expect(
    page.getByText(HEADINGS[step], { exact: true }).first(),
  ).toBeVisible();
}

/**
 * Scroll until `target` is fully on screen, clear of the fixed header and the
 * Continue button, so clicks land on it. Flutter moves the list by only a
 * fraction of each wheel delta, so the wheel amount adapts to what it sees.
 */
async function reveal(page: Page, target: Locator): Promise<void> {
  await scrollUntilVisible(page, target);
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  const top = 110;
  const bottom = vp.height - 140;
  let ratio = 0.25; // observed px scrolled per px of wheel delta
  for (let i = 0; i < 10; i++) {
    const box = await target.boundingBox();
    if (!box) return;
    let shift = 0;
    if (box.y < top) shift = box.y - top;
    else if (box.y + box.height > bottom)
      shift = Math.min(box.y + box.height - bottom, box.y - top);
    if (Math.abs(shift) < 1) return;
    const delta = shift / ratio;
    await page.mouse.move(vp.width / 2, vp.height / 2);
    await page.mouse.wheel(0, delta);
    await page.waitForTimeout(400);
    const after = await target.boundingBox();
    if (!after) return;
    const moved = box.y - after.y;
    if (Math.abs(moved) < 2) return; // reached the end of the list
    ratio = Math.min(2, Math.max(0.05, moved / delta));
  }
}

/** A selectable card (checkbox) whose name starts with `name`. */
function option(page: Page, name: string): Locator {
  return page.getByRole("checkbox", { name: new RegExp(`^${esc(name)}\\b`) });
}

async function toggleOption(page: Page, name: string): Promise<void> {
  const target = option(page, name);
  await reveal(page, target);
  await target.click();
}

async function expectOption(
  page: Page,
  name: string,
  checked: boolean,
): Promise<void> {
  const target = option(page, name);
  await reveal(page, target);
  if (checked) await expect(target).toBeChecked();
  else await expect(target).not.toBeChecked();
}

function timeToggle(
  page: Page,
  supplement: string,
  time: "AM" | "PM",
): Locator {
  return page.getByRole("checkbox", {
    name: `Take ${supplement} in the ${time}`,
    exact: true,
  });
}

function severity(
  page: Page,
  symptom: string,
  level: "Mild" | "Moderate" | "Severe",
): Locator {
  return page.getByRole("radio", {
    name: `${symptom} severity: ${level}`,
    exact: true,
  });
}

/**
 * Icon-only buttons are named by their tooltip. While the mouse hovers one (e.g.
 * after a click, when the next chip or step's button slides under the pointer)
 * Flutter shows the tooltip and adds its text to the button's semantics, so the
 * name is then "<tooltip> <tooltip>". Match either form, still case-sensitive.
 */
function tooltipButton(page: Page, tooltip: string): Locator {
  return page.getByRole("button", {
    name: new RegExp(`^${esc(tooltip)}(?: ${esc(tooltip)})?$`),
  });
}

function removeButton(page: Page, item: string): Locator {
  return tooltipButton(page, `Remove ${item}`);
}

function addButton(page: Page): Locator {
  return page.getByRole("button", { name: /^Add$/ });
}

/** Type into the screen's "add custom" field and submit with the Add button or Enter. */
async function addCustom(
  page: Page,
  label: string,
  value: string,
  submit: "button" | "enter" = "button",
) {
  const input = field(page, label).first();
  await reveal(page, input);
  await input.click();
  await input.fill(value);
  if (submit === "enter") {
    await input.press("Enter");
  } else {
    const add = addButton(page);
    await expect(add).toBeEnabled();
    await add.click();
  }
  await page.waitForTimeout(400);
}

async function clickReveal(page: Page, target: Locator): Promise<void> {
  await reveal(page, target);
  await target.click();
}

async function back(page: Page): Promise<void> {
  // Header Back icon button; "Back Back" while its tooltip is shown (see tooltipButton).
  await advance(page, /^Back(?: Back)?$/);
}

async function next(page: Page): Promise<void> {
  await advance(page, /^Continue$/);
}

/**
 * Fast-forward through onboarding steps 0-6 with minimal valid answers
 * (conditions, first goal, skip reminders) and stop at `step`.
 */
async function goToStep(
  page: Page,
  step: Step,
  opts: { conditions?: string[] } = {},
): Promise<void> {
  await boot(page);
  await advance(page, /^Get Started$/);
  for (const condition of opts.conditions ?? ["Crohn's Disease"]) {
    const card = tappable(page, new RegExp(`^${esc(condition)}\\b`));
    await reveal(page, card);
    await card.click();
  }
  await advance(page, /^Continue$/); // condition
  await advance(page, /^Reduce Symptoms/); // goal
  await advance(page, /^Continue$/);
  await advance(page, /^Continue$/); // expected results
  await advance(page, /^Continue$/); // how it works (progress)
  for (let i = 0; i < 8; i++) {
    // feature pager: "Next" until it turns into "Continue"
    if ((await tappable(page, /^Continue$/).count()) === 1) break;
    await advance(page, /^Next$/);
  }
  await advance(page, /^Continue$/);
  await advance(page, /^Skip$/); // notification preferences
  await expectHeading(page, "diet");
  for (const s of ORDER.slice(1, ORDER.indexOf(step) + 1)) {
    await next(page);
    await expectHeading(page, s);
  }
}

/** Every on-screen button must have an accessible name (icon-only buttons need a tooltip). */
async function expectAllButtonsNamed(page: Page): Promise<void> {
  const buttons = await page.getByRole("button").all();
  expect(buttons.length).toBeGreaterThan(0);
  for (const b of buttons) {
    await expect(b).toHaveAccessibleName(/\S/);
  }
}

test.describe("Onboarding profile: diet considerations (step 7)", () => {
  test("toggling common food triggers checks and unchecks them", async ({
    page,
  }) => {
    await goToStep(page, "diet");
    await expect(
      page.getByText("Select foods or ingredients that affect you"),
    ).toBeVisible();
    await expectOption(page, "Dairy", false);

    await toggleOption(page, "Dairy");
    await toggleOption(page, "Gluten");
    await expectOption(page, "Dairy", true);
    await expectOption(page, "Gluten", true);
    await beat(page);

    await toggleOption(page, "Dairy");
    await expectOption(page, "Dairy", false);
    await expectOption(page, "Gluten", true);

    await toggleOption(page, "Nuts & Seeds");
    await expectOption(page, "Nuts & Seeds", true);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Add stays disabled for an empty or blank custom item", async ({
    page,
  }) => {
    await goToStep(page, "diet");
    await expect(addButton(page)).toBeDisabled();
    const input = field(page, "Add custom item").first();
    await input.click();
    await input.fill("    ");
    await expect(addButton(page)).toBeDisabled();
    await input.fill("Tomatoes");
    await expect(addButton(page)).toBeEnabled();
    await input.fill("");
    await expect(addButton(page)).toBeDisabled();
    await expect(page.getByText("Your Custom Items")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("custom triggers can be added with Add or Enter, are not duplicated, and can be removed", async ({
    page,
  }) => {
    await goToStep(page, "diet");
    await addCustom(page, "Add custom item", "Tomatoes");
    await expect(page.getByText("Your Custom Items")).toBeVisible();
    await expect(removeButton(page, "Tomatoes")).toHaveCount(1);
    await expect(field(page, "Add custom item").first()).toHaveValue("");

    await addCustom(page, "Add custom item", "Onions", "enter");
    await expect(removeButton(page, "Onions")).toHaveCount(1);

    // Same item again (different case) is not added twice.
    await addCustom(page, "Add custom item", "tomatoes");
    await expect(removeButton(page, "Tomatoes")).toHaveCount(1);
    await expect(removeButton(page, "tomatoes")).toHaveCount(0);
    await beat(page);

    await clickReveal(page, removeButton(page, "Tomatoes"));
    await expect(removeButton(page, "Tomatoes")).toHaveCount(0);
    await expect(removeButton(page, "Onions")).toBeVisible();

    await clickReveal(page, removeButton(page, "Onions"));
    await expect(page.getByText("Your Custom Items")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("typing a listed trigger selects its card instead of creating a duplicate", async ({
    page,
  }) => {
    await goToStep(page, "diet");
    await addCustom(page, "Add custom item", "dairy");
    await expect(page.getByText("Your Custom Items")).toHaveCount(0);
    await expectOption(page, "Dairy", true);
    expect(pageErrors(page)).toEqual([]);
  });

  test("info copy points to the Diet tracker instead of a settings page that does not exist", async ({
    page,
  }) => {
    await goToStep(page, "diet");
    const tip = page.getByText(
      /log trigger and safe foods any time in the Diet tracker/,
    );
    await scrollUntilVisible(page, tip);
    await expect(tip).toBeVisible();
    await expect(page.getByText(/update these later in settings/)).toHaveCount(
      0,
    );
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: supplements (step 8)", () => {
  test("selecting a supplement reveals AM/PM toggles that set timing without deselecting it", async ({
    page,
  }) => {
    await goToStep(page, "supplements");
    await expect(timeToggle(page, "Vitamin D", "AM")).toHaveCount(0);

    await toggleOption(page, "Vitamin D");
    await expectOption(page, "Vitamin D", true);
    const am = timeToggle(page, "Vitamin D", "AM");
    const pm = timeToggle(page, "Vitamin D", "PM");
    await reveal(page, am);
    await expect(am).not.toBeChecked();
    await expect(pm).not.toBeChecked();

    await am.click();
    await expect(am).toBeChecked();
    await pm.click();
    await expect(pm).toBeChecked();
    await am.click();
    await expect(am).not.toBeChecked();
    await expect(pm).toBeChecked();
    await expectOption(page, "Vitamin D", true);
    await beat(page);

    // Tapping the card again removes the supplement and its toggles.
    await toggleOption(page, "Vitamin D");
    await expectOption(page, "Vitamin D", false);
    await expect(timeToggle(page, "Vitamin D", "AM")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("custom supplements can be added, timed and removed; listed names map to their card", async ({
    page,
  }) => {
    await goToStep(page, "supplements");
    await expect(addButton(page)).toBeDisabled();

    await addCustom(page, "Add custom supplement", "Turmeric");
    await expect(page.getByText("Your Custom Supplements")).toBeVisible();
    await expect(removeButton(page, "Turmeric")).toHaveCount(1);
    const pm = timeToggle(page, "Turmeric", "PM");
    await clickReveal(page, pm);
    await expect(pm).toBeChecked();
    await beat(page);

    await addCustom(page, "Add custom supplement", "probiotics", "enter");
    await expectOption(page, "Probiotics", true);
    await expect(removeButton(page, "probiotics")).toHaveCount(0);

    await clickReveal(page, removeButton(page, "Turmeric"));
    await expect(page.getByText("Your Custom Supplements")).toHaveCount(0);
    await expect(timeToggle(page, "Turmeric", "PM")).toHaveCount(0);
    await expectOption(page, "Probiotics", true);
    expect(pageErrors(page)).toEqual([]);
  });

  test("supplement descriptions avoid unsupported health claims", async ({
    page,
  }) => {
    await goToStep(page, "supplements");
    await reveal(page, option(page, "Omega-3"));
    await expect(option(page, "Omega-3")).toHaveAccessibleName(
      /Fish, krill, or algae oil/,
    );
    await expect(option(page, "Probiotics")).toHaveAccessibleName(
      /Live bacterial cultures/,
    );
    await expect(page.getByText(/Anti-inflammatory/)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: lifestyle (step 9)", () => {
  test("factors toggle, custom factors are added with Enter and removed from Selected Factors", async ({
    page,
  }) => {
    await goToStep(page, "lifestyle");
    await expect(page.getByText("Selected Factors")).toHaveCount(0);

    await toggleOption(page, "Poor Sleep");
    await toggleOption(page, "High Stress");
    await expectOption(page, "Poor Sleep", true);
    await expectOption(page, "High Stress", true);

    await expect(addButton(page)).toBeDisabled();
    await addCustom(page, "Lifestyle factor", "Shift Work", "enter");
    await addCustom(page, "Lifestyle factor", "smoking");
    const selected = page.getByText("Selected Factors");
    await scrollUntilVisible(page, selected);
    await expect(removeButton(page, "Shift Work")).toBeVisible();
    await expect(removeButton(page, "Smoking")).toBeVisible();
    await expectOption(page, "Smoking", true);
    await beat(page);

    await clickReveal(page, removeButton(page, "Shift Work"));
    await expect(removeButton(page, "Shift Work")).toHaveCount(0);
    await clickReveal(page, removeButton(page, "Poor Sleep"));
    await expectOption(page, "Poor Sleep", false);
    await expectOption(page, "High Stress", true);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: medications (step 10)", () => {
  test("Crohn's users see IBD medications with brand examples and can toggle them", async ({
    page,
  }) => {
    await goToStep(page, "medications");
    await expect(page.getByText("Common IBD Medications")).toBeVisible();
    await expect(page.getByText("Common IBS Medications")).toHaveCount(0);

    await toggleOption(page, "Mesalamine");
    await expectOption(page, "Mesalamine", true);
    await expect(option(page, "Mesalamine")).toHaveAccessibleName(/Asacol/);
    await toggleOption(page, "Ustekinumab");
    await expectOption(page, "Ustekinumab", true);
    await expect(option(page, "Ustekinumab")).toHaveAccessibleName(/Stelara/);
    await beat(page);

    await toggleOption(page, "Mesalamine");
    await expectOption(page, "Mesalamine", false);
    const disclaimer = page.getByText(
      "Always consult your doctor before making medication changes",
    );
    await scrollUntilVisible(page, disclaimer);
    await expect(disclaimer).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("typed brand names select the generic; custom medications can be added and removed", async ({
    page,
  }) => {
    await goToStep(page, "medications");
    await expect(addButton(page)).toBeDisabled();

    await addCustom(page, "Add custom medication", "Humira");
    await expect(page.getByText("Your Custom Medications")).toHaveCount(0);
    await expectOption(page, "Adalimumab", true);

    await addCustom(page, "Add custom medication", "Cholestyramine", "enter");
    await expect(page.getByText("Your Custom Medications")).toBeVisible();
    await expect(removeButton(page, "Cholestyramine")).toHaveCount(1);
    await beat(page);

    await clickReveal(page, removeButton(page, "Cholestyramine"));
    await expect(page.getByText("Your Custom Medications")).toHaveCount(0);
    await expectOption(page, "Adalimumab", true);
    expect(pageErrors(page)).toEqual([]);
  });

  test("IBS and GERD users get IBS and reflux medication lists instead of IBD drugs", async ({
    page,
  }) => {
    await goToStep(page, "medications", { conditions: ["IBS", "GERD"] });
    await expect(page.getByText("Common IBS Medications")).toBeVisible();
    await expect(page.getByText("Common IBD Medications")).toHaveCount(0);
    await expect(option(page, "Mesalamine")).toHaveCount(0);

    await toggleOption(page, "Loperamide");
    await expectOption(page, "Loperamide", true);
    const reflux = page.getByText("Common Reflux (GERD) Medications");
    await scrollUntilVisible(page, reflux);
    await toggleOption(page, "Omeprazole");
    await expectOption(page, "Omeprazole", true);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: current symptoms (step 11)", () => {
  test("a selected symptom defaults to Moderate and its severity can be changed", async ({
    page,
  }) => {
    await goToStep(page, "symptoms");
    await expect(page.getByText(/No symptoms right now\?/)).toHaveCount(1);

    await toggleOption(page, "Bloating");
    await expectOption(page, "Bloating", true);
    const moderate = severity(page, "Bloating", "Moderate");
    const severe = severity(page, "Bloating", "Severe");
    await reveal(page, moderate);
    await expect(moderate).toBeChecked();
    await expect(severe).not.toBeChecked();

    await severe.click();
    await expect(severe).toBeChecked();
    await expect(moderate).not.toBeChecked();
    await severity(page, "Bloating", "Mild").click();
    await expect(severity(page, "Bloating", "Mild")).toBeChecked();
    await expectOption(page, "Bloating", true);
    await beat(page);

    await toggleOption(page, "Bloating");
    await expectOption(page, "Bloating", false);
    await expect(severity(page, "Bloating", "Mild")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("blood in stool shows a contact-your-doctor notice", async ({
    page,
  }) => {
    await goToStep(page, "symptoms");
    await expect(
      page.getByText(/contact your doctor or care team/),
    ).toHaveCount(0);
    await toggleOption(page, "Blood in Stool");
    await expectOption(page, "Blood in Stool", true);
    const notice = page.getByText(/contact your doctor or care team/);
    await scrollUntilVisible(page, notice);
    await expect(notice).toBeVisible();
    await beat(page);

    await toggleOption(page, "Blood in Stool");
    await expect(
      page.getByText(/contact your doctor or care team/),
    ).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("custom symptoms get a severity and can be removed; listed names are not duplicated", async ({
    page,
  }) => {
    await goToStep(page, "symptoms");
    await addCustom(page, "Add custom symptom", "diarrhea");
    await expect(page.getByText("Your Custom Symptoms")).toHaveCount(0);
    await expectOption(page, "Diarrhea", true);

    await addCustom(page, "Add custom symptom", "Headache", "enter");
    await expect(page.getByText("Your Custom Symptoms")).toBeVisible();
    const mild = severity(page, "Headache", "Mild");
    await clickReveal(page, mild);
    await expect(mild).toBeChecked();
    await beat(page);

    await clickReveal(page, removeButton(page, "Headache"));
    await expect(page.getByText("Your Custom Symptoms")).toHaveCount(0);
    await expectOption(page, "Diarrhea", true);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: thank you (step 12)", () => {
  test("shows honest benefits without a fake review prompt, and Continue moves on", async ({
    page,
  }) => {
    await goToStep(page, "thanks");
    await expect(page.getByText("Congratulations!")).toBeVisible();
    await expect(page.getByText("Love the app?")).toHaveCount(0);
    await expect(page.getByRole("button", { name: /Rate Now/ })).toHaveCount(0);
    const aiBenefit = page.getByText(
      "Ask the AI assistant about your tracked data",
    );
    await scrollUntilVisible(page, aiBenefit);
    await expect(aiBenefit).toBeVisible();
    await expect(page.getByText(/24\/7/)).toHaveCount(0);
    await beat(page);

    await next(page);
    await expect(page.getByText(HEADINGS.thanks, { exact: true })).toHaveCount(
      0,
    );
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Onboarding profile: navigation and accessibility", () => {
  test("Continue walks through all six profile steps in order (every step is optional)", async ({
    page,
  }) => {
    const subtitles: Record<Step, string> = {
      diet: "Select foods or ingredients that affect you",
      supplements: "Track vitamins and supplements you take",
      lifestyle: "Select factors that may affect your symptoms",
      medications: "Track medications you're currently taking",
      symptoms: "Select symptoms you're currently experiencing",
      thanks: "For trusting us with your health journey",
    };
    await goToStep(page, "diet");
    for (const [i, step] of ORDER.entries()) {
      if (i > 0) await next(page);
      await expectHeading(page, step);
      await expect(page.getByText(subtitles[step])).toBeVisible();
      await beat(page, 400);
    }
    await expect(page.getByText("Congratulations!")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("every button on steps 7-12 has an accessible name", async ({
    page,
  }) => {
    test.slow();
    await goToStep(page, "diet");
    await addCustom(page, "Add custom item", "Tomatoes");
    await expectAllButtonsNamed(page);
    await next(page);

    await expectHeading(page, "supplements");
    await addCustom(page, "Add custom supplement", "Turmeric");
    await expectAllButtonsNamed(page);
    await next(page);

    await expectHeading(page, "lifestyle");
    await addCustom(page, "Lifestyle factor", "Travel");
    await expectAllButtonsNamed(page);
    await next(page);

    await expectHeading(page, "medications");
    await addCustom(page, "Add custom medication", "Cholestyramine");
    await expectAllButtonsNamed(page);
    await next(page);

    await expectHeading(page, "symptoms");
    await addCustom(page, "Add custom symptom", "Headache");
    await expectAllButtonsNamed(page);
    await next(page);

    await expectHeading(page, "thanks");
    await expectAllButtonsNamed(page);
    await expect(tooltipButton(page, "Back")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("answers on every step survive Back and forward navigation", async ({
    page,
  }) => {
    test.slow();
    await goToStep(page, "diet");
    await toggleOption(page, "Dairy");
    await addCustom(page, "Add custom item", "Tomatoes");
    await next(page);

    await expectHeading(page, "supplements");
    await toggleOption(page, "Vitamin D");
    await clickReveal(page, timeToggle(page, "Vitamin D", "AM"));
    await addCustom(page, "Add custom supplement", "Turmeric");
    await next(page);

    await expectHeading(page, "lifestyle");
    await toggleOption(page, "Poor Sleep");
    await addCustom(page, "Lifestyle factor", "Travel", "enter");
    await next(page);

    await expectHeading(page, "medications");
    await toggleOption(page, "Mesalamine");
    await addCustom(page, "Add custom medication", "Cholestyramine");
    await next(page);

    await expectHeading(page, "symptoms");
    await toggleOption(page, "Bloating");
    await clickReveal(page, severity(page, "Bloating", "Severe"));
    await addCustom(page, "Add custom symptom", "Headache");
    await next(page);

    await expectHeading(page, "thanks");
    await beat(page);

    // Walk back through every step: each answer is still there.
    await back(page);
    await expectHeading(page, "symptoms");
    await expectOption(page, "Bloating", true);
    await reveal(page, severity(page, "Bloating", "Severe"));
    await expect(severity(page, "Bloating", "Severe")).toBeChecked();
    await expect(removeButton(page, "Headache")).toHaveCount(1);
    await beat(page);

    await back(page);
    await expectHeading(page, "medications");
    await expectOption(page, "Mesalamine", true);
    await expect(removeButton(page, "Cholestyramine")).toHaveCount(1);

    await back(page);
    await expectHeading(page, "lifestyle");
    await expectOption(page, "Poor Sleep", true);
    await scrollUntilVisible(page, removeButton(page, "Travel"));
    await expect(removeButton(page, "Travel")).toBeVisible();

    await back(page);
    await expectHeading(page, "supplements");
    await expect(removeButton(page, "Turmeric")).toHaveCount(1);
    await expectOption(page, "Vitamin D", true);
    await reveal(page, timeToggle(page, "Vitamin D", "AM"));
    await expect(timeToggle(page, "Vitamin D", "AM")).toBeChecked();
    await expect(timeToggle(page, "Vitamin D", "PM")).not.toBeChecked();

    await back(page);
    await expectHeading(page, "diet");
    await expect(removeButton(page, "Tomatoes")).toHaveCount(1);
    await expectOption(page, "Dairy", true);
    await beat(page);

    // Back once more leaves the profile section (notification preferences).
    await back(page);
    await expect(page.getByText(HEADINGS.diet, { exact: true })).toHaveCount(0);

    // And forward again lands on the same answers.
    await advance(page, /^Skip$/);
    await expectHeading(page, "diet");
    await expectOption(page, "Dairy", true);
    expect(pageErrors(page)).toEqual([]);
  });
});
