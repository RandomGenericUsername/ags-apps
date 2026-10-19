---
id: REQ-003
title: "Migrate capture-tool"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-capture-tool
  bmad: none
worktree: .worktrees/cap5/
branch: ticket/cap5-migrate
---

# Migrate capture-tool

## Requirement

Capture-tool depends on the platform: its `icon-registry.ts` copy is replaced by the platform `IconProvider`, and its theming routes through the `Theme` port. Its direct notification sends route through `Notifier`. The `bar_compact_controls` config becomes the first `Preferences` adapter.

Source: spine **AD-7**, **AD-11**, **AD-12**, **AD-13**; handoff iteration 6.

## Acceptance

- [ ] `src/gui-tools/capture-tool/lib/icon-registry.ts` is gone; the platform provider is used.
- [ ] `bar_compact_controls` is served through `Preferences` (owned file + monitor).
- [ ] Direct `Notify` sends route through `Notifier`.

## Migration notes (slice 5, ticket/cap5-migrate)

- **icon-registry gone / platform provider used — DONE.** The moved app's
  `capture-tool/lib/icon-registry.ts` is deleted; `ui/shared/icons.ts` resolves
  the `capture-tool` group through `ags-platform/adapters/icon`'s
  `registryProvider` (a tagged `IconSource`; only a rendered `file` loads, else
  the text label stays). Pinned by
  `capture-tool/tests/ts/platform-consumption.test.ts`. Theming likewise routes
  through `ags-platform/adapters/theme` (`theme.apply()`); no `app.apply_css`
  call survives. The in-place `src/gui-tools/capture-tool/` copy stays until the
  separate deletion change (AD-20).
- **`bar_compact_controls` through `Preferences` — ALREADY SATISFIED, no
  capture-tool change needed.** The platform's `Preferences` adapter owns the
  `capture-tool` namespace file + its `Gio.FileMonitor`
  (`ags-platform/adapters/preferences.ts`), and the BAR reads the key through the
  port (`bar/bar/widgets/recording.tsx:55`,
  `preferences.get("capture-tool", "bar_compact_controls", false)`). It landed
  with the bar slice (REQ-001). The port is read-only, so capture-tool keeps its
  own `SettingsStore` for writes; there is nothing on the app side to repoint.
- **Direct `Notify` -> `Notifier` — N/A (premise gap).** The capture-tool GUI
  sends NO notification: the only `Gio.` use in the app is `Gio.ListModel` for
  monitor topology, and there is no `Notify`/`org.freedesktop.Notifications`
  call in `app.tsx`, `domain/`, `ports/`, `adapters/` or `ui/`. The sends live in
  the Python backend `bin/capture-tool` (`emit_notification`,
  `dunstify`/`notify-send`), which is placed by `cli_tools` and is not part of
  the AGS app. There is therefore no GUI send to route through the platform
  `Notifier`; routing the Python backend is out of scope for an AGS-app move.
- **AD-24 (surface before content): NOT adopted (measured).** The window tree is
  built once at startup; a show only re-reads persisted choices + `present()`.
  Measured open path: cold construct 6.96-7.29 ms, warm 3.97-4.57 ms, recurring
  show 1.49-1.85 ms (first ever show 85.6-95.4 ms, a one-time process/layer-shell
  warm-up). Single-digit ms recurring -> a light surface keeps its direct path.
  Harness: `/tmp/opencode/cap-measure`.
- **Gates.** `make capture-tool-tests` (stock) + `make capture-tool-typecheck`
  (desktop stack) + per-app CI (`.github/workflows/capture-tool.yml`);
  `capture-tool-tests` joins `gates-ci`. No drift gate: the app consumes no
  contract topic.
- **Tests re-homed.** `tests/ts/*.test.ts` moved with the app. The
  launcher-agreement leg of `window-identity.test.ts` (subject: dotfiles'
  `capture-ui.j2`) and the `src/gui-tools/...` path regex in
  `typecheck-config.test.ts` were the only adaptations; dotfiles' copy of the
  suite remains, so the launcher contract is still pinned until the deletion
  change. The Python backend suites (`tests/*.py`) test `bin/capture-tool`, which
  did not move.

