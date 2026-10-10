---
id: REQ-005
title: "Migrate wallpaper-selector"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-wallpaper-selector
  bmad: none
worktree: none
branch: none
---

# Migrate wallpaper-selector

## Requirement

Wallpaper-selector depends on the platform: its `event-bus-core.ts`/`event-bus.ts` copies are replaced by the one event client, its `icon-registry.ts` by the platform `IconProvider`, and its `theme.ts` by the `Theme` port. It consumes `wallpaper.state` through the shared client.

Source: spine **AD-5**, **AD-7**, **AD-13**; handoff iteration 6.

## Acceptance

- [ ] `lib/event-bus*.ts` + `lib/icon-registry.ts` + `lib/theme.ts` are gone; the platform is used.
- [ ] `wallpaper.state` (including `stage`/`reload_failures`) is consumed via the shared client.
- [ ] The drift test is repointed.
