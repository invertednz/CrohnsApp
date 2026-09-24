// Collects the videos from a recorded Playwright run into videos/e2e/,
// writes an index.html to browse them, and stitches a walkthrough MP4 of the
// key journeys (needs ffmpeg on PATH).
//
//   VIDEO=1 npx playwright test -c playwright.flutter.config.ts --reporter=json > run.json
//   node scripts/collect-e2e-videos.mjs run.json [rerun.json ...]
// Later reports replace earlier results for the same test (e.g. a rerun).
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";

const reportPaths = process.argv.slice(2);
if (!reportPaths.length) {
  console.error(
    "usage: node scripts/collect-e2e-videos.mjs <playwright-json-report> [more reports]",
  );
  process.exit(1);
}

const reports = reportPaths.map((p) => JSON.parse(fs.readFileSync(p, "utf8")));
const outDir = path.resolve("videos/e2e");
fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

const slug = (s) =>
  s
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 70);
const byKey = new Map();

function walk(suite, titles) {
  for (const child of suite.suites ?? []) walk(child, [...titles, child.title]);
  for (const spec of suite.specs ?? []) {
    for (const t of spec.tests) {
      const last = t.results[t.results.length - 1];
      const video = last?.attachments?.find(
        (a) => a.name === "video" && a.path,
      );
      if (!video || !fs.existsSync(video.path)) continue;
      // The describe path is part of the key: tests can share a title
      // across describe blocks (e.g. the same check at two viewport sizes).
      const group = titles.filter(Boolean).slice(1).join(" › ");
      byKey.set(`${spec.file}|${group}|${spec.title}|${t.projectName}`, {
        file: spec.file,
        project: t.projectName,
        title: spec.title,
        group,
        status: last.status,
        retried: t.results.length > 1,
        src: video.path,
      });
    }
  }
}
for (const report of reports)
  for (const suite of report.suites) walk(suite, [suite.title]);

const entries = [...byKey.values()];
entries.sort(
  (a, b) =>
    a.file.localeCompare(b.file) ||
    a.group.localeCompare(b.group) ||
    a.title.localeCompare(b.title),
);
entries.forEach((e, i) => {
  const name = `${String(i + 1).padStart(3, "0")}-${slug(e.file.replace(".spec.ts", ""))}-${slug(`${e.group} ${e.title}`)}.webm`;
  fs.copyFileSync(e.src, path.join(outDir, name));
  e.name = name;
});

const esc = (s) =>
  s.replace(
    /[&<>"]/g,
    (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[c],
  );
const byFile = Object.groupBy(entries, (e) => e.file);
const passed = entries.filter((e) => e.status === "passed").length;
const failed = entries.length - passed;
const retried = entries.filter((e) => e.retried).length;
const html = `<!doctype html><html><head><meta charset="utf-8"><title>GutMD E2E videos</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
body{font-family:system-ui,sans-serif;background:#0f172a;color:#e0e7ff;margin:0;padding:24px}
h1{margin:0 0 4px}h2{margin:32px 0 12px;color:#a5b4fc}
.grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px}
figure{margin:0;background:#1e1b4b;border-radius:12px;padding:10px}
video{width:100%;border-radius:8px;background:#000}
figcaption{font-size:13px;margin-top:6px}.pass{color:#10b981}.fail{color:#ef4444}
</style></head><body>
<h1>GutMD end-to-end test videos</h1>
<p>${entries.length} recordings · passed ${passed} · failed ${failed} · passed on retry ${retried} · walkthrough: <a style="color:#a5b4fc" href="walkthrough.mp4">walkthrough.mp4</a></p>
${Object.entries(byFile)
  .map(
    ([file, list]) =>
      `<h2>${esc(file)}</h2><div class="grid">${list
        .map(
          (
            e,
          ) => `<figure><video controls preload="none" src="${e.name}"></video><figcaption>
<span class="${e.status === "passed" ? "pass" : "fail"}">${e.status === "passed" ? "✓" : "✗"}</span>
${e.group ? `<small>${esc(e.group)}</small><br>` : ""}${esc(e.title)}${e.project !== "mobile" ? ` <small>(${esc(e.project)})</small>` : ""}${e.retried ? " <small>(retried)</small>" : ""}</figcaption></figure>`,
        )
        .join("")}</div>`,
  )
  .join("")}
</body></html>`;
fs.writeFileSync(path.join(outDir, "index.html"), html);
console.log(`copied ${entries.length} videos to ${outDir}`);

// Walkthrough: key journeys in product order.
const journey = [
  [/onboarding-intro/, /Full intro walkthrough/],
  [/plan-and-retention/, /personalised 14-day plan/],
  [/plan-and-retention/, /press-and-hold/],
  [/onboarding-paywall/, /trial timeline/],
  [/plan-and-retention/, /guest sees their plan/],
  [/plan-and-retention/, /checking in unlocks/],
  [/home/, /meal photo/i],
  [/home/, /typed log entry/],
  [/tracking/, /full entry saves/],
  [/diet/, /./],
  [/insights/, /./],
  [/symptoms/, /./],
  [/supplements/, /./],
  [/medications/, /./],
  [/chat/, /food triggers/],
  [/plan-and-retention/, /upgrade to a full account/],
];
const picked = [];
for (const [fileRe, titleRe] of journey) {
  const hit = entries.find(
    (e) =>
      fileRe.test(e.file) &&
      titleRe.test(e.title) &&
      e.status === "passed" &&
      !picked.includes(e),
  );
  if (hit) picked.push(hit);
}
try {
  const list = path.join(outDir, "walkthrough.txt");
  fs.writeFileSync(list, picked.map((e) => `file '${e.name}'`).join("\n"));
  execFileSync(
    "ffmpeg",
    [
      "-y",
      "-loglevel",
      "error",
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      "walkthrough.txt",
      "-vf",
      "scale=390:844:force_original_aspect_ratio=decrease,pad=390:844:(ow-iw)/2:(oh-ih)/2,fps=25",
      "-c:v",
      "libx264",
      "-pix_fmt",
      "yuv420p",
      "-movflags",
      "+faststart",
      "walkthrough.mp4",
    ],
    { cwd: outDir, stdio: "inherit" },
  );
  fs.rmSync(list);
  console.log(
    `walkthrough.mp4 from ${picked.length} journeys:\n  ${picked.map((e) => e.name).join("\n  ")}`,
  );
} catch (err) {
  console.error("walkthrough not created (is ffmpeg installed?):", err.message);
}
