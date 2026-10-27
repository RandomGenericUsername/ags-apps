---
id: REQ-008
title: "Standalone app contract, manifests, runtime ledger, repo template and cutover fixture"
kind: requirement
status: in-progress
lane: 4
links:
  openspec: none
  bmad: _bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md
worktree: .worktrees/REQ-008/
branch: ticket/REQ-008-standalone-app-contract
---

# Standalone app contract, manifests, runtime ledger, repo template and cutover fixture

## Requirement

Turn the REQ-008 architecture spine into the executable contract shared by every
app repo and every consumer repo. The spine is binding; this ticket delivers the
schemas, fixtures and prerequisites that let the app-by-app cutovers begin.

Deliver:

- `contracts`: `app.manifest.json` schema, the `dotfiles-v3` app-list schema,
  the `palette-refresh` request/JSON-string response protocol, and the runtime
  result/log schema. Update the `wallpaper.state` contract note so it no longer
  claims to drive live palette refresh.
- `ags-platform`: TypeScript manifest helper/types and the one-provider Theme
  replacement helper. The Theme replacement is a hard prerequisite for live
  refresh.
- `dotfiles-runtime`: manifest discovery and identity validation
  (`instance == app.tsx == ags list`, `configDir == link basename`), the
  applied-appearance ledger, the runtime operation lock, parallel live lane,
  serialized restart lane, structured logs, and the clipboard daemon data-path
  migration.
- `dotfiles-v3` / `dotfiles-provision`: the single app list schema/fixture, the
  `owner: legacy|standalone` filter in the old/new roles, the generic install
  loop, the stop/repoint/start link-swap sequence, and a fake-app cutover
  fixture that proves exactly one owner and both rollback directions.
- App repo template: AGENTS, tickets/LIFECYCLE/INDEX/_template, worktree guard,
  Makefile, CI, README, manifest, handler and a template-conformance gate. The
  pilot repo (`ags-clipboard`) is the reference.
- Manifest adoption: add `app.manifest.json` to the currently deployed apps,
  including the bar, before the runtime switch. The runtime switch is a
  separate release after adoption.

This child does not migrate an app repo.

## Acceptance

- [x] The architecture spine is final and linked (`bmad:` above); its AD-25…AD-37
      are the contract.
- [ ] `contracts` carries the manifest schema, app-list schema,
      `palette-refresh` request/response protocol, runtime result/log schema,
      and the corrected `wallpaper.state` description.
- [ ] `ags-platform` carries the manifest helper/types and the one-provider
      Theme replacement; the provider fix is proven before live refresh.
- [ ] The runtime discovery/identity rule is implemented and tested:
      every deployed link is enumerated, invalid/missing manifests are
      structured failures, foreign/dev name owners are conflicts, no
      wrong-instance refresh, configured restart apps are included when down.
- [ ] The applied-appearance ledger (`applied|deferred|failed|skipped`), operation
      lock, parallel live lane, serialized restart lane, shared launch lock and
      structured logs are implemented and tested.
- [ ] Live response handling covers applied, deferred and retryable failure; the
      ledger retries deferred/failed apps on the next trigger.
- [ ] The clipboard daemon config/state/cache paths have a one-time migration
      from the old `hypr-pano` paths.
- [ ] The program tuple is released and pinned in `program-tuple.yaml`:
      `ags-platform`, `contracts` and `dotfiles-assets`; the record is validated
      by a schema in `contracts` and consumed by the installer. Every app repo and
      the current monorepo use it. The current monorepo is re-pinned and released
      during adoption and keeps its per-unit platform shortcut to the same tuple
      until removal.
- [x] Every currently deployed live app has adopted its manifest **and**
      `palette-refresh` handler before the runtime switch; the bar has its
      manifest and remains `restart` with no handler.
      Adopted in the monorepo `v0.5.0` release: all seven app directories carry
      `app.manifest.json`; notifications, capture-tool, hypr-pano,
      wallpaper-selector, icme and btop-theme-studio answer `palette-refresh`
      through `createPaletteRefreshHandler`; the bar has no palette handler.
- [ ] `dotfiles-v3` has one app list with a schema, `owner`, `installDir`,
      identity, spine/XDG/bin links, launcher, autostart, launch policy and
      palette metadata; `dotfiles-provision` has the generic loop, owner filters,
      verify mirror, quiesce/stop/start and tag immutability.
- [ ] A fake-app cutover fixture proves quiesce → owner flip → install/start →
      verify, rollback, and no duplicate/missing ownership surface.
- [ ] The template fixture (`templates/ags-app/`), template-conformance gate and
      pilot exit-gate thresholds are defined; the pilot (`ags-clipboard`) uses
      the fixture.
- [ ] No production app repo is cut over by this child.

## Monorepo adoption release (`v0.5.0`)

The adoption half of this ticket (spine AD-26/AD-27/AD-36) is delivered in the
current monorepo, before any app repo cutover:

- Manifests: `bar` (`ags`/`ags`, `restart`), `notifications`
  (`notifications`/`ags-notifications`), `capture-tool` (`capture`/`ags-capture`),
  `hypr-pano` (`hypr-pano`/`ags-hypr-pano`), `wallpaper-selector`
  (`wallpaper-selector`/`ags-wallpaper-selector`), `icme`
  (`icon-color-mapping-editor`/`ags-icme`, `holdsUnsavedState: true`) and
  `btop-theme-studio` (`btop-theme-studio`/`ags-btop-studio`,
  `holdsUnsavedState: true`).
- Handlers: every live app uses `createPaletteRefreshHandler`; hypr-pano composes
  the fixed command with its existing show/hide/toggle handler, capture-tool gains
  its first handler, and the bar stays handler-free for palette.
- `wallpaper.state` is progress/status only: notifications and wallpaper-selector
  no longer apply the palette there; icme drops the subscription. The runtime
  command is the only palette trigger.
- Live refresh preserves declared state: btop/icme pending edits, clipboard
  overlay, selector drawer, notifications card/bus and capture's active surface.
- Platform/contracts are re-pinned to the local-only `v0.3.0` tuple
  (`AGS_PLATFORM_VERSION`, `CONTRACTS_VERSION`; CI contract checkouts name the
  tag). `.dev/ags-platform/v0.3.0` is a gitignored local checkout/symlink.
- `make app-contract-test` adds manifest/handler/protocol conformance.
- Released as annotated tag `v0.5.0` on `main`; the tag is local-only (not pushed
  or published) in this run.
- `hypr-pano` is not renamed and no app moved to a standalone repo (REQ-009
  pilot owns those).

## Dependencies

- `SPIKE-001` refresh-pattern findings.
- User decisions recorded in the spine/memlog: command + manifest, JSON string
  ack, parallel live lane, serialized restart lane, one program tuple, no
  legacy path, clipboard full rename, capture live, bar restart last.
- External: `contracts`, `ags-platform`, `dotfiles-runtime`,
  `dotfiles-v3`, `dotfiles-provision`, `dotfiles-assets`.

## Architecture phase evidence

- Spine: `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md`
  (`status: final`).
- Memlog: `.memlog.md` (all coaching decisions, supersessions and reviewer fixes).
- Mechanical lint: `uv run .agents/skills/bmad-architecture/scripts/lint_spine.py --workspace ...` → `ok: true`, `0` findings.
- Reviewer gate: rubric, evidence and adversarial passes in `reviews/`; final
  adversarial re-review `review-adversarial-r4.md` → **PASS**, no new critical/high.
- The EPIC-002/REQ-009…REQ-016 tickets are aligned to `mode`, manifest adoption,
  clipboard rename, the applied-appearance ledger, the program tuple and the
  one-owner cutover epoch.

## Workstream tickets

- `contracts` **REQ-009** — manifest/install-list/program-tuple/result schemas +
  `palette-refresh` protocol.
- `ags-platform` **REQ-012** + **BUG-001** — manifest helper/types + Theme
  one-provider fix.
- `dotfiles-runtime` **REQ-002** + **BUG-006** — manifest driver/ledger/lanes +
  restart liveness.
- `dotfiles-v3` OpenSpec **ags-apps-per-repo-consumption** — app list, program
  tuple, deploy coverage, cutover epoch.
- `dotfiles-provision` **REQ-008** — generic install topology + verify.
- `dotfiles-assets` **REQ-007** — clipboard launch/autostart rename.
- `ags-apps` **REQ-009…REQ-016** — app extraction children and pilot.

## Evidence

- `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md`
- `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/.memlog.md`
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md`
- Reviewer gate: `reviews/review-{rubric,evidence,adversarial,adversarial-r2,adversarial-r3,adversarial-r4}.md`
- Adoption gate: `make app-contract-test` → 17/17 pass (manifest identities,
  live-handler adoption, bar restart/no-handler, `wallpaper.state` separation,
  state-preservation source checks, JSON-string protocol).
- Stock-runner gate: `make gates-ci` → pass (bar 139/139 + test typecheck,
  app-contract 17/17, notifications 10/10 + drift, capture-tool 150/150 +
  97 backend pytest, wallpaper-selector model/apply-collapse + drift, icme
  library suites + drift, btop suites + key-widget drift).
- Local typechecks: `make bar-typecheck notifications-typecheck
  capture-tool-typecheck hypr-pano-typecheck wallpaper-selector-typecheck
  icme-typecheck btop-theme-studio-typecheck` → 0 errors in every app tree
  (0 `ags-platform` errors; only the tolerated AGS-runtime errors).
- Platform pin: `make ags-platform-dev` → `node_modules/ags-platform` and every
  app's `node_modules/ags-platform` point at `.dev/ags-platform/v0.3.0`
  (local symlink to the `ags-platform` v0.3.0 checkout).
- Release: annotated tag `v0.5.0` on `main`; `git cat-file -t v0.5.0` → `tag`.
  Local-only: no push/publication in this run.
