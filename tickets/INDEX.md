# Ticket index

> Counting rule: completeness checks cover item files (`tickets/<id>-<slug>/ticket.md`) only.
> `tickets/_template/` (and any `tickets/_fixtures/`) are excluded from INDEX completeness counting.
> Entry format: link — title | `status` | execution links. Epics add `done/total children done`, done-when, and one nested line per child. Bugs add severity. Spikes add timebox state.

## Active epics

- [EPIC-001-apps-thin-consumers/ticket.md](./EPIC-001-apps-thin-consumers/ticket.md) — AGS apps as thin consumers of the platform | `proposed` | links: none | 0/7 children done
  - done-when: ags-apps holds the bar plus the six apps, each depending only on ags-platform (never on each other), with per-app CI.
  - [REQ-001-bar-thin-consumer/ticket.md](./REQ-001-bar-thin-consumer/ticket.md) — Bar as a thin platform consumer + publish + CI | `proposed` | openspec: bar-thin-consumer
  - [REQ-002-migrate-notifications/ticket.md](./REQ-002-migrate-notifications/ticket.md) — Migrate notifications | `proposed` | openspec: migrate-notifications
  - [REQ-003-migrate-capture-tool/ticket.md](./REQ-003-migrate-capture-tool/ticket.md) — Migrate capture-tool | `proposed` | openspec: migrate-capture-tool
  - [REQ-004-migrate-hypr-pano/ticket.md](./REQ-004-migrate-hypr-pano/ticket.md) — Migrate hypr-pano | `proposed` | openspec: migrate-hypr-pano
  - [REQ-005-migrate-wallpaper-selector/ticket.md](./REQ-005-migrate-wallpaper-selector/ticket.md) — Migrate wallpaper-selector | `proposed` | openspec: migrate-wallpaper-selector
  - [REQ-006-migrate-icme/ticket.md](./REQ-006-migrate-icme/ticket.md) — Migrate icme | `proposed` | openspec: migrate-icme
  - [REQ-007-migrate-btop-theme-studio/ticket.md](./REQ-007-migrate-btop-theme-studio/ticket.md) — Migrate btop-theme-studio | `in-progress` | links: none

## Requirements

(none)

## Bugs

(none)

## Ops tasks

(none)

## Spikes

(none)

## Tasks

(none)

## Done (links only, newest last)

(none)
