---
id: REQ-008
title: "Standalone app contract, manifest schema, repo template and cutover recipe"
kind: requirement
status: proposed
lane: 4
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Standalone app contract, manifest schema, repo template and cutover recipe

## Requirement

Define the one process-level contract that lets each AGS app live in its own
repo, plus the template and cutover recipe used by every app child.

The contract must cover:

- a deployed app manifest with instance name, config directory, refresh mode
  (`live`/`restart`), command name, unsaved-state flag and transient-obligation
  flag;
- a `palette-refresh` command implemented by live apps in their
  `requestHandler`, with a defined response, timeout, failure and idempotency
  semantics;
- runtime discovery and invocation: no manifest means legacy restart; `live`
  invokes the command; `restart` is explicit and change-gated; unsaved or
  transient apps are never restarted;
- the app repo template: `AGENTS.md`, ticket flow, CI, typecheck, release tag,
  pin documentation and app-directory layout;
- the per-app cutover recipe: same config dir and instance name, add the new
  pin/role, remove the app from the old `ags-apps` unit, bump the old unit tag,
  deploy-coverage check, no duplicate deployment;
- the versioning rule for `ags-platform` and `contracts` consumed by each app
  repo.

This child is design + prototype. It does not migrate an app.

## Acceptance

- [ ] Manifest schema is written in the canonical contract location and is
      validated by the runtime and by an app-side helper.
- [ ] The `palette-refresh` command protocol is specified: argv shape, response
      format, timeout, error reporting, idempotency and the no-op case.
- [ ] Runtime behavior is specified and prototyped: manifest discovery, `live`
      invocation, explicit `restart`, no-manifest legacy, and the no-restart
      rule for unsaved/transient apps.
- [ ] The app repo template exists (or is fully specified) with AGENTS, tickets,
      CI, typecheck, release and pin docs.
- [ ] The cutover recipe is written and tested on a fake app: same config dir
      and instance, one owner at a time, old unit pin bumped, no duplicate
      deployment.
- [ ] The `ags-platform`/`contracts` versioning and pin policy is recorded.
- [ ] A GUI-free prototype proves the command round-trip and a failure path
      without driving the GUI.
- [ ] The design records whether `restart` remains a permanent manifest mode or
      is only a migration fallback.

## Dependencies

- `SPIKE-001` refresh-pattern findings.
- User decisions: command + manifest, pano pilot, bar last.
- External: `dotfiles-runtime` manifest/invocation support; `ags-platform`
  provider replacement; `dotfiles-v3`/`dotfiles-provision` cutover mechanics.

## Evidence

- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` (refresh matrix and
  contract recommendation).
- `dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md` (current documented
  split).
- Existing live handlers: notifications, wallpaper-selector, icme.
