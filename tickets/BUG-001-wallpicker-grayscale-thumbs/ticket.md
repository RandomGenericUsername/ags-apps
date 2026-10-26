---
id: BUG-001
title: "Fix grayscale thumbnails for PNG wallpapers (RGBA — gdk-pixbuf JPEG saver bug)"
kind: bug
status: in-progress
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
