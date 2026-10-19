---
id: REQ-007
title: "Migrate btop-theme-studio"
kind: requirement
status: in-progress
lane: 2
links:
  openspec: none
  bmad: none
worktree: .worktrees/btop8/
branch: ticket/btop8-migrate
---

# Migrate btop-theme-studio

## Requirement

`btop-theme-studio` (7th app-move slice, 8.1) moves from
`dotfiles-v3/src/gui-tools/btop-theme-studio/` into this unit as
`btop-theme-studio/`, depending on the platform only (spine **AD-1**):

- theming routes through the `Theme` port (`ags-platform/adapters/theme`,
  **AD-13**) — no app-local `theme.ts` and no direct `app.apply_css` call;
- no app-local icon-registry / event-bus copies (this app has none today; the
  gate pins that it does not grow one);
- no app → app imports (**AD-1**);
- per-app gates are wired (`typecheck`, pure tests including the generated
  key→widget drift check) and run in `gates-ci` + CI.

The Python live-preview engine (`live/btop_live.py`) and the generated
key→widget map (`lib/key_widgets.json`, `lib/key-widgets.generated.ts`, the
vendored btop sources + generator) are app runtime / reproducibility assets,
not a provisioning concern, so they stay in the app tree and behaviour is
preserved.

AD-24 (overlay lifecycle) is **conditional**: the studio's open-path widget-tree
build is measured on the live compositor, and the primitive is adopted only if
that build is significant (tens of ms or more). The measured number and the
decision are recorded in the migration commit.

## Acceptance

- [ ] `btop-theme-studio/` is the seventh app in this unit; it moves with its
  UI, pure lib, tests, tools, live engine and generated map unchanged first.
- [ ] Theming goes through the platform `Theme` port; no local `theme.ts`
  and no direct `app.apply_css` call survives.
- [ ] No app-local icon-registry / event-bus copy exists, and no source file
  imports a sibling app (AD-1).
- [ ] Gates `btop-theme-studio-typecheck` and `btop-theme-studio-tests`
  (including the key→widget drift check) are wired; the pure gate is in
  `gates-ci` and a `btop-theme-studio` CI workflow.
- [ ] The Python live engine and generated key→widget assets stay in the app
  tree; their behaviour is preserved and their tests are runnable.
- [ ] The open-path build is measured with an instrumented, distinctly named
  instance (live instance untouched); the AD-24 adopt/decline decision records
  that number.
- [ ] `ags bundle btop-theme-studio/app.tsx /tmp/opencode/btop.js --gtk 4`
  exits 0.
