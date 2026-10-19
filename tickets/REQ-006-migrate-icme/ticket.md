---
id: REQ-006
title: "Migrate icme"
kind: requirement
status: done
lane: 2
links:
  openspec: migrate-icme
  bmad: none
worktree: none
branch: none
---

# Migrate icme

## Requirement

`icon-color-mapping-editor` depends on the platform: its `event-bus-core.ts`/`event-bus.ts`/`event-contract.ts` copies are replaced by the one event client and the generated bindings, and its `theme.ts` by the `Theme` port. It remains a publisher of `icme.saved`.

Source: spine **AD-5**, **AD-6**, **AD-13**; handoff iteration 6.

## Acceptance

- [x] `lib/event-bus*.ts` + `lib/event-contract.ts` + `lib/theme.ts` are gone; the platform/generated bindings are used.
- [x] `icme.saved` publishing uses the generated binding.
- [x] The drift test is repointed.

## Closing evidence (v0.3.8 roll-up)

- **Merged:** `01866d5 merge ticket/icme7-migrate: icme thin consumer
  (REQ-006)`. Tag `v0.3.7`.
- **Consumed by dotfiles-v3:** `8ec816f6 feat(ags_apps): consume icme from the
  unit + bump pin to v0.3.7`.
- **Copies gone / platform used:** `find icme -name 'event-bus*' -o -name
  'event-contract.ts' -o -name 'theme.ts'` → no matches.
  `icme/ui/EditorWindow.tsx` imports
  `ags-platform/adapters/{event-bus,theme}`;
  `icme/lib/icme-saved{,-gio}.ts` import `ags-platform/ports/event-client`.
- **Generated binding:** `icme/lib/generated/contract.ts` is vendored;
  `icme/lib/icme-saved.ts:18` declares `ICME_SAVED_TOPIC = "icme.saved"
  satisfies keyof typeof EVENTS_TOPICS`, and the publisher uses the generated
  `{ path }` payload type. `icme/tests/event-contract-drift.mjs:95-109` pins
  the generated topic/payload.
- **Drift repointed:** `icme/tests/event-contract-drift.mjs:22` imports
  `ags-platform/ports/event-client`.
- **Gates (run in this repo, 2026-10-19):** `make icme-typecheck` → exit 0
  (`OK: 0 errors in icme`); `make gates-ci` → exit 0 (includes `icme-tests` +
  `icme-drift-test`).
- **CI:** `.github/workflows/icme.yml` runs the pure tests, the drift gate and
  the self-hosted typecheck.
