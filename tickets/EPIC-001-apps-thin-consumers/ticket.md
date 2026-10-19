---
id: EPIC-001
title: "AGS apps as thin consumers of the platform"
kind: epic
status: done
lane: bmad-advisory
links:
  openspec: none
  bmad: none
worktree: .worktrees/EPIC-001/
branch: ticket/EPIC-001-apps-thin-consumers
children: [REQ-001, REQ-002, REQ-003, REQ-004, REQ-005, REQ-006, REQ-007]
done-when: "ags-apps holds the bar plus the six apps, each depending only on ags-platform (never on each other), with per-app CI."
---

# AGS apps as thin consumers of the platform

## Done-when

`ags-apps` holds the bar plus the six apps, each depending **only** on `ags-platform` (never on each other), with per-app CI.

Governed by spine **AD-1** (apps → platform only), **AD-5** (one event client), **AD-8** (shapes), **AD-23** (per-app CI).

## Children

- [x] `REQ-001` — Bar as a thin platform consumer + publish + CI (`done`)
- [x] `REQ-002` — Migrate notifications (`done`)
- [x] `REQ-003` — Migrate capture-tool (`done`)
- [x] `REQ-004` — Migrate hypr-pano (`done`)
- [x] `REQ-005` — Migrate wallpaper-selector (`done`)
- [x] `REQ-006` — Migrate icme (`done`)
- [x] `REQ-007` — Migrate btop-theme-studio (`done`)

## Closing evidence (v0.3.8)

All seven children merged and tagged; dotfiles-v3 pins the unit at `v0.3.8`
(`src/provisioning/ansible/roles/ags_apps/vars/main.yml:99`). Per-child
commit/tag/consumption evidence is recorded in each `REQ-00X/ticket.md` under
"Closing evidence". AD-1 holds by source scan: no app imports a sibling app;
each app imports only `ags-platform/*` plus its own modules.

Lifecycle caveat: the OpenSpec changes linked by REQ-001..006 have no artifacts
under `openspec/changes/` (the archive is empty), so `openspec validate
--change <name>` cannot be run; REQ-003's `Notify` criterion is N/A and left
unticked. Closure here rests on the merged commits, tags, gates and dotfiles
consumption, not on those two lifecycle gates.
