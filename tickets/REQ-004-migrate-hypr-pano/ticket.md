---
id: REQ-004
title: "Migrate hypr-pano"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-hypr-pano
  bmad: none
worktree: none
branch: none
---

# Migrate hypr-pano

## Requirement

Hypr-pano depends on the platform: its `event-bus-core.ts`/`event-bus.ts` copies are replaced by the one event client (dropping the dead `speedtest.finished` literal), its `icon-registry.ts` copy by the platform `IconProvider`, and its theming by the `Theme` port.

Source: spine **AD-5**, **AD-7**, **AD-13**; handoff iteration 6; sweep evidence (dead `SPEEDTEST_FINISHED_TOPIC`).

## Acceptance

- [ ] `lib/event-bus*.ts` + `lib/icon-registry.ts` are gone; the platform is used.
- [ ] `speedtest.finished` appears nowhere in the app (grep → none).
- [ ] The drift test is repointed to the shared client.
