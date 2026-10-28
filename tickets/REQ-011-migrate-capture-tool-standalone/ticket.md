---
id: REQ-011
title: "Migrate capture-tool to ags-capture-tool with live refresh"
kind: requirement
status: done
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

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Manifest identity is `capture` / `ags-capture`, `mode: live`, no unsaved
      state.
- [x] `palette-refresh` reloads icons/windows without a process restart and
      without closing the active surface; a fake runtime test covers the busy
      path.
- [x] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner; capture's bin link remains correct.
- [x] Old source is removed from `ags-apps`; docs record the new pin.

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

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-capture-tool` `v0.1.0` (annotated); manifest `capture` /
  `capture` / `ags-capture` / `live` / `holdsUnsavedState: false`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: capture`, `owner: standalone`, `binLink: capture-tool`, launcher
  `capture-ui`, autostart `capture`, `launch: on-demand`, `cutoverId: REQ-011`.
- **Live refresh:** icons/windows reload in place without a restart or closing
  the active capture/settings surface.
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no host `ags-apps`;
  `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-capture-tool describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
