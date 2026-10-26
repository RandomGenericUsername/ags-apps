---
id: REQ-016
title: "Final dotfiles consumption cutover + ags-apps disposition"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Final dotfiles consumption cutover + ags-apps disposition

## Requirement

After the app children are complete, finish the program:

- every migrated app is consumed by its own pinned repo and role;
- no migrated app is deployed from the old `ags-apps` unit;
- there is no duplicate config dir or duplicate AGS instance in a provisioned
  session;
- deploy coverage, docs, keybind docs and runtime manifests match the new
  topology;
- decide and record what `ags-apps` becomes: a coordination/meta repo (tickets,
  shared tests, docs) or an archive.

This child is the final integration gate, not a re-implementation of any app.

## Acceptance

- [ ] Every app in scope has a standalone repo, tag and individual dotfiles
      pin/role.
- [ ] The old `ags-apps` unit no longer deploys migrated app sources (or the
      documented exception is recorded).
- [ ] No duplicate config dir or AGS instance exists after provisioning.
- [ ] Deploy coverage passes for the new topology.
- [ ] Docs list every app's repo, pin, config dir and refresh mode.
- [ ] The `ags-apps` disposition is recorded in the repo README/AGENTS or an
      archive note.
- [ ] A final no-op-reconcile check shows no consumer restart; a real palette
      change follows each app's declared refresh mode.
- [ ] All child tickets are `done` and this epic's rollup holds.

## Dependencies

- `REQ-009` through `REQ-015`.
- `REQ-008` contract.
- `dotfiles-v3`/`dotfiles-provision` final pins and roles.

## Evidence

- `dotfiles-v3/scripts/deploy-coverage.py` app coverage.
- `dotfiles-provision` role vars and verify mirrors.
- `tickets/INDEX.md` rollup.
