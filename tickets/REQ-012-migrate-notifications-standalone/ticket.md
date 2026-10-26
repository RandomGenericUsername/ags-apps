---
id: REQ-012
title: "Migrate notifications to a standalone repo (already live)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate notifications to a standalone repo (already live)

## Requirement

Move `notifications` into its own standalone repo with the manifest +
`palette-refresh` contract. Keep the deployed config directory
`ags-notifications` and the AGS instance name `notifications` unchanged.

This is primarily a packaging cutover: the app already live-refreshes. The
manifest declares `refresh: live`, no restart (it owns
`org.freedesktop.Notifications` and can hold a transient progress card), and
the command re-applies the palette and reloads the wallpaper-progress icons.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, tests and a
      release/pin note.
- [ ] Deployed config dir is still `ags-notifications`; instance name is still
      `notifications`.
- [ ] Manifest declares `refresh: live`, no restart, and the `palette-refresh`
      command.
- [ ] `palette-refresh` preserves the progress card/bus ownership and refreshes
      the palette + progress icons.
- [ ] The existing live behavior and trigger semantics are preserved or
      explicitly documented.
- [ ] Dotfiles cutover pins the new repo, removes the app from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new pin.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement before adding more live refreshes.

## Evidence

- `notifications/ui/NotificationsWindow.tsx` wallpaper handler and icons.
- `notifications/app.tsx` bus ownership.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` notifications row.
