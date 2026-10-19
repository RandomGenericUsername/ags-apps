---
id: REQ-002
title: "Migrate notifications"
kind: requirement
status: done
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

- [x] `speedtest-events.ts` + `wallpaper-events.ts` are gone; the one event client is used.
- [x] `icon-registry.ts` + `theme.ts` copies are gone.
- [x] The app still owns `org.freedesktop.Notifications`; the notification-card path is unchanged behaviorally.

## Closing evidence (v0.3.8 roll-up)

- **Merged:** `7431e29 merge ticket/notif4-migrate: notifications thin consumer
  (REQ-002)`. Tag `v0.3.4`.
- **Consumed by dotfiles-v3:** `3d2aeb44 feat(ags_apps): consume notifications
  from the unit as a live link; pin v0.3.4`.
- **Copies gone / one event client:** `find notifications -name
  'speedtest-events.ts' -o -name 'wallpaper-events.ts' -o -name
  'icon-registry.ts' -o -name 'theme.ts'` → no matches.
  `notifications/ui/NotificationsWindow.tsx` imports
  `ags-platform/adapters/event-bus`, `adapters/icon` and `adapters/theme`;
  `notifications/app.tsx` imports `adapters/theme`.
- **Daemon ownership:** `notifications/app.tsx:14` sets `NOTIFICATIONS_NAME =
  "org.freedesktop.Notifications"`; the drift gate asserts the name claim,
  the bus probe and `Notifd.get_default()`.
- **Card path:** the re-homed `notifications/tests/card-model.test.ts` suite
  passes under `make notifications-tests`; the drift gate also pins the
  `speedtest.state` / `wallpaper.state` subscriptions. This is test-suite
  evidence, not a pre/post behavioural diff against the dotfiles copy.
- **Gates (run in this repo, 2026-10-19):** `make notifications-typecheck` →
  exit 0 (`OK: 0 errors in notifications`); `make gates-ci` → exit 0 (includes
  `notifications-tests` + `notifications-drift-test`).
- **CI:** `.github/workflows/notifications.yml` runs tests, drift,
  `speedtest-no-new-architecture` and the self-hosted typecheck.
