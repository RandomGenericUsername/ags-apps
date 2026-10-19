---
id: REQ-004
title: "Migrate hypr-pano"
kind: requirement
status: done
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

- [x] `lib/event-bus*.ts` + `lib/icon-registry.ts` are gone; the platform is used.
- [x] `speedtest.finished` appears nowhere in the app (grep → none).
- [x] The drift test is repointed to the shared client.

## Closing evidence (v0.3.8 roll-up)

- **Merged:** `869068e merge ticket/pano3b-migrate: hypr-pano thin consumer
  (REQ-004)`. Tag `v0.2.0`.
- **Consumed by dotfiles-v3:** `9f7a0dfb pin ags-apps unit to v0.2.0 (monorepo
  release: bar + hypr-pano)` and `ffb6e142 merge
  ticket/panoconsume-hypr-pano-unit: consume hypr-pano from the ags-apps unit
  (v0.2.0)`; `f5cf4037 retire the per-file hypr-pano deploy; delete the in-repo
  source`.
- **Copies gone / platform used:** `find hypr-pano -name 'event-bus*' -o -name
  'icon-registry.ts'` → no matches. `hypr-pano/app.tsx` imports
  `ags-platform/adapters/theme`; `ui/ItemCard.tsx` imports `adapters/icon`;
  `ui/PanoWindow.tsx` imports `adapters/event-bus`.
- **Dead topic gone:** `grep -rn 'speedtest.finished' hypr-pano` → no matches.
- **Drift repointed:** `hypr-pano/tests/event-contract-drift.mjs:19` imports
  `ags-platform/ports/event-client`.
- **Gates (run in this repo, 2026-10-19):** `make hypr-pano-typecheck` → exit 0
  (`OK: 0 errors in hypr-pano`); `make gates-ci` → exit 0 (includes
  `hypr-pano-drift-test`).
- **CI:** `.github/workflows/hypr-pano.yml` runs the drift gate and the
  self-hosted typecheck.
