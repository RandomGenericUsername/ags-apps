---
id: REQ-013
title: "Migrate wallpaper-selector to ags-wallpaper-selector (already live)"
kind: requirement
status: done
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate wallpaper-selector to ags-wallpaper-selector (already live)

## Requirement

Move `wallpaper-selector` into `ags-wallpaper-selector`. Keep the deployed config
dir `ags-wallpaper-selector` and instance `wallpaper-selector`. The manifest
declares `app: wallpaper-selector`, `instance: wallpaper-selector`,
`configDir: ags-wallpaper-selector`, `mode: live`, `holdsUnsavedState: false`.

The command re-applies the palette, rebuilds the search icon and rescans the
wallpaper model while preserving the drawer state. There is no restart.

## Acceptance

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Manifest identity is `wallpaper-selector` / `ags-wallpaper-selector`,
      `mode: live`, no unsaved state.
- [x] `palette-refresh` preserves the drawer and refreshes palette/search
      icon/model.
- [x] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner.
- [x] Old source is removed from `ags-apps`; docs record the new pin.

## Dependencies

- `REQ-008` contract/schemas/template/cutover fixture.
- `ags-platform` Theme one-provider replacement and manifest helper.
- `dotfiles-runtime` manifest discovery, ledger, lanes.
- `dotfiles-v3`/`dotfiles-provision` app list and generic role.

## Evidence

- `wallpaper-selector/ui/WallpaperSelectorWindow.tsx` live refresh handler.
- `wallpaper-selector/app.tsx` on-demand window.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` selector row.

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-wallpaper-selector` `v0.1.0` (annotated); manifest
  `wallpaper-selector` / `wallpaper-selector` / `ags-wallpaper-selector` /
  `live` / `holdsUnsavedState: false`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: wallpaper-selector`, `owner: standalone`, launcher
  `wallpaper-selector-ui`, `launch: on-demand`, `cutoverId: REQ-013`.
- **Live refresh:** palette re-applied, search icon/model rebuilt, drawer state
  preserved, no restart.
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no host `ags-apps`;
  `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-wallpaper-selector describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
