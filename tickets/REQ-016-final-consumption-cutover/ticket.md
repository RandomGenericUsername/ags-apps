---
id: REQ-016
title: "Final dotfiles consumption cutover + archive ags-apps"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Final dotfiles consumption cutover + archive ags-apps

## Requirement

Finish the program:

- every app entry in the `dotfiles-v3` app list is `owner: standalone`;
- no app is deployed from the old `ags-apps` monorepo;
- the old `ags_apps` role and pin are deleted;
- `ags-apps` is archived, not kept as an empty meta repo;
- deploy coverage, verify, docs, keybind docs and runtime manifests match the
  new topology;
- the final state is proven on this host.

This child is the final integration gate.

## Acceptance

- [ ] Every app in scope has a standalone repo, immutable annotated tag and
      individual `dotfiles-v3` list entry with `owner: standalone`.
- [ ] No app is deployed from `ags-apps`; the old role/pin is removed, and the
      old `gui_tools`/`config_links`/`cli_tools` app entries no longer own any
      migrated launcher, autostart or link.
- [ ] No duplicate config link, XDG link, bin link, launcher, autostart entry,
      process or D-Bus instance exists; the app-list ownership predicate covers
      all of them.
- [ ] The program `ags-platform`/`contracts`/`dotfiles-assets` tuple is the only
      deployed tuple; every app repo pins it.
- [ ] Every `ags run` path uses the shared launch lock.
- [ ] `dotfiles-v3` deploy coverage and `dotfiles-provision` verify pass for the
      new topology; the app-list schema validates.
- [ ] Docs list every app's repo, pin, config dir, instance, mode and launch
      policy.
- [ ] `ags-apps` is archived with a note that the app sources and program
      tickets moved to the standalone repos/consumers.
- [ ] A final no-op reconcile performs no live refresh and no restart; a real
      appearance change follows each app's declared mode and the ledger.
- [ ] All child tickets are `done` and this epic's rollup holds.

## Dependencies

- `REQ-009` through `REQ-015`.
- `REQ-008` contract, ledger, template and cutover fixture.
- `dotfiles-v3`/`dotfiles-provision` final list, role removal and verify.

## Evidence

- `dotfiles-v3/scripts/deploy-coverage.py` app coverage.
- `dotfiles-provision` role vars/verify mirrors.
- `tickets/INDEX.md` rollup.
