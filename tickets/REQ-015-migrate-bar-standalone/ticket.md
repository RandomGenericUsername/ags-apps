---
id: REQ-015
title: "Migrate bar to ags-bar, last, as the explicit restart app"
kind: requirement
status: done
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

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Deployment still links `config/ags` to the bar checkout and uses instance
      `ags`.
- [x] Manifest identity is `bar` / `ags` / `ags`, `mode: restart`, no unsaved
      state.
- [x] Restart uses the safe serialized procedure; the configured bar is included
      even when down, so a failed restart is recoverable; no no-op restart; a
      failed restart is recorded and retried by the ledger on the next trigger.
- [x] The bar manifest is adopted before the runtime switch; the current
      deployment is not left without a manifest.
- [x] `wifi-speedtest*.json` and other writable state live outside the immutable
      tag and survive a tag bump; `colors.css` points to a stable runtime pointer
      outside the tag; `icons.json` has one producer and provisioning only
      verifies it.
- [x] Every `ags run` path (restart, autostart, on-demand launcher) holds the
      shared launch lock.
- [x] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints `config/ags`, starts the new instance and
      verifies one owner.
- [x] Old source is removed from `ags-apps`; docs record the new pin and the
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

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-bar` `v0.1.3` (annotated); manifest `bar` / `ags` / `ags` /
  `restart` / `holdsUnsavedState: false`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` — `installDir: bar`,
  `owner: standalone`, `barPalettePointer: true`, autostart `ags`,
  `launch: always`, `cutoverId: REQ-015`; `config/ags` still links the bar
  checkout and the instance stays `ags`.
- **Writable state/pointer:** `wifi-speedtest*.json` lives in
  `~/.local/state/ags/` outside the tag; `colors.css` is the runtime-owned
  pointer (`barPalettePointer` verified by the engine); `icons.json` has one
  producer.
- **Restart lane:** serialized/safe restart with the shared launch lock; the
  changed-appearance run restarted the bar (`exit 0`, PID `2184833→2260506`)
  while the no-op run restarted nothing (v3 tasks 4.2).
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no host `ags-apps`;
  `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-bar describe --tags --exact-match` → `v0.1.3`;
`cd dotfiles-v3 && make deploy-coverage`.
