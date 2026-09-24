import { expect, test, type Locator, type Page } from "@playwright/test";
import { beat, button, field, loginToHome, pageErrors } from "./helpers";

/*
 * Daily Tracking (TrackingScreen), opened from Home's "Add details" button.
 * Covers the feeling scale, bowel-movement counter, pain/energy sliders,
 * free-text factors and notes, date switching, save + reload from the
 * backend, and the unsaved-changes prompt.
 */

// ---------- area helpers ----------

/** Visible content under the gradient header (px from the top of the viewport). */
const CONTENT_TOP = 170;

/**
 * Text as Flutter exposes it: either DOM text of a leaf node or part of a
 * container's aria-label (cards that also hold buttons put their text there).
 */
function shown(page: Page, text: string): Locator {
  return page
    .getByText(text)
    .or(page.locator(`[aria-label*=${JSON.stringify(text)}]`))
    .first();
}

/** Wheel-scroll the tracking list until `target` sits fully inside the visible content area. */
async function reveal(
  page: Page,
  target: Locator,
  bottomInset = 8,
): Promise<void> {
  const vp = page.viewportSize() ?? { width: 390, height: 844 };
  await page.mouse.move(vp.width / 2, vp.height / 2 + 100);
  for (const fallback of [1, -1]) {
    for (let i = 0; i < 14; i++) {
      const box =
        (await target.count()) > 0 ? await target.first().boundingBox() : null;
      if (
        box &&
        box.height > 0 &&
        box.y >= CONTENT_TOP &&
        box.y + box.height <= vp.height - bottomInset
      )
        return;
      const direction = box ? (box.y < CONTENT_TOP ? -1 : 1) : fallback;
      await page.mouse.wheel(0, direction * 220);
      await page.waitForTimeout(250);
    }
  }
  await expect(target.first()).toBeVisible();
}

/** A Home button by its exact name (other Home widgets may mention the same words). */
function homeButton(page: Page, name: string): Locator {
  return page.getByRole("button", { name, exact: true });
}

/** Home's buttons: keep clear of its bottom input bar and tab bar. */
async function pressOnHome(page: Page, name: string): Promise<void> {
  const target = homeButton(page, name);
  await reveal(page, target, 170);
  await target.first().click();
}

async function press(page: Page, target: Locator): Promise<void> {
  await reveal(page, target);
  await target.first().click();
}

/** Snackbars and dialogs are not in the scrolling list, so just wait for them. */
async function expectNow(page: Page, text: string): Promise<void> {
  await expect(shown(page, text)).toBeVisible();
}

async function expectShown(page: Page, text: string): Promise<void> {
  const target = shown(page, text);
  await reveal(page, target);
  await expect(target).toBeVisible();
}

async function fill(page: Page, label: RegExp, value: string): Promise<void> {
  const input = field(page, label).first();
  await press(page, input);
  await input.fill(value);
}

function feeling(
  page: Page,
  name: "Terrible" | "Bad" | "Okay" | "Good" | "Great",
): Locator {
  return page.getByRole("button", { name, exact: true });
}

/** "Today, Sep 24" / "Wednesday, Sep 23" exactly as the screen formats it. */
function dayLabel(offsetDays: number): string {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  const monthDay = d.toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
  });
  if (offsetDays === 0) return `Today, ${monthDay}`;
  return `${d.toLocaleDateString("en-US", { weekday: "long" })}, ${monthDay}`;
}

async function openTracking(page: Page): Promise<void> {
  await loginToHome(page);
  await pressOnHome(page, "Add details");
  await expect(shown(page, "Daily Tracking")).toBeVisible();
  // The entry has loaded once the date controls replace the spinner.
  await expect(button(page, "Previous day")).toBeVisible();
}

/** Tap the far left (0) or far right (10) end of a 0-10 slider. */
async function setLevel(
  page: Page,
  title: "Pain level" | "Energy level",
  end: "min" | "max",
): Promise<void> {
  const card = page.getByRole("group", { name: new RegExp(`^${title}`) });
  const slider = card.getByRole("slider").locator("..");
  await reveal(page, slider);
  const box = await slider.boundingBox();
  if (!box) throw new Error(`${title} slider not rendered`);
  await page.mouse.click(
    end === "min" ? box.x + 2 : box.x + box.width - 2,
    box.y + box.height / 2,
  );
  await expect(
    page.getByRole("group", {
      name: new RegExp(`^${title}\\s+${end === "min" ? 0 : 10}/10`),
    }),
  ).toBeVisible();
}

function bowelCard(page: Page, count: number): Locator {
  return page.getByRole("group", {
    name: new RegExp(`Bowel Movements\\s+${count}(\\s|$)`),
  });
}

async function save(page: Page): Promise<void> {
  await press(page, button(page, /^Save$/));
}

async function backToHome(page: Page): Promise<void> {
  await button(page, /^Back\b/).click();
  await expect(homeButton(page, "Add details")).toBeVisible();
}

// ---------- tests ----------

test.describe("Daily tracking", () => {
  test("Add details opens today's tracking with every section and labelled controls", async ({
    page,
  }) => {
    await openTracking(page);
    await expectShown(page, dayLabel(0));
    await expect(button(page, /^Back\b/)).toBeVisible();
    await expect(button(page, "Next day")).toBeDisabled();
    await expectShown(page, "How are you feeling today?");
    for (const name of ["Terrible", "Bad", "Okay", "Good", "Great"] as const) {
      await expect(feeling(page, name)).toBeVisible();
    }
    await expect(bowelCard(page, 0)).toBeVisible();
    await expect(button(page, "Increase bowel movements")).toBeVisible();
    await expect(button(page, "Decrease bowel movements")).toBeDisabled();
    await beat(page);
    await reveal(
      page,
      page.getByRole("group", { name: /^Pain level\s+0\/10/ }),
    );
    await reveal(
      page,
      page.getByRole("group", { name: /^Energy level\s+5\/10/ }),
    );
    await reveal(page, field(page, /What made you feel good/));
    await reveal(page, field(page, /What made you feel bad/));
    await reveal(page, field(page, /Additional Notes/));
    await reveal(page, button(page, /^Save$/));
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("choosing a feeling marks only that option as selected", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Good"));
    await expect(feeling(page, "Good")).toHaveAttribute("aria-current", "true");
    await beat(page);
    await press(page, feeling(page, "Terrible"));
    await expect(feeling(page, "Terrible")).toHaveAttribute(
      "aria-current",
      "true",
    );
    await expect(feeling(page, "Good")).toHaveAttribute(
      "aria-current",
      "false",
    );
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("saving without a feeling asks the user to choose one", async ({
    page,
  }) => {
    await openTracking(page);
    await save(page);
    await expectNow(page, "Choose how you're feeling to save this day");
    await beat(page);
    await press(page, feeling(page, "Okay"));
    await expect(
      shown(page, "Choose how you're feeling to save this day"),
    ).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("bowel movement counter goes up and down but never below zero", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, button(page, "Increase bowel movements"));
    await press(page, button(page, "Increase bowel movements"));
    await press(page, button(page, "Increase bowel movements"));
    await expect(bowelCard(page, 3)).toBeVisible();
    await beat(page);
    await press(page, button(page, "Decrease bowel movements"));
    await expect(bowelCard(page, 2)).toBeVisible();
    await press(page, button(page, "Decrease bowel movements"));
    await press(page, button(page, "Decrease bowel movements"));
    await expect(bowelCard(page, 0)).toBeVisible();
    await expect(button(page, "Decrease bowel movements")).toBeDisabled();
    expect(pageErrors(page)).toEqual([]);
  });

  test("pain and energy sliders move across the 0-10 scale", async ({
    page,
  }) => {
    await openTracking(page);
    await setLevel(page, "Pain level", "max");
    await beat(page);
    await setLevel(page, "Energy level", "min");
    await beat(page);
    await setLevel(page, "Pain level", "min");
    await setLevel(page, "Energy level", "max");
    expect(pageErrors(page)).toEqual([]);
  });

  test("a full entry saves with confirmation and reloads after leaving and reopening", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Bad"));
    await press(page, button(page, "Increase bowel movements"));
    await press(page, button(page, "Increase bowel movements"));
    await setLevel(page, "Pain level", "max");
    await setLevel(page, "Energy level", "min");
    await fill(page, /What made you feel good/, "Short walk");
    await fill(page, /What made you feel bad/, "Spicy curry at lunch");
    await fill(page, /Additional Notes/, "Cramps in the evening");
    await beat(page);
    await save(page);
    await expectNow(page, "Saved your entry for today");
    await beat(page);

    await backToHome(page);
    await pressOnHome(page, "Add details");
    await expect(button(page, "Previous day")).toBeVisible();
    await expect(feeling(page, "Bad")).toHaveAttribute("aria-current", "true");
    await expect(bowelCard(page, 2)).toBeVisible();
    await reveal(
      page,
      page.getByRole("group", { name: /^Pain level\s+10\/10/ }),
    );
    await reveal(
      page,
      page.getByRole("group", { name: /^Energy level\s+0\/10/ }),
    );
    // Flutter only mirrors a field's text into the DOM while it has focus.
    const bad = field(page, /What made you feel bad/);
    await press(page, bad);
    await expect(bad).toHaveValue("Spicy curry at lunch");
    const notes = field(page, /Additional Notes/);
    await press(page, notes);
    await expect(notes).toHaveValue("Cramps in the evening");
    await beat(page);
    // Nothing changed, so leaving does not prompt.
    await backToHome(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("each day has its own entry and the date cannot move past today", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Great"));
    await save(page);
    await expectNow(page, "Saved your entry for today");

    await press(page, button(page, "Previous day"));
    await expectShown(page, dayLabel(-1));
    await expectShown(page, "How did you feel this day?");
    for (const name of ["Terrible", "Bad", "Okay", "Good", "Great"] as const) {
      await expect(feeling(page, name)).toHaveAttribute(
        "aria-current",
        "false",
      );
    }
    await beat(page);
    await press(page, feeling(page, "Terrible"));
    await save(page);
    await expectNow(
      page,
      `Saved your entry for ${dayLabel(-1).split(", ")[1]}`,
    );

    await press(page, button(page, "Next day"));
    await expectShown(page, dayLabel(0));
    await expect(feeling(page, "Great")).toHaveAttribute(
      "aria-current",
      "true",
    );
    await expect(button(page, "Next day")).toBeDisabled();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("opens on the day selected in Home's calendar", async ({ page }) => {
    await loginToHome(page);
    await button(page, /^Yesterday/).click();
    await pressOnHome(page, "Add details");
    await expect(button(page, "Previous day")).toBeVisible();
    await expectShown(page, dayLabel(-1));
    await expect(button(page, "Next day")).toBeEnabled();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("leaving with unsaved changes asks first, and Discard throws them away", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Okay"));
    await press(page, button(page, "Increase bowel movements"));
    await button(page, /^Back\b/).click();
    await expectNow(page, "Save your changes?");
    await beat(page);
    await button(page, /^Discard$/).click();
    await expect(homeButton(page, "Add details")).toBeVisible();

    await pressOnHome(page, "Add details");
    await expect(button(page, "Previous day")).toBeVisible();
    await expect(feeling(page, "Okay")).toHaveAttribute(
      "aria-current",
      "false",
    );
    await expect(bowelCard(page, 0)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("Save changes in the leave prompt stores the entry before going back", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Good"));
    await button(page, /^Back\b/).click();
    await expectNow(page, "Save your changes?");
    await button(page, /^Save changes$/).click();
    await expect(homeButton(page, "Add details")).toBeVisible();
    await beat(page);

    await pressOnHome(page, "Add details");
    await expect(feeling(page, "Good")).toHaveAttribute("aria-current", "true");
    expect(pageErrors(page)).toEqual([]);
  });

  test("changing day with unsaved changes asks before switching", async ({
    page,
  }) => {
    await openTracking(page);
    await press(page, feeling(page, "Great"));
    await press(page, button(page, "Previous day"));
    await expectNow(page, "Save your changes?");
    await button(page, /^Save changes$/).click();
    await expectShown(page, dayLabel(-1));
    await beat(page);
    await press(page, button(page, "Next day"));
    await expectShown(page, dayLabel(0));
    await expect(feeling(page, "Great")).toHaveAttribute(
      "aria-current",
      "true",
    );
    expect(pageErrors(page)).toEqual([]);
  });
});
