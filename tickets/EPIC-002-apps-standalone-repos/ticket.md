---
id: EPIC-002
title: "AGS apps as standalone repos with one palette-refresh contract"
kind: epic
status: in-progress
lane: bmad-advisory
links:
  openspec: none
  bmad: none
worktree: .worktrees/EPIC-002/
branch: ticket/EPIC-002-apps-standalone-repos
children: [REQ-008, REQ-009, REQ-010, REQ-011, REQ-012, REQ-013, REQ-014, REQ-015, REQ-016]
done-when: "Every in-scope AGS app is authored, released and pinned as its own repo; every app ships app.manifest.json; manifests and live handlers are adopted before the runtime switch; the runtime discovers manifests and keeps one applied-appearance ledger; live apps answer palette-refresh and restart apps are explicit; one program platform/contracts/assets tuple is deployed; dotfiles consumes one app list with one owner per app; ags-apps is archived at the end; btop never loses pending edits; docs, tests and deploy coverage match."
---

# AGS apps as standalone repos with one palette-refresh contract

## Triage (/triage)

- `kind: epic` — cross-repo migration program: seven app repos plus
  `contracts`, `ags-platform`, `dotfiles-runtime`, `dotfiles-v3`,
  `dotfiles-provision` and `dotfiles-assets` (icon-source tuple, launchers and
  launch lock).
- `lane: 4 — bmad-advisory` — the process contract, manifest/install-list
  schemas, runtime ledger, per-app install topology and cutover epoch are
  architectural decisions. The advisory output is the spine:
  `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md`.
- Not a spike: `SPIKE-001` answered the refresh-pattern question. This is the
  implementation program; the per-app split is conditional on the REQ-009
  pilot exit gate.
- Ambiguity resolved: command + manifest, JSON string ack, parallel live lane,
  serialized restart lane, one program platform/contracts tuple, no legacy
  path, one-owner cutover at the composition layer.
- Guard: `bash scripts/worktree-guard.sh check-clean` exited 0 before the
  EPIC-002 worktree was created.

## Goal

Move each AGS app into its own standalone repo, one at a time. Every app ships
one manifest and declares `live` or `restart`. The runtime discovers running
apps from their deployed manifests, gates on the applied-appearance ledger, and
invokes live apps or restarts the explicit restart app. Dotfiles consumes a
single per-app list with exactly one owner per app. `ags-apps` is archived after
the last app moves.

This is a strangler-fig migration. The current monorepo is re-pinned to the
program tuple, and every live app gets its manifest **and** `palette-refresh`
handler before the manifest-driven runtime is enabled. The runtime switch comes
next, then the per-app repo cutovers. The old `ags-apps` unit shrinks and is
archived; it is not kept as an empty meta repo.

The clipboard app is renamed end to end: `ags-clipboard` / `clipboard` /
`ags-clipboard` / `clipboard-window` / `clipboard-ui`, including its data paths
with a one-time migration from the old `hypr-pano` locations.

## Contract

The binding contract is the architecture spine (AD-25 through AD-37). At the
epic level:

- `app.manifest.json` is the app's declaration: identity, `mode: live|restart`,
  and `holdsUnsavedState`.
- The runtime is the only palette-refresh trigger. It invokes
  `ags request palette-refresh <appearance-hash> -i <instance>` for live apps and
  uses the safe serialized procedure for restart apps.
- Live refresh is parallel, state-preserving, JSON-string acknowledged, 5 s
  timeout, runtime-owned structured logs.
- One applied-appearance ledger and one operation lock prevent no-op refreshes,
  double triggers, and permanently skipped failures.
- One program `ags-platform`/`contracts`/`dotfiles-assets` tuple per install.
  App repos pin that tuple for CI; the deployed shared ancestor is single-valued.
  The current monorepo is re-pinned to it during adoption.
- `dotfiles-v3` owns one app list (`owner: legacy|standalone`). The old role
  filters `legacy`, the new role filters `standalone`; flipping one entry is the
  cutover transaction. Ownership covers source, links, launcher, autostart,
  processes and D-Bus names.
- Installed tags are immutable; writable state lives outside them; `colors.css`
  and `icons.json` have one producer each.

## Migration order

1. Contract, manifest/install-list schemas, repo template, runtime ledger, and
   cutover fixture.
2. Re-pin the current monorepo to the program tuple; adopt manifests and live
   `palette-refresh` handlers in the current deployment. The bar gets its
   manifest and remains `restart` with no handler; enable the manifest-driven
   runtime after adoption.
3. `ags-clipboard` — pilot and exit-gate proof: full rename + live refresh.
4. `btop-theme-studio` — pending-aware live refresh.
5. `capture-tool` — live refresh.
6. `notifications` — already live; packaging cutover.
7. `wallpaper-selector` — already live; packaging cutover.
8. `icme` — already live; packaging cutover.
9. `bar` — last; explicit `restart` app.
10. Final cutover: delete the old role/pin, archive `ags-apps`.

## Done-when

Expanded from the frontmatter:

- every in-scope app is authored, released and pinned in its own repo;
- every app ships a valid manifest; manifests and live handlers are adopted
  before the runtime switch; no legacy runtime path exists;
- the runtime discovers manifests and enforces identity; it has one
  applied-appearance ledger and one operation lock;
- live apps implement `palette-refresh`, preserve declared state, and ack with
  a JSON string; restart is explicit and only the bar uses it;
- one program platform/contracts/assets tuple is installed and every app repo
  passes conformance against it;
- `dotfiles-v3` has one app list with one owner per app; the old role only
  shrinks; the final state has no `ags-apps` pin;
- the clipboard rename is complete, including data migration;
- installed tags are immutable and user state survives a tag bump;
- `btop-theme-studio` never loses pending edits; no no-op reconcile refreshes
  or restarts anything;
- tests, typechecks, bundle checks, deploy coverage, template conformance and
  docs match the new topology.

## Children

- [ ] `REQ-008` — Standalone app contract, manifests, runtime ledger, repo template and cutover fixture (`in-progress`)
- [ ] `REQ-009` — Migrate `ags-clipboard` with full rename + live refresh (pilot) (`proposed`)
- [ ] `REQ-010` — Migrate `btop-theme-studio` with pending-aware live refresh (`proposed`)
- [ ] `REQ-011` — Migrate `capture-tool` with live refresh (`proposed`)
- [ ] `REQ-012` — Migrate `notifications` (already live) (`proposed`)
- [ ] `REQ-013` — Migrate `wallpaper-selector` (already live) (`proposed`)
- [ ] `REQ-014` — Migrate `icme` (already live) (`proposed`)
- [ ] `REQ-015` — Migrate `bar` last as the explicit restart app (`proposed`)
- [ ] `REQ-016` — Final dotfiles cutover + archive `ags-apps` (`proposed`)

## External dependencies

- `contracts` **REQ-009**: manifest/install-list/program-tuple/result schemas +
  `palette-refresh` protocol + `wallpaper.state` note.
- `ags-platform` **REQ-012** + **BUG-001**: manifest helper/types; Theme
  one-provider replacement (blocking before live refresh).
- `dotfiles-assets` **REQ-007**: clipboard autostart/keybind rename; shared
  launch-lock wrapper input; icon-source tuple.
- `dotfiles-runtime` **REQ-002** + **BUG-006**: manifest discovery/identity,
  applied-appearance ledger, operation lock, parallel live lane, serialized
  restart lane, logs, clipboard daemon rename/data migration, bar restart fix.
- `dotfiles-v3` OpenSpec **ags-apps-per-repo-consumption**: one app list, program
  tuple, deploy coverage, cutover gate.
- `dotfiles-provision` **REQ-008**: generic install loop, owner filters, verify,
  quiesce/stop/start link swap, launcher/autostart consumption, tag immutability,
  shared launch lock.
- New app repos: AGENTS/tickets/worktree guard/Makefile/CI/template
  conformance.

## Open decisions

- The REQ-009 pilot exit-gate result: if it fails, the program stops.
- Exact `ags-platform`/`contracts`/`dotfiles-assets` program tuple tags at
  REQ-008 release.
- `ags-apps` archive vs deletion at REQ-016.
- Bar live refresh is a future iteration; restart is the current explicit mode.
