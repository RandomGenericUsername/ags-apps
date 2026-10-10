---
id: REQ-003
title: "Migrate capture-tool"
kind: requirement
status: proposed
lane: 2
links:
  openspec: migrate-capture-tool
  bmad: none
worktree: none
branch: none
---

# Migrate capture-tool

## Requirement

Capture-tool depends on the platform: its `icon-registry.ts` copy is replaced by the platform `IconProvider`, and its theming routes through the `Theme` port. Its direct notification sends route through `Notifier`. The `bar_compact_controls` config becomes the first `Preferences` adapter.

Source: spine **AD-7**, **AD-11**, **AD-12**, **AD-13**; handoff iteration 6.

## Acceptance

- [ ] `src/gui-tools/capture-tool/lib/icon-registry.ts` is gone; the platform provider is used.
- [ ] `bar_compact_controls` is served through `Preferences` (owned file + monitor).
- [ ] Direct `Notify` sends route through `Notifier`.
