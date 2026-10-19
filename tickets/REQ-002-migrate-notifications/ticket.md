---
id: REQ-002
title: "Migrate notifications"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-notifications
  bmad: none
worktree: .worktrees/notif4/
branch: ticket/notif4-migrate
---

# Migrate notifications

## Requirement

Notifications becomes a consumer of the platform ports and a host that renders cards. Its two bespoke readers (`speedtest-events.ts`, `wallpaper-events.ts`) are replaced by the one event client; its `icon-registry.ts` and `theme.ts` copies are replaced by the platform adapters. It keeps ownership of `org.freedesktop.Notifications`; the keyed/progress path stays the event-card path.

Source: spine **AD-5**, **AD-11**, **AD-13**; handoff iteration 6; sweep evidence (provisioning omits `speedtest-events.ts`).

## Acceptance

- [ ] `speedtest-events.ts` + `wallpaper-events.ts` are gone; the one event client is used.
- [ ] `icon-registry.ts` + `theme.ts` copies are gone.
- [ ] The app still owns `org.freedesktop.Notifications`; the notification-card path is unchanged behaviorally.
