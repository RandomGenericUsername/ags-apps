# wallpaper-selector

AGS wallpaper picker (P5 drill-down): level 1 is the install-spine
wallpaper grid with search and hover quick-apply; level 2 is the
per-wallpaper variant gallery (breadcrumb + Back) fed by the runtime's
effects cache. Applying shells the engine (`dotfiles-runtime wallpaper
set`); progress and LIVE refresh arrive via the `wallpaper.state` domain
event. Variants promoted to wallpaper skip WEG regeneration in the
runtime (mechanism A) while palette/icons still derive.

## Thin platform consumer

This app depends on `ags-platform` and `contracts`, never on another app
(AD-1):

- **Events** — `wallpaper.state` is consumed through the one shared event
  client (`ags-platform/adapters/event-bus`, AD-5). The app-local
  `lib/event-bus.ts` + `lib/event-bus-core.ts` copies are gone.
- **Icons** — the search glyph resolves through the platform `IconProvider`
  (`ags-platform/adapters/icon`, AD-4/AD-7). The app-local
  `lib/icon-registry.ts` copy is gone.
- **Theming** — the generated palette is applied through the `Theme` port
  (`ags-platform/adapters/theme`, AD-13). The app-local `lib/theme.ts` copy
  is gone.

## Layout

```
wallpaper-selector/
  app.tsx                 instance `wallpaper-selector`, single centered window
  style.css               ws-* classes (house dark theme)
  ui/WallpaperSelectorWindow.tsx   P5 window (imperative GTK + createEffect)
  lib/model.ts            pure grouping/filtering (node-tested, no GJS imports)
  lib/scan.ts             spine + effects-cache + current.json scan (GJS)
  lib/thumbnails.ts       disk-cached GdkPixbuf thumbnails (GJS)
  lib/apply.ts            execAsync engine entry point (GJS)
  lib/contrast.ts         icons preference/regenerate CLI shell (GJS)
  tsconfig.wallpaper.json app typecheck config (hand-written, committed)
  tests/model.test.mjs            pure-model tests
  tests/event-contract-drift.mjs  shared event client <-> contract drift gate
```

## Gates

The app-local Makefile was dropped on the move (bar/ ships none); the
per-app gates live in the repo-root `Makefile`:

```
make wallpaper-selector-typecheck    tsc --noEmit (needs the desktop stack)
make wallpaper-selector-tests        pure-model unit tests (stock runner)
make wallpaper-selector-drift-test   shared event client <-> contracts drift
```

`wallpaper-selector-tests` and `wallpaper-selector-drift-test` are pure and
run in `make gates-ci`; `wallpaper-selector-typecheck` needs the machine's
GIR types and is local-only (never a CI job).

Provisioned as `<install>/config/ags-wallpaper-selector/` with launcher
`wallpaper-selector-ui` (SUPER+W).

## Lifecycle

- Only the Apply buttons set the wallpaper; thumbnail presses are inert.
- An "Auto high-contrast icons" checkbox (L2 crumb header, primary) edits
  the per-wallpaper pref via `dotfiles-runtime icons preference <hash>
  --set on|off`; the L1 hover swatch is a CSS-drawn shortcut that drills to
  L2. A live-target flip additionally runs `icons regenerate --contrast
  on|off` (icons only, no pixel change); a non-live flip persists only.
- Applies persist the focused wallpaper's checkbox state before
  `wallpaper set` (`auto` resolution). While `wallpaper.state` is
  `applying`/`visible`, Apply controls are insensitive; the checkbox stays
  live and a flip defers its regenerate until `done`/`error`.
- The window self-hides on successful apply (stays open on failure).
- The runtime's AGS reloader skips this instance (`DEFAULT_SKIP_CONFIG_DIRS`,
  same as the editor): a restart would pop the visible-on-start window back
  open uninvited. Palette restyling arrives event-driven instead — the
  `wallpaper.state → done` handler re-applies the palette through the Theme
  port plus the re-rendered search icon.
