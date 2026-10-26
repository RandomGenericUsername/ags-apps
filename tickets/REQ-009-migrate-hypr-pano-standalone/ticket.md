---
id: REQ-009
title: "Migrate hypr-pano to a standalone repo with live palette refresh"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate hypr-pano to a standalone repo with live palette refresh

## Requirement

Move `hypr-pano` into its own standalone repo and make it the pilot for the
manifest + `palette-refresh` contract. Keep the deployed config directory
`ags-hypr-pano` and the AGS instance name `hypr-pano` unchanged.

The app declares `refresh: live` and implements `palette-refresh` by:

- clearing the process-level `tokenCache` and `textureCache`;
- re-reading the palette tokens and re-applying the Theme port;
- rebuilding the cards and the static search icon so they pick up the new
  colors and textures;
- preserving overlay visibility, query, selection and clipboard state.

A wallpaper change must not restart the process.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, pure tests
      and a release/pin note.
- [ ] Deployed config dir is still `ags-hypr-pano`; instance name is still
      `hypr-pano`.
- [ ] Manifest declares `refresh: live`, no unsaved state, and the
      `palette-refresh` command.
- [ ] `palette-refresh` clears both caches, re-applies the palette, rebuilds the
      cards/search icon and preserves overlay state.
- [ ] Regression test proves a palette refresh does not quit or relaunch the
      app; a fake runtime command exercises the handler.
- [ ] Dotfiles cutover pins the new repo, removes `hypr-pano` from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new consumption pin.
- [ ] `ags bundle` and the app's gates pass.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement (the live refresh re-applies the Theme
  port).

## Evidence

- `hypr-pano/ui/ItemCard.tsx` token/texture caches.
- `hypr-pano/ui/PanoWindow.tsx` card rebuild and static search icon.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` pano row.
