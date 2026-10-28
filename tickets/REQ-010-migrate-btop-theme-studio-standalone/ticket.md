---
id: REQ-010
title: "Migrate btop-theme-studio to ags-btop-theme-studio with pending-aware live refresh"
kind: requirement
status: done
lane: 3
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate btop-theme-studio to ags-btop-theme-studio with pending-aware live refresh

## Requirement

Move `btop-theme-studio` into `ags-btop-theme-studio`. Keep the deployed config
dir `ags-btop-studio` and instance `btop-theme-studio`. The manifest declares
`app: btop-theme-studio`, `instance: btop-theme-studio`,
`configDir: ags-btop-studio`, `mode: live`, `holdsUnsavedState: true`.

`palette-refresh` must:

- re-read `current/colors.yaml` and `current/colors.btop.theme`;
- update the UI palette and generated theme map;
- preserve the in-memory pending-edit map;
- re-render through `createEffect(renderAll)`;
- show a visible status when the generated base changed while pending exists.

The app must never be restarted, even if a live refresh fails. The btop skip
safety fix is already in `dotfiles-runtime` v0.2.2; this child proves the
manifest contract and the live path.

## Acceptance

- [x] Repo is created from the template, tagged, and builds against the program
      `ags-platform`/`contracts` tuple with template conformance.
- [x] Manifest identity is `btop-theme-studio` / `ags-btop-studio`, `mode: live`,
      `holdsUnsavedState: true`.
- [x] `palette-refresh` re-reads both files, updates palette + generated theme,
      preserves pending, re-renders, and reports pending/stale status.
- [x] Regression tests prove pending survives and the app is never restarted.
- [x] The cutover flips the app list entry from `legacy` to `standalone`, stops
      the old instance, repoints the link, starts the new instance and verifies
      one owner.
- [x] Old source is removed from `ags-apps`; docs record the new pin and the
      pending policy.

## Dependencies

- `REQ-008` contract/schemas/template/cutover fixture.
- `ags-platform` Theme one-provider replacement and manifest helper.
- `dotfiles-runtime` manifest discovery, ledger, lanes.
- `dotfiles-v3`/`dotfiles-provision` app list and generic role.

## Evidence

- `btop-theme-studio/ui/StudioWindow.tsx` palette/generated loads, pending map,
  save path and reactive render.
- `btop-theme-studio/app.tsx` startup-only theme apply.
- `btop-theme-studio/README.md` thin-consumer note.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` btop gap.

## Closeout evidence (2026-10-28)

- **Repo/tag:** `ags-btop-theme-studio` `v0.1.0` (annotated); manifest
  `btop-theme-studio` / `btop-theme-studio` / `ags-btop-studio` / `live` /
  `holdsUnsavedState: true`.
- **Pin:** `dotfiles-v3/dotfiles/provisioning/apps.yaml` —
  `installDir: btop-theme-studio`, `owner: standalone`, launcher
  `btop-theme-studio`, `launch: on-demand`, `cutoverId: REQ-010`.
- **Live refresh:** palette + generated theme reload with the pending-edit map
  preserved; the app is never restarted (declared `live`, ledger-managed).
- **Program state:** tuple `ags-platform v0.3.0` / `contracts v0.3.0` /
  `dotfiles-assets v0.6.2`; runtime `v0.3.0`; engine `v0.1.24`;
  `dotfiles-provision verify` → exit 0; no duplicate surface, no host
  `ags-apps`; `RandomGenericUsername/ags-apps` archived (historical tree retained read-only, never deployed).

Verify: `git -C ags-btop-theme-studio describe --tags --exact-match` → `v0.1.0`;
`cd dotfiles-v3 && make deploy-coverage`.
