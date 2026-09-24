import { expect, test, type Locator, type Page } from "@playwright/test";
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
  tap,
} from "./helpers";

/**
 * The app must stay usable on larger screens: desktop (1280x720) and tablet
 * portrait (768x1024). Runs in the "responsive" Playwright project.
 */

const SIZES = [
  { label: "desktop 1280x720", width: 1280, height: 720 },
  { label: "tablet 768x1024", width: 768, height: 1024 },
] as const;

/** Console errors (Flutter reports layout overflows and exceptions here). */
function trackConsoleErrors(page: Page): string[] {
  const errors: string[] = [];
  page.on("console", (msg) => {
    if (msg.type() === "error") errors.push(msg.text());
  });
  return errors;
}

/** The Flutter view fills the window exactly and the page never scrolls sideways. */
async function expectFitsWindow(page: Page): Promise<void> {
  const metrics = await page.evaluate(() => {
    const view =
      document.querySelector("flutter-view") ??
      document.querySelector("flt-glass-pane");
    const rect = view?.getBoundingClientRect();
    return {
      innerWidth: window.innerWidth,
      innerHeight: window.innerHeight,
      scrollWidth: document.documentElement.scrollWidth,
      viewWidth: rect ? Math.round(rect.width) : -1,
      viewHeight: rect ? Math.round(rect.height) : -1,
    };
  });
  expect(
    metrics.scrollWidth,
    "page must not scroll horizontally",
  ).toBeLessThanOrEqual(metrics.innerWidth);
  expect(metrics.viewWidth).toBe(metrics.innerWidth);
  expect(metrics.viewHeight).toBe(metrics.innerHeight);
}

/**
 * Buttons and fields cut off by the left/right edge of the window, i.e. partly
 * on screen and partly past the edge (what a layout overflow looks like).
 * Controls entirely off screen are items scrolled out of view in a
 * horizontal list (e.g. the date strip), which is fine.
 */
async function horizontallyClipped(page: Page): Promise<string[]> {
  return page.evaluate(() => {
    const vw = window.innerWidth;
    const out: string[] = [];
    for (const el of Array.from(
      document.querySelectorAll('[role="button"], input, textarea'),
    )) {
      const r = el.getBoundingClientRect();
      if (r.width === 0 || r.height === 0) continue;
      let inHorizontalScroller = false;
      for (let p = el.parentElement; p; p = p.parentElement) {
        if (/overflow-x:\s*scroll/.test(p.getAttribute("style") ?? "")) {
          inHorizontalScroller = true;
          break;
        }
      }
      if (inHorizontalScroller) continue;
      const crossesLeft = r.left < -1 && r.right > 1;
      const crossesRight = r.left < vw - 1 && r.right > vw + 1;
      if (crossesLeft || crossesRight) {
        const name = (el.getAttribute("aria-label") || el.textContent || "")
          .trim()
          .slice(0, 40);
        out.push(
          `"${name}" spans x=${Math.round(r.left)}..${Math.round(r.right)} (window ${vw})`,
        );
      }
    }
    return out;
  });
}

async function expectUsableLayout(page: Page, screen: string): Promise<void> {
  await expectFitsWindow(page);
  expect(
    await horizontallyClipped(page),
    `controls cut off on ${screen}`,
  ).toEqual([]);
}

/**
 * Painted width (CSS px) of the chat bubble holding `message`. A chat
 * message's semantics node spans its whole list row (avatar + empty space), so
 * the bubble is measured from a screenshot instead: the widest run of
 * non-background pixels on a line through the middle of the row. The window's
 * left edge is list padding, so its pixel is the page background.
 */
async function paintedBubbleWidth(
  page: Page,
  message: Locator,
): Promise<number> {
  const row = await message.boundingBox();
  if (!row) throw new Error("chat message is not rendered");
  const width = page.viewportSize()?.width ?? 1280;
  const png = await page.screenshot({
    scale: "css",
    clip: { x: 0, y: Math.round(row.y + row.height / 2), width, height: 1 },
  });
  return page.evaluate(async (b64) => {
    const bitmap = await createImageBitmap(
      await (await fetch(`data:image/png;base64,${b64}`)).blob(),
    );
    const ctx = new OffscreenCanvas(bitmap.width, 1).getContext("2d");
    if (!ctx) throw new Error("no 2d canvas context");
    ctx.drawImage(bitmap, 0, 0);
    const px = ctx.getImageData(0, 0, bitmap.width, 1).data;
    const bg = [px[0], px[1], px[2]];
    let widest = 0;
    let run = 0;
    for (let x = 0; x < bitmap.width; x++) {
      const i = x * 4;
      const diff =
        Math.abs(px[i] - bg[0]) +
        Math.abs(px[i + 1] - bg[1]) +
        Math.abs(px[i + 2] - bg[2]);
      run = diff > 24 ? run + 1 : 0;
      widest = Math.max(widest, run);
    }
    return widest;
  }, png.toString("base64"));
}

function overflowErrors(errors: string[]): string[] {
  return errors.filter((e) => /overflow|RenderFlex|exception|Error:/i.test(e));
}

for (const size of SIZES) {
  test.describe(`Responsive layout at ${size.label}`, () => {
    test.use({ viewport: { width: size.width, height: size.height } });

    test("welcome screen fills the window with both actions reachable", async ({
      page,
    }) => {
      const consoleErrors = trackConsoleErrors(page);
      await boot(page);
      await expect(button(page, "Get Started")).toBeInViewport();
      await expect(button(page, "Log In")).toBeInViewport();
      await expectUsableLayout(page, "the welcome screen");
      await beat(page);
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });

    test("sign-in form is usable and logs in", async ({ page }) => {
      const consoleErrors = trackConsoleErrors(page);
      await boot(page);
      await button(page, "Log In").click();
      await expect(field(page, "Email")).toBeInViewport();
      await expect(field(page, "Password")).toBeInViewport();
      await expectUsableLayout(page, "the sign-in screen");
      await field(page, "Email").click();
      await field(page, "Email").fill("desktop@gutmd.app");
      await field(page, "Password").click();
      await field(page, "Password").fill("password123");
      await button(page, /^Sign In$/).click();
      await expect(button(page, /Home.*Tab 1/)).toBeVisible({
        timeout: 20_000,
      });
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });

    test("home screen content and bottom navigation fit the window", async ({
      page,
    }) => {
      const consoleErrors = trackConsoleErrors(page);
      await loginToHome(page);
      for (const tab of ["Home", "Symptoms", "Supps", "Meds", "Chat"]) {
        await expect(
          button(page, new RegExp(`^${tab}.*Tab \\d of 5`)),
        ).toBeInViewport();
      }
      await expect(
        page.getByRole("heading", { name: "How are you feeling?" }),
      ).toBeVisible();
      // The feeling picker is a radio group (Terrible .. Great).
      await expect(
        page.getByRole("radio", { name: "Great", exact: true }),
      ).toBeInViewport();
      await expect(
        field(page, /What did you eat, do, or feel/),
      ).toBeInViewport();
      await expectUsableLayout(page, "the home screen");
      await expectText(page, "Daily Logs");
      await expectUsableLayout(page, "the home screen (scrolled)");
      await beat(page);
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });

    test("every bottom tab renders its content inside the window", async ({
      page,
    }) => {
      const consoleErrors = trackConsoleErrors(page);
      await loginToHome(page);
      const landmarks = {
        Symptoms: "Add custom symptom",
        Supps: "Add custom supplement",
        Meds: "Add custom medication",
        Chat: "Type your message",
      } as const;
      for (const tab of ["Symptoms", "Supps", "Meds", "Chat"] as const) {
        await openTab(page, tab);
        await expect(field(page, landmarks[tab])).toBeVisible();
        await expectUsableLayout(page, `the ${tab} tab`);
        await beat(page, 400);
      }
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });

    test("tracking an item on the Symptoms tab works at this size", async ({
      page,
    }) => {
      await loginToHome(page);
      await openTab(page, "Symptoms");
      await tap(page, /^Add Bloating$/);
      // It moves from the "Add Symptoms to Track" list into the tracked list,
      // where it is a checkbox (tap = experienced today) with a Remove button.
      await expect(button(page, /^Add Bloating$/)).toHaveCount(0);
      await expect(
        page.getByRole("checkbox", { name: "Bloating", exact: true }),
      ).toBeVisible();
      await expect(
        page.getByRole("button", { name: "Remove Bloating", exact: true }),
      ).toBeVisible();
      await expectUsableLayout(page, "the Symptoms tab with a tracked item");
      expect(pageErrors(page)).toEqual([]);
    });

    test("chat composer stays on screen and a full message round-trip works", async ({
      page,
    }) => {
      const consoleErrors = trackConsoleErrors(page);
      await loginToHome(page);
      await openTab(page, "Chat");
      const input = field(page, /Type your message/i).first();
      await expect(input).toBeInViewport();
      await expect(
        button(page, "What foods should I avoid with my condition?"),
      ).toBeInViewport();
      await input.click();
      await input.fill("What supplements should I take?");
      await page.keyboard.press("Enter");
      await expect(onScreen(page).getByText(/B12/).first()).toBeVisible({
        timeout: 10_000,
      });
      await expect(input).toBeInViewport();
      await expect(button(page, /^Chat.*Tab/)).toBeInViewport();
      await expectUsableLayout(page, "the Chat tab with messages");
      await beat(page);
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });

    test("chat replies stay a readable width on wide screens", async ({
      page,
    }) => {
      await loginToHome(page);
      await openTab(page, "Chat");
      const input = field(page, /Type your message/i).first();
      await input.click();
      await input.fill("Hello");
      await page.keyboard.press("Enter");
      // onScreen: the reply is also mirrored into a 1px screen-reader announcement element.
      const reply = onScreen(page)
        .getByText(/You can ask me about/)
        .first();
      await expect(reply).toBeVisible({ timeout: 10_000 });
      await page.waitForTimeout(500);
      const bubbleWidth = await paintedBubbleWidth(page, reply);
      // A long multi-line reply wraps at the bubble's maximum width, so a real bubble was measured.
      expect(bubbleWidth, "the reply bubble should be painted").toBeGreaterThan(
        200,
      );
      expect(
        bubbleWidth,
        "reply bubble should not stretch across the whole window",
      ).toBeLessThanOrEqual(620);
      expect(pageErrors(page)).toEqual([]);
    });

    test("daily tracking, diet and insights screens open, fit and go back", async ({
      page,
    }) => {
      const consoleErrors = trackConsoleErrors(page);
      await loginToHome(page);
      const screens = [
        { action: "Add details", title: "Daily Tracking" },
        { action: "Meals & triggers", title: "Diet Tracker" },
        { action: "AI insights", title: /Insights/ },
      ];
      for (const screen of screens) {
        await tap(page, screen.action);
        await expect(page.getByText(screen.title).first()).toBeVisible();
        await expectUsableLayout(page, `the ${String(screen.title)} screen`);
        await beat(page, 400);
        await page.goBack();
        await expect(button(page, /^Home.*Tab 1/)).toBeVisible();
      }
      expect(overflowErrors(consoleErrors)).toEqual([]);
      expect(pageErrors(page)).toEqual([]);
    });
  });
}
