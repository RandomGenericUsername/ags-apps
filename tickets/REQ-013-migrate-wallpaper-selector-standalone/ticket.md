---
id: REQ-013
title: "Migrate wallpaper-selector to ags-wallpaper-selector (already live)"
kind: requirement
status: proposed
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

- [ ] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [ ] Manifest identity is `wallpaper-selector` / `ags-wallpaper-selector`,
      `mode: live`, no unsaved state.
- [ ] `palette-refresh` preserves the drawer and refreshes palette/search
      icon/model.
- [ ] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner.
- [ ] Old source is removed from `ags-apps`; docs record the new pin.

## Dependencies

- `REQ-008` contract/schemas/template/cutover fixture.
- `ags-platform` Theme one-provider replacement and manifest helper.
- `dotfiles-runtime` manifest discovery, ledger, lanes.
- `dotfiles-v3`/`dotfiles-provision` app list and generic role.

## Evidence

- `wallpaper-selector/ui/WallpaperSelectorWindow.tsx` live refresh handler.
- `wallpaper-selector/app.tsx` on-demand window.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` selector row.
