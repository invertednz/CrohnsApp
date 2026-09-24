import { expect, test, type Page } from "@playwright/test";
import {
  beat,
  boot,
  button,
  expectText,
  field,
  loginToHome,
  onScreen,
  openTab,
  pageErrors,
  scrollUntilVisible,
  tap,
} from "./helpers";

/**
 * Screen-reader basics for every main screen: each visible control exposes a
 * meaningful accessible name and each text field has a label. Failures list
 * the offending controls with their on-screen position so they can be traced
 * to the widget (icon-only buttons need a `tooltip:` or Semantics label).
 */

type Control = { role: string; name: string; box: string };

/** All rendered interactive controls in the Flutter semantics tree. */
async function controls(page: Page): Promise<Control[]> {
  return page.evaluate(() => {
    const selector = [
      '[role="button"]',
      "button",
      '[role="checkbox"]',
      '[role="switch"]',
      '[role="radio"]',
      '[role="tab"]',
      '[role="link"]',
      '[role="slider"]',
    ].join(",");
    const out: { role: string; name: string; box: string }[] = [];
    for (const el of Array.from(document.querySelectorAll(selector))) {
      if (el.closest('[aria-hidden="true"]')) continue;
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      const labelledBy = (el.getAttribute("aria-labelledby") ?? "")
        .split(/\s+/)
        .map((id) =>
          id ? (document.getElementById(id)?.textContent ?? "") : "",
        )
        .join(" ");
      const name = (
        el.getAttribute("aria-label") ||
        labelledBy ||
        el.getAttribute("title") ||
        el.textContent ||
        ""
      )
        .replace(/\s+/g, " ")
        .trim();
      out.push({
        role: el.getAttribute("role") ?? el.tagName.toLowerCase(),
        name,
        box: `at x=${Math.round(r.x)} y=${Math.round(r.y)} (${Math.round(r.width)}x${Math.round(r.height)})`,
      });
    }
    return out;
  });
}

/** Controls whose name is empty or has no letters/digits (e.g. emoji only). */
async function unnamedControls(page: Page): Promise<string[]> {
  return (await controls(page))
    .filter((c) => !/[\p{L}\p{N}]/u.test(c.name))
    .map((c) => `${c.role} ${c.name ? `"${c.name}"` : "<no name>"} ${c.box}`);
}

/**
 * Text fields without a label (an "e.g. ..." example is not a label).
 * Flutter renders a Slider as <input type="range" role="slider">; that is not a
 * text field and is already checked by `unnamedControls` via its slider role.
 */
async function unlabelledFields(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const out: string[] = [];
    const textFields =
      'textarea, input:not([type="range"]):not([type="checkbox"]):not([type="radio"]):not([type="hidden"])';
    for (const el of Array.from(document.querySelectorAll(textFields))) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      const name = (el.getAttribute("aria-label") ?? "")
        .replace(/\s+/g, " ")
        .trim();
      if (!/[\p{L}\p{N}]/u.test(name) || /^e\.?g\.?[\s,]/i.test(name)) {
        out.push(
          `${el.tagName.toLowerCase()} "${name}" at x=${Math.round(r.x)} y=${Math.round(r.y)}`,
        );
      }
    }
    return out;
  });
}

async function expectAccessible(page: Page, screen: string): Promise<void> {
  await page.waitForTimeout(500);
  expect
    .soft(
      await unnamedControls(page),
      `Controls without an accessible name on ${screen}`,
    )
    .toEqual([]);
  expect
    .soft(
      await unlabelledFields(page),
      `Text fields without a label on ${screen}`,
    )
    .toEqual([]);
}

async function scrollToBottom(page: Page): Promise<void> {
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  await page.mouse.move(vp.width / 2, vp.height / 2);
  for (let i = 0; i < 12; i++) {
    await page.mouse.wheel(0, 400);
    await page.waitForTimeout(120);
  }
  await page.waitForTimeout(300);
}

async function openSignIn(page: Page): Promise<void> {
  await boot(page);
  await button(page, "Log In").click();
  await expect(field(page, "Email")).toBeVisible();
}

test.describe("Accessibility: names and labels", () => {
  test("welcome screen controls all have accessible names", async ({
    page,
  }) => {
    await boot(page);
    await expectAccessible(page, "the welcome screen");
    const all = await controls(page);
    expect(all.map((c) => c.name)).toEqual(
      expect.arrayContaining(["Get Started", "Log In"]),
    );
    expect(pageErrors(page)).toEqual([]);
  });

  test("sign-in screen buttons are named and fields are labelled", async ({
    page,
  }) => {
    await openSignIn(page);
    await expect(field(page, "Email")).toBeVisible();
    await expect(field(page, "Password")).toBeVisible();
    await beat(page);
    await expectAccessible(page, "the sign-in screen");
    expect(pageErrors(page)).toEqual([]);
  });

  test("sign-up screen buttons are named and fields are labelled", async ({
    page,
  }) => {
    await openSignIn(page);
    await tap(page, /^Sign Up$/);
    await page.waitForTimeout(800);
    await expectAccessible(page, "the sign-up screen");
    await scrollToBottom(page);
    await expectAccessible(page, "the sign-up screen (scrolled)");
    expect(pageErrors(page)).toEqual([]);
  });

  test("home screen controls are named, top to bottom", async ({ page }) => {
    await loginToHome(page);
    await expectAccessible(page, "the home screen");
    await scrollToBottom(page);
    await expectAccessible(page, "the home screen (scrolled to the end)");
    expect(pageErrors(page)).toEqual([]);
  });

  test("bottom navigation tabs have descriptive names", async ({ page }) => {
    await loginToHome(page);
    for (const tab of ["Home", "Symptoms", "Supps", "Meds", "Chat"]) {
      await expect(
        button(page, new RegExp(`^${tab}.*Tab \\d of 5`)),
      ).toBeVisible();
    }
    expect(pageErrors(page)).toEqual([]);
  });

  for (const tab of ["Symptoms", "Supps", "Meds", "Chat"] as const) {
    test(`${tab} tab controls are named and fields are labelled`, async ({
      page,
    }) => {
      await loginToHome(page);
      await openTab(page, tab);
      await expectAccessible(page, `the ${tab} tab`);
      await scrollToBottom(page);
      await expectAccessible(page, `the ${tab} tab (scrolled)`);
      expect(pageErrors(page)).toEqual([]);
    });
  }

  const firstItem = {
    Symptoms: "Abdominal Pain",
    Supps: "Vitamin D",
    Meds: "Mesalamine",
  } as const;
  for (const tab of ["Symptoms", "Supps", "Meds"] as const) {
    test(`${tab} tab item controls are named once an item is being tracked`, async ({
      page,
    }) => {
      await loginToHome(page);
      await openTab(page, tab);
      const item = firstItem[tab];
      // Suggestions are "Add <item>" buttons; adding one moves it into the tracked list.
      await tap(page, new RegExp(`^Add ${item}$`));
      await expect(
        page.getByRole("checkbox", { name: item, exact: true }),
      ).toBeVisible();
      await expect(
        page.getByRole("button", { name: `Remove ${item}`, exact: true }),
      ).toBeVisible();
      await page.waitForTimeout(600);
      await beat(page);
      await expectAccessible(page, `the ${tab} tab with a tracked item`);
      expect(pageErrors(page)).toEqual([]);
    });
  }

  test("chat controls stay named during a conversation", async ({ page }) => {
    await loginToHome(page);
    await openTab(page, "Chat");
    const input = field(page, /Type your message/i).first();
    await input.click();
    await input.fill("Hello");
    await page.keyboard.press("Enter");
    await expect(
      onScreen(page)
        .getByText(/You can ask me about/)
        .first(),
    ).toBeVisible();
    await expectAccessible(page, "the Chat tab with messages");
    expect(pageErrors(page)).toEqual([]);
  });

  test("daily tracking screen controls are named and fields are labelled", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, "Add details");
    await expectText(page, "Daily Tracking");
    await expectAccessible(page, "the Daily Tracking screen");
    await scrollToBottom(page);
    await expectAccessible(page, "the Daily Tracking screen (scrolled)");
    expect(pageErrors(page)).toEqual([]);
  });

  test("diet screen and its add-trigger dialog are named and labelled", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, "Meals & triggers");
    await expectText(page, "Diet Tracker");
    await expectAccessible(page, "the Diet Tracker screen");
    await scrollToBottom(page);
    await expectAccessible(page, "the Diet Tracker screen (scrolled)");
    // The "Food Triggers" card is one semantics group named by its heading and empty-state text.
    const triggers = page.getByRole("group", { name: /^Food Triggers/ });
    await scrollUntilVisible(page, triggers);
    await triggers
      .getByRole("button", { name: "Add trigger", exact: true })
      .click();
    const dialogTitle = onScreen(page).getByText("Add Food Trigger", {
      exact: true,
    });
    await expect(dialogTitle).toBeVisible();
    await expect(field(page, /^Food name/)).toBeVisible();
    await expectAccessible(page, "the Add Food Trigger dialog");
    await button(page, /^Cancel$/).click();
    await expect(dialogTitle).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("insights screen controls are named", async ({ page }) => {
    await loginToHome(page);
    await tap(page, "AI insights");
    await page.waitForTimeout(1500);
    await expectAccessible(page, "the Insights screen");
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Accessibility: keyboard", () => {
  test("keyboard users can Tab to the welcome screen actions and activate Log In", async ({
    page,
  }) => {
    await boot(page);
    const reached: string[] = [];
    for (let i = 0; i < 12 && !reached.includes("Log In"); i++) {
      await page.keyboard.press("Tab");
      reached.push(
        await page.evaluate(() =>
          (
            document.activeElement?.getAttribute("aria-label") ||
            document.activeElement?.textContent ||
            ""
          ).trim(),
        ),
      );
    }
    expect(reached).toEqual(expect.arrayContaining(["Get Started", "Log In"]));
    await page.keyboard.press("Enter");
    await expect(field(page, "Email")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("the chat message box can be reached and used from the keyboard", async ({
    page,
  }) => {
    await loginToHome(page);
    await openTab(page, "Chat");
    const input = field(page, /Type your message/i).first();
    await input.focus();
    await page.keyboard.type("Hello");
    await page.keyboard.press("Enter");
    await expect(
      onScreen(page)
        .getByText(/You can ask me about/)
        .first(),
    ).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });
});
