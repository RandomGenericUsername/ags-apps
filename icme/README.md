# icme — Icon Color Mapping Editor

Authoring-time GUI for recoloring icon templates by editing `color_mappings`.
Click a shape → pick a palette swatch → save. See the canonical specification in
`dotfiles-v3/openspec/changes/add-icon-color-mapping-editor/` and
`tests/fixtures/substitution.json` for the preview-fidelity contract.

Moved here from `dotfiles-v3/src/gui-tools/icon-color-mapping-editor/` by
slice 7 of `ags-apps-bar-first` (REQ-006). It is the sixth app in this unit and
keeps its instance name, its single centered window and its save pipeline.

## Thin platform consumer

This app depends on `ags-platform`, `contracts` (generated binding) and
`dotfiles` (the manifest it edits), never on another app (AD-1):

- **Events (consumer)** — `wallpaper.state` is consumed through the one shared
  event client (`ags-platform/adapters/event-bus`, AD-5). The app-local
  `lib/event-bus.ts` + `lib/event-bus-core.ts` copies are gone.
- **Events (publisher)** — a successful save still publishes
  `icme.saved { path }`. The topic and payload type come from the VENDORED
  generated binding (`lib/generated/contract.ts`, pinned to the `contracts`
  artifact) and the `Emit` method name from the shared client
  (`lib/icme-saved.ts` is the pure shape; `lib/icme-saved-gio.ts` is the Gio
  seam). The app-local `lib/event-contract.ts` copy is gone.
- **Theming** — the generated palette is applied through the `Theme` port
  (`ags-platform/adapters/theme`, AD-13). The app-local `lib/theme.ts` copy is
  gone.
- **Icons** — this app has no `icon-registry.ts` copy: it renders icon
  templates from disk through `itr`, so the platform `IconProvider` does not
  apply.

## Layout

```
icme/
  app.tsx                     instance `icon-color-mapping-editor`, one centered window
  style.css                   icme-* classes (house dark theme)
  lib/model.ts                pure selection/pending model (node-tested)
  lib/svg.ts                  template parsing + preview painting (pure)
  lib/templates.ts            template edit model (pure)
  lib/diff.ts                 YAML diff rendering (pure)
  lib/substitute.ts           display-only {{PLACEHOLDER}} substitution (pure)
  lib/inputs.ts               repo/spine input resolution (GJS)
  lib/itr.ts                  typed `itr mapping ...` CLI wrapper (GJS)
  lib/icme-saved.ts           pure `icme.saved` emit shape (generated binding)
  lib/icme-saved-gio.ts       hub `Emit` transport (GJS)
  lib/generated/contract.ts   VENDORED generated event contract (pinned)
  ui/                         EditorWindow + panels
  tsconfig.icme.json          app typecheck config (hand-written, committed)
  tests/*.mjs                 pure library + publisher + drift gates
```

## Inputs

The authoring model is **repo-authoritative**: the editor edits the dotfiles
repo manifest (`dotfiles/config/icon-template-color-scheme-mappings/`) whenever a
checkout is detectable — via `ICME_REPO_ROOT` (set by the provisioned launcher)
or a working-directory ancestor walk — and bootstrap converges the manifest into
the spine on every run. On machines without a checkout it edits the spine copy
(`~/.local/share/dotfiles/icon-mappings/`) instead. `ICME_ICONS_YAML`,
`ICME_TEMPLATE_ROOT`, `ICME_REPO_ROOT` and `ICME_COLOR_SCHEME` override the
resolution. The editor never touches `generated/` or runs `itr render`;
rendered icons refresh on the next wallpaper/theme run as usual.

Running from this checkout needs the dotfiles root, e.g.

```sh
ICME_REPO_ROOT=/path/to/dotfiles-v3 ags run /path/to/ags-apps/icme/app.tsx
```

## Live palette refresh

The runtime deliberately never restarts this instance on a wallpaper set (its
config dir `ags-icme` is in `AgsReloader.DEFAULT_SKIP_CONFIG_DIRS`: a restart
would discard unsaved edits). Instead the editor consumes the hub's
`wallpaper.state` domain event — the same live-refresh pattern as the wallpaper
selector — and on `done`/`error` re-applies `colors.css` (the token-bound chrome,
through the platform Theme port) and rebuilds the show when the scheme
fingerprint moved. Pending edits are preserved: no restart, no discarded work.
The state machine is the platform's shared event client; the window only chooses
what to do with the payload.

## Editing flow

Picks never write to disk. They accumulate in a pending set (keyed by group,
variant-or-null, placeholder) with a live YAML diff sourced from
`itr mapping set --dry-run --diff`. **Save mappings** applies each edit
through `itr mapping set` / `set-default`, publishes `icme.saved`, and reloads;
a failed save keeps the pending edits. **Revert** discards them. Saving is
blocked when `icons.yaml` or `defaults.yaml` changed on disk since load — reload
first.

Scopes: *Whole group* writes `<group>.color_mappings` (default),
*This variant only* adds a `variants[].color_mappings` override, *All icons*
retargets `defaults.yaml` and names the groups shadowing the placeholder.

## Gates

The app-local Makefile was dropped on the move (the other apps ship none); the
per-app gates live in the repo-root `Makefile`:

```
make icme-typecheck     tsc --noEmit (needs the desktop stack)
make icme-tests         pure library suites + the icme.saved publisher smoke
make icme-drift-test    shared client + vendored binding <-> contracts drift
```

`icme-tests` and `icme-drift-test` are pure and run in `make gates-ci`;
`icme-typecheck` needs the machine's GIR types and runs on the self-hosted CI
job.

Provisioned as `<install>/config/ags-icme/` with launcher
`icon-color-mapping-editor` (SUPER+I).

## Known divergence

Python `\w` matches Unicode word characters while the TypeScript `/\w/` is
ASCII-only. Placeholder names are `COLOR_*` ASCII by vocabulary convention, so
the substitution contract holds for all real inputs.
