import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  beat,
  boot,
  button,
  expectText,
  field,
  loginToHome,
  pageErrors,
  scrollUntilVisible,
  tap,
  type,
} from "./helpers";

/*
 * Authentication: sign in, sign up, password reset, social / guest sign-in,
 * switching between Sign In and Sign Up, and signing out from Home.
 * The offline build uses the in-memory mock auth service: any well-formed
 * email + password signs in, Google/Apple sign in a demo user, and guests get
 * an anonymous account.
 */

const HOME_TAB = /Home.*Tab 1/;

/**
 * While a route transition runs, both screens are in the semantics tree.
 * Waiting for the previous screen to leave keeps later taps on the new one.
 */
async function waitGone(target: Locator): Promise<void> {
  await expect(target).toHaveCount(0);
}

/** Boot and open the sign-in screen from the welcome screen. */
async function openSignIn(page: Page): Promise<void> {
  await boot(page);
  await tap(page, "Log In");
  await expect(button(page, /^Sign In$/)).toBeVisible();
  await waitGone(button(page, "Get Started"));
}

/** Boot and open Create Account via Log In -> Sign Up. */
async function openSignUp(page: Page): Promise<void> {
  await openSignIn(page);
  await tap(page, /^Sign Up$/);
  await expect(button(page, /^Create Account$/)).toBeVisible();
  await waitGone(page.getByText("Welcome back"));
}

async function expectHome(page: Page): Promise<void> {
  await expect(button(page, HOME_TAB)).toBeVisible({ timeout: 20_000 });
  await expectText(page, "How are you feeling?");
}

async function expectNoText(page: Page, text: string | RegExp): Promise<void> {
  await expect(page.getByText(text)).toHaveCount(0);
}

/** The password-reset dialog (Flutter AlertDialog -> role=alertdialog). */
function dialog(page: Page): Locator {
  return page.getByRole("alertdialog");
}

/**
 * Text rendered in the open dialog. While a modal dialog is open, Flutter web
 * temporarily moves its aria-live announcement element (which repeats e.g.
 * validation errors for screen readers) inside the dialog, so leave it out.
 */
function dialogText(page: Page, text: string | RegExp): Locator {
  return dialog(page)
    .getByText(text, { exact: typeof text === "string" })
    .and(page.locator(":not([aria-live])"));
}

/**
 * Click the password show/hide toggle, then move the pointer off it. While the
 * mouse hovers an IconButton, Flutter shows its tooltip and adds the tooltip
 * text to the button's accessible name (aria-owns), e.g. "Hide password Hide password".
 */
async function clickPasswordToggle(page: Page, name: RegExp): Promise<void> {
  await button(page, name).click();
  const heading = await page
    .getByRole("heading", { name: "Welcome back" })
    .boundingBox();
  expect(heading).not.toBeNull();
  await page.mouse.move(
    heading!.x + heading!.width / 2,
    heading!.y + heading!.height / 2,
  );
}

async function fillSignUp(
  page: Page,
  values: {
    name?: string;
    email?: string;
    password?: string;
    confirm?: string;
  },
): Promise<void> {
  if (values.name !== undefined) await type(page, /^Name/, values.name);
  if (values.email !== undefined) await type(page, /^Email/, values.email);
  if (values.password !== undefined)
    await type(page, /^Password/, values.password);
  if (values.confirm !== undefined)
    await type(page, /^Confirm password/, values.confirm);
}

test.describe("Sign in", () => {
  test("Log In opens the GutMD sign-in screen", async ({ page }) => {
    await openSignIn(page);
    await expectText(page, "Welcome back");
    await expectText(page, "GutMD");
    await expectNoText(page, /Crohn's Companion/);
    await expect(field(page, /^Email/)).toBeVisible();
    await expect(field(page, /^Password/)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("submitting an empty form shows email and password errors", async ({
    page,
  }) => {
    await openSignIn(page);
    await button(page, /^Sign In$/).click();
    await expectText(page, "Please enter your email");
    await expectText(page, "Please enter your password");
    await beat(page);
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("an invalid email address is rejected", async ({ page }) => {
    await openSignIn(page);
    await type(page, /^Email/, "not-an-email");
    await type(page, /^Password/, "password123");
    await button(page, /^Sign In$/).click();
    await expectText(page, "Please enter a valid email");
    await beat(page);
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a password is required", async ({ page }) => {
    await openSignIn(page);
    await type(page, /^Email/, "sam@example.com");
    await button(page, /^Sign In$/).click();
    await expectText(page, "Please enter your password");
    await expectNoText(page, "Please enter your email");
    await expectNoText(page, "Please enter a valid email");
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("signing in with email and password opens Home", async ({ page }) => {
    await openSignIn(page);
    await type(page, /^Email/, "demo@gutmd.app");
    await type(page, /^Password/, "password123");
    await beat(page);
    await button(page, /^Sign In$/).click();
    await expectHome(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("plus-addressed emails on long domains can sign in", async ({
    page,
  }) => {
    await openSignIn(page);
    await type(page, /^Email/, "sam+gut@clinic.health");
    await type(page, /^Password/, "password123");
    await button(page, /^Sign In$/).click();
    await expectNoText(page, "Please enter a valid email");
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("pressing Enter in the password field signs in", async ({ page }) => {
    await openSignIn(page);
    await type(page, /^Email/, "demo@gutmd.app");
    await type(page, /^Password/, "password123");
    await field(page, /^Password/).press("Enter");
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the show/hide toggle reveals and hides the password", async ({
    page,
  }) => {
    await openSignIn(page);
    await type(page, /^Password/, "password123");
    await expect(field(page, /^Password/)).toHaveAttribute("type", "password");
    await clickPasswordToggle(page, /^Show password$/);
    await expect(button(page, /^Hide password$/)).toBeVisible();
    await expect(button(page, /Show password/)).toHaveCount(0);
    await expect(field(page, /^Password/)).toHaveAttribute("type", "text");
    await beat(page);
    await clickPasswordToggle(page, /^Hide password$/);
    await expect(button(page, /^Show password$/)).toBeVisible();
    await expect(button(page, /Hide password/)).toHaveCount(0);
    await expect(field(page, /^Password/)).toHaveAttribute("type", "password");
    expect(pageErrors(page)).toEqual([]);
  });

  test("Continue with Google signs in and opens Home", async ({ page }) => {
    await openSignIn(page);
    await tap(page, /^Continue with Google$/);
    await expectHome(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Continue with Apple signs in and opens Home", async ({ page }) => {
    await openSignIn(page);
    await tap(page, /^Continue with Apple$/);
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the back button returns to the welcome screen", async ({ page }) => {
    await openSignIn(page);
    await button(page, /^Back$/).click();
    await expect(button(page, "Get Started")).toBeVisible();
    await expect(button(page, "Log In")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Forgot password", () => {
  test("sends a reset link to the email typed on the sign-in form and confirms it", async ({
    page,
  }) => {
    await openSignIn(page);
    await type(page, /^Email/, "sam@example.com");
    await tap(page, /^Forgot Password\?$/);
    await expect(dialog(page)).toBeVisible();
    await expect(dialogText(page, "Reset your password")).toBeVisible();
    await beat(page);
    await dialog(page)
      .getByRole("button", { name: /^Send reset link$/ })
      .click();
    await expect(dialogText(page, "Check your email")).toBeVisible();
    await expect(
      dialogText(page, /If an account exists for sam@example\.com/),
    ).toBeVisible();
    await beat(page);
    await dialog(page)
      .getByRole("button", { name: /^Done$/ })
      .click();
    await expect(dialog(page)).toHaveCount(0);
    await expect(button(page, /^Sign In$/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("validates the email in the reset dialog before sending", async ({
    page,
  }) => {
    await openSignIn(page);
    await tap(page, /^Forgot Password\?$/);
    const send = dialog(page).getByRole("button", {
      name: /^Send reset link$/,
    });
    await send.click();
    await expect(dialogText(page, "Please enter your email")).toBeVisible();

    const email = dialog(page).getByRole("textbox", { name: /Email/ });
    await email.click();
    await email.fill("sam-at-example");
    await send.click();
    await expect(dialogText(page, "Please enter a valid email")).toBeVisible();
    await expect(dialogText(page, "Check your email")).toHaveCount(0);

    await email.click();
    await email.fill("reset.me@example.com");
    await send.click();
    await expect(
      dialogText(page, /If an account exists for reset\.me@example\.com/),
    ).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Cancel closes the reset dialog without sending", async ({ page }) => {
    await openSignIn(page);
    await tap(page, /^Forgot Password\?$/);
    await expect(dialog(page)).toBeVisible();
    await dialog(page)
      .getByRole("button", { name: /^Cancel$/ })
      .click();
    await expect(dialog(page)).toHaveCount(0);
    await expectNoText(page, "Check your email");
    await expect(button(page, /^Sign In$/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Sign up", () => {
  test("Sign Up opens Create Account and Sign In goes back", async ({
    page,
  }) => {
    await openSignUp(page);
    await expectText(page, "Start your gut health journey");
    await beat(page);
    await tap(page, /^Sign In$/);
    await expectText(page, "Welcome back");
    await waitGone(button(page, /^Create Account$/));
    // Switching back and forth does not stack screens: Back still returns to Welcome.
    await tap(page, /^Sign Up$/);
    await waitGone(page.getByText("Welcome back"));
    await button(page, /^Back$/).click();
    await expectText(page, "Welcome back");
    await waitGone(button(page, /^Create Account$/));
    // Move the pointer off the back arrow: a hover tooltip ("Back") would
    // otherwise be added to the button's accessible name.
    await page.mouse.move(200, 700);
    await button(page, /^Back$/).click();
    await expect(button(page, "Get Started")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("shows the password rules before you type", async ({ page }) => {
    await openSignUp(page);
    await expectText(page, "At least 8 characters, with a letter and a number");
    for (const label of [/^Name/, /^Email/, /^Password/, /^Confirm password/]) {
      await scrollUntilVisible(page, field(page, label));
    }
    expect(pageErrors(page)).toEqual([]);
  });

  test("an empty form shows an error for every field", async ({ page }) => {
    await openSignUp(page);
    await tap(page, /^Create Account$/);
    await expectText(page, "Please enter your name");
    await expectText(page, "Please enter your email");
    await expectText(page, "Please enter a password");
    await expectText(page, "Please confirm your password");
    await beat(page);
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("password rules and confirmation are enforced", async ({ page }) => {
    await openSignUp(page);
    await fillSignUp(page, {
      name: "Sam Lee",
      email: "sam.lee@example.com",
      password: "short1",
      confirm: "short1",
    });
    await tap(page, /^Create Account$/);
    await expectText(page, "Password must be at least 8 characters");

    await fillSignUp(page, { password: "lettersonly", confirm: "lettersonly" });
    await tap(page, /^Create Account$/);
    await expectText(page, "Password must include a letter and a number");

    await fillSignUp(page, { password: "gutcheck1", confirm: "gutcheck2" });
    await tap(page, /^Create Account$/);
    await expectText(page, "Passwords do not match");
    await beat(page);
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("an invalid email is rejected on sign up", async ({ page }) => {
    await openSignUp(page);
    await fillSignUp(page, {
      name: "Sam Lee",
      email: "sam.lee@",
      password: "gutcheck1",
      confirm: "gutcheck1",
    });
    await tap(page, /^Create Account$/);
    await expectText(page, "Please enter a valid email");
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("creating an account with valid details opens Home", async ({
    page,
  }) => {
    await openSignUp(page);
    await fillSignUp(page, {
      name: "Sam Lee",
      email: "sam.lee@example.com",
      password: "gutcheck1",
      confirm: "gutcheck1",
    });
    await beat(page);
    await tap(page, /^Create Account$/);
    await expectHome(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Continue as guest opens Home without an account", async ({ page }) => {
    await openSignUp(page);
    await expectText(page, /create one later to keep your data/);
    await tap(page, /^Continue as guest$/);
    await expectHome(page);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("Continue with Google on sign up opens Home", async ({ page }) => {
    await openSignUp(page);
    await tap(page, /^Continue with Google$/);
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("sign up does not load a remote Google logo (works offline, no CORS errors)", async ({
    page,
  }) => {
    // Flutter loads network images via XHR, which Playwright does not report as a
    // page request, but a blocked/failed load is logged to the console.
    const consoleErrors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") consoleErrors.push(msg.text());
    });
    await openSignUp(page);
    await scrollUntilVisible(page, button(page, /^Continue with Apple$/));
    await page.waitForTimeout(1500);
    expect(consoleErrors.filter((e) => /favicon|CORS/i.test(e))).toEqual([]);
    expect(pageErrors(page)).toEqual([]);
  });
});

test.describe("Sign out", () => {
  test("Cancel keeps you signed in", async ({ page }) => {
    await loginToHome(page);
    await tap(page, /^Sign out$/i);
    await expect(dialog(page)).toBeVisible();
    await expect(
      dialogText(page, "Are you sure you want to sign out?"),
    ).toBeVisible();
    await beat(page);
    await dialog(page)
      .getByRole("button", { name: /^Cancel$/ })
      .click();
    await expect(dialog(page)).toHaveCount(0);
    await expect(button(page, HOME_TAB)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("signing out returns to sign in, and you can sign back in", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, /^Sign out$/i);
    await dialog(page)
      .getByRole("button", { name: /^Sign Out$/ })
      .click();
    await expectText(page, "Welcome back");
    await expect(button(page, HOME_TAB)).toHaveCount(0);
    // Signed-out sign-in is the first screen, so there is nothing to go back to.
    await expect(button(page, /^Back$/)).toHaveCount(0);
    await beat(page);

    await type(page, /^Email/, "demo@gutmd.app");
    await type(page, /^Password/, "password123");
    await button(page, /^Sign In$/).click();
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("a guest can sign out and create an account from sign in", async ({
    page,
  }) => {
    await openSignUp(page);
    await tap(page, /^Continue as guest$/);
    await expectHome(page);
    await tap(page, /^Sign out$/i);
    await dialog(page)
      .getByRole("button", { name: /^Sign Out$/ })
      .click();
    await expectText(page, "Welcome back");
    await tap(page, /^Sign Up$/);
    await fillSignUp(page, {
      name: "Pat",
      email: "pat@example.com",
      password: "gutcheck1",
      confirm: "gutcheck1",
    });
    await tap(page, /^Create Account$/);
    await expectHome(page);
    expect(pageErrors(page)).toEqual([]);
  });
});
