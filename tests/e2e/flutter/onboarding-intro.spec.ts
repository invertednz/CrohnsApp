import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  beat,
  boot,
  button,
  expectText,
  pageErrors,
  scrollUntilVisible,
  tap,
} from "./helpers";

/*
 * Onboarding intro, steps 0-6 of OnboardingFlow:
 *   0 Welcome -> 1 Condition -> 2 Goal -> 3 What to Expect -> 4 Tracking journey
 *   -> 5 App tour ("How It Works") -> 6 Notification Preferences -> (7 Diet considerations)
 *
 * OnboardingFlow cross-fades steps with an AnimatedSwitcher, so for ~300ms both
 * the outgoing and incoming step are in the semantics tree. Every step change
 * below waits for the outgoing step's heading to disappear before touching the
 * next step, so a stale "Continue"/"Back" from the old step is never clicked.
 */

const CONDITIONS = [
  "Crohn's Disease",
  "Ulcerative Colitis",
  "IBS",
  "IBD (Other)",
  "Celiac Disease",
  "GERD",
  "Other Digestive Condition",
  "Not Sure / Undiagnosed",
] as const;

const GOALS = [
  "Reduce Symptoms",
  "Identify Triggers",
  "Improve Diet",
  "Better Understanding",
  "Overall Wellness",
] as const;

const REMINDER_TIMES = ["Morning", "Midday", "Afternoon", "Evening"] as const;

const HEADINGS = {
  welcome: "Find what calms your gut",
  condition: /What condition\(s\)\s+are you managing\?/,
  goal: "What's your main goal?",
  expected: "What to Expect",
  journey: "Your Tracking Journey",
  // Case-sensitive: "daily tracking reminders" on the next step must not match.
  appTourCard: /Daily Tracking/,
  appTourLastCard: /AI Assistant/,
  notifications: "Notification Preferences",
  // Step 7 heading. The diet cards are checkboxes whose names live in
  // aria-label (not text nodes), so match the rendered heading instead.
  dietStep: /^Diet Considerations$/,
};

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

/** A selectable option card (condition, goal or reminder time) by its title. */
function option(page: Page, title: string): Locator {
  return page.getByRole("button", {
    name: new RegExp(`^${escapeRe(title)}(\\s|$)`),
  });
}

/**
 * The header Back (icon) button. Its tooltip is "Back"; after a click the mouse
 * stays over the same spot, so the next step's Back button is hovered and its
 * tooltip is shown, which Flutter adds to the button's semantics ("Back Back").
 */
function backButton(page: Page): Locator {
  return page.getByRole("button", { name: /^Back(?: Back)?$/ });
}

function continueButton(page: Page): Locator {
  return button(page, /^Continue$/);
}

async function choose(page: Page, title: string): Promise<void> {
  const target = option(page, title);
  await scrollUntilVisible(page, target);
  await target.click();
}

/** Selected option cards expose aria-current="true" (Flutter `Semantics(selected:)`). */
async function expectSelected(
  page: Page,
  title: string,
  selected = true,
): Promise<void> {
  const target = option(page, title);
  await scrollUntilVisible(page, target);
  if (selected) {
    await expect(target).toHaveAttribute("aria-current", "true");
  } else {
    await expect(target).not.toHaveAttribute("aria-current", "true");
  }
}

/** Wait until `leaving` has gone and `arriving` is on screen. */
async function arrive(
  page: Page,
  leaving: string | RegExp,
  arriving: string | RegExp,
): Promise<void> {
  await expect(page.getByText(leaving)).toHaveCount(0);
  await expectText(page, arriving);
}

async function startOnboarding(page: Page): Promise<void> {
  await boot(page);
  await tap(page, "Get Started");
  await arrive(page, HEADINGS.welcome, HEADINGS.condition);
}

type Step =
  "condition" | "goal" | "expected" | "journey" | "appTour" | "notifications";
const ORDER: Step[] = [
  "condition",
  "goal",
  "expected",
  "journey",
  "appTour",
  "notifications",
];

/** Walk forward from Welcome to `target`, making the minimum valid choices. */
async function goTo(page: Page, target: Step): Promise<void> {
  await startOnboarding(page);
  for (const step of ORDER.slice(0, ORDER.indexOf(target))) {
    switch (step) {
      case "condition":
        await choose(page, "Crohn's Disease");
        await continueButton(page).click();
        await arrive(page, HEADINGS.condition, HEADINGS.goal);
        break;
      case "goal":
        await choose(page, "Reduce Symptoms");
        await continueButton(page).click();
        await arrive(page, HEADINGS.goal, HEADINGS.expected);
        break;
      case "expected":
        await continueButton(page).click();
        await expect(page.getByText(HEADINGS.expected)).toHaveCount(0);
        await expect(continueButton(page)).toBeVisible();
        break;
      case "journey":
        await continueButton(page).click();
        await expectText(page, HEADINGS.appTourCard);
        break;
      case "appTour":
        await walkAppTourToEnd(page);
        await continueButton(page).click();
        await arrive(page, HEADINGS.appTourLastCard, HEADINGS.notifications);
        break;
      default:
        break;
    }
  }
}

/** App tour: tap Next through the four cards; ends on the last card. */
async function walkAppTourToEnd(page: Page): Promise<void> {
  for (const title of ["Smart Insights", "Diet Management", "AI Assistant"]) {
    await button(page, /^Next$/).click();
    await expectText(page, title);
  }
  await expect(continueButton(page)).toBeVisible();
}

/** Role=button nodes with no accessible name (icon-only buttons missing a tooltip/label). */
async function unnamedButtonCount(page: Page): Promise<number> {
  return page
    .locator('flt-semantics[role="button"]')
    .evaluateAll(
      (els) =>
        els.filter(
          (el) =>
            !(
              (el.getAttribute("aria-label") ?? "") + (el.textContent ?? "")
            ).trim(),
        ).length,
    );
}

test.describe("Onboarding intro (steps 0-6)", () => {
  // ---------------------------------------------------------------- Welcome
  test("Welcome shows honest value propositions instead of unverified clinical claims", async ({
    page,
  }) => {
    await boot(page);
    await expectText(page, HEADINGS.welcome);
    await expectText(
      page,
      "Check in daily, snap your meals, and let AI spot your patterns.",
    );
    await expectText(page, "Made for Crohn's, colitis & IBS");
    for (const feature of [
      "Quick daily check-ins",
      "Meal & trigger diary",
      "AI pattern insights",
      "Meds & supplements log",
    ]) {
      await expectText(page, feature);
    }
    await expectText(page, /does not diagnose or treat any condition/);
    await beat(page);

    // The old unsubstantiated claims and statistics are gone.
    for (const claim of [
      "Clinically Validated",
      "87%",
      "92%",
      "10k+",
      "4.8★",
      "peer-reviewed",
      "proven to help",
    ]) {
      await expect(page.getByText(claim)).toHaveCount(0);
    }
    await expect(button(page, "Get Started")).toBeVisible();
    await expect(button(page, "Log In")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Welcome: Log In opens the sign-in screen", async ({ page }) => {
    await boot(page);
    await tap(page, "Log In");
    await expect(page.getByRole("textbox", { name: /Email/ })).toBeVisible({
      timeout: 15_000,
    });
    await expect(page.getByRole("textbox", { name: /Password/ })).toBeVisible();
    await expect(button(page, /^Sign In$/)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Welcome: Back from the sign-in screen returns to the welcome screen", async ({
    page,
  }) => {
    await boot(page);
    await tap(page, "Log In");
    await expect(button(page, /^Sign In$/)).toBeVisible({ timeout: 15_000 });
    await backButton(page).click();
    await expect(button(page, /^Sign In$/)).toHaveCount(0);
    await expect(button(page, "Get Started")).toBeVisible();
    await expectText(page, HEADINGS.welcome);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Welcome: Get Started opens step 1 with Continue disabled until a condition is chosen", async ({
    page,
  }) => {
    await startOnboarding(page);
    await expectText(page, /^Onboarding progress \d+ percent$/);
    await expectText(page, "Select all that apply");
    const disabled = button(page, /^Select at least one condition$/);
    await expect(disabled).toBeVisible();
    await expect(disabled).toBeDisabled();
    await expect(continueButton(page)).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  // -------------------------------------------------------------- Condition
  test("Condition: all eight conditions are listed with descriptions", async ({
    page,
  }) => {
    await startOnboarding(page);
    for (const condition of CONDITIONS) {
      const card = option(page, condition);
      await scrollUntilVisible(page, card);
      await expect(card).toBeVisible();
    }
    await expect(option(page, "Crohn's Disease")).toHaveAccessibleName(
      /inflammatory bowel disease/i,
    );
    await expect(option(page, "Not Sure / Undiagnosed")).toHaveAccessibleName(
      /no formal diagnosis/i,
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("Condition: several conditions can be selected and toggled off again", async ({
    page,
  }) => {
    await startOnboarding(page);
    await choose(page, "Crohn's Disease");
    await choose(page, "Ulcerative Colitis");
    await choose(page, "IBS");
    await expect(continueButton(page)).toBeEnabled();
    await beat(page);

    // Deselect all three: Continue is disabled again.
    await choose(page, "Crohn's Disease");
    await choose(page, "Ulcerative Colitis");
    await expect(continueButton(page)).toBeEnabled();
    await choose(page, "IBS");
    await expect(
      button(page, /^Select at least one condition$/),
    ).toBeDisabled();
    await expect(continueButton(page)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Condition: every option can be selected on its own to continue", async ({
    page,
  }) => {
    await startOnboarding(page);
    for (const condition of CONDITIONS) {
      await choose(page, condition);
      await expect(continueButton(page)).toBeEnabled();
      await choose(page, condition);
      await expect(
        button(page, /^Select at least one condition$/),
      ).toBeDisabled();
    }
    expect(pageErrors(page)).toEqual([]);
  });

  test("Condition: option cards announce their selected state", async ({
    page,
  }) => {
    await startOnboarding(page);
    await expectSelected(page, "GERD", false);
    await choose(page, "GERD");
    await choose(page, "Celiac Disease");
    await expectSelected(page, "GERD");
    await expectSelected(page, "Celiac Disease");
    await expectSelected(page, "IBS", false);
    await choose(page, "GERD");
    await expectSelected(page, "GERD", false);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Condition: Back returns to the welcome screen", async ({ page }) => {
    await startOnboarding(page);
    await backButton(page).click();
    await arrive(page, HEADINGS.condition, HEADINGS.welcome);
    await expect(button(page, "Get Started")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Condition: selections are remembered after going back from the goal step", async ({
    page,
  }) => {
    await startOnboarding(page);
    await choose(page, "Crohn's Disease");
    await choose(page, "Ulcerative Colitis");
    await continueButton(page).click();
    await arrive(page, HEADINGS.condition, HEADINGS.goal);

    await backButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.condition);
    await expect(continueButton(page)).toBeEnabled();
    await expectSelected(page, "Crohn's Disease");
    await expectSelected(page, "Ulcerative Colitis");
    await expectSelected(page, "IBS", false);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  // ------------------------------------------------------------------- Goal
  test("Goal: Continue stays disabled until a goal is picked", async ({
    page,
  }) => {
    await goTo(page, "goal");
    await expectText(page, "Help us personalize your experience");
    const disabled = button(page, /^Select a goal to continue$/);
    await expect(disabled).toBeVisible();
    await expect(disabled).toBeDisabled();

    await choose(page, "Better Understanding");
    await expect(continueButton(page)).toBeEnabled();
    await continueButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.expected);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Goal: each of the five goals can be chosen and only one is active at a time", async ({
    page,
  }) => {
    await goTo(page, "goal");
    for (const goal of GOALS) {
      await choose(page, goal);
      await expectSelected(page, goal);
      for (const other of GOALS.filter((g) => g !== goal)) {
        await expectSelected(page, other, false);
      }
      await expect(continueButton(page)).toBeEnabled();
      await beat(page, 300);
    }
    expect(pageErrors(page)).toEqual([]);
  });

  test("Goal: chosen goal is kept after going back from What to Expect", async ({
    page,
  }) => {
    await goTo(page, "goal");
    await choose(page, "Improve Diet");
    await continueButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.expected);

    await backButton(page).click();
    await arrive(page, HEADINGS.expected, HEADINGS.goal);
    await expectSelected(page, "Improve Diet");
    await expect(continueButton(page)).toBeEnabled();

    // And Back again reaches the condition step with its selection intact.
    await backButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.condition);
    await expectSelected(page, "Crohn's Disease");
    expect(pageErrors(page)).toEqual([]);
  });

  // --------------------------------------------------------- What to Expect
  test("What to Expect lists what tracking helps with, without outcome promises", async ({
    page,
  }) => {
    await goTo(page, "expected");
    await expectText(
      page,
      "Consistent tracking helps you and your care team see the full picture",
    );
    for (const benefit of [
      "Clearer Bowel Patterns",
      "A Record of Pain & Flares",
      "Possible Food Triggers",
      "Energy & Wellbeing Trends",
      "Better-Informed Appointments",
    ]) {
      await expectText(page, benefit);
    }
    await expectText(page, /not a treatment/);
    await beat(page);

    for (const promise of [
      "Real results from consistent tracking",
      "Reduced Pain & Discomfort",
      "Increased Energy Levels",
      "Better Mental Clarity",
    ]) {
      await expect(page.getByText(promise)).toHaveCount(0);
    }
    expect(pageErrors(page)).toEqual([]);
  });

  // ------------------------------------------------------- Tracking journey
  test("Tracking journey: chart is labelled as an illustration with a matching legend", async ({
    page,
  }) => {
    await goTo(page, "journey");
    await expectText(page, HEADINGS.journey);
    await expectText(page, "Insights Grow With Your Data");
    await expect(
      page.getByRole("img", { name: /^Illustrative chart/ }),
    ).toBeVisible();
    await expectText(page, "Learning phase");
    await expectText(page, "Pattern insights");
    await expectText(
      page,
      "Illustration only, not a prediction of your results",
    );
    await expectText(page, "Slide 1 of 5");
    await expect(page.getByText("Symptom Improvement Over Time")).toHaveCount(
      0,
    );
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Tracking journey: arrow buttons step through all five slides and back", async ({
    page,
  }) => {
    await goTo(page, "journey");
    await expect(button(page, "Previous slide")).toHaveCount(0);

    const milestones: Array<[string, string]> = [
      ["Week 1-2", "Getting Started"],
      ["Week 3-4", "Early Patterns"],
      ["Week 5-8", "Testing Changes"],
      ["Week 9+", "The Long-Term Picture"],
    ];
    for (const [i, [week, title]] of milestones.entries()) {
      await button(page, "Next slide").click();
      await expectText(page, `Slide ${i + 2} of 5`);
      await expectText(page, week);
      await expectText(page, title);
      await beat(page);
    }
    await expect(button(page, "Next slide")).toHaveCount(0);

    await button(page, "Previous slide").click();
    await expectText(page, "Slide 4 of 5");
    await expectText(page, "Week 5-8");

    // Continue works from any slide.
    await continueButton(page).click();
    await expectText(page, HEADINGS.appTourCard);
    expect(pageErrors(page)).toEqual([]);
  });

  // --------------------------------------------------------------- App tour
  test("App tour: Next and Previous walk through the four feature cards", async ({
    page,
  }) => {
    await goTo(page, "appTour");
    await expectText(page, "How It Works");
    await expect(button(page, /^Previous$/)).toHaveCount(0);

    await button(page, /^Next$/).click();
    await expectText(page, "Smart Insights");
    await expect(button(page, /^Previous$/)).toBeVisible();
    await button(page, /^Previous$/).click();
    await expectText(page, HEADINGS.appTourCard);
    await expect(button(page, /^Previous$/)).toHaveCount(0);

    await walkAppTourToEnd(page);
    await beat(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.appTourLastCard, HEADINGS.notifications);
    expect(pageErrors(page)).toEqual([]);
  });

  test("App tour: feature cards describe real app capabilities", async ({
    page,
  }) => {
    await goTo(page, "appTour");
    await expectText(page, "Feature 1 of 4");
    await expectText(page, "Bowel movement log");
    await expectText(page, "Medication & supplement checklists");

    await button(page, /^Next$/).click();
    await expectText(page, "Feature 2 of 4");
    await expectText(page, "Possible food trigger detection");

    await button(page, /^Next$/).click();
    await expectText(page, "Meal photo analysis");
    await expectText(page, "Personal trigger & safe food lists");

    await button(page, /^Next$/).click();
    await expectText(page, "Feature 4 of 4");
    await expectText(page, /does not replace medical advice/);
    await expectText(page, "Answers that consider your own logs");
    await beat(page);

    // Claims for features the app does not have are gone.
    for (const claim of [
      "Evidence-based answers",
      "Personalized advice",
      "Symptom guidance",
    ]) {
      await expect(page.getByText(claim)).toHaveCount(0);
    }
    expect(pageErrors(page)).toEqual([]);
  });

  test("App tour: Previous and Next buttons line up (Previous label does not wrap)", async ({
    page,
  }) => {
    await goTo(page, "appTour");
    await button(page, /^Next$/).click();
    await expectText(page, "Smart Insights");
    const prev = await button(page, /^Previous$/).boundingBox();
    const next = await button(page, /^Next$/).boundingBox();
    expect(prev).not.toBeNull();
    expect(next).not.toBeNull();
    expect(Math.abs(prev!.height - next!.height)).toBeLessThanOrEqual(2);
    expect(Math.abs(prev!.y - next!.y)).toBeLessThanOrEqual(2);
    expect(pageErrors(page)).toEqual([]);
  });

  // ---------------------------------------------------------- Notifications
  test("Notifications: Continue needs a reminder time and several times can be chosen", async ({
    page,
  }) => {
    await goTo(page, "notifications");
    await expectText(page, "When would you like to receive reminders?");
    const disabled = button(page, /^Select at least one$/);
    await expect(disabled).toBeVisible();
    await expect(disabled).toBeDisabled();

    for (const time of REMINDER_TIMES) {
      await scrollUntilVisible(page, option(page, time));
    }
    await choose(page, "Morning");
    await expect(continueButton(page)).toBeEnabled();
    await choose(page, "Evening");
    await expect(continueButton(page)).toBeEnabled();
    await beat(page);

    // Deselecting every time disables Continue again.
    await choose(page, "Morning");
    await choose(page, "Evening");
    await expect(button(page, /^Select at least one$/)).toBeDisabled();

    await choose(page, "Afternoon");
    await continueButton(page).click();
    await arrive(page, HEADINGS.notifications, HEADINGS.dietStep);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Notifications: Skip moves on to diet considerations without choosing a time", async ({
    page,
  }) => {
    await goTo(page, "notifications");
    await expectText(page, /Reminders are optional/);
    await expect(
      page.getByText(/change these settings anytime in your profile/),
    ).toHaveCount(0);
    await button(page, /^Skip$/).click();
    await arrive(page, HEADINGS.notifications, HEADINGS.dietStep);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Notifications: chosen times are kept after going back to the app tour", async ({
    page,
  }) => {
    await goTo(page, "notifications");
    await choose(page, "Midday");
    await choose(page, "Evening");
    await expectSelected(page, "Midday");
    await expectSelected(page, "Evening");

    await backButton(page).click();
    await arrive(page, HEADINGS.notifications, HEADINGS.appTourCard);
    await walkAppTourToEnd(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.appTourLastCard, HEADINGS.notifications);

    await expect(continueButton(page)).toBeEnabled();
    await expectSelected(page, "Midday");
    await expectSelected(page, "Evening");
    await expectSelected(page, "Morning", false);
    expect(pageErrors(page)).toEqual([]);
  });

  // ------------------------------------------------------- Cross-step flows
  test("Back navigation walks from Notification Preferences all the way to Welcome", async ({
    page,
  }) => {
    await goTo(page, "notifications");

    await backButton(page).click();
    await arrive(page, HEADINGS.notifications, HEADINGS.appTourCard);
    await backButton(page).click();
    await arrive(page, HEADINGS.appTourCard, HEADINGS.journey);
    await backButton(page).click();
    await arrive(page, HEADINGS.journey, HEADINGS.expected);
    await backButton(page).click();
    await arrive(page, HEADINGS.expected, HEADINGS.goal);
    await expectSelected(page, "Reduce Symptoms");
    await backButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.condition);
    await expectSelected(page, "Crohn's Disease");
    await backButton(page).click();
    await arrive(page, HEADINGS.condition, HEADINGS.welcome);
    await expect(button(page, "Get Started")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Every button on onboarding steps 0-6 has an accessible name", async ({
    page,
  }) => {
    await boot(page);
    expect(await unnamedButtonCount(page), "welcome").toBe(0);

    await tap(page, "Get Started");
    await arrive(page, HEADINGS.welcome, HEADINGS.condition);
    expect(await unnamedButtonCount(page), "condition").toBe(0);
    await choose(page, "IBS");
    await continueButton(page).click();

    await arrive(page, HEADINGS.condition, HEADINGS.goal);
    expect(await unnamedButtonCount(page), "goal").toBe(0);
    await choose(page, "Overall Wellness");
    await continueButton(page).click();

    await arrive(page, HEADINGS.goal, HEADINGS.expected);
    expect(await unnamedButtonCount(page), "what to expect").toBe(0);
    await continueButton(page).click();

    await arrive(page, HEADINGS.expected, HEADINGS.journey);
    expect(await unnamedButtonCount(page), "journey, first slide").toBe(0);
    await button(page, "Next slide").click();
    await expectText(page, "Slide 2 of 5");
    expect(await unnamedButtonCount(page), "journey, second slide").toBe(0);
    await continueButton(page).click();

    await arrive(page, HEADINGS.journey, HEADINGS.appTourCard);
    expect(await unnamedButtonCount(page), "app tour").toBe(0);
    await walkAppTourToEnd(page);
    await continueButton(page).click();

    await arrive(page, HEADINGS.appTourLastCard, HEADINGS.notifications);
    expect(await unnamedButtonCount(page), "notifications").toBe(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Full intro walkthrough: welcome to diet considerations with a choice on every step", async ({
    page,
  }) => {
    await boot(page);
    await beat(page);
    await tap(page, "Get Started");
    await arrive(page, HEADINGS.welcome, HEADINGS.condition);

    await choose(page, "Crohn's Disease");
    await choose(page, "IBS");
    await beat(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.condition, HEADINGS.goal);

    await choose(page, "Identify Triggers");
    await beat(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.goal, HEADINGS.expected);
    await beat(page);

    await continueButton(page).click();
    await expect(page.getByText(HEADINGS.expected)).toHaveCount(0);
    await beat(page);
    await continueButton(page).click();

    await expectText(page, HEADINGS.appTourCard);
    await walkAppTourToEnd(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.appTourLastCard, HEADINGS.notifications);

    await choose(page, "Morning");
    await choose(page, "Evening");
    await beat(page);
    await continueButton(page).click();
    await arrive(page, HEADINGS.notifications, HEADINGS.dietStep);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});
