---
id: REQ-013
title: "Migrate wallpaper-selector to a standalone repo (already live)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate wallpaper-selector to a standalone repo (already live)

## Requirement

Move `wallpaper-selector` into its own standalone repo with the manifest +
`palette-refresh` contract. Keep the deployed config directory
`ags-wallpaper-selector` and the AGS instance name `wallpaper-selector`
unchanged.

This is primarily a packaging cutover: the app already live-refreshes. The
manifest declares `refresh: live`, no restart (restarting would reopen the
on-demand drawer), and the command re-applies the palette, rebuilds the search
icon and rescans the wallpaper model.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, tests and a
      release/pin note.
- [ ] Deployed config dir is still `ags-wallpaper-selector`; instance name is
      still `wallpaper-selector`.
- [ ] Manifest declares `refresh: live`, no restart, and the `palette-refresh`
      command.
- [ ] `palette-refresh` preserves the drawer state and refreshes palette,
      search icon and model.
- [ ] Existing live behavior and BUG-002 click-collapse behavior are preserved.
- [ ] Dotfiles cutover pins the new repo, removes the app from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new pin.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement before adding more live refreshes.

## Evidence

- `wallpaper-selector/ui/WallpaperSelectorWindow.tsx` live refresh handler.
- `wallpaper-selector/app.tsx` on-demand window.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` selector row.
