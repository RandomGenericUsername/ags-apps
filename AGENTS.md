# AGENTS.md — ags-apps operating contract

Canonical agent instructions for this repo. Claude (`CLAUDE.md` symlinks here), OpenCode, and all BMAD/OpenSpec skills must follow this.

## 1. Evidence rule (hard requirement)

No suggestion "in the air". Every technical claim, recommendation, or design decision must carry testable evidence — at least one of:

- **Doc evidence:** file path + line range, or commit SHA, or URL + quoted section.
- **Prototype evidence:** a script/command in-repo that runs and prints the validating output. State the exact command and observed result.
- **Test evidence:** `command run → result` (exit code + key output). Failing-as-expected counts if it validates the claim.

Format: any non-trivial claim gets an `Evidence:` line and a `Verify:` line (how to reproduce in one command). If evidence doesn't exist yet, say `Evidence: MISSING — run <X> to produce it` and do not present the claim as fact.

## 2. How we work here

- This repo holds the **AGS applications**: the status bar first, then notifications, capture-tool, hypr-pano, wallpaper-selector and the icon-color-mapping-editor.
- Every app **depends on `ags-platform`** (ports + shared adapters) and on `contracts`; **never app → app**.
- The bar is a thin consumer: capabilities + a default layout. The runtime provides assets and events; the bar renders. Presence is reactive state (`visible`), not a layout edit.
- Prefer executed output over recalled text. Read files, run commands, paste results.

## 3. OpenSpec + BMAD routing (via tickets)

- All work starts as a ticket in `tickets/` (`_template/`, vocab + rollup in `INDEX.md`, flow in `LIFECYCLE.md`). Triage with `/triage` (lanes in `tickets/_fixtures/router-lanes.md`).
- Broad scope (app architecture, UX, cross-app work) → BMAD. Only installed skills: `bmad`, `bmad-build`, `bmad-architecture`, `bmad-product-brief`, `bmad-spec` — say so when a step needs a missing skill instead of improvising.
- Bounded slices (one proposal + spec + design + tasks) → OpenSpec (`/opsx-propose`, `/opsx-apply`, `/opsx-archive`). Artifact rules in `openspec/config.yaml` restate this evidence rule per artifact.
- Never work on main: `scripts/worktree-guard.sh create <id> <slug>` scaffolds `ticket/<id>-<slug>` + worktree, aborts when dirty. Record worktree/branch in the ticket.
- Keep changes small, verifiable, committable. Never mix planning edits with implementation in one turn.

## 4. CI scope: stock runners only, typecheck is LOCAL

**Local is the authority.** CI exists to catch stock-runner regressions, not to reproduce the desktop stack.

- **Typecheck is a LOCAL gate.** Run `make <app>-typecheck` (e.g. `make bar-typecheck`, `make icme-typecheck`) before merging. It needs `ags` on PATH plus the Astal/GIR libraries and generates ~49 MB of machine-specific `.d.ts`, so it cannot run on a stock runner.
- **CI runs only stock-runner jobs** (`ubuntu-latest`): the pure-module tests (`make <app>-tests`), the drift gates, the capture-tool backend pytest suite, and the speedtest architecture gate. `.github/workflows/` contains no other kind of job.
- **No self-hosted typecheck jobs.** GitHub reports **0** registered runners for this repo (`gh api repos/RandomGenericUsername/ags-apps/actions/runners` → `total_count: 0`), so such jobs queued forever without ever reporting. They were removed; do not re-add one expecting a runner to exist.
- **No CI secrets for contracts.** `contracts` is **public**, so the drift jobs check it out with the default token (no `token:` override). The "Assert the canonical contract is present" step stays as a fail-fast guard for a missing checkout.

Evidence: `.github/workflows/*.yml` (all jobs `runs-on: ubuntu-latest`); `git log --oneline -- .github/workflows/`.

Verify: `grep -rn 'self-hosted\|CONTRACTS_READ_TOKEN' .github/workflows/` → no matches; `make gates-ci`.
