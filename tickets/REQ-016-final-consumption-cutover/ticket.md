---
id: REQ-016
title: "Final dotfiles consumption cutover + archive ags-apps"
kind: requirement
status: done
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

- [x] Every app in scope has a standalone repo, immutable annotated tag and
      individual `dotfiles-v3` list entry with `owner: standalone`.
- [x] No app is deployed from `ags-apps`; the old role/pin is removed, and the
      old `gui_tools`/`config_links`/`cli_tools` app entries no longer own any
      migrated launcher, autostart or link.
- [x] No duplicate config link, XDG link, bin link, launcher, autostart entry,
      process or D-Bus instance exists; the app-list ownership predicate covers
      all of them.
- [x] The program `ags-platform`/`contracts`/`dotfiles-assets` tuple is the only
      deployed tuple; every app repo pins it.
- [x] Every `ags run` path uses the shared launch lock.
- [x] `dotfiles-v3` deploy coverage and `dotfiles-provision` verify pass for the
      new topology; the app-list schema validates.
- [x] Docs list every app's repo, pin, config dir, instance, mode and launch
      policy.
- [x] `ags-apps` is archived with a note that the app sources and program
      tickets moved to the standalone repos/consumers.
- [x] A final no-op reconcile performs no live refresh and no restart; a real
      appearance change follows each app's declared mode and the ledger.
- [x] All child tickets are `done` and this epic's rollup holds.

## Dependencies

- `REQ-009` through `REQ-015`.
- `REQ-008` contract, ledger, template and cutover fixture.
- `dotfiles-v3`/`dotfiles-provision` final list, role removal and verify.

## Evidence

- `dotfiles-v3/scripts/deploy-coverage.py` app coverage.
- `dotfiles-provision` role vars/verify mirrors.
- `tickets/INDEX.md` rollup.

## Closeout evidence (2026-10-28)

Final integration gate — proven on this host:

- **Ownership:** all 7 `apps.yaml` entries are `owner: standalone`; the old
  `ags_apps` role/pin/playbook is absent from the pinned engine
  (`deploy-coverage`: "legacy `ags_apps` role/playbook absent"); no
  `gui_tools`/`config_links`/`cli_tools` entry owns a migrated surface.
- **No duplicate/missing surface:** `dotfiles-provision verify` → exit 0
  (`returncode: 0`, `~/.local/share/dotfiles`); one live/restart owner per app
  (bar + notifications always-on, the rest on-demand); no `<install>/ags-apps`.
- **Tuple:** `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`, mirrored by the engine + verify vars; the seven app
  repos pin the same tuple. Engine `v0.1.24`, runtime `v0.3.0`.
- **Docs:** `dotfiles-v3/docs/102-ags-app-consumption.md` lists every app's
  repo, tag, config dir, instance, mode, launcher and cutover id.
- **Archive:** `RandomGenericUsername/ags-apps` → `isArchived: true`; the tree is
  retained as read-only history (per the EPIC-002 archive decision), not
  deployed anywhere.
- **4.2 refresh proof:** no-op reconcile `20261028T220521Z` performed no live
  refresh/restart; changed appearance `20261028T220612Z` restarted the bar
  (`restart`, exit 0) and applied a live `palette-refresh` to notifications
  (`{"ok":true}`), 0 failures; five on-demand apps stayed down.
- **Rollup:** EPIC-002 and all nine children are `done` in `tickets/INDEX.md`.

Verify: `cd dotfiles-v3 && make deploy-coverage && dotfiles-provision verify`;
`gh repo view RandomGenericUsername/ags-apps --json isArchived`.
