---
id: REQ-015
title: "Migrate bar to a standalone repo, last"
kind: requirement
status: proposed
lane: 4
links:
  openspec: none
  bmad: none
worktree: none
branch: none
---

# Migrate bar to a standalone repo, last

## Requirement

Move the AGS bar into its own standalone repo, **last**, after the six other
apps and the contract are proven. Preserve the special deployment shape: the
bar is linked as `~/.config/ags` (the default AGS instance `ags`), not as an
`ags-*` config directory.

The child must make an explicit live-vs-restart decision:

- **live**: re-apply the palette, refresh generated icons/backdrops and rebuild
  the bar surfaces/widgets in place;
- **explicit restart**: declared in the manifest, change-gated to a real
  palette change, with confirmed quit and no no-op login restart.

Either way, the bar must not be restarted on every reconcile, and a no-op
reconcile must not touch it.

## Acceptance

- [ ] New repo is tagged and has AGENTS, ticket flow, CI, typecheck, tests and a
      release/pin note.
- [ ] Deployment still links the bar as `~/.config/ags`; instance name remains
      `ags`.
- [ ] Manifest declares the chosen mode and the bar's session-wide service
      constraint.
- [ ] If live: palette/icons/backdrop/widgets refresh without a process
      restart.
- [ ] If restart: only on a real palette change, with confirmed quit and no
      no-op reconcile restart.
- [ ] The bar's popup/service behavior is preserved or explicitly documented.
- [ ] Dotfiles cutover pins the new repo, removes the bar from the old
      `ags-apps` unit, updates the whole-unit link, and passes deploy coverage.
- [ ] Old in-tree source is deleted; docs record the new pin and decision.
- [ ] A GUI-free fake-runtime test covers the no-op and changed-palette paths.

## Dependencies

- `REQ-008` contract and template.
- `REQ-009`…`REQ-014` proven app cutovers.
- `dotfiles-runtime` manifest/invocation support.
- `ags-platform` provider replacement if live.
- `dotfiles-v3`/`dotfiles-provision` handling for the special `~/.config/ags`
  link.

## Evidence

- `bar/app.tsx` startup theme and widget construction.
- `bar/kit/widget.tsx` icon loading.
- `tickets/SPIKE-001-ags-refresh-patterns/ticket.md` bar row.
