---
id: EPIC-002
title: "AGS apps as standalone repos with one palette-refresh contract"
kind: epic
status: proposed
lane: bmad-advisory
links:
  openspec: none
  bmad: none
worktree: .worktrees/EPIC-002/
branch: ticket/EPIC-002-apps-standalone-repos
children: [REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-013, REQ-014, REQ-015, REQ-016]
done-when: "Every migrated AGS app is authored, released and pinned as its own repo; each app declares its refresh mode in one manifest and implements the palette-refresh command when live; dotfiles consumes each app individually; no undeclared restart remains; btop never loses pending edits; docs, tests and deploy coverage match the new topology."
---

# AGS apps as standalone repos with one palette-refresh contract

## Triage (/triage)

- `kind: epic` — this is a cross-repo migration program, not one bounded feature
  or bug. It touches new app repos, `ags-platform`, `dotfiles-runtime`,
  `dotfiles-v3`/`dotfiles-provision` and the per-app cutovers.
- `lane: 4 — bmad-advisory` — the process boundary, manifest/command response,
  fallback rules, repo template, versioning and cutover mechanics are
  architectural decisions that must be designed before app-by-app
  implementation.
- Not a spike: the investigation is complete
  (`tickets/SPIKE-001-ags-refresh-patterns/ticket.md`); this is a program of
  work, not more questions.
- Not lane 3: the pieces are not all fully understood yet. The contract,
  provisioning cutover, and `ags-apps` disposition need advisory design.
- Ambiguity: command response/ack and timeout, whether restart remains an
  explicit manifest mode, how each app repo pins `ags-platform`/`contracts`,
  what `ags-apps` becomes when the apps leave, and whether the bar is migrated
  or kept as the long-lived exception.
- Guard: `bash scripts/worktree-guard.sh check-clean` exited 0 before this
  worktree was created.

## Goal

Move each AGS app into its own standalone repo, one at a time. Each app
implements one palette-refresh contract. Dotfiles consumes each migrated app
through its own pinned repo. The old `ags-apps` unit stops deploying the
migrated app.

The deployed config directory and AGS instance name stay identical during a
cutover, so keybinds, logs, runtime discovery and user configuration do not
change.

This is a strangler-fig migration: the old app remains consumed until its new
repo is tagged, pinned and verified. The cutover commit removes the old owner
and adds the new one; there must never be two deployments of the same app.

## Contract

Each app ships a small manifest declaring:

- instance name;
- deployed config directory;
- refresh mode: `live` or `restart`;
- command name, normally `palette-refresh` (required for `live`);
- whether it holds unsaved state;
- whether it has a transient user-facing obligation that forbids restart.

Each live app implements the command in its `requestHandler`. The runtime
discovers running apps, reads the manifest, and either invokes the command or
restarts. No manifest means legacy restart. An app declaring unsaved state or a
transient obligation is never restarted; a failed refresh is reported instead.

`restart` is allowed only as an explicit, change-gated fallback. It is not the
default once an app has a manifest. The long-term direction is live refresh for
every app that can prove its invalidation path.

## Migration order

1. Contract, manifest schema, repo template and cutover recipe.
2. `hypr-pano` — pilot: prove the repo split + command contract with low
   unsaved-state risk.
3. `btop-theme-studio` — the data-loss case; pending-edit semantics.
4. `capture-tool` — choose live icon/window refresh or an explicit, deferred
   restart; no unconditional restart.
5. `notifications` — already live; packaging cutover.
6. `wallpaper-selector` — already live; packaging cutover.
7. `icme` — already live; packaging cutover.
8. `bar` — last; session-critical; live-vs-restart decision at that child.
9. Final consumption cutover and `ags-apps` disposition.

## Done-when

Expanded from the frontmatter:

- every in-scope app is authored in its own repo, tagged, and consumed by
  dotfiles through an individual pin;
- every app ships the manifest and declares `live` or `restart`; every `live`
  app implements `palette-refresh`;
- the runtime no longer hardcodes the app list for refresh policy; it reads the
  deployed manifest and honors `unsaved`/`transient` no-restart rules;
- the old `ags-apps` unit no longer deploys any migrated app, and there is no
  duplicate config dir or duplicate AGS instance;
- `btop-theme-studio` never loses pending edits on a wallpaper change;
- no app is restarted on a no-op reconcile, and no app with unsaved or
  transient state is restarted;
- tests, typechecks, bundle checks, deploy coverage and docs match the new
  topology;
- the `ags-apps` disposition (coordination/meta repo or archive) is recorded.

## Children

- [ ] `REQ-008` — Standalone app contract, manifest schema, repo template and cutover recipe (`proposed`)
- [ ] `REQ-009` — Migrate `hypr-pano` to a standalone repo + live refresh (`proposed`)
- [ ] `REQ-010` — Migrate `btop-theme-studio` to a standalone repo + pending-aware live refresh (`proposed`)
- [ ] `REQ-011` — Migrate `capture-tool` to a standalone repo + safe refresh policy (`proposed`)
- [ ] `REQ-012` — Migrate `notifications` to a standalone repo (already live) (`proposed`)
- [ ] `REQ-013` — Migrate `wallpaper-selector` to a standalone repo (already live) (`proposed`)
- [ ] `REQ-014` — Migrate `icme` to a standalone repo (already live) (`proposed`)
- [ ] `REQ-015` — Migrate `bar` to a standalone repo, last (`proposed`)
- [ ] `REQ-016` — Final dotfiles consumption cutover + `ags-apps` disposition (`proposed`)

## External dependencies

- `dotfiles-runtime`: immediate btop skip-list safety bug.
- `dotfiles-runtime`: manifest discovery + `palette-refresh` invocation and
  fallback.
- `ags-platform`: one-provider palette replacement contract; required before
  new live consumers.
- `dotfiles-v3` / `dotfiles-provision`: per-app pins and roles, no duplicate
  deployment during cutover.
- New app repos: AGENTS, ticket flow, CI, typecheck, release and pin docs.

## Open decisions

- Command + manifest vs event broadcast. The user selected command + manifest;
  the child contract must define the response, timeout and fallback.
- Whether `restart` remains a permanent manifest mode or is only a migration
  fallback.
- Versioning: each app repo pins `ags-platform`/`contracts` independently.
- What remains of `ags-apps`: coordination/meta repo, or archive.
- Whether the bar is migrated or kept in `ags-apps` after the program.
