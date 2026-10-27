---
id: REQ-014
title: "Migrate icme to ags-icme (already live)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate icme to ags-icme (already live)

## Requirement

Move `icme` into `ags-icme`. Keep the deployed config dir `ags-icme` and
instance `icon-color-mapping-editor`. The manifest declares `app: icme`,
`instance: icon-color-mapping-editor`, `configDir: ags-icme`, `mode: live`,
`holdsUnsavedState: true`.

The command re-applies the palette and rebuilds the show only when the scheme
fingerprint moved, preserving all pending/staging maps. The app must never be
restarted.

## Acceptance

- [ ] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [ ] Manifest identity is `icme` / `icon-color-mapping-editor` / `ags-icme`,
      `mode: live`, unsaved state true.
- [ ] `palette-refresh` preserves pending edits and only rebuilds the show when
      the scheme fingerprint changes.
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

- `icme/ui/EditorWindow.tsx` live handler, fingerprint and map handler.
- `icme/app.tsx` startup theme.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` ICME row.
