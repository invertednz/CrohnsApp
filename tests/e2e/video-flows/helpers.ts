import { Page, expect } from "@playwright/test";
import path from "path";
import fs from "fs";

const VIDEOS_DIR = path.resolve(__dirname, "../../../videos");

export async function saveVideo(page: Page, filename: string) {
  await page.close();
  const video = page.video();
  if (video) {
    const videoPath = await video.path();
    const destPath = path.join(VIDEOS_DIR, filename);
    if (!fs.existsSync(VIDEOS_DIR)) {
      fs.mkdirSync(VIDEOS_DIR, { recursive: true });
    }
    // Wait a moment for video to finalize
    await new Promise((r) => setTimeout(r, 1000));
    fs.copyFileSync(videoPath, destPath);
  }
}

export async function smoothScroll(page: Page, selector: string) {
  await page.locator(selector).scrollIntoViewIfNeeded();
  await page.waitForTimeout(600);
}

/**
 * Scrolls the inner .page-container so that the target element is at the top
 * of the visible area. This produces distinct screenshots for elements that
 * are within the same device-frame scroll container.
 */
export async function scrollToTop(page: Page, selector: string) {
  await page.locator(selector).evaluate((el) => {
    const container =
      el.closest(".page-container") || el.closest(".overflow-y-auto");
    if (container) {
      const elTop = el.getBoundingClientRect().top;
      const containerTop = container.getBoundingClientRect().top;
      container.scrollTop += elTop - containerTop - 10;
    } else {
      el.scrollIntoView({ block: "start" });
    }
  });
  await page.waitForTimeout(600);
}

export async function pause(page: Page, ms = 800) {
  await page.waitForTimeout(ms);
}

/**
 * Takes a screenshot, saves it to /videos/ with the given filename,
 * and verifies the screenshot file was created and has a non-trivial size
 * (> 5KB means it rendered real content, not a blank page).
 */
export async function takeAndVerifyScreenshot(
  page: Page,
  filename: string,
  options?: { fullPage?: boolean },
) {
  if (!fs.existsSync(VIDEOS_DIR)) {
    fs.mkdirSync(VIDEOS_DIR, { recursive: true });
  }
  const screenshotPath = path.join(VIDEOS_DIR, filename);
  await page.screenshot({
    path: screenshotPath,
    fullPage: options?.fullPage ?? false,
  });

  // Verify screenshot file exists and has meaningful content (not blank)
  expect(fs.existsSync(screenshotPath)).toBe(true);
  const stats = fs.statSync(screenshotPath);
  expect(stats.size).toBeGreaterThan(5000);
}

/**
 * Takes a screenshot of a specific element/section, saves it to /videos/.
 * Useful for capturing distinct screenshots of sections within the same page
 * that would otherwise look identical in a viewport screenshot.
 */
export async function takeElementScreenshot(
  page: Page,
  selector: string,
  filename: string,
) {
  if (!fs.existsSync(VIDEOS_DIR)) {
    fs.mkdirSync(VIDEOS_DIR, { recursive: true });
  }
  const screenshotPath = path.join(VIDEOS_DIR, filename);
  const locator = page.locator(selector).first();
  await locator.scrollIntoViewIfNeeded();
  await page.waitForTimeout(300);
  await locator.screenshot({ path: screenshotPath });

  expect(fs.existsSync(screenshotPath)).toBe(true);
  const stats = fs.statSync(screenshotPath);
  expect(stats.size).toBeGreaterThan(1000);
}
