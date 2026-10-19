// ---------------------------------------------------------------------------
// Platform-consumption acceptance tests (REQ-003, EPIC-001).
//
// These make the REQ-003 acceptance executable rather than prose:
//
//   1. `lib/icon-registry.ts` is gone; the platform IconProvider is used
//      (spine AD-7).
//   2. Theming routes through the platform `Theme` port; no direct
//      `app.apply_css` call survives (spine AD-13).
//   3. No app -> app imports (spine AD-1): an app depends on `ags-platform`
//      (and `contracts`), never on a sibling app directory.
//   4. No bespoke event reader (spine AD-5): the one event client is the
//      platform's. capture-tool has no event reader today; this pins that it
//      does not grow one, and that the app-local copies AD-5 replaced stay gone.
//
// Source-text assertions, labelled as such: they pin wiring (which module a
// symbol is imported from), which is exactly what the acceptance criteria
// name. They do not execute the app.
// ---------------------------------------------------------------------------

import { test } from "node:test"
import assert from "node:assert/strict"
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, resolve, relative } from "node:path"

const HERE = dirname(fileURLToPath(import.meta.url))
const CAPTURE_TOOL = resolve(HERE, "../..")

/** Every app source file (`.ts`/`.tsx`), excluding the test tree. */
function appSources(): string[] {
  const out: string[] = []
  const walk = (dir: string): void => {
    for (const entry of readdirSync(dir)) {
      if (entry === "node_modules" || entry === "@girs" || entry === "tests") continue
      const full = resolve(dir, entry)
      const st = statSync(full)
      if (st.isDirectory()) {
        walk(full)
      } else if (entry.endsWith(".ts") || entry.endsWith(".tsx")) {
        out.push(full)
      }
    }
  }
  walk(CAPTURE_TOOL)
  return out.sort()
}

function read(path: string): string {
  return readFileSync(path, "utf8")
}

function rel(path: string): string {
  return relative(CAPTURE_TOOL, path)
}

// ---------------------------------------------------------------------------
// 1. The icon-registry copy is gone; the platform provider is used
// ---------------------------------------------------------------------------

test("no app-local icon-registry copy survives", () => {
  assert.equal(
    existsSync(resolve(CAPTURE_TOOL, "lib/icon-registry.ts")),
    false,
    "capture-tool/lib/icon-registry.ts must be gone — the platform IconProvider (AD-7) replaces it",
  )
  assert.equal(
    existsSync(resolve(CAPTURE_TOOL, "lib/theme.ts")),
    false,
    "capture-tool/lib/theme.ts must not exist — theming routes through the platform Theme port (AD-13)",
  )
})

test("the capture-tool icons resolve through the platform IconProvider", () => {
  const icons = read(resolve(CAPTURE_TOOL, "ui/shared/icons.ts"))
  assert.match(
    icons,
    /from "ags-platform\/adapters\/icon"/,
    "ui/shared/icons.ts must import the platform registry-backed IconProvider",
  )
  assert.match(
    icons,
    /registryProvider\.resolve\(/,
    "ui/shared/icons.ts must resolve the capture-tool group through registryProvider",
  )
})

// ---------------------------------------------------------------------------
// 2. Theming through the platform Theme port
// ---------------------------------------------------------------------------

test("the app applies its palette through the platform Theme port", () => {
  const app = read(resolve(CAPTURE_TOOL, "app.tsx"))
  assert.match(
    app,
    /from "ags-platform\/adapters\/theme"/,
    "app.tsx must import the platform Theme adapter (AD-13)",
  )
  assert.match(app, /theme\.apply\(\)/, "app.tsx must call theme.apply()")
})

test("no direct app.apply_css call survives in the app", () => {
  for (const path of appSources()) {
    assert.equal(
      /app\.apply_css\(/.test(read(path)),
      false,
      `${rel(path)} still calls app.apply_css directly — theming must route through the Theme port`,
    )
  }
})

// ---------------------------------------------------------------------------
// 3. No app -> app imports (AD-1)
// ---------------------------------------------------------------------------

//: The sibling app directories in this monorepo. An import specifier that
//: resolves into one of these is an app -> app edge. `capture-tool` itself is
//: deliberately absent: importing its own files is not an app -> app edge.
const SIBLING_APPS = [
  "bar",
  "notifications",
  "hypr-pano",
  "wallpaper-selector",
  "icme",
  "btop-theme-studio",
]

const IMPORT_RE = /(?:from|import)\s+["']([^"']+)["']/g

test("no source file imports a sibling app (AD-1)", () => {
  const offenders: string[] = []
  for (const path of appSources()) {
    const text = read(path)
    for (const m of text.matchAll(IMPORT_RE)) {
      const spec = m[1]
      // Relative specifiers only; bare specifiers (ags-platform, ags, gi://) are fine.
      if (!spec.startsWith(".")) continue
      const target = resolve(dirname(path), spec)
      for (const app of SIBLING_APPS) {
        if (target === resolve(CAPTURE_TOOL, "..", app) || target.startsWith(resolve(CAPTURE_TOOL, "..", app) + "/")) {
          offenders.push(`${rel(path)} -> ${spec}`)
        }
      }
    }
  }
  assert.deepEqual(
    offenders,
    [],
    `capture-tool must depend only on ags-platform, never on a sibling app (AD-1):\n${offenders.join("\n")}`,
  )
})

// ---------------------------------------------------------------------------
// 4. No bespoke event reader (AD-5)
// ---------------------------------------------------------------------------

test("no app-local event client survives", () => {
  const offenders = appSources().filter((p) => /(?:event-bus|events)\.ts$/.test(p))
  assert.deepEqual(
    offenders.map(rel),
    [],
    "capture-tool must not carry its own event client — the platform's shared client is the one (AD-5)",
  )
})
