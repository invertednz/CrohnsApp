import { expect, test } from "@playwright/test";
import { boot, button, loginToHome, openTab, pageErrors } from "./helpers";

test.describe("Smoke", () => {
  test("app boots to the welcome screen", async ({ page }) => {
    await boot(page);
    await expect(button(page, "Log In")).toBeVisible();
    expect(pageErrors(page)).toEqual([]);
  });

  test("returning user can log in and reach every tab", async ({ page }) => {
    await loginToHome(page);
    for (const tab of ["Symptoms", "Supps", "Meds", "Chat", "Home"] as const) {
      await openTab(page, tab);
      await expect(button(page, new RegExp(`^${tab}.*Tab`))).toBeVisible();
    }
    expect(pageErrors(page)).toEqual([]);
  });
});
