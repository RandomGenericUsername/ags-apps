# btop Theme Studio

A launch-on-demand AGS/GTK4 authoring tool for btop themes (OpenSpec change
`add-btop-theme-studio`). It makes btop's two systemic colour defects visible
(`meter_bg` and `used_start` resolving to the same mid-luminance palette stop)
and lets a user create, fork, tune, preview, and deploy themes.

Moved here from `dotfiles-v3/src/gui-tools/btop-theme-studio/` by slice 8.1 of
`ags-apps-bar-first` (REQ-007). It is the seventh app in this unit and keeps its
instance name (`btop-theme-studio`), its single centered window, its save
pipeline and its live-preview engine.

## Thin platform consumer

This app depends on `ags-platform`, never on another app (AD-1):

- **Theming** — the desktop palette is applied through the `Theme` port
  (`ags-platform/adapters/theme`, AD-13). The app had no `theme.ts` copy to
  remove; `style.css` chrome is now token-bound (`@color_*` from `colors.css`)
  so a palette swap restyles the window. The two CONTENT literals that remain
  are deliberate: `.canvas` is the neutral stage the candidate btop theme is
  judged on, and `.live-frame` reproduces btop's own black terminal.
- **Icons / events** — this app has no icon-registry or event-bus copy and
  consumes no contract topic: it reads and writes files locally. The
  acceptance test pins that it does not grow one.
- **AD-24 (overlay lifecycle)** — measured, not assumed. The open-path
  widget-tree build is recorded in the migration commit; the primitive is
  adopted only when that build is significant (tens of ms or more).

## Layout

| path | role |
|---|---|
| `app.tsx` | AGS entry point — its own instance, one centered window |
| `ui/StudioWindow.tsx` | the window: schematic, key tree, picker, diagnosis, diff, save targets, live view |
| `lib/` | pure, I/O-free logic (unit-tested with plain `node`) |
| `lib/key_widgets.json` | the canonical generated key→widget map (drift-checked) |
| `lib/key-widgets.generated.ts` | the importable form of the same artifact |
| `tools/key_widgets.py` | the generator + drift-guard verifier |
| `tools/btop_*.cpp` | vendored btop v1.4.7 sources the generator parses (Apache-2.0) |
| `live/btop_live.py` | the live preview engine (real btop on a pty + `pyte`) |
| `tests/` | pure-logic tests + platform-consumption acceptance (`node`) |
| `live/tests/` | live-engine tests (`uv run --with pyte pytest`) |
| `tsconfig.btop.json` | app typecheck config (hand-written, committed) |

### Why the Python engine and generated map live here

Both are app runtime / reproducibility assets, not provisioning concerns:

- `live/btop_live.py` is what the "Refresh live preview" button executes
  (`<cwd>/live/btop_live.py`, where `ags run -d btop-theme-studio` puts the
  app dir in cwd). Shipping the app without it would break the Live view.
- `lib/key_widgets.json` + `lib/key-widgets.generated.ts` are imported app
  source, and `tools/` is the generator that `key-widgets-verify` re-runs as a
  drift guard. They must travel with the app for the gate to stay meaningful.

Behaviour is unchanged by the move; only the chrome palette and the typecheck
config are new.

## Gates

The app-local Makefile was dropped on the move (the other apps ship none); the
per-app gates live in the repo-root `Makefile`:

```sh
make btop-theme-studio-typecheck   # tsc --noEmit (needs the desktop stack)
make btop-theme-studio-tests       # pure lib + platform acceptance + key→widget drift
make btop-theme-studio-live-tests  # real btop on a pty (needs uv + pyte + btop)
```

`btop-theme-studio-tests` is pure (node + python3) and runs in `make gates-ci`;
`btop-theme-studio-typecheck` needs the machine's GIR types and runs on the
self-hosted CI job. `btop-theme-studio-live-tests` is deliberately NOT in
`gates-ci`: it needs a real btop binary, `uv` and `pyte`, so it runs on the
self-hosted job (or by hand).

## Key decisions

- **The key→widget map is generated from btop source** (`btop_theme.cpp` key
  set; `btop_draw.cpp` attribution), committed, and re-derived by a drift guard.
  The studio never hand-traces "where does this key show?".
- **The schematic consumes btop's real config** (`shown_boxes` + `presets`) and
  never invents box geometry.
- **The preview is the real btop binary.** The live engine runs
  `btop --no-tty --force-utf` on a pty, keeps one warm process, reloads it with
  `SIGUSR2` per edit, and reconstructs the frame with `pyte`. It writes only to
  a throwaway temp root.

### Live-view integration (design Open Question)

The shipped AGS app **reuses the pty + terminal-emulator engine**
(`live/btop_live.py`) for the Live view rather than embedding a VTE widget. The
design explicitly permits either (behaviorally identical per the
`btop-live-preview` spec); reusing the engine keeps the one preview
implementation that has fixture, `SIGUSR2`-delta, and side-effect-free tests.
The app's "Refresh live preview" button writes the effective theme to a temp
file and runs the engine against it.

## Vendored sources

`tools/btop_draw.v1.4.7.cpp` and `tools/btop_theme.cpp` are vendored from btop
v1.4.7 (Apache-2.0) solely so the generator is reproducible and drift-checked.
They are not compiled. Refresh them deliberately when pinning a new btop
version, then regenerate the artifact with `make btop-theme-studio-tests`
(and `--ts`).
