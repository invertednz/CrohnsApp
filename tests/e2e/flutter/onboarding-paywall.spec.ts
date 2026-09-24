import { expect, test, type Page } from "@playwright/test";
import {
  beat,
  boot,
  button,
  expectText,
  field,
  onScreen,
  openTab,
  pageErrors,
  scrollUntilVisible,
  tap,
  holdToCommit,
} from "./helpers";

/**
 * Onboarding steps 13-15 and the paywall branches: Trial Offer, Timeline,
 * Compare Plans, checkout, the new-member offer, referral sharing and the
 * hand-off to account creation. The app processes no payments, so every
 * screen must say so honestly and never pretend a charge happened.
 */

const TRIAL_DAYS = 7;

/** Main onboarding steps animate for 300ms; wait so only one screen is on stage. */
async function settle(page: Page): Promise<void> {
  await page.waitForTimeout(450);
}

async function press(page: Page, name: string | RegExp): Promise<void> {
  await tap(page, name);
  await settle(page);
}

async function isEnabledButton(page: Page, name: RegExp): Promise<boolean> {
  const target = button(page, name).first();
  return (
    (await target.count()) > 0 &&
    (await target.isVisible()) &&
    (await target.isEnabled())
  );
}

/** Text shown either as plain text or as the accessible name of a group/button. */
async function expectShown(page: Page, text: string): Promise<void> {
  const screen = onScreen(page);
  const target = screen
    .getByText(text)
    .or(screen.locator(`[aria-label*="${text}"]`))
    .first();
  await scrollUntilVisible(page, target);
  await expect(target).toBeVisible();
}

interface Answers {
  supplement?: string;
  medication?: string;
}

/**
 * Walks the question steps (1-12) with minimal answers until the Trial Offer
 * (step 13) is on screen. Optionally adds a custom supplement and medication.
 */
async function fastForwardToTrialOffer(
  page: Page,
  answers: Answers = {},
): Promise<void> {
  await boot(page);
  await press(page, "Get Started");
  let addedSupplement = !answers.supplement;
  let addedMedication = !answers.medication;

  for (let i = 0; i < 40; i++) {
    if (await isEnabledButton(page, /^Try for \$0\.00/)) return;

    if (
      !addedSupplement &&
      (await field(page, /Add custom supplement/).count())
    ) {
      const input = field(page, /Add custom supplement/).first();
      await input.click();
      await input.fill(answers.supplement!);
      await button(page, /^Add$/).first().click();
      await expectShown(page, answers.supplement!);
      addedSupplement = true;
      continue;
    }
    if (
      !addedMedication &&
      (await field(page, /Add custom medication/).count())
    ) {
      const input = field(page, /Add custom medication/).first();
      await input.click();
      await input.fill(answers.medication!);
      await button(page, /^Add$/).first().click();
      await expectShown(page, answers.medication!);
      addedMedication = true;
      continue;
    }

    if (await isEnabledButton(page, /^Continue$/)) {
      await press(page, /^Continue$/);
    } else if (await isEnabledButton(page, /^Start my plan$/)) {
      await press(page, /^Start my plan$/); // personal plan reveal
    } else if (await isEnabledButton(page, /^Hold to commit$/)) {
      await holdToCommit(page); // commitment step
      await settle(page);
    } else if (await isEnabledButton(page, /^Crohn's Disease/)) {
      await press(page, /^Crohn's Disease/); // step 1 needs a condition
    } else if (await isEnabledButton(page, /^Reduce Symptoms/)) {
      await press(page, /^Reduce Symptoms/); // step 2 needs a goal
    } else if (await isEnabledButton(page, /^Skip$/)) {
      await press(page, /^Skip$/); // notification times are optional
    } else if (await isEnabledButton(page, /^Next$/)) {
      await press(page, /^Next$/);
    } else {
      await settle(page);
    }
  }
  await expect(button(page, /^Try for \$0\.00/)).toBeVisible();
}

async function openTimeline(page: Page): Promise<void> {
  await fastForwardToTrialOffer(page);
  await press(page, /^Try for \$0\.00/);
  await expect(button(page, /^Try for FREE/)).toBeVisible();
}

async function openComparePlans(page: Page): Promise<void> {
  await openTimeline(page);
  await press(page, /^Compare plans$/);
  await expect(button(page, /^Continue with Annual/)).toBeVisible();
}

async function openCheckout(
  page: Page,
  plan: RegExp = /^Annual/,
): Promise<void> {
  await openComparePlans(page);
  await press(page, plan);
  await press(page, /^Continue with/);
  await expect(
    button(page, `Start ${TRIAL_DAYS}-day free trial`),
  ).toBeVisible();
}

async function openOffer(page: Page): Promise<void> {
  await openComparePlans(page);
  await press(page, /^No thanks$/);
  await expect(button(page, /^Claim offer/)).toBeVisible();
}

async function openReferral(page: Page): Promise<string> {
  await openOffer(page);
  await press(page, /^Claim offer/);
  await expectText(page, "Share GutMD");
  return readReferralCode(page);
}

/** Reads the personal code shown on its own line beneath the "Your Referral Code" label. */
async function readReferralCode(page: Page): Promise<string> {
  const label = onScreen(page).getByText("Your Referral Code", { exact: true });
  await scrollUntilVisible(page, label);
  const code = onScreen(page).getByText(/^[A-HJ-NP-Z2-9]{8}$/);
  await expect(
    code,
    "exactly one 8-character referral code on screen",
  ).toHaveCount(1);
  await expect(code).toBeVisible();
  const labelBox = await label.boundingBox();
  const codeBox = await code.boundingBox();
  expect(labelBox && codeBox, "label and code are laid out").toBeTruthy();
  // The code sits directly under its label inside the same card.
  expect(codeBox!.y).toBeGreaterThan(labelBox!.y);
  expect(codeBox!.y - (labelBox!.y + labelBox!.height)).toBeLessThan(60);
  return ((await code.textContent()) ?? "").trim();
}

/** Account creation is where signed-out users land when onboarding ends. */
async function expectAccountCreation(page: Page): Promise<void> {
  await expect(page.getByText(/Create (your )?Account/i).first()).toBeVisible({
    timeout: 15_000,
  });
  await expect(field(page, "Email").first()).toBeVisible();
}

async function readClipboard(page: Page): Promise<string> {
  return page.evaluate(() => navigator.clipboard.readText());
}

/** Copy that must never appear: fake charges, fake donors, false reminders. */
async function expectNoDishonestCopy(page: Page): Promise<void> {
  for (const text of [
    /sponsored your/i,
    /Processing/i,
    /Credit Card/i,
    /Apple Pay/i,
    /send (you )?a reminder/i,
    /3-day/i,
    /Crohn's Companion/i,
  ]) {
    await expect(page.getByText(text)).toHaveCount(0);
  }
}

test.describe("Onboarding paywall", () => {
  // Every test walks the 12 question steps first.
  test.describe.configure({ timeout: 180_000 });

  test("trial offer explains the free trial honestly", async ({ page }) => {
    await fastForwardToTrialOffer(page);
    await expectText(page, "Try GutMD free");
    await expectText(
      page,
      "No payment today, full access to all features, cancel any time",
    );
    await expectText(page, `Your ${TRIAL_DAYS}-day free trial runs until`);
    await expectText(page, "You are never charged automatically");
    await expectText(page, `during your ${TRIAL_DAYS}-day trial`);
    await expectNoDishonestCopy(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("trial offer back button returns to the commitment step", async ({
    page,
  }) => {
    await fastForwardToTrialOffer(page);
    await press(page, /^Back$/);
    await expectText(page, "Make a promise to yourself");
    await beat(page);
    await holdToCommit(page);
    await expect(button(page, /^Try for \$0\.00/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Try for $0.00 opens the trial timeline with an honest schedule", async ({
    page,
  }) => {
    await openTimeline(page);
    await expectText(page, "How your free trial works");
    await expectText(page, "Today");
    await expectText(page, "No payment details needed");
    await expectText(page, `In ${TRIAL_DAYS} days`);
    await expectText(page, "you are never charged automatically");
    await expectText(page, "then $49/year");
    await expect(button(page, /^Compare plans$/)).toBeVisible();
    await expectNoDishonestCopy(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("timeline back button returns to the trial offer", async ({ page }) => {
    await openTimeline(page);
    await press(page, /^Back$/);
    await expect(button(page, /^Try for \$0\.00/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("timeline Try for FREE starts the trial and opens account creation", async ({
    page,
  }) => {
    await openTimeline(page);
    await press(page, /^Try for FREE/);
    await expectAccountCreation(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("compare plans lists every plan with consistent prices and trial terms", async ({
    page,
  }) => {
    await openComparePlans(page);
    await expectText(page, "Compare Plans");
    await expect(button(page, /^Annual.*Save 59%.*\$49.*\/year/)).toBeVisible();
    await expect(button(page, /^Monthly.*\$9\.99.*\/month/)).toBeVisible();
    await scrollUntilVisible(
      page,
      button(page, /^Pay It Forward.*\$59.*\/year/),
    );
    await expectText(
      page,
      `All plans start with a ${TRIAL_DAYS}-day free trial`,
    );
    await expectText(page, "you are never charged automatically");
    await expect(
      page.getByText(/Smart reminders|Priority support|sponsors someone/i),
    ).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("compare plans: picking a plan updates the continue button and shows its features", async ({
    page,
  }) => {
    await openComparePlans(page);
    await expect(button(page, /^Annual.*Meal photo analysis/)).toBeVisible();

    await press(page, /^Monthly/);
    await expect(button(page, /^Continue with Monthly/)).toBeVisible();
    await expect(
      button(page, /^Monthly.*AI health assistant chat/),
    ).toBeVisible();
    await beat(page);

    await press(page, /^Pay It Forward/);
    await expect(button(page, /^Continue with Pay It Forward/)).toBeVisible();
    await expect(
      button(page, /^Pay It Forward.*Everything in Annual/),
    ).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("compare plans back button returns to the timeline", async ({
    page,
  }) => {
    await openComparePlans(page);
    await press(page, /^Back$/);
    await expect(button(page, /^Try for FREE/)).toBeVisible();
    await expect(button(page, /^Compare plans$/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("checkout keeps the chosen plan and collects no payment details", async ({
    page,
  }) => {
    await openCheckout(page, /^Monthly/);
    await expectText(page, "Unlock Your Full Health Journey");
    await expectText(page, `Start your ${TRIAL_DAYS}-day free trial today`);
    await expect(button(page, /^Monthly Plan/)).toBeVisible();
    await expectText(page, "Then $9.99/month if you choose to continue");
    await expectText(page, "No payment details are collected");
    await expectNoDishonestCopy(page);
    await expect(page.getByText(/Google Pay/i)).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("checkout: Change plan lets you switch to another plan", async ({
    page,
  }) => {
    await openCheckout(page, /^Monthly/);
    await press(page, /^Change plan$/);
    await expectText(page, "Choose Your Plan");
    await press(page, /^BEST VALUE/);
    await expectText(page, "Then $49/year if you choose to continue");
    await scrollUntilVisible(page, button(page, /^PAY IT FORWARD/));
    await press(page, /^PAY IT FORWARD/);
    await expectText(page, "Then $59/year if you choose to continue");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("checkout: starting the free trial opens account creation", async ({
    page,
  }) => {
    await openCheckout(page);
    await press(page, `Start ${TRIAL_DAYS}-day free trial`);
    await expectAccountCreation(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("checkout back button returns to compare plans", async ({ page }) => {
    await openCheckout(page, /^Monthly/);
    await press(page, /^Back$/);
    await expectText(page, "Compare Plans");
    await expect(button(page, /^Continue with Monthly/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("checkout close button leads to the new member offer", async ({
    page,
  }) => {
    await openCheckout(page);
    await press(page, /^Close$/);
    await expectText(page, "NEW MEMBER OFFER");
    await expectText(page, "Your first year for $29");
    await expect(button(page, /^Claim offer – \$29\/year/)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("No thanks on compare plans shows an honest new member offer", async ({
    page,
  }) => {
    await openOffer(page);
    await expectText(page, "Your first year for $29");
    await expectText(
      page,
      `You still start with a ${TRIAL_DAYS}-day free trial`,
    );
    await expectText(page, "First year only, then $49/year");
    await expectText(page, "Save $20 on your first year");
    await expectText(page, "No payment today");
    await expectNoDishonestCopy(page);
    await expect(
      page.getByText(/YOU JUST RECEIVED A GIFT|matched this gift/i),
    ).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("declining the offer finishes onboarding at account creation", async ({
    page,
  }) => {
    await openOffer(page);
    await press(page, /No thanks – continue without the offer/);
    await expectAccountCreation(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("claiming the offer opens referral sharing with a personal code", async ({
    page,
  }) => {
    const code = await openReferral(page);
    expect(code).toMatch(/^[A-HJ-NP-Z2-9]{8}$/);
    await expectText(page, "Invite them with your personal code");
    await expectText(
      page,
      "Each friend who subscribes with your code earns you a $10 credit",
    );
    await expectText(
      page,
      "Your code is saved to your account when you sign up.",
    );
    await expectText(page, "$0 / $50");
    await expectText(page, "They enter it when they sign up for GutMD");
    await expectNoDishonestCopy(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("referral: the copy button copies the code", async ({
    page,
    context,
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    const code = await openReferral(page);
    await press(page, /^Copy referral code$/);
    await expectText(page, "Referral code copied");
    expect(await readClipboard(page)).toBe(code);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("referral: Share Your Code works on the web by copying the invite", async ({
    page,
    context,
  }) => {
    await context.grantPermissions(["clipboard-read", "clipboard-write"]);
    const code = await openReferral(page);
    await press(page, /^Share Your Code$/);
    await expectText(page, "Invite message copied");
    const invite = await readClipboard(page);
    expect(invite).toContain(code);
    expect(invite).toContain("GutMD");
    expect(invite).not.toMatch(/Crohn's Companion|life-changing|both save/i);
    // The app is still here: no navigation to a mail client, no crash.
    await expectText(page, "Share GutMD");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("referral: Continue to App finishes onboarding at account creation", async ({
    page,
  }) => {
    await openReferral(page);
    await press(page, /^Continue to App$/);
    await expectAccountCreation(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("referral: Skip also finishes onboarding", async ({ page }) => {
    await openReferral(page);
    await press(page, /^Skip$/);
    await expectAccountCreation(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("onboarding answers carry into the app after creating an account", async ({
    page,
  }) => {
    const supplement = "Slippery Elm";
    const medication = "Ustekinumab";
    await fastForwardToTrialOffer(page, { supplement, medication });
    await press(page, /^Try for \$0\.00/);
    await press(page, /^Try for FREE/);
    await expectAccountCreation(page);

    for (const [label, value] of [
      [/^Name$/, "Paywall Tester"],
      [/^Email$/, "paywall.e2e@gutmd.app"],
      [/^Password$/, "password123"],
      [/^Confirm password$/, "password123"],
    ] as const) {
      const input = field(page, label).first();
      await scrollUntilVisible(page, input);
      await input.click();
      await input.fill(value);
    }
    await tap(page, /^Create Account$/);
    await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 20_000 });
    await beat(page);

    await openTab(page, "Supps");
    await expectShown(page, supplement);
    await beat(page);
    await openTab(page, "Meds");
    await expectShown(page, medication);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});
