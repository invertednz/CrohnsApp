import { expect, test, type Locator, type Page } from "@playwright/test";
import {
  beat,
  button,
  expectText,
  field,
  loginToHome,
  onScreen,
  openTab,
  pageErrors,
  scrollUntilVisible,
  tap,
  type,
} from "./helpers";

/**
 * Chat assistant tab. The offline test build answers with deterministic,
 * data-aware replies (no Gemini), so replies are asserted by content.
 */

const INPUT_LABEL = /Type your message/i;

async function openChat(page: Page): Promise<void> {
  await loginToHome(page);
  await openTab(page, "Chat");
  await expect(page.getByText("Chat Assistant")).toBeVisible();
}

function chatInput(page: Page): Locator {
  return field(page, INPUT_LABEL).first();
}

function sendButton(page: Page): Locator {
  return button(page, /^Send message$/).first();
}

/** Type a message into the composer and submit it with the Enter key. */
async function sendWithEnter(page: Page, text: string): Promise<void> {
  const input = chatInput(page);
  await input.click();
  await input.fill(text);
  await page.keyboard.press("Enter");
}

/**
 * Chat text rendered on screen. Scoped to the semantics tree because a new
 * reply is also mirrored into an off-screen screen-reader live region (which
 * sits before the app in the DOM, so a page-wide `.first()` would pick it).
 */
function chatText(page: Page, text: string | RegExp): Locator {
  return onScreen(page).getByText(text).first();
}

async function expectReply(page: Page, text: string | RegExp): Promise<void> {
  await expect(chatText(page, text)).toBeVisible({ timeout: 10_000 });
}

/** Chat messages appear top-to-bottom in the given order. */
async function expectTopToBottom(
  page: Page,
  texts: (string | RegExp)[],
): Promise<void> {
  let previousY = -Infinity;
  for (const text of texts) {
    const box = await chatText(page, text).boundingBox();
    expect(box, `${text} is in the conversation`).not.toBeNull();
    expect(box!.y, `${text} is below the previous message`).toBeGreaterThan(
      previousY,
    );
    previousY = box!.y;
  }
}

/** Wheel-scroll the conversation up until `target` is inside the visible message area. */
async function scrollConversationUpTo(
  page: Page,
  target: Locator,
): Promise<void> {
  const header = await onScreen(page)
    .getByText("Ask questions about your gut health")
    .boundingBox();
  const composer = await chatInput(page).boundingBox();
  expect(header).not.toBeNull();
  expect(composer).not.toBeNull();
  const listTop = header!.y + header!.height;
  const listBottom = composer!.y;
  await page.mouse.move(
    page.viewportSize()!.width / 2,
    (listTop + listBottom) / 2,
  );
  for (let i = 0; i < 20; i++) {
    const box = (await target.count()) > 0 ? await target.boundingBox() : null;
    if (box && box.y >= listTop && box.y + box.height <= listBottom) return;
    await page.mouse.wheel(0, -250);
    await page.waitForTimeout(250);
  }
  await expect(target).toBeInViewport();
}

/** Record whether `text` ever appears in the semantics DOM (for short-lived UI). */
async function watchForText(page: Page, text: string): Promise<void> {
  await page.evaluate((needle) => {
    const w = window as unknown as {
      __sawText?: boolean;
      __watcher?: MutationObserver;
    };
    w.__sawText = false;
    w.__watcher?.disconnect();
    const check = () => {
      if ((document.body.textContent ?? "").includes(needle))
        w.__sawText = true;
    };
    w.__watcher = new MutationObserver(check);
    w.__watcher.observe(document.body, {
      childList: true,
      subtree: true,
      characterData: true,
    });
    check();
  }, text);
}

async function sawWatchedText(page: Page): Promise<boolean> {
  return page.evaluate(
    () => (window as unknown as { __sawText?: boolean }).__sawText === true,
  );
}

test.describe("Chat assistant", () => {
  test("empty chat shows a welcome message and suggested starter questions", async ({
    page,
  }) => {
    await openChat(page);
    await expect(
      page.getByText("Ask questions about your gut health").first(),
    ).toBeVisible();
    await expectText(page, "Start a conversation");
    await expectText(page, "Suggested Questions");
    for (const question of [
      "What foods should I avoid with my condition?",
      "How can I manage pain during a flare-up?",
      "What supplements are recommended for gut health?",
      "Can stress trigger digestive symptoms?",
    ]) {
      await expect(button(page, question)).toBeVisible();
    }
    await expect(chatInput(page)).toBeVisible();
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("starter questions include a check-in summary prompt", async ({
    page,
  }) => {
    await openChat(page);
    await expect(button(page, "How have I been feeling lately?")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("a medical disclaimer is always shown under the message box", async ({
    page,
  }) => {
    await openChat(page);
    await expect(page.getByText(/not medical advice/i).first()).toBeVisible();
    await expect(page.getByText(/contact your doctor/i).first()).toBeVisible();
    await sendWithEnter(page, "Hello");
    await expectReply(page, /You can ask me about/);
    await expect(page.getByText(/not medical advice/i).first()).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("pressing Enter sends the message, clears the box and shows the assistant reply", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "Hello there");
    await expect(chatText(page, "Hello there")).toBeVisible();
    await expect(chatInput(page)).toHaveValue("");
    await expectReply(page, /You can ask me about/);
    await expect(page.getByText("Start a conversation")).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the Send message button sends the typed message", async ({ page }) => {
    await openChat(page);
    const input = chatInput(page);
    await input.click();
    await input.fill("What supplements should I take?");
    await expect(sendButton(page)).toBeEnabled();
    await sendButton(page).click();
    await expect(
      chatText(page, "What supplements should I take?"),
    ).toBeVisible();
    await expectReply(page, /vitamin D|B12/i);
    await expect(input).toHaveValue("");
    expect(pageErrors(page)).toEqual([]);
  });

  test("an empty or blank message is never sent", async ({ page }) => {
    await openChat(page);
    const input = chatInput(page);
    await input.click();
    await page.keyboard.press("Enter");
    await input.fill("    ");
    await page.keyboard.press("Enter");
    await page.waitForTimeout(800);
    await expect(page.getByText("Start a conversation")).toBeVisible();
    await expect(page.getByText(/You can ask me about/)).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the Send message button is disabled until there is text to send", async ({
    page,
  }) => {
    await openChat(page);
    await expect(sendButton(page)).toBeDisabled();
    const input = chatInput(page);
    await input.click();
    await input.fill("   ");
    await expect(sendButton(page)).toBeDisabled();
    await input.fill("Hi");
    await expect(sendButton(page)).toBeEnabled();
    await input.fill("");
    await expect(sendButton(page)).toBeDisabled();
    await expect(page.getByText("Start a conversation")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("a typing indicator shows while the assistant is replying", async ({
    page,
  }) => {
    await openChat(page);
    await watchForText(page, "GutMD Assistant is typing");
    await sendWithEnter(page, "Hello");
    await expectReply(page, /You can ask me about/);
    expect(await sawWatchedText(page)).toBe(true);
    await expect(page.getByText("GutMD Assistant is typing")).toHaveCount(0);
    expect(pageErrors(page)).toEqual([]);
  });

  test("tapping a suggested food question sends it and answers about trigger foods", async ({
    page,
  }) => {
    await openChat(page);
    await tap(page, "What foods should I avoid with my condition?");
    await expect(
      chatText(page, "What foods should I avoid with my condition?"),
    ).toBeVisible();
    await expectReply(page, /trigger foods/i);
    await expect(
      button(page, "How can I manage pain during a flare-up?"),
    ).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the suggested flare-up pain question gets flare self-care guidance", async ({
    page,
  }) => {
    await openChat(page);
    await tap(page, "How can I manage pain during a flare-up?");
    await expectReply(page, /ibuprofen/i);
    await expect(
      chatText(page, /contact your doctor or IBD team/i),
    ).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("the suggested stress question gets stress guidance, not a generic symptom reply", async ({
    page,
  }) => {
    await openChat(page);
    await tap(page, "Can stress trigger digestive symptoms?");
    await expectReply(page, /Stress is commonly linked/);
    expect(pageErrors(page)).toEqual([]);
  });

  test("urgent symptoms are met with advice to contact a doctor straight away", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "I have blood in my stool and a fever");
    await expectReply(page, /urgent medical attention/i);
    await expect(chatText(page, /emergency services/i)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("replies use food triggers the user saved on the Diet screen", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, "Meals & triggers");
    await expectText(page, "Diet Tracker");
    // The Food Triggers card is one semantics group named by its title (and empty-state text).
    const triggers = page.getByRole("group", { name: /^Food Triggers\b/ });
    await scrollUntilVisible(page, triggers);
    await triggers.getByRole("button", { name: /^Add trigger$/ }).click();
    await expect(
      onScreen(page).getByText("Add Food Trigger", { exact: true }),
    ).toBeVisible();
    await type(page, /^Food name/, "Popcorn");
    await button(page, /^Add$/).last().click();
    await expect(
      onScreen(page).getByText("Add Food Trigger", { exact: true }),
    ).toHaveCount(0);
    // Saved triggers are chips inside the Food Triggers card.
    await expect(
      triggers.getByRole("checkbox", { name: /^Popcorn$/ }),
    ).toBeVisible();
    await tap(page, /^Save diet log$/);
    await expect(
      onScreen(page).getByText("Saved your diet log for today"),
    ).toBeVisible();
    await beat(page);
    await page.goBack();
    await expect(button(page, /^Home.*Tab 1/)).toBeVisible();

    await openTab(page, "Chat");
    await sendWithEnter(page, "What foods should I avoid?");
    await expectReply(page, /triggers to avoid: Popcorn/);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("replies use the mood saved on the Daily Tracking screen", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, "Add details");
    await expectText(page, "Daily Tracking");
    await tap(page, /🤗|^Great/);
    await tap(page, /^Save$/);
    await expect(
      onScreen(page).getByText("Saved your entry for today"),
    ).toBeVisible();
    await page.goBack();
    await expect(button(page, /^Home.*Tab 1/)).toBeVisible();

    await openTab(page, "Chat");
    await sendWithEnter(page, "How have I been feeling lately?");
    await expectReply(page, /great/i);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the check-in summary starter question reports the latest mood", async ({
    page,
  }) => {
    await loginToHome(page);
    await tap(page, "Add details");
    await expectText(page, "Daily Tracking");
    await tap(page, /🤗|^Great/);
    await tap(page, /^Save$/);
    await expect(
      onScreen(page).getByText("Saved your entry for today"),
    ).toBeVisible();
    await page.goBack();

    await openTab(page, "Chat");
    await tap(page, "How have I been feeling lately?");
    await expectReply(page, /most recent check-in .* was "Great"/);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the conversation is kept when switching tabs and coming back", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "What supplements should I take?");
    await expectReply(page, /B12/);
    await openTab(page, "Home");
    await expect(page.getByText("Chat Assistant")).toHaveCount(0);
    await openTab(page, "Meds");
    await openTab(page, "Chat");
    await expect(
      chatText(page, "What supplements should I take?"),
    ).toBeVisible();
    await expect(chatText(page, /B12/)).toBeVisible();
    await expect(page.getByText("Start a conversation")).toHaveCount(0);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the Reload conversation button reloads saved messages", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "Hello");
    await expectReply(page, /You can ask me about/);
    await expect(button(page, /^Reload conversation$/)).toBeEnabled();
    await button(page, /^Reload conversation$/).click();
    await expect(chatText(page, "Hello")).toBeVisible();
    await expect(chatText(page, /You can ask me about/)).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("a long multi-sentence message is sent in full and answered", async ({
    page,
  }) => {
    await openChat(page);
    const longMessage =
      "Here is everything I ate today so I can keep a proper record for my dietitian. " +
      "Breakfast was porridge made with oat milk, a sliced banana and a spoon of honey. " +
      "Mid-morning I had a cup of peppermint tea and two plain crackers. " +
      "Lunch was white rice with poached chicken, steamed carrots and a little olive oil. " +
      "In the afternoon I snacked on a pot of lactose-free yoghurt and some peeled apple. " +
      "Dinner was baked salmon with mashed potato and courgette, followed by a small bowl of stewed pears. " +
      "Which of these foods are usually gentle on the gut, and is there anything here I should be careful with?";
    await sendWithEnter(page, longMessage);
    await expect(
      chatText(page, "Here is everything I ate today"),
    ).toBeVisible();
    await expect(
      chatText(page, "is there anything here I should be careful with?"),
    ).toBeVisible();
    await expectReply(page, /trigger foods/i);
    await beat(page);
    expect(pageErrors(page)).toEqual([]);
  });

  test("several messages in a row stay in order and the newest reply is scrolled into view", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "What supplements should I take?");
    await expectReply(page, /B12/);
    await sendWithEnter(page, "Hello again");
    await expectReply(page, /You can ask me about/);
    await sendWithEnter(page, "What foods should I avoid?");
    await expectReply(page, /trigger foods/i);
    await expect(chatText(page, "What foods should I avoid?")).toBeInViewport();
    await expect(chatText(page, /trigger foods/i)).toBeInViewport();
    await expectTopToBottom(page, [
      "What foods should I avoid?",
      /trigger foods/i,
    ]);

    // Scrolling back up shows the earlier exchange, still in the order it was sent.
    // (The list is lazy, so the first message is only in the DOM once scrolled near.)
    await scrollConversationUpTo(
      page,
      chatText(page, "What supplements should I take?"),
    );
    await expectTopToBottom(page, [
      "What supplements should I take?",
      /B12/,
      "Hello again",
    ]);
    expect(pageErrors(page)).toEqual([]);
  });

  test("the message box keeps focus after sending so a follow-up can be typed straight away", async ({
    page,
  }) => {
    await openChat(page);
    await sendWithEnter(page, "Hello");
    await expectReply(page, /You can ask me about/);
    await expect(chatInput(page)).toBeFocused();
    await page.keyboard.type("What supplements should I take?");
    await page.keyboard.press("Enter");
    await expect(
      chatText(page, "What supplements should I take?"),
    ).toBeVisible();
    await expectReply(page, /B12/);
    expect(pageErrors(page)).toEqual([]);
  });
});
