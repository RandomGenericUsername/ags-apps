---
id: REQ-014
title: "Migrate icme to a standalone repo (already live)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate icme to a standalone repo (already live)

## Requirement

Move `icme` (the icon-color mapping editor) into its own standalone repo with
the manifest + `palette-refresh` contract. Keep the deployed config directory
`ags-icme` and the AGS instance name `icon-color-mapping-editor` unchanged.

This is primarily a packaging cutover: the app already live-refreshes and holds
unsaved edits. The manifest declares `refresh: live`, `holdsUnsavedState: true`,
and no restart. The command re-applies the palette and rebuilds the show only
when the scheme fingerprint moved, preserving all pending/staging maps.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, tests and a
      release/pin note.
- [ ] Deployed config dir is still `ags-icme`; instance name is still
      `icon-color-mapping-editor`.
- [ ] Manifest declares `refresh: live`, `holdsUnsavedState: true`, and the
      `palette-refresh` command.
- [ ] `palette-refresh` preserves pending edits and only rebuilds the show when
      the scheme fingerprint changes.
- [ ] Existing live behavior and pending-edit protection are preserved.
- [ ] Dotfiles cutover pins the new repo, removes the app from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new pin.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement before adding more live refreshes.

## Evidence

- `icme/ui/EditorWindow.tsx` live handler, fingerprint and map handler.
- `icme/app.tsx` startup theme.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` ICME row.
