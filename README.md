# ags-apps

The AGS application unit: the status bar and its sibling apps, developed and released together.

Every app depends on **`ags-platform`** (ports + shared adapters) and on **`contracts`**.
**Never app → app.**

## Apps

| Directory | App |
| --- | --- |
| `bar/` | the status bar (bar, panels, settings panel, services) |
| `hypr-pano/` | clipboard overlay |
| `notifications/` | notification daemon + cards |
| `capture-tool/` | screenshot/recording GUI + backend |
| `wallpaper-selector/` | wallpaper picker |
| `icme/` | icon color-mapping editor |
| `btop-theme-studio/` | btop theme authoring studio |

The unit is consumed by the installer as one pinned tag (`ags_apps_version` in
`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml`, currently `v0.4.1`), not per-file.

## Workspace

Developed beside its consumers under `~/Development/dotfiles/`. The canonical ownership/pin map
is [`../dotfiles-v3/docs/WORKSPACE.md`](../dotfiles-v3/docs/WORKSPACE.md). `ags-platform` is
pinned at `v0.2.0` (`AGS_PLATFORM_VERSION` in the `Makefile`); `contracts` is a sibling checkout.

## Gates

```bash
make gates-ci                 # stock-runner subset: pure tests + drift/mock/parity guards
make bar-typecheck            # LOCAL only: needs ags + Astal/GIR (not CI)
make btop-theme-studio-tests  # one app's pure suite
make help                     # every app-specific target
```

Typecheck is deliberately **local**: the desktop stack and generated `@girs/` declarations are
not available on a stock runner. CI runs only stock-runner jobs (see `AGENTS.md` §4).

## Tooling

- **BMAD-METHOD:** `.agents/skills/`.
- **OpenSpec:** `openspec/` — `/opsx-propose`.
- **Tickets:** `tickets/` — route with `/triage`.
- **Worktrees:** `scripts/worktree-guard.sh create <id> <slug>`; never work on `main`.
