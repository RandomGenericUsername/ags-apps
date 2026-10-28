# Ticket index

> Counting rule: completeness checks cover item files (`tickets/<id>-<slug>/ticket.md`) only.
> `tickets/_template/` (and any `tickets/_fixtures/`) are excluded from INDEX completeness counting.
> Entry format: link — title | `status` | execution links. Epics add `done/total children done`, done-when, and one nested line per child. Bugs add severity. Spikes add timebox state.

## Epics

- [EPIC-001-apps-thin-consumers/ticket.md](./EPIC-001-apps-thin-consumers/ticket.md) — AGS apps as thin consumers of the platform | `done` | links: none | 7/7 children done
  - done-when: ags-apps holds the bar plus the six apps, each depending only on ags-platform (never on each other), with per-app CI.
  - [REQ-001-bar-thin-consumer/ticket.md](./REQ-001-bar-thin-consumer/ticket.md) — Bar as a thin platform consumer + publish + CI | `done` | openspec: bar-thin-consumer
  - [REQ-002-migrate-notifications/ticket.md](./REQ-002-migrate-notifications/ticket.md) — Migrate notifications | `done` | openspec: migrate-notifications
  - [REQ-003-migrate-capture-tool/ticket.md](./REQ-003-migrate-capture-tool/ticket.md) — Migrate capture-tool | `done` | openspec: migrate-capture-tool
  - [REQ-004-migrate-hypr-pano/ticket.md](./REQ-004-migrate-hypr-pano/ticket.md) — Migrate hypr-pano | `done` | openspec: migrate-hypr-pano
  - [REQ-005-migrate-wallpaper-selector/ticket.md](./REQ-005-migrate-wallpaper-selector/ticket.md) — Migrate wallpaper-selector | `done` | openspec: migrate-wallpaper-selector
  - [REQ-006-migrate-icme/ticket.md](./REQ-006-migrate-icme/ticket.md) — Migrate icme | `done` | openspec: migrate-icme
  - [REQ-007-migrate-btop-theme-studio/ticket.md](./REQ-007-migrate-btop-theme-studio/ticket.md) — Migrate btop-theme-studio | `done` | links: none
- [EPIC-002-apps-standalone-repos/ticket.md](./EPIC-002-apps-standalone-repos/ticket.md) — AGS apps as standalone repos with one palette-refresh contract | `done` | links: none | 9/9 children done
  - done-when: every in-scope app is authored, released and pinned as its own repo; every app ships app.manifest.json; manifests and live handlers are adopted before the runtime switch; the runtime discovers manifests and keeps one applied-appearance ledger; live apps answer palette-refresh and restart apps are explicit; one program platform/contracts/assets tuple is deployed; dotfiles consumes one app list with one owner per app; ags-apps is archived at the end; btop never loses pending edits; docs, tests and deploy coverage match.
  - [REQ-008-standalone-app-contract/ticket.md](./REQ-008-standalone-app-contract/ticket.md) — Standalone app contract, manifests, runtime ledger, repo template and cutover fixture | `done`
  - [REQ-009-migrate-clipboard-standalone/ticket.md](./REQ-009-migrate-clipboard-standalone/ticket.md) — Migrate the clipboard app to ags-clipboard with full rename + live refresh (pilot) | `done`
  - [REQ-010-migrate-btop-theme-studio-standalone/ticket.md](./REQ-010-migrate-btop-theme-studio-standalone/ticket.md) — Migrate btop-theme-studio to ags-btop-theme-studio with pending-aware live refresh | `done`
  - [REQ-011-migrate-capture-tool-standalone/ticket.md](./REQ-011-migrate-capture-tool-standalone/ticket.md) — Migrate capture-tool to ags-capture-tool with live refresh | `done`
  - [REQ-012-migrate-notifications-standalone/ticket.md](./REQ-012-migrate-notifications-standalone/ticket.md) — Migrate notifications to ags-notifications (already live) | `done`
  - [REQ-013-migrate-wallpaper-selector-standalone/ticket.md](./REQ-013-migrate-wallpaper-selector-standalone/ticket.md) — Migrate wallpaper-selector to ags-wallpaper-selector (already live) | `done`
  - [REQ-014-migrate-icme-standalone/ticket.md](./REQ-014-migrate-icme-standalone/ticket.md) — Migrate icme to ags-icme (already live) | `done`
  - [REQ-015-migrate-bar-standalone/ticket.md](./REQ-015-migrate-bar-standalone/ticket.md) — Migrate bar to ags-bar, last, as the explicit restart app | `done`
  - [REQ-016-final-consumption-cutover/ticket.md](./REQ-016-final-consumption-cutover/ticket.md) — Final dotfiles consumption cutover + archive ags-apps | `done`

## Requirements

(none)

## Bugs

- [BUG-001-wallpicker-grayscale-thumbs/ticket.md](./BUG-001-wallpicker-grayscale-thumbs/ticket.md) — grayscale thumbnails for PNG wallpapers (RGBA — gdk-pixbuf JPEG saver bug) | severity: high | `done` | links: worktree .worktrees/BUG-001, branch ticket/BUG-001-grayscale-thumbs
- [BUG-002-selector-collapse-on-apply/ticket.md](./BUG-002-selector-collapse-on-apply/ticket.md) — Apply click must collapse the wallpaper selector immediately | severity: medium | `done` | links: worktree .worktrees/BUG-002/, branch ticket/BUG-002-selector-collapse-on-apply

## Ops tasks

(none)

## Spikes

- [SPIKE-001-ags-refresh-patterns/ticket.md](./SPIKE-001-ags-refresh-patterns/ticket.md) — AGS refresh patterns: why some apps live-refresh while others restart (incl. btop-theme-studio) | `reported` | links: worktree .worktrees/SPIKE-001/, branch ticket/SPIKE-001-ags-refresh-patterns | reported

## Tasks

(none)

## Done (links only, newest last)

(none)
