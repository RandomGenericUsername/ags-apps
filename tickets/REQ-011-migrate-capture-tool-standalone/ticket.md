---
id: REQ-011
title: "Migrate capture-tool to a standalone repo with a safe palette-refresh policy"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate capture-tool to a standalone repo with a safe palette-refresh policy

## Requirement

Move `capture-tool` into its own standalone repo and put it on the manifest +
palette-refresh contract. Keep the deployed config directory `ags-capture` and
the AGS instance name `capture` unchanged.

This child must choose and prove the least-risk refresh policy:

- **live**, by reloading the generated icons and updating or rebuilding the
  per-monitor windows in place; or
- **explicit restart**, declared in the manifest, change-gated to a real palette
  change and deferred while the capture/settings surface is open.

It must not be restarted unconditionally, and it must not be restarted while a
capture or settings interaction is in flight. Settings and UI state are
persisted, so the no-restart rule is about not disrupting the interaction, not
about recovering unsaved documents.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, tests and a
      release/pin note.
- [ ] Deployed config dir is still `ags-capture`; instance name is still
      `capture`.
- [ ] Manifest declares the chosen refresh mode and the transient-obligation
      flag; `live` implements `palette-refresh`.
- [ ] If live: icons/windows refresh without a process restart and without
      losing the open surface.
- [ ] If restart: only on a real palette change, only when idle, with a
      confirmed quit; a no-op reconcile never restarts capture.
- [ ] A fake runtime test covers the chosen path and the no-restart rule.
- [ ] Dotfiles cutover pins the new repo, removes the app from the old
      `ags-apps` unit, bumps the old unit tag, and passes deploy coverage with
      no duplicate config dir.
- [ ] Old in-tree source is deleted; docs record the new pin and policy.

## Dependencies

- `REQ-008` contract and template.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement if the live path re-applies the Theme
  port.

## Evidence

- `capture-tool/app.tsx` startup theme and window set.
- `capture-tool/ui/shared/icons.ts` generated icons built into widgets.
- `capture-tool/ui/classic/SettingsPage.tsx` immediate settings persistence.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` capture row.
