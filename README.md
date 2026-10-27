# ags-apps

The AGS application unit: the status bar and its sibling apps, developed and released together.

Every app depends on **`ags-platform`** (ports + shared adapters) and on `contracts`.
**Never app → app.**

## Apps

| Directory | App | Manifest identity | Mode |
| --- | --- | --- | --- |
| `bar/` | the status bar | `ags` / `ags` / `ags` | `restart` |
| `notifications/` | notification daemon + cards | `notifications` / `notifications` / `ags-notifications` | `live` |
| `capture-tool/` | screenshot/recording GUI + backend | `capture` / `capture` / `ags-capture` | `live` |
| `hypr-pano/` | clipboard overlay | `hypr-pano` / `hypr-pano` / `ags-hypr-pano` | `live` |
| `wallpaper-selector/` | wallpaper picker | `wallpaper-selector` / `wallpaper-selector` / `ags-wallpaper-selector` | `live` |
| `icme/` | icon color-mapping editor | `icme` / `icon-color-mapping-editor` / `ags-icme` | `live` |
| `btop-theme-studio/` | btop theme authoring studio | `btop-theme-studio` / `btop-theme-studio` / `ags-btop-studio` | `live` |

Each directory carries `app.manifest.json` at its root, deployed with the app (spine
AD-26/AD-36). Every `live` app answers the fixed
`ags request palette-refresh <appearance-hash> -i <instance>` command through
`createPaletteRefreshHandler` from `ags-platform/ports/palette-refresh`; the bar is
`restart` and has no palette handler. `wallpaper.state` remains the progress/status
event and is no longer a palette-refresh trigger (AD-27).

Live refreshes are state-preserving:

- notifications re-applies the Theme pointer and re-reads progress-card icons; the
  card stack, timers and daemon/bus state stay live;
- capture-tool re-applies the Theme pointer; the active capture surface, shared UI
  state and per-monitor windows stay as they are;
- hypr-pano dispatches `palette-refresh` ahead of its show/hide/toggle requests and
  never hides or rebuilds the overlay;
- wallpaper-selector re-applies the Theme pointer and re-renders the search icon
  only; the drawer, query, contrast choices and in-flight apply are untouched;
- icme returns `deferred` while a save is in flight and otherwise reloads the show;
  pending edits and selection are preserved;
- btop-theme-studio reloads the palette and generated base map only; pending edits,
  selected theme, scope and save target are preserved.

The unit is consumed by the installer as one pinned tag (`ags_apps_version` in
`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml`, currently `v0.4.1`). The
monorepo adoption release for the standalone-app contract is `v0.5.0`.

## Workspace and pins

Developed beside its consumers under `~/Development/dotfiles/`. The canonical ownership/pin map
is [`../dotfiles-v3/docs/WORKSPACE.md`](../dotfiles-v3/docs/WORKSPACE.md).

- `ags-platform` is pinned at **`v0.3.0`** (`AGS_PLATFORM_VERSION` in the `Makefile`).
- `contracts` is pinned at **`v0.3.0`** (`CONTRACTS_VERSION`; CI checks that tag out).
- Both `v0.3.0` tags are **local-only** during the adoption release. `make
  ags-platform-dev` uses a checkout/symlink at `.dev/ags-platform/v0.3.0` when it
  exists and only tries the network fetch for a published tag. `.dev/` is
  gitignored: local checkouts and fetched artifacts are never committed.

## Gates

```bash
make ags-platform-dev         # local v0.3.0 platform shortcut (see pins above)
make app-contract-test        # manifests + palette-refresh conformance
make gates-ci                 # stock-runner subset: pure tests + drift/mock/parity guards
make bar-typecheck            # LOCAL only: needs ags + Astal/GIR (not CI)
make btop-theme-studio-tests  # one app's pure suite
make help                     # every app-specific target
```

`app-contract-test` validates every manifest with the platform helper against the
contracts v0.3.0 schema, checks handler adoption (live) / absence (bar), proves
`wallpaper.state` does not apply palettes, and executes the JSON-string response
protocol.

Typecheck is deliberately **local**: the desktop stack and generated `@girs/` declarations are
not available on a stock runner. CI runs only stock-runner jobs (see `AGENTS.md` §4).

## Tooling

- **BMAD-METHOD:** `.agents/skills/`.
- **OpenSpec:** `openspec/` — `/opsx-propose`.
- **Tickets:** `tickets/` — route with `/triage`.
- **Worktrees:** `scripts/worktree-guard.sh create <id> <slug>`; never work on `main`.
