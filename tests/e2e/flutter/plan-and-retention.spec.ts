import { expect, test, type Page } from "@playwright/test";
import {
  beat,
  boot,
  button,
  expectText,
  field,
  holdToCommit,
  onScreen,
  pageErrors,
  scrollUntilVisible,
  tap,
} from "./helpers";

/**
 * The conversion and retention redesign: quiz progress bar, AI plan building,
 * personalised plan reveal, commitment step, and the Home dashboard's
 * wellbeing score, plan card, milestones, check-in streak and guest upgrade.
 */

async function settle(page: Page): Promise<void> {
  await page.waitForTimeout(450);
}

async function enabled(page: Page, name: RegExp): Promise<boolean> {
  const target = button(page, name).first();
  return (
    (await target.count()) > 0 &&
    (await target.isVisible()) &&
    (await target.isEnabled())
  );
}

/** Walk the quiz with minimal answers (Crohn's, Reduce Symptoms) until `until` returns true. */
async function walkQuiz(
  page: Page,
  until: () => Promise<boolean>,
): Promise<void> {
  for (let i = 0; i < 60; i++) {
    if (await until()) return;
    if (await enabled(page, /^Continue$/)) await tap(page, /^Continue$/);
    else if (await enabled(page, /^Crohn's Disease/))
      await tap(page, /^Crohn's Disease/);
    else if (await enabled(page, /^Reduce Symptoms/))
      await tap(page, /^Reduce Symptoms/);
    else if (await enabled(page, /^Skip$/)) await tap(page, /^Skip$/);
    else if (await enabled(page, /^Next$/)) await tap(page, /^Next$/);
    await settle(page);
  }
  throw new Error("walkQuiz: target never reached");
}

async function toPlanReveal(page: Page): Promise<void> {
  await boot(page);
  await tap(page, "Get Started");
  await walkQuiz(
    page,
    async () => (await button(page, /^Start my plan$/).count()) > 0,
  );
}

/** Finish onboarding without an account: plan -> commit -> trial -> timeline -> sign up -> guest. */
async function onboardAsGuest(page: Page): Promise<void> {
  await toPlanReveal(page);
  await tap(page, /^Start my plan$/);
  await holdToCommit(page);
  await tap(page, /^Try for \$0\.00/);
  await tap(page, /^Try for FREE/);
  await tap(page, /Continue as guest/);
  await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 20_000 });
}

const PROGRESS = /^Onboarding progress \d+ percent$/;

async function progressPercent(page: Page): Promise<number> {
  const label = await onScreen(page).getByText(PROGRESS).first().textContent();
  return Number(/(\d+) percent/.exec(label ?? "")?.[1] ?? NaN);
}

function scoreRing(page: Page) {
  return page.getByRole("button", { name: /^Wellbeing score/ }).first();
}

test.describe("Onboarding: progress, AI plan and commitment", () => {
  test.describe.configure({ timeout: 180_000 });

  test("a progress bar tracks the quiz and grows step by step", async ({
    page,
  }) => {
    await boot(page);
    await expect(onScreen(page).getByText(PROGRESS)).toHaveCount(0);
    await tap(page, "Get Started");
    const first = await progressPercent(page);
    expect(first).toBeGreaterThan(0);
    await tap(page, /^Crohn's Disease/);
    await tap(page, /^Continue$/);
    await settle(page);
    const second = await progressPercent(page);
    expect(second).toBeGreaterThan(first);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("answers are turned into a personalised 14-day plan", async ({
    page,
  }) => {
    await boot(page);
    await tap(page, "Get Started");
    await walkQuiz(
      page,
      async () =>
        (await onScreen(page)
          .getByText("Building your personal plan")
          .count()) > 0,
    );
    await expectText(page, "Building your personal plan");
    await expectText(page, "Reviewing your conditions");
    await beat(page, 1500);

    await expect(button(page, /^Start my plan$/)).toBeVisible({
      timeout: 20_000,
    });
    await expectText(page, "Your 14-day plan for Crohn's Disease");
    await expectText(page, "Personalised for you");
    await expectText(page, "Calm your symptoms"); // goal: Reduce Symptoms
    await expectText(page, "Your first experiment");
    await expectText(page, "Your daily routine");
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the commitment step is a press-and-hold that leads to the trial offer", async ({
    page,
  }) => {
    await toPlanReveal(page);
    await tap(page, /^Start my plan$/);
    await expectText(page, "Make a promise to yourself");
    await expectText(page, "Press and hold to commit");

    await holdToCommit(page);
    await expectText(page, /Committed!/);
    await expect(button(page, /^Try for \$0\.00/)).toBeVisible({
      timeout: 10_000,
    });
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Home: stickiness features", () => {
  test.describe.configure({ timeout: 180_000 });

  test("a guest sees their plan, a save-your-progress banner and locked milestones", async ({
    page,
  }) => {
    await onboardAsGuest(page);
    await expectText(page, /You're using GutMD as a guest/);
    await expect(button(page, /^Create account$/)).toBeVisible();

    await expectText(page, "Your 14-day plan");
    await expectText(page, "Your 14-day plan for Crohn's Disease");
    await expectText(page, "0/14 days");

    await expectText(page, "0 of 6 milestones unlocked");
    await expect(
      onScreen(page).getByText("First check-in, locked"),
    ).toHaveCount(1);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("checking in unlocks the score, a milestone and plan progress", async ({
    page,
  }) => {
    await onboardAsGuest(page);
    const ring = scoreRing(page);
    await scrollUntilVisible(page, ring);
    await expect(ring).toHaveAccessibleName(/not ready yet/);

    const good = page.getByRole("radio", { name: "Good" });
    await scrollUntilVisible(page, good);
    await good.click();
    await expect(good).toBeChecked();
    await expectText(page, /Checked in for today/);

    await scrollUntilVisible(page, ring);
    await expect(ring).toHaveAccessibleName(/Wellbeing score \d+ out of 100/);
    await expectText(page, "1/14 days");
    await expectText(page, "1 of 6 milestones unlocked");
    await expect(
      onScreen(page).getByText("First check-in, unlocked"),
    ).toHaveCount(1);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the wellbeing score opens AI insights", async ({ page }) => {
    await onboardAsGuest(page);
    const ring = scoreRing(page);
    await scrollUntilVisible(page, ring);
    await ring.click();
    await expectText(page, "Patterns found in the data you have tracked");
    await expectText(page, "No insights yet");
    await tap(page, /^Back$/);
    await expect(button(page, /Home.*Tab 1/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("a guest can upgrade to a full account from the banner and keep their check-in", async ({
    page,
  }) => {
    await onboardAsGuest(page);
    const good = page.getByRole("radio", { name: "Good" });
    await scrollUntilVisible(page, good);
    await good.click();
    await expect(good).toBeChecked();

    await tap(page, /^Create account$/);
    await field(page, /^Name/).first().fill("Sam");
    await field(page, /^Email/)
      .first()
      .fill("sam.guest@example.com");
    const passwords = page.getByRole("textbox", { name: /password/i });
    for (let i = 0; i < (await passwords.count()); i++)
      await passwords.nth(i).fill("secret123");
    await tap(page, /^Create Account$/);
    await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 20_000 });

    await expect(
      onScreen(page).getByText(/You're using GutMD as a guest/),
    ).toHaveCount(0);
    await expectText(page, /Good (morning|afternoon|evening), Sam/);
    const goodAgain = page.getByRole("radio", { name: "Good" });
    await scrollUntilVisible(page, goodAgain);
    await expect(goodAgain).toBeChecked();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });
});
