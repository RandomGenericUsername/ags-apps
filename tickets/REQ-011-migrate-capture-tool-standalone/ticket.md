---
id: REQ-011
title: "Migrate capture-tool to ags-capture-tool with live refresh"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate capture-tool to ags-capture-tool with live refresh

## Requirement

Move `capture-tool` into `ags-capture-tool`. Keep the deployed config dir
`ags-capture` and instance `capture`. The manifest declares `app: capture`,
`instance: capture`, `configDir: ags-capture`, `mode: live`,
`holdsUnsavedState: false`.

`palette-refresh` must reload the generated icons and update or rebuild the
per-monitor windows in place without closing the active capture/settings
surface. If an operation is in flight, the handler must preserve it or return a
busy result; it must never restart the process.

## Acceptance

- [ ] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [ ] Manifest identity is `capture` / `ags-capture`, `mode: live`, no unsaved
      state.
- [ ] `palette-refresh` reloads icons/windows without a process restart and
      without closing the active surface; a fake runtime test covers the busy
      path.
- [ ] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner; capture's bin link remains correct.
- [ ] Old source is removed from `ags-apps`; docs record the new pin.

## Dependencies

- `REQ-008` contract/schemas/template/cutover fixture.
- `ags-platform` Theme one-provider replacement and manifest helper.
- `dotfiles-runtime` manifest discovery, ledger, lanes.
- `dotfiles-v3`/`dotfiles-provision` app list and generic role.

## Evidence

- `capture-tool/app.tsx` startup theme and window set.
- `capture-tool/ui/shared/icons.ts` generated icons built into widgets.
- `capture-tool/ui/classic/SettingsPage.tsx` immediate settings persistence.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` capture row.
