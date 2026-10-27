# Adversarial Consistency Review — Fourth Pass (Fix Verification)

- **Reviewer lens:** adversarial-consistency, final fix verification. Scope is limited to the three r3 blockers (N2/H3, H1, H2) and any **new** critical/high contradiction introduced by their fixes.
- **Target:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md` (draft, 2026-10-26, 559 lines), `.memlog.md`, `tickets/EPIC-002-apps-standalone-repos/ticket.md`, `tickets/REQ-008…REQ-016/ticket.md`, and `reviews/review-adversarial-r3.md`.
- **Date:** 2026-10-26
- **Shorthand:** `SPINE` = the target spine; `EPIC` = EPIC-002; `REQ008`/`REQ009`/… = those tickets; `PROVISION` = `dotfiles-provision`; `V3` = `dotfiles-v3`.

**Verdict: PASS — the three r3 blockers are closed; no new critical/high contradiction was introduced.**

The r3 mediums remain mediums; none became critical/high. The three fixes are textually complete in the spine and propagated to the tickets that matter for the pilot and the bar cutover.

---

## 1. Fix verification

### 1.1 N2/H3 — one program tuple, no per-cutover drift, legacy shortcut

**Status: RESOLVED.**

- `AD-31` now names a **single program tuple record**: `dotfiles-v3/dotfiles/provisioning/program-tuple.yaml`, naming the `ags-platform`, `contracts`, and `dotfiles-assets` tags. It is released once during adoption; a tuple bump is a program-wide revalidation event, never a per-cutover change (`SPINE:201-210`).
- `AD-32` step 2 now says the program tuple is the one released during adoption; a cutover releases only the app repo and, if its code changed, the engine/runtime. A platform/contracts/assets tuple bump is explicitly a separate program-wide event (`SPINE:227-230`). This removes the r3 per-epoch drift construction.
- The legacy monorepo exception is explicit: it is re-pinned to the same tuple and keeps its existing per-unit platform shortcut pointing at that tuple until removal; only standalone installs use the shared `<install>/apps/node_modules` ancestor (`SPINE:207-210`). This removes the r3 "legacy checkout outside the shared ancestor" contradiction.
- The Stack and conventions agree: exact tuple tags at the REQ-008 release, one `program-tuple.yaml` (`SPINE:357,367`). REQ-008 acceptance now requires the tuple to be released and pinned in `program-tuple.yaml`, with the monorepo re-pinned and its per-unit shortcut retained until removal (`REQ008:69-73`). EPIC's contract bullet includes the assets tuple (`EPIC:69-71`).

**Residual medium (not a new high):** the AD names the record but does not explicitly say the installer, runtime, and verify read it. `AD-34` still says the runtime validates manifests against "the program's `contracts` pin" (`SPINE:278-279`), while the brownfield runtime still has `CONTRACT_PIN` (`dbdc5b8`). The architecture is now single-source, but the implementation work should name those consumers and retire/derive `CONTRACT_PIN` from `program-tuple.yaml`. The tuple file also has no schema in `contracts`; add a small schema or validation step. These are implementation wiring, not a new architectural contradiction.

### 1.2 H1 — bar "no handler" versus universal handler verification/template/EPIC

**Status: RESOLVED.**

- `AD-32` step 5 now verifies `identity/manifest/ownership` on every surface, **plus the `palette-refresh` handler for live apps** (`SPINE:236-238`). The bar, `mode: restart`, is not required to have one.
- `AD-33` now says every app repo carries `AGENTS.md`, tickets, worktree guard, Makefile, CI, README, manifest, and tests; **live apps also carry the `palette-refresh` handler**. The template-conformance gate validates handler presence **for live mode** (`SPINE:257-261`). The bar repo can pass template conformance without a palette-refresh handler.
- `AD-36` still says every live app receives the handler and the bar has no handler and is `restart` (`SPINE:314-316`), which is now consistent with AD-32/AD-33.
- EPIC now says the bar gets its manifest, remains `restart`, and has no handler; the runtime is enabled after adoption (`EPIC:83-86`). REQ-008 acceptance says the bar has its manifest and remains `restart` with no handler (`REQ008:74-76`).
- The bar's existing `requestHandler` for popup-close/settings-close is not a `palette-refresh` handler, so the terminology is now unambiguous in context.

**Residual medium (not a new high):** the REQ-008 deliverable bullet still says "App repo template: … manifest, handler and a template-conformance gate" without qualifying handler for live mode (`REQ008:40-41`). The template may ship a handler file for live apps; the bar's app does not register it. Clarify "live-mode handler" in the deliverable, but it does not create two conforming deployments.

### 1.3 H2 — pilot one-command scaffold versus deferred generator

**Status: RESOLVED.**

- `AD-33` now says the pilot gate is "scaffold-to-green ≤ 30 min using the documented template copy (no generator required)" (`SPINE:264-265`).
- The Deferred item remains: the template fixture and conformance gate are required; an automated repo generator is deferred until the pilot proves the copy (`SPINE:537-538`).
- REQ-009's acceptance carries "scaffold-to-green ≤ 30 min" without the former "one command" phrase (`REQ009:68-69`). The pilot can use the documented copy and measure the gate; no generator is required, and the deferred generator is no longer in conflict.

**Residual medium (not a new high):** the "documented template copy" should be named as a REQ-008 acceptance artifact (the template README or a copy note) so the pilot's measurement is reproducible. REQ-008 acceptance currently names the template fixture, gate, and thresholds but not the copy documentation (`REQ008:83-84`). This is a documentation acceptance detail.

---

## 2. New critical/high check

**No new critical/high contradiction was introduced by the three fixes.**

Checked for the failure mode the r2/r3 reviews used — two units obeying every AD yet deploying incompatibly:

- **Tuple:** the per-cutover release loophole is gone; the legacy shortcut is explicitly same-tuple, not a second version. A V3 unit and an installer unit now both read the one released tuple. The only remaining ambiguity is which component reads `program-tuple.yaml`, which is a wiring/acceptance detail, not two different tuple values.
- **Handler:** a live app must have the handler; a restart app must not. AD-32, AD-33, AD-36, EPIC, and REQ-008 now agree on the bar. There is no remaining rule that requires a `palette-refresh` handler from the bar.
- **Pilot gate:** the gate no longer requires automation that the Deferred forbids. The pilot can copy the template manually/documented and measure; the generator remains a post-pilot option.

The only ticket-level residual is `EPIC:31` ("one program platform/contracts tuple") and `EPIC:151` ("Exact `ags-platform`/`contracts` program tuple tags") still omit `dotfiles-assets`, while `EPIC:69-71` includes it. This is documentation drift, not a new critical/high contradiction; the binding spine and REQ-008 include assets.

---

## 3. Residual mediums carried from r3 (not re-reviewed, unchanged)

These remain non-blocking and are recorded only so the pass is not mistaken for a claim that they are closed:

- N4: `colors.css` creation actor/order — state whether provisioning creates the symlink before the read-only seal or the link lives outside the tag (`SPINE:328-333`).
- N5: the exact icon artifact path is still a REQ-008 acceptance detail but is not in `REQ008` acceptance (`SPINE:544-545`).
- N9: `--include-dev` versus "foreign/dev instance … never refreshed" (`SPINE:104-108`); define the bar's bare `ags run` default (`ASSETS/configs/hypr/autostart.lua:19`; `bar/app.tsx:37`); scope enumeration to `config/ags*` as hardening.
- N11: launch-lock release point/bounded wait is undefined (`SPINE:151-153`).
- App-list seed M1/M2: clipboard pre-flipped before the pilot; bar entry lacks `instance`/`configDir`/`cutoverId` (`SPINE:397-419`).
- `wallpaper.state` removal in the adoption release; memlog still says "No retry"/"discovers running apps" (`.memlog.md:19,30`).
- Program-tuple consumer wiring/schema and the EPIC assets wording above.

---

## 4. Check performed

- Read the revised `SPINE` (559 lines), `EPIC-002`, `REQ-008`, `REQ-009`, `REQ-015`, and the r3 review.
- Grepped the revised spine and tickets for `program-tuple`, `handler`, `restart`, `generator`, and `one command`; verified the three fixes at the line ranges cited above.
- Confirmed the per-cutover tuple sentence is gone from `AD-32` step 2 and replaced by the program-wide rule (`SPINE:227-230`).
- Confirmed `AD-32`/`AD-33` handler requirements are live-only and the bar is explicitly no-handler in `AD-36`, EPIC, and REQ-008.
- Confirmed `AD-33` no longer says "one command" and the Deferred generator remains.
- No files were modified except this review.

---

## 5. Required change set

No freeze blockers. Before the first cutover, close the mediums in §3 — in particular:

1. Name `program-tuple.yaml` as read by the installer, runtime, and verify, and retire/derive the runtime `CONTRACT_PIN`; add a tuple schema or validation.
2. Add "live-mode handler" to the REQ-008 template deliverable and name the documented template copy in REQ-008 acceptance.
3. Align EPIC's triage/open-decision wording with the three-part tuple (include `dotfiles-assets`).
4. The r3 N4/N5/N9/N11 and seed/memlog items.

---

*End of review.*
