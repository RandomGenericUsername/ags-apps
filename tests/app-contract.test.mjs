// ---------------------------------------------------------------------------
// Manifest + palette-refresh conformance for the in-tree AGS apps (REQ-008,
// AD-26/AD-27/AD-36).
//
// This is the adoption-release gate for the monorepo, not the per-repo template
// gate (`ags-platform`'s `checkAppRepo` owns that once an app moves out). It
// proves four things against the platform v0.3.0 helper and the contracts
// v0.3.0 schema:
//
//   1. every app directory carries a schema-valid `app.manifest.json` with the
//      identity the runtime will discover;
//   2. every `live` app registers a `palette-refresh` handler built from the
//      platform helper; the `restart` bar does not;
//   3. `wallpaper.state` is progress/status only -- no live app applies the
//      palette from that event path;
//   4. the refresh paths preserve the declared state (pending edits, open
//      cards/drawers/overlays) instead of rebuilding or dismissing it.
//
// Plus the platform helper's JSON-string protocol, executed with the same
// applied/deferred/failure shapes the runtime parses.
//
// Run from the repo root:  make app-contract-test
// ---------------------------------------------------------------------------

import { test } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseAgsAppManifest } from "ags-platform/ports/app-manifest";
import {
  PALETTE_REFRESH_COMMAND,
  createPaletteRefreshHandler,
} from "ags-platform/ports/palette-refresh";

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

//: The identity each deployed directory declares. This table is the monorepo
//: adoption record: changing a deployed name is a manifest change, not a
//: runtime list edit (AD-26).
const APPS = [
  {
    dir: "bar",
    manifest: {
      schemaVersion: 1,
      app: "bar",
      instance: "ags",
      configDir: "ags",
      mode: "restart",
      holdsUnsavedState: false,
    },
  },
  {
    dir: "notifications",
    manifest: {
      schemaVersion: 1,
      app: "notifications",
      instance: "notifications",
      configDir: "ags-notifications",
      mode: "live",
      holdsUnsavedState: false,
    },
  },
  {
    dir: "capture-tool",
    manifest: {
      schemaVersion: 1,
      app: "capture",
      instance: "capture",
      configDir: "ags-capture",
      mode: "live",
      holdsUnsavedState: false,
    },
  },
  {
    dir: "hypr-pano",
    manifest: {
      schemaVersion: 1,
      app: "hypr-pano",
      instance: "hypr-pano",
      configDir: "ags-hypr-pano",
      mode: "live",
      holdsUnsavedState: false,
    },
  },
  {
    dir: "wallpaper-selector",
    manifest: {
      schemaVersion: 1,
      app: "wallpaper-selector",
      instance: "wallpaper-selector",
      configDir: "ags-wallpaper-selector",
      mode: "live",
      holdsUnsavedState: false,
    },
  },
  {
    dir: "icme",
    manifest: {
      schemaVersion: 1,
      app: "icme",
      instance: "icon-color-mapping-editor",
      configDir: "ags-icme",
      mode: "live",
      holdsUnsavedState: true,
    },
  },
  {
    dir: "btop-theme-studio",
    manifest: {
      schemaVersion: 1,
      app: "btop-theme-studio",
      instance: "btop-theme-studio",
      configDir: "ags-btop-studio",
      mode: "live",
      holdsUnsavedState: true,
    },
  },
];

const LIVE = APPS.filter((app) => app.manifest.mode === "live");

function readText(...parts) {
  return readFileSync(join(ROOT, ...parts), "utf8");
}

function appSource(appDir) {
  return readText(appDir, "app.tsx");
}

const SOURCE_EXTENSIONS = [".ts", ".tsx", ".js", ".jsx", ".mjs", ".cjs"];
const SKIP_DIRECTORIES = new Set([
  "node_modules",
  "@girs",
  "tests",
  ".dev",
  ".worktrees",
  "dist",
  "build",
]);

/** Concatenate the app's runtime source (tests/build/dev copies excluded). */
function runtimeSource(appDir) {
  const files = [];
  const visit = (relative) => {
    for (const entry of readdirSync(join(ROOT, appDir, relative))) {
      const next = relative === "" ? entry : `${relative}/${entry}`;
      if (SKIP_DIRECTORIES.has(entry)) continue;
      const stat = statSync(join(ROOT, appDir, next));
      if (stat.isDirectory()) visit(next);
      else if (SOURCE_EXTENSIONS.some((extension) => entry.endsWith(extension))) {
        files.push(next);
      }
    }
  };
  visit("");
  return files.map((file) => readText(appDir, file)).join("\n");
}

/** Strip comments, keeping strings intact (same shape as the BUG-002 gate). */
function stripComments(source) {
  let out = "";
  let state = null;
  let i = 0;
  while (i < source.length) {
    const c = source[i];
    const next = source[i + 1];
    if (state === "line") {
      if (c === "\n") {
        state = null;
        out += c;
      }
      i += 1;
      continue;
    }
    if (state === "block") {
      if (c === "*" && next === "/") {
        state = null;
        i += 2;
      } else {
        i += 1;
      }
      continue;
    }
    if (state === "'" || state === '"' || state === "`") {
      out += c;
      if (c === "\\") {
        out += next ?? "";
        i += 2;
        continue;
      }
      if (c === state) state = null;
      i += 1;
      continue;
    }
    if (c === "/" && next === "/") {
      state = "line";
      i += 2;
      continue;
    }
    if (c === "/" && next === "*") {
      state = "block";
      i += 2;
      continue;
    }
    if (c === "'" || c === '"' || c === "`") state = c;
    out += c;
    i += 1;
  }
  return out;
}

/** The `{...}` body of the function named by `marker`, comments stripped. */
function functionBody(source, marker) {
  const clean = stripComments(source);
  const start = clean.indexOf(marker);
  assert.notEqual(start, -1, `missing function marker: ${marker}`);
  const brace = clean.indexOf("{", start);
  assert.notEqual(brace, -1, `missing function body for: ${marker}`);
  let depth = 0;
  let state = null;
  for (let i = brace; i < clean.length; i += 1) {
    const c = clean[i];
    if (state !== null) {
      if (c === "\\") {
        i += 1;
      } else if (c === state) {
        state = null;
      }
      continue;
    }
    if (c === "'" || c === '"' || c === "`") {
      state = c;
      continue;
    }
    if (c === "{") depth += 1;
    if (c === "}") {
      depth -= 1;
      if (depth === 0) return clean.slice(brace + 1, i);
    }
  }
  throw new Error(`unterminated function body: ${marker}`);
}

function findContractsRoot() {
  const override = process.env.CONTRACTS_ROOT;
  if (override) return override;
  let dir = ROOT;
  for (let i = 0; i < 8; i += 1) {
    dir = dirname(dir);
    if (existsSync(join(dir, "contracts", "schemas", "ags-app-manifest.schema.json"))) {
      return join(dir, "contracts");
    }
  }
  return null;
}

// ── 1. Manifests ───────────────────────────────────────────────────────────

test("every app directory carries its deployed identity manifest", () => {
  for (const app of APPS) {
    const result = parseAgsAppManifest(readText(app.dir, "app.manifest.json"));
    assert.equal(
      result.ok,
      true,
      `${app.dir}/app.manifest.json is invalid: ${JSON.stringify(result.issues ?? [])}`,
    );
    assert.deepEqual(
      result.manifest,
      app.manifest,
      `${app.dir} manifest must match the deployed identity`,
    );
  }
});

test("the contracts v0.3.0 schema and platform schemaVersion agree", () => {
  const contractsRoot = findContractsRoot();
  assert.notEqual(
    contractsRoot,
    null,
    "cannot find the contracts checkout (set CONTRACTS_ROOT)",
  );
  const schema = JSON.parse(
    readFileSync(
      join(contractsRoot, "schemas", "ags-app-manifest.schema.json"),
      "utf8",
    ),
  );
  assert.equal(schema.properties.schemaVersion.const, 1);
  assert.equal(schema.additionalProperties, false);
  assert.deepEqual(
    [...schema.required].sort(),
    ["app", "configDir", "holdsUnsavedState", "instance", "mode", "schemaVersion"],
  );
  assert.equal(
    schema.allOf[0].then.properties.holdsUnsavedState.const,
    false,
    "restart must stay invalid when holdsUnsavedState is true",
  );

  const protocol = readFileSync(
    join(contractsRoot, "ags-app-refresh.md"),
    "utf8",
  );
  assert.match(protocol, /`palette-refresh`/);
  assert.match(protocol, /not the palette-refresh\s+trigger/i);
});

test("the adoption pins name the v0.3.0 tuple", () => {
  const makefile = readText("Makefile");
  assert.match(makefile, /^AGS_PLATFORM_VERSION := v0\.3\.0$/m);
  assert.match(makefile, /^CONTRACTS_VERSION := v0\.3\.0$/m);
});

// ── 2. Handler adoption ────────────────────────────────────────────────────

test("every live app registers the platform palette-refresh handler", () => {
  for (const app of LIVE) {
    const source = appSource(app.dir);
    assert.match(
      source,
      /from\s+"ags-platform\/ports\/palette-refresh"/,
      `${app.dir}/app.tsx must import the platform helper`,
    );
    assert.match(
      source,
      /createPaletteRefreshHandler\(/,
      `${app.dir}/app.tsx must build its handler with createPaletteRefreshHandler`,
    );
    assert.match(
      source,
      /requestHandler/,
      `${app.dir}/app.tsx must register the handler on app.start`,
    );
    assert.match(
      source,
      /theme\.apply\(\)/,
      `${app.dir}/app.tsx handler must wrap the app's palette refresh`,
    );
  }
});

test("the bar stays restart with no palette-refresh handler", () => {
  const bar = APPS.find((app) => app.dir === "bar");
  assert.equal(bar.manifest.mode, "restart");
  const source = appSource("bar");
  assert.doesNotMatch(source, /createPaletteRefreshHandler/);
  assert.doesNotMatch(source, /PALETTE_REFRESH_COMMAND/);
  assert.doesNotMatch(source, /ags-platform\/ports\/palette-refresh/);
});

test("hypr-pano composes palette-refresh with its existing request surface", () => {
  const source = appSource("hypr-pano");
  assert.match(source, /PALETTE_REFRESH_COMMAND/);
  assert.match(source, /handleRequest\(/);
  assert.match(
    source,
    /if \(argv\[0\] === PALETTE_REFRESH_COMMAND\)[\s\S]*paletteRefresh\(argv, res\)/,
    "the fixed command must dispatch to the platform handler before the legacy controls",
  );
});

// ── 3. wallpaper.state is not a palette trigger ────────────────────────────

test("notifications applies no palette from the wallpaper.state card path", () => {
  const body = functionBody(
    readText("notifications", "ui", "NotificationsWindow.tsx"),
    "function wallpaperUpdate",
  );
  assert.doesNotMatch(body, /theme\.apply/);
  assert.doesNotMatch(body, /refreshWallpaperIcon/);
  assert.doesNotMatch(body, /refreshNotificationCardIcons/);
});

test("wallpaper-selector applies no palette from the wallpaper.state path", () => {
  const body = functionBody(
    readText("wallpaper-selector", "ui", "WallpaperSelectorWindow.tsx"),
    "function onWallpaperEvent",
  );
  assert.doesNotMatch(body, /theme\.apply/);
  assert.doesNotMatch(body, /refreshChrome/);
  assert.doesNotMatch(body, /refreshWallpaperSelectorChrome/);
});

test("icme no longer subscribes to wallpaper.state for palette", () => {
  const source = stripComments(readText("icme", "ui", "EditorWindow.tsx"));
  assert.doesNotMatch(source, /wallpaper\.state/);
  assert.doesNotMatch(source, /domainEvents\.subscribe/);
});

test("apps without progress cards never consume wallpaper.state", () => {
  for (const app of ["capture-tool", "hypr-pano", "btop-theme-studio"]) {
    assert.doesNotMatch(
      stripComments(runtimeSource(app)),
      /wallpaper\.state/,
      `${app} must not subscribe to wallpaper.state`,
    );
  }
});

// ── 4. Refresh paths preserve declared state ───────────────────────────────

test("notifications refresh never rebuilds or dismisses the card stack", () => {
  const source = readText("notifications", "ui", "NotificationsWindow.tsx");
  const body = functionBody(source, "function refreshWallpaperIcon");
  assert.doesNotMatch(body, /cards\s*=\s*\[\]/);
  assert.doesNotMatch(body, /dismissWallpaperCard/);
  assert.doesNotMatch(body, /hideWindow/);
  assert.match(appSource("notifications"), /refreshNotificationCardIcons\(\)/);
});

test("wallpaper-selector refresh never closes or rescans the drawer", () => {
  const source = readText(
    "wallpaper-selector",
    "ui",
    "WallpaperSelectorWindow.tsx",
  );
  const body = functionBody(source, "function refreshSelectorChrome");
  assert.doesNotMatch(body, /rescan/);
  assert.doesNotMatch(body, /hideWindow/);
  assert.doesNotMatch(body, /clearFlow/);
  assert.match(appSource("wallpaper-selector"), /refreshWallpaperSelectorChrome\(\)/);
});

test("icme refresh preserves pending edits and defers during a save", () => {
  const source = readText("icme", "ui", "EditorWindow.tsx");
  const body = functionBody(source, "async function refreshEditorPaletteNow");
  assert.match(body, /"deferred"/);
  assert.doesNotMatch(body, /setPending\(new Map\(\)\)/);
  assert.doesNotMatch(body, /setSelection\(null\)/);
  assert.doesNotMatch(body, /\bload\(/);
  assert.match(appSource("icme"), /refreshEditorPalette\(\)/);
});

test("btop refresh preserves pending edits, selection and save target", () => {
  const source = readText("btop-theme-studio", "ui", "StudioWindow.tsx");
  const body = functionBody(source, "function reloadPaletteForRefresh");
  assert.match(body, /setPalette\(loadPalette\(\)\)/);
  assert.match(body, /loadGeneratedMap\(\)/);
  assert.doesNotMatch(body, /setPending\(new Map\(\)\)/);
  assert.doesNotMatch(body, /setSelection\(/);
  assert.doesNotMatch(body, /setCurrentId\(/);
  assert.doesNotMatch(body, /setTarget\(/);
  assert.match(appSource("btop-theme-studio"), /refreshStudioPalette\(\)/);
});

test("overlay/capture refresh only re-applies the Theme pointer", () => {
  for (const app of ["hypr-pano", "capture-tool"]) {
    const source = appSource(app);
    assert.match(
      source,
      /createPaletteRefreshHandler\(\(\) => \{\s*theme\.apply\(\)\s*return \{ status: "applied" \}\s*\}\)/s,
      `${app} refresh must only apply the palette`,
    );
    assert.doesNotMatch(
      source,
      /createPaletteRefreshHandler\([\s\S]{0,400}(hideWindow|toggleWindow|showWindow|rebuild\()/,
      `${app} refresh must not touch the transient surface`,
    );
  }
});

// ── 5. The helper's JSON-string protocol ───────────────────────────────────

test("the platform helper answers once with the protocol's JSON strings", () => {
  const cases = [
    [{ status: "applied" }, { ok: true }],
    [
      { status: "deferred", reason: "unsaved edits" },
      { ok: true, deferred: "unsaved edits" },
    ],
    [
      { status: "failed", error: "palette not ready", retryable: true },
      { ok: false, error: "palette not ready", retryable: true },
    ],
  ];

  for (const [result, expected] of cases) {
    const responses = [];
    const handler = createPaletteRefreshHandler(() => result);
    handler([PALETTE_REFRESH_COMMAND, "appearance-hash"], (response) => {
      responses.push(response);
    });
    assert.equal(responses.length, 1, "exactly one response per request");
    assert.equal(typeof responses[0], "string", "AGS transport is a string");
    assert.deepEqual(JSON.parse(responses[0]), expected);
  }
});

test("a malformed request is a terminal failure, not an applied refresh", () => {
  const responses = [];
  let calls = 0;
  const handler = createPaletteRefreshHandler(() => {
    calls += 1;
    return { status: "applied" };
  });
  handler([PALETTE_REFRESH_COMMAND], (response) => responses.push(response));
  assert.equal(calls, 0, "malformed argv must not run the refresh");
  assert.equal(responses.length, 1);
  assert.deepEqual(JSON.parse(responses[0]), {
    ok: false,
    error: "malformed palette-refresh request",
    retryable: false,
  });
});
