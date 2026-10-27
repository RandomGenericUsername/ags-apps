# Adversarial Consistency Review — Second Pass

- **Reviewer lens:** adversarial-consistency. The test is: construct two units one level down (an app repo, `dotfiles-runtime`, `dotfiles-v3`, `dotfiles-provision`, `ags-apps`) that each obey every AD to the letter, yet still build, deploy, or drive the desktop incompatibly.
- **Target:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md` (draft, 2026-10-26, 504 lines), `.memlog.md`, `tickets/EPIC-002-apps-standalone-repos/ticket.md`, `tickets/REQ-008…REQ-016/ticket.md`, and the prior reviews `reviews/review-adversarial.md` + `reviews/review-evidence.md`.
- **Codebase read (read-only):** `/home/inumaki/Development/dotfiles/{ags-apps,dotfiles-runtime,dotfiles-provision,dotfiles-v3,dotfiles-assets,contracts,ags-platform}`; AGS 3.1.0 CLI / 3.1.2 JS.
- **Date:** 2026-10-26
- **Shorthand:** `SPINE` = the target spine; `EPIC` = EPIC-002; `REQ008`/`REQ009`/… = those tickets; `RUNTIME` = `dotfiles-runtime`; `PROVISION` = `dotfiles-provision`; `V3` = `dotfiles-v3`; `ASSETS` = `dotfiles-assets`.

**Verdict: BLOCK — do not freeze and do not start the pilot (REQ-009).**

The revision genuinely closes most of the *spatial* contract holes: one program tuple is stated, the applied-appearance ledger exists, the cutover is an epoch with positive owner filters, the app-list schema is named, the clipboard rename and `mode` field are propagated through the tickets, manifest identity/discovery is defined, the AGS string transport is explicit, the runtime is the sole log emitter, the launch lock and safe restart are named, and the Theme provider replacement is promoted to a blocking prerequisite.

It is still not executable as one program. Two **critical** contradictions remain reachable with every written AD satisfied:

1. **The runtime switch is one release before any live app can answer `palette-refresh`.** AD-36 adopts only `app.manifest.json`; the currently deployed live apps have no request handler at all (or a handler that knows only `show`/`hide`/`popup-close`), and their cutovers are later. AD-27/AD-28 will record malformed-response failures for every unmigrated live app on the first palette change. AD-36's own “Prevents” claim (“a no-legacy runtime leaving unmigrated apps stale”) is false as written.
2. **The “one program tuple” rule is not migration-aware and has no no-drift rule.** The legacy `ags-apps` unit keeps its own `ags-platform` v0.2.0 per-unit shortcut while the new tuple (with the one-provider Theme fix) is installed at `apps/node_modules`; the runtime then refreshes legacy live apps through the old Theme adapter. Separately, AD-31 says every app repo pins the tuple “for its cutover” while AD-32 step 2 releases prerequisites per epoch and the Stack says one tuple set at REQ-008; two cutover epochs can therefore legitimately carry two tuples.

Several **high** contradictions were also introduced or left: `colors.css` is seeder-owned but lives inside the read-only tag; `icons.json`'s `dotfiles-assets` input is not in the tuple and its relocation is deferred to REQ-015, after the capture cutover; AD-27 says a transient surface may “defer” while `ok:true` means “applied”; AD-30 says a failed bar restart is retried next trigger while “if the bar is down … there is no hidden launch”; the ownership predicate covers launcher/autostart/XDG/source surfaces the app-list schema cannot name; the cutover can install/link a new tag before the old process stops; and the launch lock does not cover the on-demand launchers that also run `ags run`.

The direction is still right. The spine does not need a re-think of AD-25/AD-33. It needs one more revision focused on the migration window (adoption + legacy tuple) and a small set of ordering/data-model fixes before freeze.

---

## 1. Summary

| # | Finding | Severity | Primary ADs | Status after revision |
| --- | --- | --- | --- | --- |
| F1 | One shared platform/contracts tuple vs per-app pins | CRITICAL | AD-17, AD-31, AD-34, Stack | **Partial** — spatial split closed; migration window and tuple evolution open (N2) |
| F2 | One applied-appearance ledger + single-flight + failure recovery | CRITICAL | AD-28, AD-29 | **Mostly closed** — ledger/lock/recovery present; bar-down retry contradiction (N7), ledger schema medium (M6) |
| F3 | Cutover epoch, app-list schema, owner filters, prerequisites, stop/repoint/start, ownership predicate | CRITICAL | AD-31, AD-32 | **Partial** — epoch/list/filters/prereqs present; install-path ambiguity (N3), predicate data gap (N6), order/hot-swap + stop confirmation (N8) |
| F4 | Ticket alignment: clipboard rename, `mode` not `refresh`, no legacy, manifest adoption | CRITICAL | AD-26, AD-33, AD-35, AD-36 | **Open** — text aligned, adoption lacks handlers (N1); pilot gate has no thresholds (N12) |
| F5 | Manifest identity/discovery, bar via manifest | CRITICAL | AD-26, AD-27 | **Mostly closed** — identity/bar/invalid-manifest present; “valid manifest” enumeration and dev-instance identity (N9) |
| F6 | Installed-tag immutability, user state, colors/icons ownership | HIGH | AD-21, AD-37 | **Partial** — prose present; `colors.css` inside the tag (N4), icons source pin/relocation (N5) |
| F7 | AGS request string transport, exactly-once, timeout | HIGH | AD-27, AD-28 | **Closed** — string/exactly-once/after-apply/busy/5 s explicit; process-group/late completion medium (M7) |
| F8 | Runtime-owned structured logs / `reload_failures` | HIGH | AD-28 | **Mostly closed** — emitter/fields/structured failures/order present; CLI exit code/sink/phase/discovery index (M4, M8) |
| F9 | Link swap vs running code | HIGH | AD-31, AD-32 | **Partial** — stop/repoint/start + “never hot-swapped” present; installer stop and list-flip window (N8) |
| F10 | Shared AGS launch lock | HIGH | AD-25, AD-28 | **Partial** — per-user lock named; on-demand launchers not covered (N11) |
| F11 | Safe restart procedure and recovery | HIGH | AD-28, AD-30 | **Partial** — wait/fail/report present; bar-down retry (N7), new-instance ownership check missing (N8) |
| F12 | Theme provider replacement as a hard gate | HIGH | AD-13, AD-27, AD-34 | **Closed for new repos; open for the migration window** — legacy apps stay on the old provider (N2); child-ticket removal/tests medium (M11) |
| F13 | Live state preservation | HIGH | AD-26, AD-27, AD-30 | **Partial** — non-destructive rule + test present; “defer” vs `ok:true` (N10), no transient flag (M3), atomicity medium (F13) |
| N1 | Manifest adoption lacks `palette-refresh`; runtime switch breaks every unmigrated live app | **CRITICAL** | AD-26, AD-27, AD-36 | New |
| N2 | One tuple is not migration-aware; legacy unit keeps a second platform/Theme; per-cutover tuple drift | **CRITICAL** | AD-31, AD-34, AD-32 | New/residual F1 |
| N3 | Install path `<install>/apps/<app>/<tag>` vs seed `apps/capture-tool/<tag>`; `capture` vs `capture-tool` | **HIGH** | AD-31 | New |
| N4 | `colors.css` is seeder-owned but inside the read-only tag | **HIGH** | AD-37 | Residual F6 |
| N5 | `icons.json` input (`dotfiles-assets`) is not in the tuple; relocation after capture cutover | **HIGH** | AD-21, AD-37 | Residual F6 |
| N6 | Ownership predicate covers surfaces the app-list schema cannot name | **HIGH** | AD-31, AD-32 | Residual F3 |
| N7 | “Failed restart retried next trigger” vs “bar down → no hidden launch” | **HIGH** | AD-26, AD-29, AD-30 | Residual F2/F11 |
| N8 | Cutover list flip/install before stop; “stops” is not a confirmed quit; no new-instance ownership check | **HIGH** | AD-28, AD-32 | Residual F3/F9/F11 |
| N9 | Discovery “links that contain a valid manifest” vs invalid-manifest failure; dev instance can be refreshed | **HIGH** | AD-26 | Residual F5 |
| N10 | AD-27 “preserve it or defer” vs “`ok:true` means applied” | **HIGH** | AD-27 | Residual F7/F13 |
| N11 | Launch lock does not cover on-demand launchers | **HIGH** | AD-28 | Residual F10 |
| N12 | Pilot exit gate has no thresholds; template is defined by the pilot it governs | **HIGH** | AD-33 | New/program gate |
| M1 | App-list seed pre-flips clipboard to `standalone` before REQ-009 | MEDIUM | AD-31, AD-32 | New |
| M2 | Bar has no explicit `instanceName`; identity rule needs the effective default | MEDIUM | AD-26 | Residual F5 |
| M3 | No transient obligation field; `holdsUnsavedState` is only a boolean | MEDIUM | AD-26, AD-27 | Residual F13 |
| M4 | CLI exit code on app failure is undefined | MEDIUM | AD-28 | Residual F8 |
| M5 | `contracts` “tag/commit” equality is undefined | MEDIUM | AD-34 | Residual F1 |
| M6 | Ledger schema not in `contracts`; `runId` vs operation id | MEDIUM | AD-29, AD-34 | Residual F2 |
| M7 | Timeout cancellation/process group and late-completion semantics | MEDIUM | AD-27 | Residual F7 |
| M8 | Log sink, `phase`, `discoveryIndex` undefined | MEDIUM | AD-28 | Residual F8 |
| M9 | `ags-apps` archive at last app move vs REQ-016 final cutover | MEDIUM | AD-32, AD-33 | New |
| M10 | `BUG-003` is a SPIKE section, not a ticket; REQ-015 depends on it | MEDIUM | AD-28, AD-30 | New |
| M11 | REQ-012/013/014 do not explicitly remove the `wallpaper.state` palette path or add provider-count tests | MEDIUM | AD-27 | Residual F12 |
| M12 | Repo naming `ags-<app>` contradicts `ags-capture-tool` | MEDIUM | Conventions | New (supports N3) |
| M13 | Clipboard daemon `clipboard` namespace vs app `ags-clipboard` config | MEDIUM | AD-35, AD-37 | Residual F4/F6 |
| M14 | Pure handler module/shared fixtures not adopted | MEDIUM | AD-33 | Residual F15 |

The two critical findings are detailed in §4; the F1–F13 verification is in §3. The two-unit constructions are in §5.

---

## 2. What the revision actually closed

Credit where due; these are real, testable tightenings:

- **F1 spatial split.** AD-31 now states one `ags-platform` pin and one `contracts` pin owned by `V3`, one shared `<install>/apps/node_modules/ags-platform`, and no `node_modules`/vendored platform in an app tag (`SPINE:188-192`). AD-34 binds app CI to “the exact `ags-platform` tag used by the install” and requires equality with the program tuple at the install gate (`SPINE:246-248`). The old “each app repo pins its own” hole is gone for the seven new repos.
- **F2 ledger.** AD-29 now names one persisted applied-appearance ledger under `$XDG_STATE_HOME/dotfiles/`, one writer, atomic write after both lanes, a per-app map, per-app retry of failed apps, icons-only/wallpaper-set coverage, a single runtime operation lock, and the “pointer moved during the operation” rule (`SPINE:150-167`). This is no longer two independent last-hash files.
- **F3 cutover.** AD-32 now defines a six-step epoch, a positive `owner: legacy|standalone` filter in both roles, engine/runtime/platform/contracts prerequisites, stop/repoint/start, end-to-end test, launcher/autostart/assets update, and a fake-app fixture with both rollback directions (`SPINE:200-221`). AD-31 names `V3/dotfiles/provisioning/apps.yaml`, a `contracts` schema, and the field list (`SPINE:193-197`). The absolute “no `ags-apps` pin” is correctly scoped to program completion (`SPINE:198`).
- **F4 text.** REQ-009 is now `ags-clipboard` / `clipboard` / `ags-clipboard` / `clipboard-window` / `clipboard-ui`, `mode: live`, with the daemon data migration (`REQ009:23-37`). EPIC-002 no longer says “names stay identical” or “no manifest = legacy restart”; it says manifests are adopted before the runtime switch and no legacy runtime path exists (`EPIC:77-90`). REQ-008 includes the adoption and the `wallpaper.state` note (`REQ008:24-27,43-45`).
- **F5 identity/discovery.** AD-26 now requires `manifest.instance == app.tsx instanceName == ags list name`, `manifest.configDir == config-link basename`, one lowercase segment, deployed-link discovery intersected with `ags list`, dedupe by instance, `--include-dev`, the bar through `config/ags`, and a structured failure for missing/invalid manifests (`SPINE:89-107`).
- **F6 prose.** AD-37 states installed tags are read-only, writable state lives under XDG, `colors.css` has one owner (runtime seeder), `icons.json` has one producer (app repo generated from pinned assets), the bar's `wifi-speedtest` state moves before REQ-015, and rollback is a link repoint plus the same external state (`SPINE:282-295`).
- **F7 wire.** AD-27 now says a single JSON-encoded **string**, exactly once, after the refresh fully completes, object literals forbidden, malformed/empty/extra/non-zero/5 s timeout failure, `ok:true` means applied, re-entrant or busy, non-destructive, and `wallpaper.state` no longer drives palette (`SPINE:109-128`).
- **F8 logs.** AD-28 now makes the runtime the sole emitter of one JSON Lines record per app per operation with `runId`, identity, mode, phase, hash, timings, argv, exit, response, error, timeout, discovery index; `reload_failures` becomes `{app, instance, mode, reason, detail}` with a string view; invalid manifests are included; summary order is ascending discovery index (`SPINE:130-148`).
- **F9/F10/F11/F12/F13 direction.** Stop/repoint/start plus “never hot-swapped” (`SPINE:212-221`), a per-user AGS launch lock (`SPINE:146-147`), the 5 s D-Bus/process release wait (`SPINE:143-145`), the Theme one-provider replacement as blocking (`SPINE:34,56,461`; `REQ008:56-57`), and the non-destructive live rule + state-class test (`SPINE:122-125`) are all real improvements.

The remaining findings are not a rejection of that direction. They are places where the new text is still two-valued or one migration step short.

---

## 3. F1–F13 verification

### F1 — One shared platform/contracts tuple vs per-app pins

**Status: PARTIAL. The spatial split is closed; the migration window and tuple evolution are not.**

**Closed:** For the seven new app repos, AD-31/AD-34 now make the tuple single-valued and forbid a vendored platform in the tag. That is the core F1 fix, and it is testable: install one shared shortcut, run `ags bundle` in an app whose tag contains no `node_modules`, and verify the resolved `ags-platform` realpath.

**Open:**

1. **The legacy unit is a second tuple.** The current `ags_apps` role pins `ags_apps_platform_version: v0.2.0` and creates `<unit>/node_modules/ags-platform` (`PROVISION/ansible/roles/ags_apps/vars/main.yml:314-336`). The new topology creates `<install>/apps/node_modules/ags-platform` at the program tuple. AD-31 says “exactly one shared” shortcut and “one `ags-platform` pin” (`SPINE:188-192`), but AD-32 step 6 keeps the old role/pin until the last app moves (`SPINE:216-217`). During the entire migration, the install has two platform pins and two Theme implementations: legacy apps resolve v0.2.0, new apps resolve the program tuple. The runtime switch (AD-36) is before the app cutovers, so the runtime invokes legacy live apps through the old `theme.apply()` adapter — the exact provider-accumulation hazard AD-13/the Theme gate exists to remove. This is not a wording nit; it is the F1/F12 class inside the migration window.
2. **Per-cutover tuple drift.** AD-31 says every app repo builds/tests “against that exact tuple **for its cutover**” (`SPINE:190-192`). AD-32 step 2 says “the engine/runtime/**platform/contracts** prerequisites are released and pinned” per epoch (`SPINE:206-208`). The Stack says one tuple per install, exact tags set at REQ-008 release, then pinned by every app repo (`SPINE:322`). These are three different rules. If the tuple is immutable from REQ-008, per-epoch “platform/contracts released” is wrong; if the tuple can move at an epoch, the one shared ancestor and AD-34’s equality gate have no rule for the already-cut-over apps. Two app repos can legitimately pin T1 and T2; the deployment can install only one. This is the original F1 incompatibility moved from “per-app pins” to “per-epoch pins.”
3. **Where the tuple lives is not single-valued.** `V3` owns the pin, but the install has `installer.pin` (`v0.1.16`), `cli-tools.yaml` (`dotfiles-runtime v0.2.2`), the `ags_platform` role (`v0.2.0`), and the runtime `CONTRACT_PIN` (`dbdc5b8`). The app-list schema does not include `platformTag`/`contractsTag`; the tuple is a prose rule spread over four files. A verify unit cannot check “equality with the program tuple” without a single record.

**Evidence:** `SPINE:182-198,200-221,238-251,322`; `PROVISION/ansible/roles/ags_apps/vars/main.yml:314-336`; `PROVISION/ansible/roles/ags_platform/vars/main.yml:27-42`; `V3/dotfiles/provisioning/installer.pin` (`v0.1.16`); `V3/dotfiles/provisioning/cli-tools.yaml:30-32` (`v0.2.2`); `RUNTIME/src/runtime/adapters/CONTRACT_PIN` (`dbdc5b8`); `contracts/schemas/` contains only `current`, `history`, `last-converged`, `meta` — no app-list/ledger schema.

**Verify:** `grep -n 'ags_apps_platform_version\|ags_apps_resolution_shortcut' PROVISION/ansible/roles/ags_apps/vars/main.yml; cat V3/dotfiles/provisioning/installer.pin; sed -n '27,42p' PROVISION/ansible/roles/ags_platform/vars/main.yml; cat RUNTIME/src/runtime/adapters/CONTRACT_PIN`. Then construct the two-unit pair in §5.1.

**Fix:** State the tuple is immutable for the program; AD-32 step 2 may release a new **engine/runtime** but not a new platform/contracts tuple without a program-wide epoch. Add `platformTag`/`contractsTag` (and `assetsTag`) to the app-list schema or a single `program-tuple.yaml` that the installer/runtime/verify all read. For the migration window, either (a) rebase `ags-apps` on the same program tuple in the adoption release, or (b) explicitly exempt the legacy unit and do not invoke legacy live apps until they are rebased/cut over. The current text does neither.

---

### F2 — One applied-appearance ledger + single-flight + failure recovery

**Status: MOSTLY CLOSED. The ledger/lock/recovery are present; one recovery contradiction and one schema gap remain.**

**Closed:** AD-29’s ledger is one file, one writer, atomic after both lanes, with per-app `{instance, mode, status, appearanceHash, reason}`, a per-app retry rule for failed apps, icons-only/`wallpaper set`/`reconcile` sharing the ledger, a single operation lock across daemon/CLI/`wallpaper set`, an older-operation-never-writes-newer rule, and the pointer-moved guard (`SPINE:150-167`). This is a credible fix for the original two last-hash files and permanent-failure problem.

**Open:**

- **Bar down vs “running app.”** AD-29 says “A running app is refreshed when … its last result is failed” (`SPINE:161-162`). AD-26’s discovery intersects deployed links with `ags list` (`SPINE:100-103`), so a bar that is down is not discovered. AD-30 says a failed restart is “retried on the next trigger” and also “If the bar is down, the operation reports it; there is no hidden launch” (`SPINE:178-180`). The next trigger cannot both retry a down bar and not launch it. This is N7.
- **Ledger schema.** AD-34 lists the schemas `contracts` owns (`SPINE:242-245`); the ledger schema is not among them. AD-29 allows “or a schema-versioned extension of an existing state file” (`SPINE:155-156`). The existing `last-converged.schema.json` has `additionalProperties: false` and requires `input_hash`; a unit that extends it must bump the version and keep the daemon backstop working, and a unit that creates a new file must define a schema. Both are “a ledger.” Two runtimes can read each other’s file differently. This is M6, not a freeze blocker, but it should be decided before the first cutover.
- **Operation id vs runId.** AD-29 records an “operation id”; AD-28 records `runId` (`SPINE:134-139`). If they are not the same value, the ledger cannot be joined to the per-app logs. State the equality.

**Evidence:** `SPINE:150-167,178-180`; `contracts/schemas/last-converged.schema.json:1-17`; `RUNTIME/src/runtime/adapters/converge_backstop.py:42-48,85-100`; `RUNTIME/src/runtime/application/converge.py:73-83`; `RUNTIME/src/runtime/application/reconcile.py:333-354`.

**Verify:** `sed -n '150,167p' SPINE; cat contracts/schemas/last-converged.schema.json`. Then resolve the down-bar path in N7.

---

### F3 — Cutover epoch, app-list schema, owner filters, prerequisites, stop/repoint/start, ownership predicate

**Status: PARTIAL. The epoch and owner filter are real; the install-path, predicate data, ordering, and stop semantics are not single-valued.**

**Closed:**

- The app list is named (`V3/dotfiles/provisioning/apps.yaml`), schema-owned by `contracts`, with `app`, `owner: legacy|standalone`, repo/tag, config link, instance, config dir, optional bin link, bar palette pointer, launch/autostart policy, cutover id (`SPINE:193-197`).
- The old role filters `legacy`, the new role filters `standalone`, so the old-role deny-list problem is structurally replaced by a positive owner split (`SPINE:209-212,369-370`).
- Engine/runtime/platform/contracts prerequisites are in the epoch, not implicit (`SPINE:206-208`).
- Stop/repoint/start is in the epoch, and “A config link is never hot-swapped under a running process” is stated (`SPINE:212-221`).
- The ownership predicate lists source checkout, spine link, XDG link, bin link, launcher, autostart entry, running process, and D-Bus name (`SPINE:218-220`).
- The absolute “no `ags-apps` pin” is now “at program completion” (`SPINE:198`).

**Open:**

- **Install-path ambiguity.** AD-31 says `<install>/apps/<app>/<tag>/`; the structural seed places capture at `<install>/apps/capture-tool/<tag>/` and links `config/ags-capture -> ../apps/capture-tool/<tag>` (`SPINE:187-190,330-348`). The app map says app `capture`, repo `ags-capture-tool` (`SPINE:436`). The app-list field `app` is the manifest app id (`capture`), not the repo stem (`capture-tool`). A `V3` unit deriving the path from `app` installs `apps/capture/<tag>`; a provisioning unit following the seed installs `apps/capture-tool/<tag>`. Both obey AD-31. The link dangles or the verify fails. This is N3, and it is a concrete build/deploy incompatibility, not a naming preference.
- **Ownership predicate data gap.** The list has a `launch/autostart policy`, not launcher/autostart **identities**. It has no `xdgLink`, `sourceDir`, or `expectedLauncher`/`autostartEntry` field. The verifier can derive the XDG link (`~/.config/<configLink>`), source (`<install>/apps/<app>/<tag>` for standalone; the legacy unit for legacy), and D-Bus name (`io.Astal.<instance>`), but not the launcher/autostart names. A schema-valid list with `launch: on-demand` lets the verifier pass while an old `hypr-pano-ui` launcher/autostart entry remains. This is N6; the original F3 “exactly one owner” finding is still open for two of the eight surfaces.
- **Ordering/hot-swap.** Step 3 flips the list; the new generic role then installs/links the new tag. Step 4 says the installer stops the old instance, repoints, starts. The seed and mermaid show the flip/install (C/D) before the stop/repoint (E) (`SPINE:209-215,419-425`). If the new role links at step 3 while the old process is still running, the config link is hot-swapped under it, violating the last sentence of AD-32. If the new role does not link until step 4, the step is not “the generic role installs” and the installer owns linking. The epoch needs an explicit install-only phase and a link phase. This is N8 (ordering).
- **Stop is not a confirmed quit.** AD-32 step 4 says “stops the old app instance” but does not reference AD-28’s 5 s D-Bus/process release wait. The current `AgsReloader` calls `ags quit`, treats exit 0 as delivered, and launches immediately (`RUNTIME/.../ags_reloader.py:205-238`). An installer that copies that behavior “stops” the app and hot-swaps the link during teardown. N8.
- **Pilot gate.** The epoch is conditional on the REQ-009 exit gate, but the gate has no thresholds (N12).

**Evidence:** `SPINE:182-221,330-348,369-370,419-425,432-440`; `PROVISION/ansible/roles/ags_apps/vars/main.yml:109-235` (current `capture-tool`/`hypr-pano` unit dirs); `PROVISION/ansible/roles/gui_tools/tasks/main.yml:184-196`; `RUNTIME/src/runtime/adapters/ags_reloader.py:205-238`.

**Verify:** `sed -n '187,221p' SPINE; sed -n '330,348p' SPINE; sed -n '432,440p' SPINE`; compute `apps/<app>/<tag>` for `app: capture` and compare with the seed's `apps/capture-tool/<tag>`. Then run the fake-app fixture with a stale launcher/autostart entry; the current list schema has no field to reject it.

---

### F4 — Ticket alignment: clipboard rename, `mode` not `refresh`, no legacy, manifest adoption

**Status: OPEN. The names/mode/no-legacy text are aligned; the adoption is manifest-only and therefore cannot be enabled before the app cutovers.**

**Closed:**

- REQ-009 uses the new clipboard names, `mode: live`, `holdsUnsavedState: false`, and the daemon data migration (`REQ009:23-37,50-69`). The old `hypr-pano` names appear only as migration-source evidence and in the “no old name remains” acceptance.
- EPIC-002 no longer says “names stay identical” or “no manifest = legacy restart”; it says manifests are adopted before the runtime switch and no legacy runtime path exists (`EPIC:77-90,96-99`).
- REQ-008 includes the manifest adoption and the `wallpaper.state` contract note (`REQ008:24-27,43-45`).
- All seven child tickets use `mode`, not `refresh:`; the grep is clean (`tickets/REQ-009…REQ-015`).
- The pilot is `ags-clipboard`, not `hypr-pano`; AD-33/REQ-009 agree.

**Open — the critical one:** AD-36 says “every currently deployed app — including the bar and the still-monorepo apps — receives `app.manifest.json` in its deployed config dir,” and “the runtime switch is one release after that adoption” (`SPINE:268-280`). It does **not** say those apps receive a `palette-refresh` handler. The current tree has `requestHandler` only in `bar/app.tsx:52` and `hypr-pano/app.tsx:33`; notifications, capture, wallpaper-selector, icme, and btop have none (`grep -n 'requestHandler' ags-apps/*/app.tsx`). Hypr-pano's handler knows `show`/`hide`/`toggle`/`popup-close` and returns `"ok"` or `"unknown request: ..."` (`ags-apps/hypr-pano/lib/requests.ts:40-53`); the bar's handler knows `popup-close`/`settings-close`/debug commands (`ags-apps/bar/app.tsx:52-80`). AGS returns `instance "X" has no request handler implemented` for the other apps (`/usr/share/ags/js/lib/gtk4/app.ts:272-276`). AD-27 treats that as a malformed/non-JSON failure; the app is stale. The runtime switch is before REQ-009's pilot handler and before REQ-010–REQ-014's handlers. This is N1; it is a program-sequencing contradiction, not a wording issue.

**Also open:** the pilot exit gate is the conditional basis for the whole seven-repo program, but it has no numeric/boolean thresholds (“repo creation, CI/release overhead, install, rollback, one-owner cutover and measured cost” — `REQ009:67-69`; `SPINE:232-236`). A pilot can “pass” arbitrarily. N12. `BUG-003` is a SPIKE-001 section, not a ticket; REQ-015 depends on it (`REQ015:35,62`; `tickets/SPIKE-001...:308`). M10.

**Evidence:** `SPINE:268-280`; `REQ008:43-45`; `REQ009:39-44,67-69`; `EPIC:77-90`; `ags-apps/bar/app.tsx:52-80`; `ags-apps/hypr-pano/app.tsx:33-39`; `ags-apps/hypr-pano/lib/requests.ts:40-53`; `/usr/share/ags/js/lib/gtk4/app.ts:272-276`; `grep -n 'requestHandler' ags-apps/{notifications,capture-tool,wallpaper-selector,icme,btop-theme-studio}/app.tsx` → no matches.

**Verify:** `grep -n 'requestHandler' ags-apps/*/app.tsx; sed -n '272,276p' /usr/share/ags/js/lib/gtk4/app.ts; sed -n '39,44p' tickets/REQ-009-migrate-clipboard-standalone/ticket.md`. Then start the current notifications app and run `ags request palette-refresh deadbeef -i notifications`; it exits 0 with the no-handler string, not the required JSON.

---

### F5 — Manifest identity/discovery, bar via manifest

**Status: MOSTLY CLOSED. The identity tuple, deployed-link discovery, bar path, and invalid-manifest failure are present; two discovery contradictions remain.**

**Closed:**

- AD-26 now requires `manifest.instance == app.tsx instanceName == ags list name`, `manifest.configDir == deployed config-link basename`, one lowercase segment (`SPINE:94-100`).
- Discovery is deployed links under `<install>/config` + `ags list`, dedupe by instance, `--include-dev` for worktrees, bar through `config/ags` (`SPINE:100-106`).
- Missing/invalid manifest is a structured failure, never a silent no-op or a restart (`SPINE:105-107`); AD-28 includes invalid-manifest entries in `reload_failures` (`SPINE:140-142`).
- The app map and app-list seed are consistent for clipboard/bar/notifications/selector/icme/btop; capture is the exception (N3).

**Open:**

- **“Links that contain a valid manifest” vs “invalid manifest is a failure.”** The discovery sentence says the runtime discovers links “that contain a valid manifest” (`SPINE:100-102`). An invalid manifest link is then not in the discovered set, so no failure entry is produced. The next sentence says missing/invalid is a structured failure. A literal runtime B enumerates valid manifests and silently drops the invalid app; runtime A enumerates all links and emits a failure. Both can cite AD-26. This is N9; the fix is one sentence: enumerate all deployed links, validate each, invalid → failure entry and exclude from refresh.
- **Dev instance identity.** The runtime reads the deployed manifest and intersects by instance name, but it does not verify that the running process's loaded config dir/realpath equals the deployed link target. A developer starts a worktree instance with the same `instanceName` (AD-33 encourages worktrees); `ags list` shows the name; the runtime sends `-i <instance>`; the request reaches the worktree app. The “dev/worktree instances are ignored unless `--include-dev`” claim (`SPINE:103-104`) is not enforceable from `ags list` alone. This is the original F5 wrong-instance class, narrower but still schema-valid. The fix: verify the running process's `-d`/cwd/realpath against the deployed link target (or get AGS to expose it); a mismatch is a structured failure/ignored dev instance.
- **Bar default instance.** The bar's `app.tsx` has no explicit `instanceName` (`ags-apps/bar/app.tsx:37`; `grep -n 'instanceName' ags-apps/bar/app.tsx` only finds `.d.ts`). The effective name is AGS's default `ags`. The identity rule should say “effective instance name (default `ags` when omitted)” or the bar's CI will fail a literal property grep. M2.

**Evidence:** `SPINE:89-107,140-142`; `ags-apps/bar/app.tsx:37`; `ags-apps/*/app.tsx` instance names; `RUNTIME/src/runtime/adapters/ags_reloader.py:110-148` (current `/proc` discovery; the revision replaces it, but shows why `ags list` alone does not give a config dir); `ags list --help`.

**Verify:** `sed -n '89,107p' SPINE; grep -n 'instanceName' ags-apps/*/app.tsx; grep -n 'instanceName' ags-apps/bar/app.tsx | grep -v '@girs'`. Then start a worktree notifications instance and the deployed one; `ags list` shows the same name; the runtime cannot tell which config dir is loaded.

---

### F6 — Installed-tag immutability, user state, colors/icons ownership

**Status: PARTIAL. The ownership rules are stated; the paths they govern contradict immutability and the icon source is not program-pinned.**

**Closed:**

- AD-37 states installed tags are read-only, writable user state is under XDG, `colors.css` has one owner (runtime seeder), `icons.json` has one producer (app repo generated from pinned `dotfiles-assets`), provisioning verifies and never writes, the bar's `wifi-speedtest*.json` moves before REQ-015, a tag-bump test is required, and rollback is a link repoint plus external state (`SPINE:282-295`).
- The app-list seed and app map carry the bar palette pointer and the per-app install paths; the current two-writer `colors.css` and `compositor_configs` icons paths are at least named as targets.

**Open:**

- **`colors.css` is inside the tag.** The current consumer pointer is `<install>/config/ags/colors.css` (`RUNTIME/src/runtime/adapters/consumer_path_spec.py:48-57`), and `config/ags` is the link to `<install>/apps/bar/<tag>`. The seeder repoints that path (`RUNTIME/src/runtime/adapters/seeder.py:776-796`), and provisioning creates the same `<unit>/bar/colors.css` link (`PROVISION/ansible/roles/ags_apps/tasks/main.yml:256-267`). AD-37 says the tag is read-only and the seeder is the one owner. On a read-only tag the seeder gets `EACCES`/`EROFS`; if it succeeds, the tag was not read-only. The revision says “one owner” but not “the pointer lives outside the tag.” This is N4; it is the original F6 path contradiction, still live.
- **`icons.json` input is not program-pinned.** AD-37 says the app repo generates the artifact from “the pinned `dotfiles-assets` source” (`SPINE:290-292`), but the program tuple (AD-31/AD-34/Stack) has no `dotfiles-assets` tag. The app repo's CI can pin `assetsA`, provisioning's `<install>/icon-mappings/icons.yaml` can be `assetsB`; both obey “pinned,” the bytes differ, and provisioning's byte-equality verify fails. The current `compositor_configs` role writes `<install>/config/ags/icons.json` and `<install>/config/ags-capture/icons.json` (`PROVISION/ansible/roles/compositor_configs/vars/main.yml:210-219`, `tasks/main.yml:101-115`). The deferred “icons artifact relocation … REQ-015 prerequisite” (`SPINE:485-486`) is after the capture cutover (REQ-011), so capture cannot satisfy AD-37 at its cutover. This is N5; both are high.
- **Read-only enforcement.** AD-37 does not say how the tag is made read-only (permissions, ownership, `chattr`), who does it, or how rollback to an older tag preserves the mode. A tag is a git checkout; a `git checkout`/`git clean` by a provisioning rerun can write into it. The rule needs an enforcement/test, not just an adjective.

**Evidence:** `SPINE:282-295,485-486`; `RUNTIME/src/runtime/adapters/consumer_path_spec.py:48-57`; `RUNTIME/src/runtime/adapters/seeder.py:776-796`; `PROVISION/ansible/roles/ags_apps/tasks/main.yml:256-267`; `PROVISION/ansible/roles/compositor_configs/vars/main.yml:210-219`; `PROVISION/ansible/roles/compositor_configs/tasks/main.yml:101-115`; `EPIC:77-90` (capture before bar).

**Verify:** `readlink -f ~/.config/ags/colors.css; readlink -f <install>/apps/bar/<tag>/colors.css` (same path); `chmod -R a-w <install>/apps/bar/<tag>` then run `dotfiles-runtime reconcile`; the seeder's repoint fails. `grep -n 'icons.json' PROVISION/ansible/roles/compositor_configs/{vars,tasks}/main.yml`.

---

### F7 — AGS request string transport, exactly-once, timeout

**Status: CLOSED. The wire contract is now explicit and matches the AGS transport.**

**Closed:** AD-27 says a single JSON-encoded **string** on stdout, exactly once, after full completion; `res(JSON.stringify({ok:true}))` / `res(JSON.stringify({ok:false,error:"..."}))`; object literals forbidden; malformed/empty/extra/non-zero/5 s timeout failure; `ok:true` means applied, not scheduled; re-entrant or `{"ok":false,"error":"busy"}`; non-destructive; `wallpaper.state` is progress/UI only (`SPINE:113-128`). AD-28 adds the 5 s lane timeout (`SPINE:135-137`).

**Residual (medium):** AD-27 does not say the runtime kills the `ags request` process group on timeout, records the timeout, and does not treat a late handler completion as success. AGS has no built-in timeout and `subprocess.run(timeout=5)` kills only the CLI; a handler that completes after the timeout can still mutate palette state. The handler's re-entrancy/busy rule limits overlap, but a timed-out handler is not “another refresh in progress” if the app has already released its busy flag. Add the process-group kill and the late-completion rule to the runtime contract. M7.

**Evidence:** `SPINE:113-128`; `/usr/share/ags/js/lib/gtk4/app.ts:272-282`; `/usr/share/ags/js/lib/app/dbus.ts:7`; `ags request --help` (no timeout flag); current handlers `res("ok")` (`ags-apps/hypr-pano/lib/requests.ts:40-53`).

**Verify:** `sed -n '272,282p' /usr/share/ags/js/lib/gtk4/app.ts; sed -n '1,12p' /usr/share/ags/js/lib/app/dbus.ts; ags request --help`. A fake handler `res({ok:true})` fails D-Bus marshalling; `res(JSON.stringify({ok:true}))` returns the JSON. A handler that returns without `res` blocks until the caller's timeout.

---

### F8 — Runtime-owned structured logs / `reload_failures`

**Status: MOSTLY CLOSED. The emitter and failure shape are fixed; the CLI result and sink are not.**

**Closed:** The runtime is the sole emitter (`SPINE:136-139`); one JSON Lines record per app per operation with `runId`, app, instance, config dir, mode, phase, appearance hash, start/end, duration, argv, exit code, parsed response, error, timeout, discovery index; app logs separate; `reload_failures` is a structured list `{app, instance, mode, reason, detail}` with a string view; invalid-manifest entries included; summary order ascending discovery index (`SPINE:130-148`). This fixes the “every app emits” impossibility and the string-list `reload_failures` mismatch (`RUNTIME/src/runtime/application/reconcile.py:81,333-354`; `ags-apps/notifications/ui/NotificationsWindow.tsx:361-362`).

**Residual (medium):** AD-28 does not define the CLI exit code. The current V3 doc says the command exits non-zero for `reload_failures` (`V3/docs/ags-restart-vs-live-theme-refresh.md:60`). A conforming runtime A exits 0 when the palette was applied even if an app failed; runtime B exits 1. Keybinds/scripts see different results. Define one: recommend 0 when the operation completed (palette applied), non-zero only for operation-level failure, with app failures in `reload_failures`; or match the current doc and state it. Also define the log sink (journald/file) and the exact `phase`/`discoveryIndex` derivation; “discovery index” is otherwise `iterdir()` order. M8.

**Evidence:** `SPINE:130-148`; `RUNTIME/src/runtime/application/reconcile.py:81,333-354`; `ags-apps/notifications/ui/NotificationsWindow.tsx:361-362`; `V3/docs/ags-restart-vs-live-theme-refresh.md:60`.

**Verify:** `sed -n '130,148p' SPINE; sed -n '55,62p' V3/docs/ags-restart-vs-live-theme-refresh.md`; run a failing fake app and inspect the CLI exit code and the notification card.

---

### F9 — Link swap vs running code

**Status: PARTIAL. The stop/repoint/start rule and the no-hot-swap sentence are present; the list-flip/install order and the installer's “stop” are not safe.**

**Closed:** AD-32 step 4 says the installer stops the old instance, repoints the link, starts the new instance, and verifies identity/manifest/handler (`SPINE:212-215`); the last sentence says a config link is never hot-swapped under a running process (`SPINE:221`). The fake-app fixture is required to prove both directions (`SPINE:220-221`).

**Open:** The epoch order is list flip → new role installs → stop/repoint/start (`SPINE:209-215`; mermaid `SPINE:419-425`). If the new role links at step 3, the old process is still running; if it does not, the “generic role” is not doing the install AD-31 describes. And “stops” is not a confirmed quit; the current reloader calls `ags quit` and launches on exit 0 without waiting (`RUNTIME/.../ags_reloader.py:205-238`). The safe stop procedure is AD-28's 5 s D-Bus/process wait (`SPINE:143-145`), but AD-32 does not reference it. This is N8. It is a direct violation of the “never hot-swapped” sentence by a conforming installer.

**Evidence:** `SPINE:209-221,419-425`; `RUNTIME/src/runtime/adapters/ags_reloader.py:205-238`; `PROVISION/ansible/roles/gui_tools/tasks/main.yml:184-196` (current start-if-down, no confirmed stop).

**Verify:** `sed -n '209,221p' SPINE; sed -n '205,238p' RUNTIME/src/runtime/adapters/ags_reloader.py`. Then run the cutover fixture with a fake app whose quit returns 0 but whose process stays up for 2 s; the installer that treats exit 0 as stopped repoints the link while the old process runs.

---

### F10 — Shared AGS launch lock

**Status: PARTIAL. The lock is named; it does not cover every `ags run` caller.**

**Closed:** AD-28 defines a per-user AGS launch lock shared by the runtime restart lane, provisioning, and autostart, so the shared bundle cannot race (`SPINE:146-147`); live `ags request` does not bundle and may overlap (`SPINE:147-148`).

**Open:** The on-demand launchers run `ags run` directly and are not named. Current templates: `capture-ui.j2:29` `exec ags run -d "$DIR" --log-file "$LOG"`; `hypr-pano-ui.j2:51` `ags run -d "$DIR" --log-file "$LOG" &`; `wallpaper-selector-ui.j2:30`; `btop-theme-studio.j2:38`; `icon-color-mapping-editor.j2` (`exec ags run ...`); `gui_tools/tasks/main.yml:184-196` `setsid {{ item.launch }}`; `dotfiles-assets/configs/hypr/autostart.lua:19-51` staggered `ags run`. The launchers are provisioned by `dotfiles-provision` but executed on demand; a literal reading of “provisioning” may or may not include the installed wrapper. A user keybind/terminal `ags run` is definitely outside. The shared `/run/user/$UID/ags.js` can still race. This is N11. The fix is “every `ags run` caller” or a single `ags-launch` wrapper that acquires the lock; enumerate the launchers, `gui_tools`, `cli_tools`, and user scripts in the contract.

**Evidence:** `SPINE:146-147`; `PROVISION/ansible/roles/cli_tools/templates/{capture-ui,hypr-pano-ui,wallpaper-selector-ui,btop-theme-studio,icon-color-mapping-editor}.j2`; `PROVISION/ansible/roles/gui_tools/tasks/main.yml:184-196`; `PROVISION/ansible/roles/gui_tools/vars/main.yml:203,222`; `ASSETS/configs/hypr/autostart.lua:19-51`.

**Verify:** `grep -rn 'ags run' PROVISION/ansible/roles/cli_tools/templates PROVISION/ansible/roles/gui_tools ASSETS/configs/hypr/autostart.lua`. Start a launcher and a runtime restart concurrently; inspect `/run/user/$UID/ags.js` and `ags list`.

---

### F11 — Safe restart procedure and recovery

**Status: PARTIAL. The confirmed-quit wait and fail/report are present; the recovery semantics and new-instance verification are not.**

**Closed:** AD-28’s restart lane sends quit, waits up to 5 s for the D-Bus name/process to release, fails and reports if it does not, then launches; no concurrent `ags run` (`SPINE:143-147`). AD-30 says restart is explicit, never a fallback, invalid with `holdsUnsavedState`, and a failed live refresh never becomes a restart (`SPINE:169-180`). The `wallpaper.state done` is published after both lanes; no immediate retry (`SPINE:147-148`).

**Open:**

- **Bar down vs retry.** AD-30 says a failed restart is “retried on the next trigger” and “If the bar is down, the operation reports it; there is no hidden launch” (`SPINE:178-180`). AD-29 gates on “a running app” and AD-26 discovery intersects `ags list`; a down bar is not running. The next trigger cannot both retry and not launch. N7.
- **No new-instance ownership check.** AD-28 stops at “then launch” (`SPINE:145`). It does not say the new instance must own the D-Bus name/pid before the restart is considered successful, or how a launch that exits 0 due to delegation is classified. The original F11 “no exit-0 misclassification” is only half-closed: the old instance's death is checked, not the new instance's life. Add a ≤5 s post-launch `ags list`/D-Bus ownership check and a launch record.
- **Launch context.** AD-28 says “then launch” but not with what argv/cwd/env/log file. The bar is launched bare `ags run` by autostart (`ASSETS/configs/hypr/autostart.lua:19`); a runtime relaunch that drops `--log-file`/cwd/env loses the original context. Capture the launch record at discovery or from the app list, as the first review proposed.
- **Stopped apps.** AD-30 does not say “restart only instances that were running at discovery; a stopped app stays stopped.” AD-26's discovery intersection implies it, but AD-32 step 4 starts the new instance unconditionally at cutover. State it for both the cutover and the palette lane.

**Evidence:** `SPINE:143-147,169-180,100-103`; `ASSETS/configs/hypr/autostart.lua:19`; `RUNTIME/src/runtime/adapters/ags_reloader.py:205-257`.

**Verify:** `sed -n '143,148p;169,180p' SPINE; sed -n '205,257p' RUNTIME/src/runtime/adapters/ags_reloader.py`. Run a fake quit that returns 0 without exiting; the current reloader launches and misclassifies. Then run a fake launch that exits 0 by delegation; AD-28 has no post-launch ownership check.

---

### F12 — Theme provider replacement as a hard gate

**Status: CLOSED for new app repos; OPEN for the migration window.**

**Closed:** Inherited AD-13 now says the port's provider replacement is a hard prerequisite (`SPINE:56`); the workstream table says “Theme one-provider replacement (blocking)” (`SPINE:461`); REQ-008 requires the fix proven before live refresh (`REQ008:56-57`); REQ-009 depends on it (`REQ009:78`). The old Deferred “provider replacement” item is gone from the Deferred list (`SPINE:469-490`). This is the F12 gate.

**Open:** The migration window. The legacy `ags-apps` unit uses `ags-platform` v0.2.0 and its old Theme adapter; the new tuple has the fix. The runtime switch is before the app cutovers; the legacy live apps are refreshed through the old adapter (N2). The gate is true for new repos and false for the apps the runtime refreshes first. Also, REQ-012/013/014 are titled “already live” and their acceptance does not explicitly require removing the `wallpaper.state` palette path or a provider-count test (`REQ012:23-38`; `REQ013:23-37`; `REQ014:23-38`). The spine AD-27 says live apps do not subscribe for palette (`SPINE:126-128`), so the binding rule is clear, but the work orders should carry the acceptance. M11.

**Evidence:** `SPINE:56,126-128,461`; `REQ008:56-57`; `REQ009:78`; `REQ012/013/014`; `PROVISION/ansible/roles/ags_apps/vars/main.yml:314-320` (legacy platform v0.2.0); `ags-apps/notifications/ui/NotificationsWindow.tsx:982`; `ags-apps/wallpaper-selector/ui/WallpaperSelectorWindow.tsx:781-786,800-824`; `ags-apps/icme/ui/EditorWindow.tsx:178`.

**Verify:** `grep -n 'provider replacement\|blocking' SPINE REQ008; grep -n 'wallpaper.state\|theme.apply' ags-apps/{notifications,wallpaper-selector,icme}/ui/*.tsx`. Then build a legacy app against v0.2.0 and apply N palettes; the provider count grows. Build the same app against the program tuple; it stays one.

---

### F13 — Live state preservation

**Status: PARTIAL. The non-destructive rule is present; the “defer” branch, the transient flag, and atomicity are not.**

**Closed:** AD-27 says `palette-refresh` must be non-destructive; apps with `holdsUnsavedState: true` preserve pending edits; apps with an active transient surface preserve it or defer; the app repo test proves the declared state class (`SPINE:122-125`). `ok:true` means applied, not scheduled (`SPINE:120-121`). This closes the original “a live handler may destroy declared state” hole for the unsaved case.

**Open:**

- **“Defer” vs `ok:true`.** If an app with an active transient surface defers the apply and returns `{"ok":true}`, it violates “`ok:true` means applied.” If it returns `{"ok":false,"error":"busy"}`, the ledger records a failure and retries; that is not a defer, and the app may retry forever while the surface is open. The contract needs one semantics: preserve + apply + `ok:true`, or busy + `ok:false` with a defined retry. N10.
- **No transient flag.** The manifest has `holdsUnsavedState: boolean`; there is no `transientObligation`/`stateClass`. AD-27's “apps with an active transient surface” is unenforceable from the manifest. Notifications' progress card and capture's active surface both have `holdsUnsavedState: false`; the runtime cannot know. The app CI “proves the declared state class,” but the declared class is only the boolean. M3.
- **Atomicity.** AD-27 does not say prepare/validate the new provider, then swap; on failure keep the previous palette. A handler that removes the old provider and fails to load the new one returns `ok:false` but leaves the app unstyled. The original F13 atomicity point is not adopted; this is a medium gap inside F13, not a separate summary row.

**Evidence:** `SPINE:113-128`; `REQ008:23-24` (transient flag requested); `ags-apps/btop-theme-studio/ui/StudioWindow.tsx:87-113,453-462`; `ags-apps/icme/ui/EditorWindow.tsx:172-183`.

**Verify:** `grep -n 'holdsUnsavedState\|transient' SPINE EPIC REQ008; grep -n 'Pending edits' ags-apps/btop-theme-studio/ui/StudioWindow.tsx`. Then run a fake handler that clears pending and returns ok:true; a schema-only test passes. Run a fake handler that defers and returns ok:true; the runtime logs success while the app is old.

---

## 4. New critical findings

### N1 — AD-36 adopts manifests but not `palette-refresh`; the runtime switch breaks every unmigrated live app

**Severity: CRITICAL.**

**The two units:**

- **Unit A — `ags-apps` manifest-adoption release.** Follows AD-36 literally: it adds `app.manifest.json` at each deployed app's config dir, including the bar and the still-monorepo apps; the live apps get `mode: live` and their `holdsUnsavedState` values. It does not change `app.tsx` or add a request handler; AD-36 only says “receives `app.manifest.json`” and REQ-008's deliverable is the manifest schema/fixture, not the handler. The manifests validate; the adoption is complete.
- **Unit B — `dotfiles-runtime` manifest-driven release.** Follows AD-26/AD-27/AD-36: it discovers the deployed links, intersects with `ags list`, and invokes `ags request palette-refresh <appearance-hash> -i <instance>` on each running live app. AD-36 says the runtime switch is one release after adoption. It is.

**The incompatibility (exact):** The current live apps do not have a `requestHandler` (notifications, capture, wallpaper-selector, icme, btop) or have one that only knows `show`/`hide`/`popup-close` (hypr-pano; the bar is restart and does not need the command). AGS answers a no-handler request with `instance "X" has no request handler implemented` (`/usr/share/ags/js/lib/gtk4/app.ts:272-276`) and exits 0; hypr-pano answers `"unknown request: palette-refresh <hash>"` (`ags-apps/hypr-pano/lib/requests.ts:40-53`). AD-27 treats malformed/non-JSON output as a failure. The runtime records a failure for every unmigrated live app on every palette change; the apps stay stale. If the runtime instead treats the no-handler string as a no-op, it violates AD-26/AD-28's “never a silent no-op.” Either way, the runtime switch is not usable. The pilot (REQ-009) adds the handler for clipboard, but the switch is before it; REQ-010–REQ-014 add handlers later. The EPIC migration order (`EPIC:77-90`, step 2 before step 3+) makes the gap unavoidable.

**Why AD-36's “Prevents” is false:** AD-36 says it prevents “a no-legacy runtime leaving unmigrated apps stale during the app-by-app migration.” A manifest without a handler leaves them stale in exactly the same way; the only difference is that the app is now a failure entry instead of silently absent. The no-legacy rule is satisfied; the desktop is not.

**Evidence:** `SPINE:268-280` (adoption, runtime switch one release later), `SPINE:113-128` (wire contract), `SPINE:105-107` (missing/invalid failure), `REQ008:43-45` (adoption deliverable), `REQ009:39-44` (clipboard handler is added in the pilot), `EPIC:77-90` (step 2 before the app cutovers); `ags-apps/bar/app.tsx:52` and `ags-apps/hypr-pano/app.tsx:33` are the only `requestHandler`s; `/usr/share/ags/js/lib/gtk4/app.ts:272-276`; `ags-apps/hypr-pano/lib/requests.ts:40-53`; `grep -n 'requestHandler' ags-apps/{notifications,capture-tool,wallpaper-selector,icme,btop-theme-studio}/app.tsx` → no matches.

**Verify:** `grep -n 'requestHandler' ags-apps/*/app.tsx; sed -n '272,276p' /usr/share/ags/js/lib/gtk4/app.ts; sed -n '39,44p' tickets/REQ-009-migrate-clipboard-standalone/ticket.md; sed -n '77,90p' tickets/EPIC-002-apps-standalone-repos/ticket.md`. Then start notifications and run `ags request palette-refresh deadbeef -i notifications`; it exits 0 with the no-handler string. Parse it as JSON; it fails.

**Fix (smallest):** AD-36's adoption release must include the `palette-refresh` handler and a JSON-string handler test for every currently deployed live app (notifications, capture, hypr-pano/clipboard, selector, icme, btop), and the bar's restart path test. The runtime switch is gated on a deployed-handler inventory that shows every live app answers. Alternatively, delay the runtime switch until each app's cutover, but that is a second runtime mode/legacy path and contradicts the memlog's “no legacy” decision. The first is the only option consistent with the stated invariants.

---

### N2 — The one-tuple rule is not migration-aware, and per-cutover tuple drift is allowed

**Severity: CRITICAL.**

**The two units:**

- **Unit A — legacy `ags-apps` role.** Follows AD-31/AD-32: the old role may only shrink (`SPINE:216-217`); it keeps the `ags-apps` pin and its own `ags_apps_platform_version: v0.2.0` per-unit shortcut (`PROVISION/ansible/roles/ags_apps/vars/main.yml:314-336`) until the last app moves. It deploys the still-monorepo apps. This is exactly the “old role may only shrink” rule.
- **Unit B — new `dotfiles-v3` program tuple + new app role.** Follows AD-31: one `ags-platform` pin (the program tuple, e.g. v0.3.0 with the one-provider Theme fix) and one `contracts` pin, one `<install>/apps/node_modules/ags-platform` shortcut, and new app tags built against that tuple. It follows AD-34's equality gate.

**The incompatibility (exact):** During the migration the install has two platform pins and two Theme implementations: legacy apps resolve `<unit>/node_modules/ags-platform -> <install>/ags-platform/v0.2.0`; new apps resolve `<install>/apps/node_modules/ags-platform -> <install>/ags-platform/v0.3.0`. AD-31 says “exactly one shared shortcut” and “one `ags-platform` pin,” but AD-32 keeps the old role/pin until the last app; the two rules cannot both be true until the program completes. With N1's minimal fix (handlers added to the legacy live apps), the runtime switch invokes those handlers through the v0.2.0 `theme.apply()`; the provider replacement that AD-13/AD-34 make a “hard prerequisite” is not in that adapter. The apps leak providers on every palette change, exactly the hazard the gate exists to remove. The revision's F1 fix is true for the seven new repos and false for the legacy unit the runtime refreshes first.

The second variant is tuple evolution. AD-31 says every app repo pins the tuple “for its cutover” (`SPINE:190-192`); AD-32 step 2 says platform/contracts prerequisites are released/pinned per epoch (`SPINE:206-208`); the Stack says one tuple set at REQ-008 (`SPINE:322`). If the tuple is immutable, the per-epoch sentence is wrong; if it can move, the shared ancestor and AD-34 equality gate have no rule for previously cut-over apps. Two app repos can legitimately pin T1 and T2, and the deployment can install only one. This is the original F1 build incompatibility, moved from “per-app pins” to “per-epoch pins.”

**Evidence:** `SPINE:182-198,200-221,238-251,322`; `PROVISION/ansible/roles/ags_apps/vars/main.yml:314-336`; `PROVISION/ansible/roles/ags_platform/vars/main.yml:27-42`; `V3/dotfiles/provisioning/installer.pin` (`v0.1.16`); `V3/dotfiles/provisioning/cli-tools.yaml:30-32` (`v0.2.2`); `RUNTIME/src/runtime/adapters/CONTRACT_PIN` (`dbdc5b8`); `contracts/schemas/` (no app-list/ledger schema).

**Verify:** `grep -n 'ags_apps_platform_version\|ags_apps_resolution_shortcut' PROVISION/ansible/roles/ags_apps/vars/main.yml; grep -n 'ags_platform_version' PROVISION/ansible/roles/ags_platform/vars/main.yml; cat V3/dotfiles/provisioning/installer.pin; cat RUNTIME/src/runtime/adapters/CONTRACT_PIN`. Then install a legacy app and a new app side by side and `readlink -f` each app's resolved `ags-platform`; they differ.

**Fix:** (a) State the program tuple is immutable; AD-32 step 2 may release a new **engine/runtime**, not a new platform/contracts tuple, without a program-wide revalidation/retag epoch. (b) Record `platformTag`/`contractsTag`/`assetsTag` in one `program-tuple.yaml` or the app-list schema; the installer/runtime/verify read that one record. (c) Rebase `ags-apps` on the same program tuple in the adoption release (a new `ags-apps` tag and a `ags_apps_platform_version` equal to the program tuple) before the runtime switch, or explicitly exempt the legacy unit and do not invoke legacy live apps until they are rebased/cut over. The current text does neither.

---

## 5. Two units that obey every AD and still fail

### 5.1 Build/deploy pair — install-path derivation (N3)

- **Unit A — `dotfiles-v3` app-list author.** AD-31 says install each app at `<install>/apps/<app>/<tag>/` (`SPINE:187-190`). The app list's `app` field is the manifest app id; REQ-011 declares `app: capture`, `instance: capture`, `configDir: ags-capture` (`REQ011:19-21`). Unit A derives `<install>/apps/capture/v0.2.0`.
- **Unit B — `dotfiles-provision` generic install role / structural seed.** AD-31's install topology seed places capture at `<install>/apps/capture-tool/<tag>/` and links `config/ags-capture -> ../apps/capture-tool/<tag>` (`SPINE:330-348`). The app map says repo `ags-capture-tool` (`SPINE:436`). Unit B installs `<install>/apps/capture-tool/v0.2.0`.

Both units obey AD-31. The install and the link disagree; `config/ags-capture` dangles (or the verify role looks in `apps/capture` and fails). The clipboard entry does not expose the bug because `app: clipboard` and the repo stem `clipboard` coincide. The capture entry does. The same class applies to the bar's `configDir: ags` vs app `bar` (the link is special-cased, so it is less visible) and to `btop` (`app: btop-theme-studio`, repo stem `btop-theme-studio`, coincide).

**Fix:** Add an explicit `unitDir`/`installDir` field to the app-list schema (e.g. `unit: capture-tool`) and make AD-31's `<app>` mean that field; or change the topology to `apps/capture/<tag>` and the link to `../apps/capture/<tag>`. Align the convention table's `ags-<app>` with `ags-capture-tool` or rename the repo/app id. M12 is the same issue.

### 5.2 Build/integration pair — tuple drift (N2)

- **Unit A — `ags-notifications`, cut over first.** AD-31/AD-34: pins the program tuple T1 (P1/C1) “for its cutover”; no vendored platform; CI passes against T1.
- **Unit B — `ags-icme`, cut over later.** AD-32 step 2 releases/pins the platform/contracts prerequisites for its epoch; it needs a platform API added after T1, so it pins T2 (P2/C2); no vendored platform; CI passes against T2.
- **Deployment.** AD-31: one `ags-platform` pin and one `contracts` pin, one shared ancestor. The program tuple can be only one. If T2, notifications' T1 tag fails AD-34's equality gate (or bundles against an untested P2); if T1, icme's T2-only API fails to bundle against P1. Both units obeyed; one cannot deploy.

**Fix:** Freeze the tuple for the program; any platform/contracts change is a program-level epoch that retags and revalidates every cut-over app before the shared ancestor moves. Add the tuple to the app-list schema (N2's fix) so the verify can check it.

### 5.3 Runtime pair — adoption without handler (N1)

- **Unit A** adds only manifests (AD-36); **Unit B** invokes `palette-refresh` (AD-27) after the switch (AD-36). The unmigrated live apps have no handler; the runtime records malformed-response failures and the apps stay stale. This is not a build pair, but it is the deployment that the program actually performs; it is in §4 because it blocks the runtime switch itself.

---

## 6. Medium findings (fix before the first cutover, not necessarily before freeze)

- **M1 — App-list seed pre-flips clipboard.** The seed shows `app: clipboard`, `owner: standalone`, `tag: v0.1.0` (`SPINE:354-361`) while the pilot is REQ-009 and the list is “the sole ownership source” (`SPINE:369-370`). A `V3` unit that copies the seed deploys a repo/tag that does not exist and removes the old owner. Label the seed illustrative or show the pre-cutover state (`owner: legacy` for clipboard until REQ-009). Also add `instance`/`configDir` to the bar seed entry; it currently has only `configLink`, `launch`, `barPalettePointer` and would fail the AD-31 field list.
- **M2 — Bar default `instanceName`.** The bar's `app.tsx` has no explicit `instanceName`; AGS defaults to `ags`. AD-26's equality should say “effective instance name (default `ags` when omitted)” or the bar CI will fail a literal property grep (`SPINE:97-99`; `ags-apps/bar/app.tsx:37`).
- **M3 — No transient flag.** `holdsUnsavedState` is a boolean; AD-27's “active transient surface” has no manifest field (`SPINE:94-96,123-125`). Add `transientObligation: boolean` or `stateClass: none|unsaved|transient`; make `mode: restart` invalid for either; add the test. Notifications' progress card and capture's active surface are the concrete cases (`REQ012:23-38`; `REQ011:23-26`).
- **M4 — CLI exit code.** AD-28 defines `reload_failures` but not the reconcile exit code; the current V3 doc says non-zero for those failures (`SPINE:130-148`; `V3/docs/ags-restart-vs-live-theme-refresh.md:60`). Pick one and state it.
- **M5 — `contracts` tag/commit equality.** AD-34 allows “tag/commit” for the app conformance pin; the install gate requires equality with the program tuple (`SPINE:246-248`). A tag and a commit SHA pointing at the same commit are not string-equal. Define equality by resolved commit (`git rev-parse <tag>^{commit}`) and record the commit in the tuple.
- **M6 — Ledger schema.** AD-34's `contracts` list does not include the applied-appearance ledger (`SPINE:242-245`); AD-29 allows an extension of `last-converged` (`SPINE:155-156`), whose schema is `additionalProperties: false` and requires `input_hash` (`contracts/schemas/last-converged.schema.json`). Add the ledger schema to `contracts` or state the exact extension/version. Also state `operation id == runId`.
- **M7 — Timeout cancellation.** AD-27 says 5 s failure but not process-group kill/late completion (`SPINE:116-121`). Add: kill the `ags request` process group on timeout; record timeout; a late handler completion is not success; the handler must be idempotent/busy.
- **M8 — Log sink/phase/discoveryIndex.** AD-28's fields are named but `phase`, `discoveryIndex`, and the sink are not defined (`SPINE:134-142`). A log consumer cannot parse consistently. Define the enum and ascending `(configLink, instance)` order; journald or a file.
- **M9 — Archive timing.** AD-32 step 6 says archive when the last app moves (`SPINE:216-217`); AD-33 says cross-app work stays in `ags-apps` until archive (`SPINE:233-235`); REQ-016 is the final consumption cutover after REQ-015 (`REQ016:14-26,41-42`). Archive at the last app move leaves no workshop for REQ-016. Move archive to REQ-016 close, as the first review's deferred item proposed.
- **M10 — `BUG-003` is not a ticket.** REQ-015 depends on `BUG-003` (`REQ015:35,62`); the only occurrence is a SPIKE-001 section heading (`tickets/SPIKE-001-ags-refresh-patterns/ticket.md:308`). Create the bug ticket or reference the runtime fix by its actual issue, and make it a hard gate before the bar cutover (the revision's AD-28 procedure is the fix, but the ticket dependency is dangling).
- **M11 — Child-ticket F12 acceptance.** REQ-012/013/014 are still titled “already live” and do not explicitly require removing the `wallpaper.state` palette subscription or a provider-count test (`REQ012/013/014`). The spine AD-27 is binding, but the work orders should carry the acceptance; the current selector/notifications/icme code has the subscription (`NotificationsWindow.tsx:982`; `WallpaperSelectorWindow.tsx:781-786,800-824`; `EditorWindow.tsx:178`). Add “remove the event palette path; add a provider-count regression.”
- **M12 — Repo naming.** The convention says `ags-<app>` (`SPINE:301`); the app map has `ags-capture-tool` for app `capture` (`SPINE:436`). The naming rule is not single-valued; fix the convention or the app id. This is the same seam as N3.
- **M13 — Clipboard namespace.** AD-35 moves the daemon's config/state/cache to the `clipboard` namespace (`SPINE:260-266`) while the app's config dir is `ags-clipboard` (`SPINE:302`). If preferences live in the daemon config, the app and daemon may read different files. State which namespace is the source of user preferences and include both in the one-time migration.
- **M14 — Pure handler/testkit.** AD-33 requires a handler and tests (`SPINE:230-235`), but does not require the handler logic to be a pure module or ship shared `contracts` fixtures. A stock CI cannot import `app.tsx`; app A can inline a handler that returns the wrong shape and still “pass.” The first review's F15 proposal (pure module + `contracts` testkit) is still the right fix; at minimum the template seed should include `lib/palette-refresh.ts` and `tests/fixtures`.

---

## 7. Proposed change set (ordered by freeze blocker)

1. **N1 — Adoption includes the handler.** Amend AD-36/REQ-008: the adoption release adds `app.manifest.json` **and** a `palette-refresh` handler with a JSON-string response and a handler test for every currently deployed live app; the bar's restart path is tested. Gate the runtime switch on a deployed-handler inventory. Update EPIC's “Adopt manifests … and enable the runtime” step to “adopt manifests + handlers, then enable.”
2. **N2 — Migration-aware tuple.** State the program tuple is immutable; AD-32 step 2 may release engine/runtime, not a new platform/contracts tuple, without a program-wide revalidation/retag epoch. Add `platformTag`/`contractsTag`/`assetsTag` to one `program-tuple.yaml` or the app-list schema. Rebase `ags-apps` on the program tuple in the adoption release, or explicitly exempt it and do not invoke legacy live apps until rebased.
3. **N3 — Install-path identity.** Add `unitDir`/`installDir` to the app-list schema and use it in AD-31/AD-32 and the verify; align the `capture-tool`/`capture`/`ags-capture-tool` naming. Update the seed and the app map.
4. **N4 — `colors.css` outside the tag.** Define the pointer as a link created once at install (or a state-side file) whose target the seeder writes; the tag contains no writable pointer. Add a tag-read-only/tag-bump test.
5. **N5 — Icons tuple/relocation.** Add `dotfiles-assets` to the program tuple; move the icons producer before REQ-011 (REQ-008), not REQ-015; provisioning verifies only.
6. **N6 — Ownership predicate data.** Add `xdgLink`, `launcherName`, `autostartEntry`, `sourceDir` (or documented derivations) to the app-list schema; make the verify enumerate actual launchers/autostart entries and reject unexpected ones. Add a stale-launcher/stale-autostart case to the fake-app fixture.
7. **N7 — Down-bar recovery.** Define `down-at-discovery` (report, leave stopped) vs `failed-this-operation` (retry next trigger, only if the runtime stopped it). Add `wasRunning`/`restartState` to the ledger; make AD-30's two sentences one rule.
8. **N8 — Cutover stop/order.** AD-32 step 4 must cite AD-28's confirmed stop (quit, wait ≤5 s for D-Bus/process release, fail/report) and the launch lock. Reorder the epoch to install-only → stop old → repoint → start new → verify, or define an explicit link phase. Add a post-launch new-instance ownership check.
9. **N9 — Discovery enumeration.** Rewrite AD-26: enumerate all deployed `<install>/config/ags*` links, validate each manifest, invalid/missing → failure entry and exclude from refresh; verify the running process's config dir/realpath against the deployed link; `--include-dev` is explicit. Add the bar default-instance wording.
10. **N10 — `defer` semantics.** Remove “or defer” or define a `deferred` ledger status and retry; require `ok:true` only after apply. Add a forced-failure atomicity test (keep the old palette).
11. **N11 — Launch-lock scope.** “Every `ags run` caller” including generated launchers, `gui_tools`, `cli_tools`, autostart, and user scripts; or a single `ags-launch` wrapper. Add a concurrency test with a launcher and a restart.
12. **N12 — Pilot gate thresholds.** Define the REQ-009 exit gate as measurable pass/fail thresholds (repo creation time, CI/release wall time, install/rollback time, one-owner cutover result, measured cost) and the template ownership (who creates the template before the pilot; the pilot is the reference, not the definition).
13. **M1–M14** as above; M4/M5/M6/M7/M8/M9/M10/M11 should land before the first cutover (REQ-009).

---

## 8. Check performed

- Read the revised `SPINE` (504 lines) and `.memlog.md` in full.
- Read `EPIC-002`, `REQ-008` through `REQ-016`, and the prior `review-adversarial.md` + `review-evidence.md` (including the F1–F13/F1–F12 dispositions).
- Read the current brownfield: `dotfiles-runtime` `AgsReloader`, `ReconcileDesktopStateUseCase`, `StaticConsumerPathSpec`, `CacheSeeder`, `CONTRACT_PIN`; `dotfiles-provision` `ags_apps`, `ags_platform`, `compositor_configs`, `gui_tools`, `cli_tools`; `dotfiles-v3` `installer.pin`, `cli-tools.yaml`, `deploy-coverage.py` assumptions; `dotfiles-assets/configs/hypr/autostart.lua`; `contracts/schemas/*`; `ags-apps` app.tsx/request handlers, `bar/services/speedtest-service.ts`, `btop-theme-studio`/`icme` UI state, `hypr-pano` requests.
- Checked AGS 3.1 request transport (`/usr/share/ags/js/lib/gtk4/app.ts:272-296`, `/usr/share/ags/js/lib/app/dbus.ts:7`, `ags request --help`), the no-handler string, the string-returning current handlers, and the shared bundle/autostart comments.
- Verified `grep -n 'requestHandler' ags-apps/*/app.tsx` → only `bar/app.tsx:52` and `hypr-pano/app.tsx:33`; the other five live apps have none.
- Verified `V3/dotfiles/provisioning/apps.yaml` is absent; `contracts/schemas/` has no manifest/app-list/ledger schema; `installer.pin` is `v0.1.16`; `cli-tools.yaml` pins runtime `v0.2.2`; `CONTRACT_PIN` is `dbdc5b8`; `ags-platform`/`contracts` tags are `v0.2.0`.
- No files were modified except this review.

---

*End of review.*
