---
id: EPIC-001
title: "AGS apps as thin consumers of the platform"
kind: epic
status: proposed
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

- [ ] `REQ-001` — Bar as a thin platform consumer + publish + CI (`proposed`)
- [ ] `REQ-002` — Migrate notifications (`proposed`)
- [ ] `REQ-003` — Migrate capture-tool (`proposed`)
- [ ] `REQ-004` — Migrate hypr-pano (`proposed`)
- [ ] `REQ-005` — Migrate wallpaper-selector (`proposed`)
- [ ] `REQ-006` — Migrate icme (`proposed`)
- [ ] `REQ-007` — Migrate btop-theme-studio (`in-progress`)
