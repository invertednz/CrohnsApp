import { expect, type Locator, type Page } from "@playwright/test";

/**
 * Helpers for driving the Flutter web build through its accessibility
 * (semantics) tree. main.dart calls ensureSemantics() on web, so every
 * control is a real DOM node:
 *   - buttons / tappables -> role=button, name = their visible text
 *   - text fields         -> <input>/<textarea> with aria-label = label/hint
 *   - static text         -> <span> text, reachable with getByText
 * Only on-screen widgets (plus a small cache extent) are in the tree, so use
 * `scrollUntilVisible` for content further down a scroll view.
 *
 * Snackbar/live-region text is ALSO mirrored into an aria-live
 * <flt-announcement-polite> element outside the semantics host, so plain
 * page.getByText() can match twice. Use `onScreen(page).getByText(...)` or
 * `expectText` to only match what is rendered.
 */

/** The rendered semantics tree (excludes screen-reader announcement mirrors). */
export function onScreen(page: Page): Locator {
  return page.locator("flt-semantics-host");
}

/** Open the app and wait for the welcome screen. */
export async function boot(page: Page): Promise<void> {
  const pageErrors: string[] = [];
  page.on("pageerror", (err) => pageErrors.push(err.message));
  (page as Page & { __pageErrors?: string[] }).__pageErrors = pageErrors;
  await page.goto("/");
  await expect(page.getByRole("button", { name: "Get Started" })).toBeVisible({
    timeout: 30_000,
  });
}

/** Uncaught JS errors seen since boot(); assert this is empty at the end of a test. */
export function pageErrors(page: Page): string[] {
  return (page as Page & { __pageErrors?: string[] }).__pageErrors ?? [];
}

/** Button by accessible name (string = substring match, case-insensitive). */
export function button(page: Page, name: string | RegExp): Locator {
  return page.getByRole("button", {
    name: typeof name === "string" ? new RegExp(escapeRe(name), "i") : name,
  });
}

/** Text input by its label / hint text. */
export function field(page: Page, label: string | RegExp): Locator {
  return page.getByRole("textbox", {
    name: typeof label === "string" ? new RegExp(escapeRe(label), "i") : label,
  });
}

export async function tap(page: Page, name: string | RegExp): Promise<void> {
  const target = button(page, name).first();
  await scrollUntilVisible(page, target);
  await target.click();
}

/** Type into a Flutter text field (click to focus first, then fill). */
export async function type(
  page: Page,
  label: string | RegExp,
  value: string,
): Promise<void> {
  const input = field(page, label).first();
  await scrollUntilVisible(page, input);
  await input.click();
  await input.fill(value);
}

/**
 * Scroll the main scroll view with the mouse wheel until `target` is visible.
 * Scrolls down first, then back up if it was above.
 */
export async function scrollUntilVisible(
  page: Page,
  target: Locator,
  maxSteps = 15,
): Promise<void> {
  if (await isShown(target)) return;
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  await page.mouse.move(vp.width / 2, vp.height / 2);
  for (const direction of [1, -1]) {
    for (let i = 0; i < maxSteps; i++) {
      await page.mouse.wheel(0, direction * 350);
      await page.waitForTimeout(250);
      if (await isShown(target)) return;
    }
  }
  await expect(target).toBeVisible();
}

async function isShown(target: Locator): Promise<boolean> {
  if ((await target.count()) === 0) return false;
  return target.isVisible();
}

/** Expect visible text somewhere on screen, scrolling if needed. */
export async function expectText(
  page: Page,
  text: string | RegExp,
): Promise<void> {
  const target = onScreen(page).getByText(text).first();
  await scrollUntilVisible(page, target);
  await expect(target).toBeVisible();
}

/** Log in through the real sign-in screen (offline build accepts any valid email). */
export async function loginToHome(
  page: Page,
  email = "demo@gutmd.app",
): Promise<void> {
  await boot(page);
  await tap(page, "Log In");
  await type(page, "Email", email);
  await type(page, "Password", "password123");
  await button(page, /^Sign In$/).click();
  await expect(button(page, /Home.*Tab 1/)).toBeVisible({ timeout: 20_000 });
}

/** Switch bottom-navigation tab: Home | Symptoms | Supps | Meds | Chat. */
export async function openTab(
  page: Page,
  tab: "Home" | "Symptoms" | "Supps" | "Meds" | "Chat",
): Promise<void> {
  await button(page, new RegExp(`^${tab}.*Tab \\d of \\d`)).click();
  await page.waitForTimeout(400);
}

/** Press and hold the Commitment screen's "Hold to commit" control (clicks are too short). */
export async function holdToCommit(page: Page): Promise<void> {
  const target = button(page, /^Hold to commit$/);
  await expect(target).toBeVisible();
  const box = await target.boundingBox();
  if (!box) throw new Error("Hold to commit control has no bounding box");
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.waitForTimeout(1_600);
  await page.mouse.up();
}

/** Short pause so recorded videos are watchable (no-op when not recording). */
export async function beat(page: Page, ms = 600): Promise<void> {
  if (process.env.VIDEO) await page.waitForTimeout(ms);
}

function escapeRe(s: string): string {
  return s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}
