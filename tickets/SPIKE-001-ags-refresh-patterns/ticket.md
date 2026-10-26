---
id: SPIKE-001
title: "AGS refresh patterns: why some apps live-refresh while others restart (incl. btop-theme-studio)"
kind: spike
status: boxed
lane: bmad-advisory
timebox: "2 days"
questions:
  - "For every app (bar, notifications, wallpaper-selector, icme, hypr-pano, capture-tool, btop-theme-studio): what inputs does it consume, what state does it cache, what refresh mechanism is actually implemented, why was that mechanism chosen, and is it in the runtime skip list?"
  - "What pattern does btop-theme-studio follow — runtime palette, only btop themes, or neither — and should it be skipped, restarted, or neither?"
  - "Does AgsReloader.DEFAULT_SKIP_CONFIG_DIRS match the documented contract, and are any apps missing or extra?"
  - "Why does the login reconcile restart AGS consumers — intentional recovery or an unconditional reload — and what are last-converged.json / watch-health.json for?"
  - "Why does capture exit 0 on relaunch: a real restart failure, an instance-name/quit issue, or a liveness-check bug?"
  - "Why are there two hypr-pano processes, and which one owns the AGS instance?"
  - "What is the correct idempotency/refresh contract going forward (app → inputs → refresh mechanism → restart trigger)?"
answered: []
open: []
links:
  openspec: none
  bmad: none
worktree: .worktrees/SPIKE-001/
branch: ticket/SPIKE-001-ags-refresh-patterns
---

# AGS refresh patterns: why some apps live-refresh while others restart (incl. btop-theme-studio)

## Triage

Run through `/triage` on 2026-10-26.

- `kind:` **spike** — the request is an investigation with named questions and a box; it explicitly must not produce implementation.
- `lane:` **4 — bmad-advisory** — cross-repo (ags-apps + dotfiles-runtime + the AGS launcher/CLI) and architectural: the refresh contract is not documented for every app (btop-theme-studio is missing) and the observed symptoms could be policy or launcher races. The advisory output is this report, not an implementation plan.
- `timebox:` **2 days** (plan 02 — runtime BUG-002 follow-up; priority P3).
- `questions:` recorded in the frontmatter above (7 named questions).
- Ambiguity: none — the plan supplies the questions, the box, and the no-code constraint.

Evidence: `/home/inumaki/.opencode/plan/02-runtime-BUG-002-reconcile-restart-races.md:3-7, 36-68` (spike kind, 1–2 day box, questions, no implementation).
Verify: `sed -n '1,90p' /home/inumaki/.opencode/plan/02-runtime-BUG-002-reconcile-restart-races.md`

### Triage evidence rule

- Evidence for the split: `dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md:64-75` (app-by-app rule) and `dotfiles-runtime/src/runtime/adapters/ags_reloader.py:53-63` (skip list).
- Evidence for the symptom set: `~/.local/state/dotfiles/login-reconcile.log` (capture exit 0), `ps -eo pid,lstart,args | grep ags` (two pano wrappers), `~/.local/state/dotfiles/history.jsonl` (four reconciles).
- All claims in the final report carry their own `Evidence:` / `Verify:` lines.

## Questions

1. For each app (bar, notifications, wallpaper-selector, icme, hypr-pano,
   capture-tool, btop-theme-studio), enumerate:
   - inputs consumed (palette CSS, palette-derived icons, effects, wallpapers,
     config, live events);
   - cached state that outlives a CSS refresh;
   - the refresh mechanism actually implemented (live provider, event handler,
     process restart, none);
   - why that mechanism was chosen (doc/code/commit).
2. What pattern does **btop-theme-studio** follow? Does it consume the runtime
   palette, only btop themes, or neither? Should it be in the reloader skip list,
   restart set, or neither?
3. Does the runtime's `DEFAULT_SKIP_CONFIG_DIRS` (notifications, icme,
   wallpaper-selector) match the contract? Are any apps missing/extra?
4. Why does the **login reconcile** restart consumers? Is that intentional
   recovery or an unconditional reload? What is `last-converged.json` /
   `watch-health.json` for?
5. Why does `capture` exit 0 on relaunch? Is it a real restart failure, an
   instance-name/quit issue, or a liveness-check bug?
6. Why are there two `hypr-pano` processes? Reconstruct the autostart vs
   login-reconcile timeline; which process owns the AGS instance?
7. What is the correct idempotency/refresh contract going forward? State it as a
   matrix (app → inputs → refresh mechanism → restart trigger).

## Findings

> Pending. This ticket is boxed; the report lands before the box closes.

### Answered

- Pending.

### Open

- Pending.

> Spike stops at the box and reports `answered:` / `open:`. Implementation output from a spike is a failure. No second box without an explicit user call.
