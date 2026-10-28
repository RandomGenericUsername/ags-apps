---
id: REQ-012
title: "Migrate notifications to ags-notifications (already live)"
kind: requirement
status: done
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

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Manifest identity is `notifications` / `ags-notifications`, `mode: live`,
      no unsaved state.
- [x] `palette-refresh` preserves the progress card/bus ownership and refreshes
      palette + progress icons.
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

- `notifications/ui/NotificationsWindow.tsx` wallpaper handler and icons.
- `notifications/app.tsx` bus ownership.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` notifications row.

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-notifications` `v0.1.0` (annotated); manifest
  `notifications` / `notifications` / `ags-notifications` / `live` /
  `holdsUnsavedState: false`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: notifications`, `owner: standalone`, autostart `notifications`,
  `launch: always`, `cutoverId: REQ-012`.
- **Live refresh:** palette + progress icons reload while the progress card and
  `org.freedesktop.Notifications` bus ownership stay live; `wallpaper.state`
  remains the progress event, not the palette trigger.
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no host `ags-apps`;
  `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-notifications describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
