---
id: BUG-001
title: "Fix grayscale thumbnails for PNG wallpapers (RGBA — gdk-pixbuf JPEG saver bug)"
kind: bug
status: done
severity: high
lane: 2
links:
  openspec: none
  bmad: none
worktree: .worktrees/BUG-001/
branch: ticket/BUG-001-grayscale-thumbs
---

# BUG-001 — Fix grayscale thumbnails for PNG wallpapers

## Symptom

The wallpaper-selector main grid renders every `.png` card in black & white while
the same file applies in full color. `.jpg` cards render correctly. The L2 variant
gallery is affected by the same path (`dim`/`dark_blur` variants).

## Root cause

`wallpaper-selector/lib/thumbnails.ts` saves thumbnails with
`pixbuf.savev(cached, "jpeg", …)` directly on the pixbuf returned by
`Pixbuf.new_from_file_at_size()`. PNG inputs decode as 4-channel RGBA pixbufs;
JPEG inputs decode as 3-channel. The gdk-pixbuf JPEG writer (2.44.8 on this host)
mishandles 4-channel buffers and emits a fully desaturated JPEG.

Disk-cache keys are `sha256(path\0mtime\0size)`; spine files never move, so the
poisoned v1 JPEGs re-hit forever (`cachedTexture` fast path + the per-process
`memoryCache`).

### Evidence (measured on this host, 2026-10-25)

- Spine files are color: `magick <file> -resize 64x64! -colorspace HSL -channel S
  -separate -format %[fx:mean]` → `background.png` 0.64, `colors.png` 0.72,
  `circuit.png` 0.21. Their stored v1 thumbnails measure **0.0**; `background.jpg`
  measures 0.69 (3-channel pixbuf → writer works).
- Decode is color: python-gi `new_from_file_at_size` → PNG roundtrip measures
  0.69-0.99 saturation for the same PNGs.
- Save is the killer: python-gi `savev(…, "jpeg", ["quality"], ["82"])` exactly as
  the selector does → saturation **0** for ALL 4-channel sources tested
  (background/colors/circuit/aurora_dragon/black_eagle/golden_eagle/diwali/wave
  .png); 3-channel sources (background/aurora/garuda_eagle .jpg) save correctly
  (0.30-0.69).
- Cache lookup: naming format matches — every v1 thumb is
  `~/.cache/dotfiles-wallpaper-selector/<sha256(path\0mtime\0size)>-208.jpg`,
  written in one batch on 2026-10-21 11:15:43.
- Corpus anonym check: of 40 spine PNGs only `test_wallpaper.png` (broken junk)
  and `hyprland_honeycomb_sgs.png` (min-alpha 247) dip below alpha 250; the only
  real transparency is in WEG `dim`/`dark_blur`/`brightness` variants
  (min-alpha 179-204), which the desktop composites over Hyprland's clear color
  (black) anyway.

## Fix (Option A, agreed)

- Flatten any RGBA pixbuf onto an opaque 3-channel pixbuf over black before the
  JPEG save; 3-channel pixbufs pass through untouched. Pure GdkPixbuf ops — no
  new subprocess dependency, JPEG speed choice retained (see the file's own
  perf rationale).
- Bump the disk entry naming to `…-v2-<maxDim>.jpg` (`CACHE_VER`): stats alone
  can never invalidate poisoned entries whose source files never move, so a
  version suffix regenerates everything on next open. Legacy v1 files are left
  on disk (harmless garbage).
- Flatten decision applies to the in-memory texture too, so memory and disk
  show the same image (one definition of "a thumbnail").

## Acceptance

- [x] `generateThumb` emits color thumbnails for RGBA sources (probe measures
      saturation ≈ source, not 0).
- [x] Old poisoned entries are no longer read (v2 naming); next open regenerates.
- [x] `make wallpaper-selector-typecheck` → exit 0.
- [x] `make wallpaper-selector-tests` + drift gate → exit 0.

## Closing evidence (2026-10-25)

- **Commit:** `4aea5f4 fix(wallpaper-selector): grayscale PNG thumbnails —
  flatten RGBA before JPEG save` (branch `ticket/BUG-001-grayscale-thumbs`).
- **v1 reproduction:** python-gi + gjs probes → `savev(…, "jpeg")` on a
  4-channel pixbuf saturates to 0.0 for all 8 PNG wallpapers tested; 3-channel
  `.jpg` sources save correctly (0.30-0.69). Probe:
  `gjs -m /tmp/opencode/flatten-gjs-probe.mjs`.
- **v2 verification (exact production call sequence in GJS):** background.png
  0.651, colors.png 0.805, circuit.png 0.218, aurora_dragon.png 0.319,
  black_eagle.png 0.593, golden_eagle.png 0.978 — all match their sources'
  saturation; `.jpg` passthrough byte-stable against the pre-fix good values
  (background 0.689443, aurora 0.50107). Measured with
  `magick <thumb> -resize 64x64! -colorspace HSL -channel S -separate
  -format '%[fx:mean]' info:`; color visually confirmed on the regenerated
  `background.png` card thumb (purple GARUDA scene, was gray mush).
- **Gates (worktree, 2026-10-25):** `make wallpaper-selector-typecheck` →
  `OK: 0 errors in wallpaper-selector`; `make wallpaper-selector-tests` →
  `model: all green`; `make wallpaper-selector-drift-test` → `all checks
  passed`.
- **Roll-out note:** the installed selector consumes the pinned `ags-apps`
  tag, so the fix goes live only after the next tag bump + re-provision
  (`dotfiles-v3` pin update — separate change). Until then the installed
  build keeps re-writing v1 (gray) entries into the cache; nothing to do
  manually — once the fixed build runs, every card thumbnail regenerates as
  v2 on the first open and v1 files are bypassed (left as harmless disk
  garbage).
