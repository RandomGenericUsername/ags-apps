# Changelog

Notable changes to `ags-apps`. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Release identity is
the annotated git tag.

## [Unreleased]

(nothing yet)

## [0.5.0] - 2026-10-26

Monorepo adoption release for the standalone AGS app contract (REQ-008,
AD-26/AD-27/AD-36). Every app now declares its deployed identity; every live
app answers the runtime-owned `palette-refresh` command; the bar stays an
explicit `restart` app. No app moved to a new repository and `hypr-pano` was
not renamed — that is the REQ-009 pilot.

### Added

- `app.manifest.json` in every app directory with the deployed identity:
  `bar` (`ags`/`ags`, restart), `notifications`, `capture`
  (`capture`/`ags-capture`), `hypr-pano` (`ags-hypr-pano`),
  `wallpaper-selector`, `icme`
  (`icon-color-mapping-editor`/`ags-icme`, unsaved state) and
  `btop-theme-studio` (`ags-btop-studio`, unsaved state).
- `palette-refresh` handlers in all live apps through the platform v0.3.0
  `createPaletteRefreshHandler`: notifications, capture-tool, hypr-pano,
  wallpaper-selector, icme and btop-theme-studio. hypr-pano composes the fixed
  command with its existing show/hide/toggle request surface; capture-tool
  gains its first request handler.
- `make app-contract-test` (`tests/app-contract.test.mjs`): manifest validation
  against the platform helper/contracts v0.3.0 schema, handler adoption,
  `wallpaper.state` separation and the JSON-string protocol.
- `CHANGELOG.md`.

### Changed

- `wallpaper.state` is progress/card/status only. Notifications and
  wallpaper-selector no longer re-apply the palette from it; icme drops its
  `wallpaper.state` subscription entirely. The runtime command is the only
  palette-refresh trigger (AD-27).
- Live refresh paths preserve declared state: btop/icme pending edits and
  selection, clipboard overlay state, selector drawer, notifications card/bus,
  capture's active surface.
- Re-pinned the dev platform and contracts reference from `v0.2.0` to
  `v0.3.0` (`AGS_PLATFORM_VERSION`, `CONTRACTS_VERSION`, CI checkout refs).
  The `v0.3.0` tags are local-only for this release; `.dev/ags-platform/v0.3.0`
  is a gitignored local checkout/symlink.

### Release

- Annotated tag `v0.5.0` on `main` after the gates pass.
- Local-only: not pushed or published in this run.
- Gates: `make app-contract-test`, `make gates-ci` and the per-app local
  typechecks (see `tickets/REQ-008-standalone-app-contract/ticket.md` evidence).
