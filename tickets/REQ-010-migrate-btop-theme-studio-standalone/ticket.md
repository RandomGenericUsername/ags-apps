---
id: REQ-010
title: "Migrate btop-theme-studio to a standalone repo with pending-aware live refresh"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate btop-theme-studio to a standalone repo with pending-aware live refresh

## Requirement

Move `btop-theme-studio` into its own standalone repo and give it the
manifest + `palette-refresh` contract. Keep the deployed config directory
`ags-btop-studio` and the AGS instance name `btop-theme-studio` unchanged.

The app declares `refresh: live` and `holdsUnsavedState: true`. It must never be
restarted by the runtime, even if a refresh fails.

`palette-refresh` must:

- re-read `current/colors.yaml` and `current/colors.btop.theme`;
- update the UI palette and the generated theme map;
- preserve the in-memory pending-edit map;
- re-render through the existing reactive `createEffect(renderAll)`;
- show a visible status when the generated base changed while pending edits
  exist.

The exact pending policy (full refresh with a status, or chrome-only plus a
stale marker) is an explicit decision in this child. The default is to preserve
pending edits and never discard them.

The immediate runtime skip-list safety fix is a separate `dotfiles-runtime`
bug and is a prerequisite for this child's cutover.

## Acceptance

- [ ] The runtime skip-list bug for `ags-btop-studio` is fixed and tested before
      this child claims safety.
- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, pure tests
      and a release/pin note.
- [ ] Deployed config dir is still `ags-btop-studio`; instance name is still
      `btop-theme-studio`.
- [ ] Manifest declares `refresh: live`, `holdsUnsavedState: true`, and the
      `palette-refresh` command.
- [ ] `palette-refresh` re-reads both palette files, updates palette + generated
      theme, preserves pending, re-renders and reports the pending/stale state.
- [ ] Regression tests prove pending edits survive a refresh and the app is
      never restarted.
- [ ] Dotfiles cutover pins the new repo, removes the app from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new pin and pending policy.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime`: skips `ags-btop-studio`; manifest/invocation support.
- `ags-platform` provider replacement before live chrome refresh.
- Immediate btop skip-list bug (separate ticket).

## Evidence

- `btop-theme-studio/ui/StudioWindow.tsx` palette/generated-map loads, pending
  map, save path and reactive render.
- `btop-theme-studio/app.tsx` startup-only theme apply.
- `btop-theme-studio/README.md` thin-consumer and no-contract-topic note.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` btop gap.
