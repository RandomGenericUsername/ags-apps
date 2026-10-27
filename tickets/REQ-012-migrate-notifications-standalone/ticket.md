---
id: REQ-012
title: "Migrate notifications to ags-notifications (already live)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate notifications to ags-notifications (already live)

## Requirement

Move `notifications` into `ags-notifications`. Keep the deployed config dir
`ags-notifications` and instance `notifications`. The manifest declares
`app: notifications`, `instance: notifications`,
`configDir: ags-notifications`, `mode: live`, `holdsUnsavedState: false`.

The command re-applies the palette and reloads the wallpaper-progress icons
while preserving the progress card and `org.freedesktop.Notifications`
ownership. `wallpaper.state` remains the progress-card/UI event, not the
palette-refresh trigger.

## Acceptance

- [ ] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [ ] Manifest identity is `notifications` / `ags-notifications`, `mode: live`,
      no unsaved state.
- [ ] `palette-refresh` preserves the progress card/bus ownership and refreshes
      palette + progress icons.
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

- `notifications/ui/NotificationsWindow.tsx` wallpaper handler and icons.
- `notifications/app.tsx` bus ownership.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` notifications row.
