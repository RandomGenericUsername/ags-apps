---
id: REQ-009
title: "Migrate the clipboard app to ags-clipboard with full rename + live refresh (pilot)"
kind: requirement
status: proposed
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate the clipboard app to ags-clipboard with full rename + live refresh (pilot)

## Requirement

Move the clipboard-history overlay out of `ags-apps` into the standalone
`ags-clipboard` repo. This is the pilot for the repo template, the manifest +
`palette-refresh` contract, the one-owner cutover and the per-app install
topology.

Full rename, not an alias:

- repo: `ags-clipboard`
- config dir: `ags-clipboard`
- AGS instance: `clipboard`
- window: `clipboard-window`
- launcher: `clipboard-ui`
- keybind description: “Open clipboard history”
- manifest: `app: clipboard`, `instance: clipboard`,
  `configDir: ags-clipboard`, `mode: live`, `holdsUnsavedState: false`

The runtime clipboard daemon keeps the command name `dotfiles-runtime
clipboard`, but its config/state/cache paths move to the `clipboard` namespace
with a one-time migration from the old `hypr-pano` paths so history and
preferences survive.

The app implements `palette-refresh` with the existing cache invalidation:

- clear `tokenCache` and `textureCache`;
- re-read palette tokens and re-apply the Theme port;
- rebuild the cards and static search icon;
- preserve overlay visibility, query, selection and clipboard state.

A wallpaper change must not restart the process.

## Acceptance

- [ ] The pilot repo is created from the REQ-008 template fixture with AGENTS,
      tickets (LIFECYCLE/INDEX/_template), worktree guard, Makefile, CI, README,
      manifest, handler, `templates/ags-app/` and tests.
- [ ] Repo is tagged; the app builds against the program
      `ags-platform`/`contracts` tuple and passes template conformance.
- [ ] `app.manifest.json` has the identity tuple
      (`clipboard` / `ags-clipboard` / `live` / no unsaved state) and the
      identity equals `app.tsx` + `ags list` + the deployed link basename.
- [ ] `palette-refresh` uses a single JSON-encoded string response, is
      idempotent by appearance hash, and preserves overlay state.
- [ ] No `hypr-pano` app/config/window/launcher/keybind name remains; the
      daemon's old data paths are migrated once and the new paths are used.
- [ ] `dotfiles-assets` autostart/keybind and the provisioned launcher use
      `ags-clipboard` / `clipboard-ui`.
- [ ] The cutover quiesces the old instance, flips the app list entry from
      `legacy` to `standalone`, installs/starts the new instance, and verifies
      every app-list ownership surface (install dir, spine/XDG/bin links,
      launcher, autostart, process, D-Bus name).
- [ ] The pilot exit gate is measured and recorded against the REQ-008
      thresholds: scaffold-to-green ≤ 30 min, CI/release ≤ 10 min, install/
      rollback ≤ 2 min each, zero duplicate/missing ownership surfaces, no
      unnecessary restart, no bespoke provisioning code. If the gate fails, the
      program stops.
- [ ] The old source is deleted from `ags-apps`; the old role has one fewer
      `legacy` entry.
- [ ] `ags bundle`, typecheck (local), pure tests, manifest conformance and the
      one-owner cutover gate pass.

## Dependencies

- `REQ-008` contract, schemas, runtime ledger, template and cutover fixture.
- `ags-platform` one-provider Theme replacement and manifest helper.
- `dotfiles-runtime` manifest discovery/identity, ledger, lanes, clipboard data
  migration.
- `dotfiles-v3` app list/pin, `dotfiles-provision` generic role/verify/stop-start,
  `dotfiles-assets` autostart/keybind.

## Evidence

- `hypr-pano/ui/ItemCard.tsx` token/texture caches.
- `hypr-pano/ui/PanoWindow.tsx` card rebuild and static search icon.
- `dotfiles-runtime/src/runtime/adapters/clipboard_config.py`,
  `json_history_store.py` (old data paths).
- `dotfiles-assets/configs/hypr/autostart.lua` (old launch path).
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` clipboard row.
