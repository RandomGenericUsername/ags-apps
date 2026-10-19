---
id: REQ-005
title: "Migrate wallpaper-selector"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-wallpaper-selector
  bmad: none
worktree: .worktrees/wall6/
branch: ticket/wall6-migrate
---

# Migrate wallpaper-selector

## Requirement

Wallpaper-selector depends on the platform: its `event-bus-core.ts`/`event-bus.ts` copies are replaced by the one event client, its `icon-registry.ts` by the platform `IconProvider`, and its `theme.ts` by the `Theme` port. It consumes `wallpaper.state` through the shared client.

Source: spine **AD-5**, **AD-7**, **AD-13**; handoff iteration 6.

## Acceptance

- [x] `lib/event-bus*.ts` + `lib/icon-registry.ts` + `lib/theme.ts` are gone; the platform is used.
- [x] `wallpaper.state` (including `stage`/`reload_failures`) is consumed via the shared client.
- [x] The drift test is repointed.

## Migration notes (slice 6, ticket/wall6-migrate)

- **Moved (commit 1).** `dotfiles-v3/src/gui-tools/wallpaper-selector/` ->
  `ags-apps/wallpaper-selector/`, verbatim, minus the app-local Makefile (the
  house pattern: bar/ ships none). The in-place dotfiles copy stays until the
  separate deletion change (AD-20).
- **event-bus copies gone / shared client (AD-5).** `lib/event-bus.ts` +
  `lib/event-bus-core.ts` deleted; `ui/WallpaperSelectorWindow.tsx` subscribes
  `wallpaper.state` through `ags-platform/adapters/event-bus` (`domainEvents`),
  with the topic literal declared locally (the platform exports no
  `WALLPAPER_STATE_TOPIC`; notifications uses the literal too). The subscribe-
  before-read hydration delivers the last payload, so an open mid-apply renders
  the in-flight state. Evidence: `grep -rn 'ags-platform' wallpaper-selector/ui`
  -> `adapters/event-bus`, `adapters/icon`, `adapters/theme`.
- **icon-registry gone / platform IconProvider (AD-4/AD-7).**
  `lib/icon-registry.ts` deleted; `searchUiIcon()` resolves `("ui","search")`
  through `registryProvider.resolve` (a tagged `IconSource` — a rendered `file`
  loads via GdkPixbuf, a `name` renders as a themed symbolic icon, else the
  stock `system-search-symbolic` fallback). The bundled platform `icons.json`
  carries the `ui` group, so the manifest source changes from
  `~/.config/ags/icons.json` to the platform artifact (per the port).
- **theme copy gone / Theme port (AD-13).** `lib/theme.ts` deleted; `app.tsx`
  and the done/error `refreshChrome()` call `theme.apply()`
  (`ags-platform/adapters/theme`). `reloadIconManifest()` retired with the copy
  (the platform registry reads a bundled manifest; the rendered SVGs are
  re-stat'd per resolve).
- **No app->app imports (AD-1).** The app imports only `ags-platform` and its
  own modules.
- **Drift test repointed.** `tests/event-contract-drift.mjs` now imports
  `ags-platform/ports/event-client` (was `../lib/event-bus-core.ts`); it pins the
  hub constants, the `wallpaper.state` shape incl. the optional
  `stage`/`reload_failures` members, the hydration state machine (incl.
  tolerance of their absence), and the structural platform consumption.
- **Typecheck-forced corrections (commit 3).** The committed
  `tsconfig.wallpaper.json` (mirroring pano/notifications) surfaced 3 pre-existing
  type errors; none changes the picker's user-facing behaviour. `sha256File`
  throws on a null checksum; `cacheKey` passes the explicit byte length to
  `GLib.compute_checksum_for_string` (GJS throws on a 2-arg call, so the disk
  thumb cache was dead at runtime — it now works as its doc comment intended);
  `anchor={0}` -> `Astal.WindowAnchor.NONE` (identical anchoring, honest type).
- **Gates.** `wallpaper-selector-typecheck` (desktop stack) +
  `wallpaper-selector-tests` + `wallpaper-selector-drift-test` (stock);
  the two pure gates join `gates-ci`. `tests/model.mjs` re-homed as
  `tests/model.test.mjs` (house `*.test.mjs` naming).
  Evidence: `make gates-ci` -> exit 0; `ags bundle
  wallpaper-selector/app.tsx /tmp/opencode/wall.js --gtk 4` -> exit 0.
- **AD-24 (surface before content): NOT adopted (measured).** Instrumented copy
  (distinct instance `wallpaper-selector-perf`, isolated `XDG_CACHE_HOME`, live
  `wallpaper-selector` untouched): the grid builds **64 cards in 6-11 ms**; a
  warm toggle-open (`map` -> rescan -> grid build -> present) is **8-17 ms**
  across three cycles; the one-time hydration-driven rescan at construction is
  **16 ms**. The heavy work — decoding all thumbnails (~3.2 s cold) — already
  runs deferred on the idle queue (warmup + the async thumb pump), i.e. off the
  open path. All synchronous open-path build costs are single- to high-teens ms,
  below AD-24's "tens of ms or more" threshold, so the light surface keeps its
  direct path. Harness: `/tmp/opencode/build_wsperf.py` + `/tmp/opencode/wsperf*`.
