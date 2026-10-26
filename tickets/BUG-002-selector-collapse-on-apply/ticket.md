---
id: BUG-002
title: "Apply click must collapse the wallpaper selector immediately"
kind: bug
status: in-progress
lane: 2
severity: medium
links:
  openspec: none
  bmad: none
worktree: .worktrees/BUG-002/
branch: ticket/BUG-002-selector-collapse-on-apply
repro: "rg -n 'hideWindow\\(\\)|state === \"visible\"' wallpaper-selector/ui/WallpaperSelectorWindow.tsx"
observed: "hideWindow() only in doApply's finally after the awaits (line 776) and in the 'visible' event branch (line 811); no hide at the Apply click, so the drawer stays open until the wallpaper event arrives"
expected: "hideWindow() called in doApply after the busy guard and before its first await, and no hideWindow() in the 'visible' branch; the drawer collapses on the Apply click while the apply continues in the background"
---

# BUG-002 — Apply click must collapse the wallpaper selector immediately

## Symptom

The intended UX is that pressing **Apply** in the wallpaper selector collapses
the drawer immediately. The code does not collapse on the click: it hides on
the `wallpaper.state → visible` event (and again in `doApply`'s success
`finally`). Today that reads as "instant" only because the current runtime
swaps the wallpaper first, so `visible` arrives almost immediately. When the
palette reorder makes `visible` later (palette generated before the visible
swap), the drawer would stay open for seconds after the click.

## Repro

Code evidence (exact command):

```
rg -n 'hideWindow\(\)|state === "visible"' wallpaper-selector/ui/WallpaperSelectorWindow.tsx
```

Timing repro (manual, GUI): with a deliberately slow apply (8K fixture or any
wallpaper that makes palette generation take seconds), open the selector →
click **Apply** → the drawer stays visible until the `visible` event, not on
the click. In the current runtime the palette step is fast, so the defect is
masked; the source evidence above is the deterministic reproduction.

## Observed

`wallpaper-selector/ui/WallpaperSelectorWindow.tsx` (at `49adc30`):

- `doApply()` starts at line 726. After the guard `if (localApply || eventBusy) return;`
  (line 731) it never calls `hideWindow()`; the first `await` is at line 750
  (`loadContrastPref`) and the apply is awaited at line 762.
- The drawer is hidden in two other places:
  - line 776, in `doApply`'s `finally`: `if (ok) hideWindow();`
  - line 811, in `onWallpaperEvent` when `state === "visible"`:
    `if (localApply) hideWindow();`
- So the collapse trigger is the wallpaper event/success, not the Apply click.
  External sets (`localApply === false`) never hide — that part is correct.

## Expected

- Clicking **Apply** calls `hideWindow()` immediately, after the busy guard and
  before the first await; the drawer collapses on the click.
- The apply keeps running in the background; `done`/`error` still rescan,
  refresh chrome and unlock the Apply controls.
- No hide from the `visible` branch. A window the user reopens while the apply
  is still running must not be closed when the apply completes.
- A failed apply is surfaced by the notifications app's `wallpaper.state:error`
  card (the runtime contract); the selector does not reopen itself.
- External sets never hide the window.

## Triage (/triage)

- `kind: bug` — implementation does not match the intended UX; the ticket
  carries `repro` / `observed` / `expected`, so it enters at `triage` rather
  than being rejected.
- `lane: 2` — one bounded behavior fix, fully understood, one item; no
  OpenSpec change is needed for a bug fix (the bug lifecycle is
  `triage → in-progress → done`), and there is no architectural unknown, so
  BMAD is not invoked.
- `severity: medium` — no data loss and no crash; the drawer stays open longer
  than intended once the palette reorder lands, and the error surface moves to
  the notification card. Not release-blocking by itself, but the palette
  reorder depends on this being explicit.
- Guard: `bash scripts/worktree-guard.sh check-clean` → exit 0 before creating
  the worktree.

Evidence: `wallpaper-selector/ui/WallpaperSelectorWindow.tsx:726-778` (apply
path, no click-time hide) and `:794-829` (event handler hides on `visible`);
`/home/inumaki/.opencode/plan/08-ags-apps-BUG-002-selector-collapse.md:9-51`
(required behavior and fix). Verify: the `repro` command above.

## Fix notes

- `doApply`: after the busy guard, set `localApply`/busy and call
  `hideWindow()` before the first `await` (the contrast-store lookup). Comment
  the contract: the click collapses, the apply continues in the background.
- Remove the `visible`-branch hide: it is the wrong trigger and, after the
  palette reorder, arrives seconds late; it would also close a window the user
  reopened while the apply finished.
- Remove the `finally` success hide: with the click hide it is redundant, and
  because the apply runs in the background it would close a selector the user
  reopened before `done`. The click hide is the contract.
- `error`: do not reopen; the notifications app subscribes to
  `wallpaper.state` (`notifications/ui/NotificationsWindow.tsx:329-386`) and
  renders the sticky "Wallpaper update stopped" card on `phase === "error"`
  with the failed stage (`notifications/lib/card-model.ts:76-87`).
- Regression test: `wallpaper-selector/tests/apply-collapse.test.mjs`
  (source-level wiring/timing assertion — the TSX cannot be imported under
  plain `node` because it imports `ags/gtk4` + `gi://*`). It pins the single
  click-time `hideWindow()` before the first await and the absence of any
  hide in `onWallpaperEvent`.

## Acceptance

- [ ] Apply click → drawer collapses immediately; apply continues in the
      background (source/timing proof green; manual step recorded).
- [ ] No `hideWindow()` in the `visible` branch or in a later `finally`.
- [ ] External sets never hide the window.
- [ ] Error surface unchanged: notification card, no auto-reopen.
- [ ] `make wallpaper-selector-tests` → exit 0.
- [ ] `make wallpaper-selector-typecheck` → exit 0.
- [ ] `make wallpaper-selector-drift-test` → exit 0.
- [ ] `make gates-ci` → exit 0.

## Closing evidence

(Filled at closeout.)
