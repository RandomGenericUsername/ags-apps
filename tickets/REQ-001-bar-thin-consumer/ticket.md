---
id: REQ-001
title: "Bar as a thin platform consumer + publish + CI"
kind: requirement
status: proposed
lane: 2
links:
  openspec: bar-thin-consumer
  bmad: none
worktree: none
branch: none
---

# Bar as a thin platform consumer + publish + CI

## Requirement

Move the bar into `ags-apps` as a thin consumer of `ags-platform`: it imports the ports/adapters (icons, events, preferences, notifier, theme) and carries only bar-specific code (layout default, surface bodies, `PopupHost`, shapes, capabilities, `bar-manifest.ts`). Add per-app CI.

Source: spine **AD-1**, **AD-8**, **AD-14**, **AD-23**; handoff iteration 4.

## Acceptance

- [ ] The bar imports the platform and no other app (grep: no `ags-*` cross-imports).
- [ ] `make bar-typecheck` + `make ags-test` pass from this repo.
- [ ] Per-app CI runs the bar's typecheck + tests.
