---
id: REQ-015
title: "Migrate bar to ags-bar, last, as the explicit restart app"
kind: requirement
status: proposed
lane: 4
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate bar to ags-bar, last, as the explicit restart app

## Requirement

Move the AGS bar into `ags-bar`, last. Preserve the special deployment shape:
`config/ags` -> the `ags-bar` checkout, default AGS instance `ags`. The manifest
declares `app: bar`, `instance: ags`, `configDir: ags`, `mode: restart`,
`holdsUnsavedState: false`.

Restart is the explicit mode, not a fallback. It uses the safe serialized
procedure (confirmed quit, no concurrent `ags run`, no exit-0 misclassification)
and only runs when the applied-appearance ledger says the appearance changed or
a previous restart failed. Moving the bar to live is a future iteration, not
this child.

Before the bar cutover:

- add `config/ags/app.manifest.json` in the current deployment (AD-36);
- move `wifi-speedtest*.json` and any other writable state out of the tag into
  XDG config/state (AD-37);
- make `colors.css` a stable runtime pointer outside the tag; make `icons.json`
  a single-producer artifact verified by provisioning, never written by it;
- land the runtime restart fix (BUG-003) so the restart lane is safe;
- use the shared AGS launch lock in the restart lane, autostart and every
  on-demand launcher.

## Acceptance

- [ ] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [ ] Deployment still links `config/ags` to the bar checkout and uses instance
      `ags`.
- [ ] Manifest identity is `bar` / `ags` / `ags`, `mode: restart`, no unsaved
      state.
- [ ] Restart uses the safe serialized procedure; the configured bar is included
      even when down, so a failed restart is recoverable; no no-op restart; a
      failed restart is recorded and retried by the ledger on the next trigger.
- [ ] The bar manifest is adopted before the runtime switch; the current
      deployment is not left without a manifest.
- [ ] `wifi-speedtest*.json` and other writable state live outside the immutable
      tag and survive a tag bump; `colors.css` points to a stable runtime pointer
      outside the tag; `icons.json` has one producer and provisioning only
      verifies it.
- [ ] Every `ags run` path (restart, autostart, on-demand launcher) holds the
      shared launch lock.
- [ ] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints `config/ags`, starts the new instance and
      verifies one owner.
- [ ] Old source is removed from `ags-apps`; docs record the new pin and the
      restart rationale.

## Dependencies

- `REQ-008` contract, ledger, template and cutover fixture.
- `ags-platform` manifest helper (Theme provider fix not required for restart,
  but the app still routes theming through the port).
- `dotfiles-runtime` safe restart (BUG-003), manifest discovery, ledger.
- `dotfiles-v3`/`dotfiles-provision` app list, stop/start, tag immutability.
- `dotfiles-assets` bar autostart/link updates if any.

## Evidence

- `bar/app.tsx` startup theme and widget construction.
- `bar/kit/widget.tsx` icon loading.
- `bar/services/speedtest-service.ts` in-tag writable state.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` bar row.
