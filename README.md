# ags-apps

The AGS applications: the status bar and its siblings.

Every app depends on `ags-platform` (ports + shared adapters) and on `contracts`. **Never app → app.**

## Apps

- `bar/` — the status bar (first to migrate).

(notifications, capture-tool, hypr-pano, wallpaper-selector, icon-color-mapping-editor to follow.)

## Tooling here

- **BMAD-METHOD:** `.agents/skills/`.
- **OpenSpec:** `openspec/` — `/opsx-propose`.
- **Tickets:** `tickets/` — route with `/triage`.

## Status

Scaffold. Next: extract the bar here, consuming `ags-platform`.
