---
id: REQ-014
title: "Migrate icme to ags-icme (already live)"
kind: requirement
status: done
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate icme to ags-icme (already live)

## Requirement

Move `icme` into `ags-icme`. Keep the deployed config dir `ags-icme` and
instance `icon-color-mapping-editor`. The manifest declares `app: icme`,
`instance: icon-color-mapping-editor`, `configDir: ags-icme`, `mode: live`,
`holdsUnsavedState: true`.

The command re-applies the palette and rebuilds the show only when the scheme
fingerprint moved, preserving all pending/staging maps. The app must never be
restarted.

## Acceptance

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Manifest identity is `icme` / `icon-color-mapping-editor` / `ags-icme`,
      `mode: live`, unsaved state true.
- [x] `palette-refresh` preserves pending edits and only rebuilds the show when
      the scheme fingerprint changes.
- [x] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner.
- [x] Old source is removed from `ags-apps`; docs record the new pin.

## Dependencies

- `REQ-008` contract/schemas/template/cutover fixture.
- `ags-platform` Theme one-provider replacement and manifest helper.
- `dotfiles-runtime` manifest discovery, ledger, lanes.
- `dotfiles-v3`/`dotfiles-provision` app list and generic role.

## Evidence

- `icme/ui/EditorWindow.tsx` live handler, fingerprint and map handler.
- `icme/app.tsx` startup theme.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` ICME row.

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-icme` `v0.1.0` (annotated); manifest `icme` /
  `icon-color-mapping-editor` / `ags-icme` / `live` /
  `holdsUnsavedState: true`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: icme`, `owner: standalone`, launcher
  `icon-color-mapping-editor`, `launch: on-demand`, `cutoverId: REQ-014`.
- **Live refresh:** palette re-applied and the show rebuilt only when the scheme
  fingerprint moved; pending/staging maps preserved; never restarted.
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no host `ags-apps`;
  `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-icme describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
