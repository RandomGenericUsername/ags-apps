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

## Requirements

(none)

## Bugs

- [BUG-001-wallpicker-grayscale-thumbs/ticket.md](./BUG-001-wallpicker-grayscale-thumbs/ticket.md) — grayscale thumbnails for PNG wallpapers (RGBA — gdk-pixbuf JPEG saver bug) | severity: high | `done` | links: worktree .worktrees/BUG-001, branch ticket/BUG-001-grayscale-thumbs
- [BUG-002-selector-collapse-on-apply/ticket.md](./BUG-002-selector-collapse-on-apply/ticket.md) — Apply click must collapse the wallpaper selector immediately | severity: medium | `done` | links: worktree .worktrees/BUG-002/, branch ticket/BUG-002-selector-collapse-on-apply

## Ops tasks

(none)

## Spikes

- [SPIKE-001-ags-refresh-patterns/ticket.md](./SPIKE-001-ags-refresh-patterns/ticket.md) — AGS refresh patterns: why some apps live-refresh while others restart (incl. btop-theme-studio) | `boxed` | links: worktree .worktrees/SPIKE-001/, branch ticket/SPIKE-001-ags-refresh-patterns | boxed 2 days

## Tasks

(none)

## Done (links only, newest last)

(none)
