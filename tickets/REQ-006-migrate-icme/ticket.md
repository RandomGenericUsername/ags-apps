---
id: REQ-006
title: "Migrate icme"
kind: requirement
status: proposed
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

- [ ] `lib/event-bus*.ts` + `lib/event-contract.ts` + `lib/theme.ts` are gone; the platform/generated bindings are used.
- [ ] `icme.saved` publishing uses the generated binding.
- [ ] The drift test is repointed.
