---
id: REQ-009
title: "Migrate the clipboard app to ags-clipboard with full rename + live refresh (pilot)"
kind: requirement
status: done
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

- [x] The pilot repo is created from the REQ-008 template fixture with AGENTS,
      tickets (LIFECYCLE/INDEX/_template), worktree guard, Makefile, CI, README,
      manifest, handler, `templates/ags-app/` and tests.
- [x] Repo is tagged; the app builds against the program
      `ags-platform`/`contracts` tuple and passes template conformance.
- [x] `app.manifest.json` has the identity tuple
      (`clipboard` / `ags-clipboard` / `live` / no unsaved state) and the
      identity equals `app.tsx` + `ags list` + the deployed link basename.
- [x] `palette-refresh` uses a single JSON-encoded string response, is
      idempotent by appearance hash, and preserves overlay state.
- [x] No `hypr-pano` app/config/window/launcher/keybind name remains; the
      daemon's old data paths are migrated once and the new paths are used.
- [x] `dotfiles-assets` autostart/keybind and the provisioned launcher use
      `ags-clipboard` / `clipboard-ui`.
- [x] The cutover quiesces the old instance, flips the app list entry from
      `legacy` to `standalone`, installs/starts the new instance, and verifies
      every app-list ownership surface (install dir, spine/XDG/bin links,
      launcher, autostart, process, D-Bus name).
- [ ] The pilot exit gate is measured and recorded against the REQ-008
      thresholds: scaffold-to-green ≤ 30 min, CI/release ≤ 10 min, install/
      rollback ≤ 2 min each, zero duplicate/missing ownership surfaces, no
      unnecessary restart, no bespoke provisioning code. If the gate fails, the
      program stops.
      **Open evidence item:** the pilot cleared operationally (the program went on
      to ship all seven repos) but no per-step timing record was captured, so
      this box stays unticked rather than claiming measurements that do not
      exist. Everything else in the gate (zero duplicate/missing surfaces, no
      unnecessary restart, no bespoke provisioning code) is covered by
      `deploy-coverage` + `verify` below.
- [x] The old source is deleted from `ags-apps`; the old role has one fewer
      `legacy` entry.
- [x] `ags bundle`, typecheck (local), pure tests, manifest conformance and the
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

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-clipboard` `v0.1.0` (annotated); manifest
  `clipboard` / `clipboard` / `ags-clipboard` / `live` /
  `holdsUnsavedState: false`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: clipboard`, `owner: standalone`, launcher `clipboard-ui`,
  autostart `clipboard`, `launch: on-demand`, `cutoverId: REQ-009`.
- **Rename/migration:** no `hypr-pano` app/config/window/launcher remains in the
  repo; `dotfiles-runtime v0.3.0` migrated history once to the `clipboard`
  namespace (`~/.local/state/clipboard/history.json`) and the old
  `~/.config|~/.local/state|~/.cache/hypr-pano` paths are absent on the host.
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; engine `v0.1.24`; `dotfiles-provision verify` →
  exit 0; no host `ags-apps` unit; `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).
- **Pilot gate:** cleared operationally (the program shipped the remaining six
  repos); per-step timing was not recorded — see the open box above.

Verify: `git -C ags-clipboard describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
