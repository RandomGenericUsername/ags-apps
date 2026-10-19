---
id: REQ-001
title: "Bar as a thin platform consumer + publish + CI"
kind: requirement
status: done
lane: 2
links:
  openspec: bar-thin-consumer
  bmad: none
worktree: .worktrees/bar1/
branch: ticket/bar1-thin-consumer
---

# Bar as a thin platform consumer + publish + CI

## Requirement

Move the bar into `ags-apps` as a thin consumer of `ags-platform`: it imports the ports/adapters (icons, events, preferences, notifier, theme) and carries only bar-specific code (layout default, surface bodies, `PopupHost`, shapes, capabilities, `bar-manifest.ts`). Add per-app CI.

Source: spine **AD-1**, **AD-8**, **AD-14**, **AD-23**; handoff iteration 4.

## Acceptance

- [x] The bar imports the platform and no other app (grep: no `ags-*` cross-imports).
- [x] `make bar-typecheck` + `make ags-test` pass from this repo.
- [x] Per-app CI runs the bar's typecheck + tests.

## Closing evidence (v0.3.8 roll-up)

- **Merged:** `8a7ea20 merge ticket/bar1-thin-consumer: bar thin consumer
  (REQ-001 slice 1)`; guards re-homed by `182ed86 merge
  ticket/bar7-rehome-guards: re-home bar guards (icons-json-drift, parity,
  audio, symbol)`. Tags `bar-v0.1.0` and `bar-v0.1.1`.
- **Consumed by dotfiles-v3:** `da26ab3f feat(provisioning): consume
  ags-apps/bar as one pinned unit (slice 2)` (pin `bar-v0.1.0`), then
  `3efc9918 chore(provisioning): pin ags-apps bar unit to bar-v0.1.1`.
- **AD-1 evidence:** `grep -rnE 'from\s+"(bar|notifications|capture-tool|hypr-pano|wallpaper-selector|icme|btop-theme-studio)/'`
  over all seven app trees → no matches. `bar/` imports only `ags-platform/*`
  adapters plus its own modules.
- **Gates (run in this repo, 2026-10-19):** `make bar-typecheck` → exit 0
  (`OK: 0 errors in bar`); `make gates-ci` → exit 0 (includes `make ags-test`).
- **CI:** `.github/workflows/bar.yml` defines `ags-test` (stock runner) and
  `bar-typecheck` (self-hosted). Wired in the repo; the GitHub run history was
  not queried from here.
