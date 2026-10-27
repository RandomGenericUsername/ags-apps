# Reviewer Gate — Rubric Walker

**Spine:** `architecture-standalone-app-contract.md` (status `draft`, altitude `epic`, binds EPIC-002 / REQ-008)
**Lens:** good-spine checklist (reviewer-gate.md §"Good-spine checklist")
**Verdict:** **REVISE**
**Gate run:** 2026-10-26, Validate intent (report only; no spine edits)
**Mechanical pre-pass:** `python3 .agents/skills/bmad-architecture/scripts/lint_spine.py --workspace _bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract` → `ok: true`, `total_findings: 0`. The findings below are semantic, not mechanical.

---

## 1. One-sentence verdict

The app-level contract is concrete and largely sound, and the install topology correctly absorbs the esbuild realpath finding from the brownfield; but the spine is not yet safe for handoff because it leaves four program-level seams undefined — **installed platform/contracts version compatibility, runtime activation across the app-by-app migration (including the bar), Theme-port safety while adding live consumers, and live-refresh preservation of unsaved/in-flight state** — and it does not record the supersession of the child-ticket clauses and inherited gate clauses it contradicts.

No critical findings. **6 high, 12 medium, 7 low.** The high findings are F1–F6 below.

---

## 2. Method and evidence

Read for this review:

- the spine and `.memlog.md`;
- `reviewer-gate.md`;
- `dotfiles-v3/docs/GUIDE-ags-app-repos-refinement.md` (the 2026-10-16 three-repo decision + §7 exit gate);
- the parent `architecture-ags-platform-2026-10-09/ARCHITECTURE-SPINE.md`;
- EPIC-002, SPIKE-001, REQ-008–REQ-016 tickets;
- the brownfield consumers named in the spine's Evidence table: `dotfiles-runtime/src/runtime/adapters/ags_reloader.py`, `src/runtime/application/reconcile.py`, `dotfiles-runtime/src/runtime/adapters/clipboard_config.py`, `json_history_store.py`, `dotfiles-provision/ansible/roles/{ags_apps,ags_platform,gui_tools}`, `dotfiles-v3/dotfiles/provisioning/*`, `dotfiles-v3/scripts/deploy-coverage.py`, `ags-apps` Makefile and workflows, `contracts/event-contract.json`, and the AGS 3.1.0/3.1.2 install (`/usr/share/ags/js/lib/gtk4/app.ts`).

Evidence labels below use the same convention as the house AGENTS files: `path:lines`, command → result, or a named ticket/ADR.

---

## 3. Checklist walk

### 3.1 Does it fix the real divergence points for the level below, and miss none?

**Mostly no for the program-level seams.** The spine nails the per-app contract: one repo per app, root-is-package, one manifest, one command, one response, one timeout, one failure surface, one restart procedure, one install topology, one cutover recipe, one dev-flow template. Those are the divergence points the app children (REQ-009…REQ-015) need.

What it misses is the set of points where **the child tickets, the runtime, the installer, and the platform meet**:

1. **Version compatibility** — each app repo pins `ags-platform`/`contracts` independently (AD-34, Deferred), while the host installs exactly one shared `<install>/apps/node_modules/ags-platform` shortcut (AD-31). Two apps can legally pin different versions the host cannot satisfy at once. See F1.
2. **Activation order** — AD-26 says “no legacy path” and “missing manifest → do nothing”, but the program is a strangler-fig app-by-app migration (AD-20/AD-32), the pilot is first, and the bar is last. There is no rule for what the runtime does to the still-unmigrated apps, and the bar is not discoverable by the current discovery path. See F2.
3. **Theme safety** — the live lanes the spine mandates run through the Theme port, whose provider-accumulation bug is explicitly Deferred as “required before new live refresh work is considered safe” (Deferred; SPIKE-001 §“Extra finding”). See F3.
4. **Live-refresh state safety** — the spine makes restart “all-times safe” (AD-30) but imposes no preservation rule on live refresh. `holdsUnsavedState` is only used to forbid restart. btop is live with `holdsUnsavedState: true`; capture is live during in-flight UI. See F4.
5. **Authority** — the child tickets still carry the superseded contract (legacy manifest, restart fallback, `refresh` field, stable `hypr-pano` names, open bar decision, open archive decision). The spine only records supersession of the GUIDE and the parent Deferred item. See F5.
6. **Gate discipline** — the new local-typecheck rule contradicts inherited AD-19/AD-23 without a recorded supersession. See F6.

### 3.2 Is every AD's Rule enforceable, and does it prevent its stated divergence?

| AD | Enforceable as written? | Prevents its stated divergence? | Note |
| --- | --- | --- | --- |
| AD-25 one repo per app | Yes (repo count/root/no app imports/archive). | Yes, with wording gap. | “Deployed config link points at the repo root” means the installed app root; clarify vs AD-31 `<install>/apps/<app>/<tag>/`. Low. |
| AD-26 manifest is the declaration | Partly. | Partly. | Bar has no discovery path to its manifest; no live-state rule; no schema-evolution/configDir-validation rule; “no legacy” has no migration-window rule. F2, F4, M3/M5. |
| AD-27 runtime is the only trigger | Partly. | Partly. | `{"ok":false}` is not listed as a failure; idempotency “by palette hash” is undefined; extra output/stderr handling undefined; no live-state preservation. F4, M3, M9. |
| AD-28 parallel live / serialized restart / logs | Mostly. | Mostly. | “Every app emits” is the runtime's act; restart lane has no bound; autostart concurrency not covered; `reload_failures` is reloader-level, not per-app. M3/M7, L3. |
| AD-29 one palette-change gate | Partly. | Partly. | “CLI needs its own gate **or** an explicit no-reload mode” is an undecided choice; the CLI has no persisted last-applied hash; partial-failure semantics undefined. M1. |
| AD-30 restart explicit / never fallback | Mostly. | Partly. | Bar discovery/manifest path undefined; no bar failure recovery; live-state safety missing. F2, F4, M7. |
| AD-31 per-app install topology | Partly. | Partly. | Single shared platform shortcut vs per-app platform pins; launch/always-on policy missing; old per-unit shortcut removal not stated. F1, M12, low. |
| AD-32 one owner per app | Partly. | Partly. | “One commit set” spans dotfiles-v3 + dotfiles-provision; the old exclusion list duplicates the new per-app list; activation/pin order not defined. M2. |
| AD-33 dev flow / template | Mostly. | Partly. | Typecheck-local vs inherited AD-19/23; platform/contracts acquisition in the template missing; six manual copies can drift. F6, M6. |
| AD-34 contract ownership/versioning | Mostly. | Partly. | Per-app pins vs one installed platform; schema evolution undefined; direct app→contracts edge vs parent AD-1. F1, M5, M8. |
| AD-35 clipboard rename | Mostly. | Partly. | Data/config/cache paths owned by the runtime daemon remain `hypr-pano`; “old names retired” is overbroad and risks history/config split. M4. |

**Conclusion:** every AD is directionally right, but AD-26, AD-27, AD-29, AD-31, AD-32, AD-34 do not yet fully prevent their stated divergence. The highest-leverage fixes are F1–F4.

### 3.3 Could anything under Deferred let two units diverge?

| Deferred item | Can two units diverge? | Assessment |
| --- | --- | --- |
| `palette.changed` event | No. | One runtime; command is the contract. Fine. |
| Bar live refresh | No. | Bar stays restart; future iteration. Fine. |
| `ags-platform` Theme provider replacement | **Yes.** | Each app can compensate differently, or leak. The item says it is “required before new live refresh work is considered safe”, yet is Deferred while the spine adds live consumers. **F3.** |
| Bar restart mechanism (BUG-003) | No unit divergence, but safety gate. | It is a prerequisite for the bar child but not an AD/acceptance gate. M7. |
| `ags-apps` archive mechanics | No. | GitHub archive vs deletion is a REQ-016 detail. Fine. |
| App repo CI/template automation | **Yes, weakly.** | Six manual copies of the pilot template can drift; no template-conformance check. M6. |
| Exact `contracts`/`ags-platform` tags per app | **Yes.** | This is the version-skew seam; Deferring exact tags without a compatibility rule leaves the install undefined. **F1.** |
| Invalid-manifest UX beyond logs | No. | Logs + app CI is a defensible boundary. Fine. |
| `dotfiles-assets` changes | No. | Scope is the rename. Fine. |

**Conclusion:** two Deferred items are not safe to defer as written: the Theme provider replacement and the per-app platform/contracts pins. One more (template automation) is a medium drift risk.

### 3.4 Is named tech verified-current?

| Name | Spine says | Verified in the brownfield | Assessment |
| --- | --- | --- | --- |
| AGS CLI / JS package | 3.1.0 / 3.1.2 | `ags --version` → `ags version 3.1.0`; `/usr/share/ags/js/package.json` → `"version": "3.1.2"` | Correct for this host. The host package is AUR `aylurs-gtk-shell-git` and **unpinned**; the parent Stack (`:240-245`) and Open Questions (`:318`) flag this. The spine does not carry it. M7. |
| TypeScript | 5.9 repo pin | `ags-apps/Makefile:147,190,238,306` installs `typescript@5.9`; parent Open Question says 5.9 is “not current”. | Correct as a repo pin, but the parent's “confirm the pin is deliberate” question is not carried. Low/medium. |
| Python runtime | 3.14.7 | `python3 --version` → 3.14.7; `dotfiles-runtime/pyproject.toml:8` → `requires-python = ">=3.14"` | Correct. |
| `ags-platform` | “existing pinned tag; each app repo pins its own” | Current pin `v0.2.0` (`ags-apps/Makefile:32`; `dotfiles-provision/.../ags_platform/vars/main.yml:32`) | Vague; not a version. Low/medium. |
| `contracts` | “existing pinned contract; each app repo pins its own” | Runtime pins commit `dbdc5b8` (`src/runtime/adapters/CONTRACT_PIN`); contracts also has tags `v0.1.0`/`v0.2.0`; current app CI checks out the default branch (e.g. `.github/workflows/hypr-pano.yml:31-40`) | Vague; the app CI does not currently pin a commit. M6/M7. |
| Distribution | GitHub HTTPS, annotated tags, no registry | Current `ags-apps`/`ags-platform` are public, anonymous HTTPS; runtime/tools pin tags; no registry in the Makefiles | Correct and brownfield-ratified. |

**Conclusion:** the two host versions (AGS, Python) and the TypeScript pin are real; the two contract pins are placeholders, and the AGS host package's unpinned status is a live operational risk the spine does not resolve or defer explicitly.

### 3.5 Does it ratify rather than contradict the brownfield code?

| Spine claim | Brownfield evidence | Verdict |
| --- | --- | --- |
| Per-app install at `<install>/apps/<app>/<tag>/`, shared `<install>/apps/node_modules/ags-platform` | `dotfiles-provision/.../ags_apps/vars/main.yml:57-59` says AGS/esbuild **realpaths** the live-bar symlink, so the old `<install>/config/node_modules` shortcut is not an ancestor of the real unit tree; the role creates a per-unit shortcut (`tasks/main.yml:19,154`). Moving the install root under `<install>/apps/` makes `apps/node_modules` an ancestor of every real checkout. | **Ratifies and improves.** This is the strongest technical move in the spine. |
| `palette-refresh` via `ags request` and a `requestHandler` | AGS CLI has `request` (`ags request --help`); AGS app code supports `requestHandler` (`/usr/share/ags/js/lib/gtk4/app.ts:272-296,300-307`); existing apps already use it (`hypr-pano/app.tsx:33-39`, `bar/app.tsx:52-...`). | **Ratifies.** JSON responses are a change from today's `res("ok")` strings, but the mechanism is right. |
| Manifest-driven discovery replaces the skip list | Current runtime hardcodes `DEFAULT_SKIP_CONFIG_DIRS` (`ags_reloader.py:64-66`) and reads `instanceName` from `app.tsx` (`:100-107`). | **Directionally ratifies** the need; the discovery switch is new work, and the bar is outside the current discovery path. F2. |
| Typecheck is local; pure tests are stock CI | `ags-apps/AGENTS.md` §4: typecheck is a local gate; stock runners only; 0 self-hosted runners. Parent AD-23 says the opposite. | **Ratifies reality, but weakens a binding parent AD without saying so.** F6. |
| One owner per app during cutover | Current old role has all seven links; `dotfiles-v3/scripts/deploy-coverage.py` asserts the old shape; `gui_tools_ags_instances` owns launch/always-on (`gui_tools/vars/main.yml:200-235`). | **Right invariant; mechanics incomplete.** M2/M12. |
| “Old `hypr-pano` names are retired” | Runtime clipboard daemon still owns `~/.config/hypr-pano/config.json`, `~/.local/state/hypr-pano/history.json`, `~/.cache/hypr-pano/` (`clipboard_config.py:31-35`; `json_history_store.py:53-59`); the app reads `~/.local/state/hypr-pano/history.json` (`hypr-pano/lib/history.ts:15-17`). | **Contradicts the rename as written** unless the data paths are explicitly excepted. M4. |
| `wallpaper.state` is progress/UI only | `contracts/event-contract.json:92-102` still says it “drives ... LIVE refresh”. | **Needs a contract-note update.** M11. |

**Conclusion:** the spine is unusually well-grounded in the brownfield. The two real contradictions are the clipboard data paths and the `wallpaper.state` contract note; the rest are gaps, not false claims.

### 3.6 Does it cover EPIC-002's capabilities?

| EPIC-002 requirement / done-when | Spine coverage | Verdict |
| --- | --- | --- |
| Every app in its own repo, released and pinned individually | AD-25, AD-31, AD-33, Workstreams | Covered. |
| Every app declares live/restart; live implements `palette-refresh` | AD-26, AD-27, AD-30, AD-33 | Covered, except the manifest field name is `mode` (children say `refresh`) and the “transient obligation” field was dropped. F5. |
| Runtime no longer hardcodes the app list | AD-26 | Partial: the bar is outside discovery and AD-30 fixes it as restart; no rule says how its manifest is read. F2. |
| No undeclared restart; no no-op restart; no unsaved/transient restart | AD-29, AD-30 | Covered for restart; live apps have no state-preservation rule. F4. |
| `btop-theme-studio` never loses pending edits | AD-26 flag + AD-30 restart rule only | **Not guaranteed for live refresh.** F4. |
| Old `ags-apps` unit stops deploying migrated apps; one owner | AD-32 | Covered as an invariant; cross-repo mechanics incomplete. M2. |
| Tests, typechecks, bundle checks, deploy coverage, docs match | AD-32, AD-33, AD-34 | Partial: local typecheck vs inherited CI; template acquisition gap. F6/M6. |
| `ags-apps` disposition recorded | AD-32 archive; Deferred mechanics | Covered, but REQ-016 still says “meta repo or archive”. F5. |
| Cutover keeps config dir/instance stable (EPIC contract) | AD-32; **AD-35 is an explicit exception** | Covered for all but clipboard; the exception is not called out against the EPIC's stable-identity rule. F5/M4. |

**Conclusion:** the capability map is complete at the area level; the two behavioral gaps are live-state preservation (F4) and the bar/manifest discovery (F2). The child-ticket wording is the handoff risk (F5).

### 3.7 Does it avoid weakening inherited ADs?

| Parent AD | New treatment | Verdict |
| --- | --- | --- |
| AD-1 dependency direction (`apps → platform only`; `contracts ← platform ← apps`) | AD-34 makes every app repo pin `contracts`; new Inherited table repeats “apps → platform only”. | **Ambiguous/weakened.** Is contracts a test-only dependency or a runtime one? M8. |
| AD-5 one event client | Unchanged; apps consume the platform client. | Fine. |
| AD-6 contract single source | AD-34 extends `contracts` to the manifest schema/protocol. | Fine, except the manifest schema has no evolve/drift rule. M5. |
| AD-13 Theme is a port | AD-27 routes live refresh through it; the port leaks a provider per apply. | **Contradiction in practice.** F3. |
| AD-17 distribution: one versioned framework unit + shared ancestor | AD-31 moves the shortcut to `<install>/apps/node_modules` and adds per-app units. | **Correct extension**, but per-app platform pins conflict. F1. |
| AD-19 gate discipline (typecheck in `gates-ci`; per-app suites in the root gate) | AD-33 says typecheck local; each repo gates itself. | **Weakened without supersession.** F6. |
| AD-20 sequenced migration / pilot first | AD-25/33/59-62 keep app-by-app and pilot first. | Fine, but no runtime activation sequence. F2. |
| AD-21 one icon manifest | Unchanged. | Fine. |
| AD-22 one producer per topic | AD-27 makes runtime the sole palette-refresh trigger. | Fine. |
| AD-23 operational envelope (CI, self-hosted runner for typechecks, rollback, fresh host) | Inherited table reduces it to “per-repo CI, pinned installs, fresh-host verification”; AD-33 makes typecheck local. | **Weakened without supersession; rollback and the self-hosted clause are dropped.** F6/M7. |

**Conclusion:** the spine does not create a new app→app edge and keeps AD-17/21/22 intact, but it silently narrows AD-19/AD-23 and blurs AD-1. Those must be explicit supersessions or explicit clarifications.

### 3.8 Is every dimension the altitude owns decided, deferred, or open (especially the operational envelope)?

| Dimension | Status in the spine | Assessment |
| --- | --- | --- |
| Deployment topology | Decided in AD-31 (install root, links, shared platform). | Good; missing launch policy, rollback, existing-host cleanup. M7/M12. |
| Environments | Decided conceptually: dev worktrees, stock CI, fresh host. | Good; the self-hosted clause conflict and dev acquisition are gaps. F6/M6. |
| Infra/provider | Decided: GitHub HTTPS, annotated tags, no registry. | Good; repo visibility/credentials/branch protection not stated. M7. |
| Operations and observability | Decided: per-app structured log fields, `reload_failures` + notification card, no retry, summary order. | Good fields; no sink/retention/health model; `reload_failures` shape is reloader-level. M3/M7. |
| Versioning and compatibility | Partly: app tags, `schemaVersion: 1`, per-app platform/contracts pins; AGS/TS pins in Stack. | **Not decided:** one host platform version vs per-app pins; schema evolution; AGS host pin; rollback. F1/M5/M7. |
| Rollout and sequencing | Not decided. | **The largest silent dimension.** No activation point or interim behavior for the unmigrated set, and the bar's discovery path. F2. |
| Data | Manifest only; clipboard data paths. | Missing history/config/cache continuity across the rename. M4. |
| Security | Low stakes; public repos/no secrets implied. | Not stated; probably fine, but the repo visibility/credentials decision belongs in M7. |
| Quality gates | Decided: conformance, pure tests stock CI, deploy coverage, local typecheck. | Missing template drift gate and the inherited gate supersession. F6/M6. |
| Documentation | Decided: per-repo README/AGENTS/tickets; docs updates in AD-35/REQ-016. | Good. |

**Conclusion:** the operational/environmental envelope is the weakest dimension. The spine covers the install shape but not compatibility, rollback, existing-host migration, AGS pinning, or the runtime activation sequence. That is exactly the domain-focused-draft failure mode the reviewer gate warns about.

---

## 4. Findings

Findings are tiered. Each carries a suggested disposition for the parent: **autofix** (doc-level change inside the spine), **discuss** (needs a user/architect call), **defer** (move to Deferred/Open with a revisit condition), or **ignore**.

### 4.1 High

#### F1 — Per-app `ags-platform`/`contracts` pins vs one shared, installed platform (HIGH)

**Where:** AD-31 (`architecture-standalone-app-contract.md:145-151`), AD-34 (`:179-183`), Deferred (`:355`), Stack (`:219-220`).

**Evidence:**
- AD-31: install each app at `<install>/apps/<app>/<tag>/`, create the **shared** `<install>/apps/node_modules/ags-platform` shortcut, and `dotfiles-v3` owns the per-app list of `(repo, tag, config link, optional bin link, bar palette pointer)` — **no platform-version field per app**.
- AD-34: each app repo pins `ags-platform` **and** `contracts` by git tag/commit and runs a conformance test.
- Deferred: “Exact `contracts`/`ags-platform` tags per app — set at each app cutover.”
- Brownfield: the installer installs exactly one platform unit at `<install>/ags-platform/<version>/` and one shortcut (`dotfiles-provision/ansible/roles/ags_platform/vars/main.yml:32`; `ags_apps/tasks/main.yml:19,154`).

**Divergence this lets in:** app A pins platform `v0.2.0`, app B pins `v0.3.0`; the host has one shortcut pointing at one directory. Either the install silently violates one app's pin, or the generic loop grows per-app shortcuts (contradicting AD-17's one-unit shared ancestor), or every app must be re-cut over whenever one app's platform pin moves. The same applies to `contracts`: the runtime validates against its `CONTRACT_PIN` commit, while each app repo may pin a different commit. There is no compatibility set, no “app pins are dev-only” statement, and no deploy gate that every deployed app conforms to the installed platform/contract. This is precisely the multi-repo/version-skew tax the 2026-10-16 GUIDE warned about, and the spine never accounts for it.

**Recommendation:** decide the distribution invariant explicitly. The cleanest is: **one platform/contract version per host**, owned by `dotfiles-v3`; app-repo pins are development/CI pins, and every app cutover must pass conformance against the installed version. Add a deploy gate that reads every deployed manifest/handler and proves conformance against the installed platform/contract; add a compatibility matrix; keep exact app pins in Deferred only if this rule exists. If independent app platform versions are truly intended, AD-17 must be superseded and per-app resolution shortcuts specified.

**Disposition:** discuss (architectural decision), then autofix the spine text and the Deferred entry.

#### F2 — No runtime activation/transition rule across the app-by-app migration; the bar is not discoverable (HIGH)

**Where:** AD-26 (`:80-87`), AD-30 (`:128-138`), AD-20/AD-32 inherited (`:53-54,153-162`), AD-33 pilot (`:169`), Supersedes (`:59-62`).

**Evidence:**
- AD-26: “A missing or invalid manifest means the runtime does nothing to that app and logs a structured error. **There is no legacy path.**”
- Current runtime discovery only sees `ags run` processes that carry a `-d/--directory` argument (`ags_reloader.py:110-148`); the bar is launched as bare `ags run` and is restarted separately (`:13-18,175-196`). `gui_tools_ags_instances` confirms the bar's launch is `ags run` (`gui_tools/vars/main.yml:200-203`).
- The program order is clipboard pilot first, bar last (AD-25/AD-33; REQ-009/REQ-015). The memlog records “the whole machine migrates in this program, so no extra effort is spent on a transitional restart path” (`.memlog.md:16`).

**Divergence this lets in:**
1. If the no-legacy runtime ships with the pilot (or any time before the last app), every unmigrated app — notifications, capture, wallpaper-selector, icme, btop (and the bar if not separately handled) — is not refreshed and goes stale on every palette change. The notifications progress card and the selector's visible window are user-visible casualties.
2. If the runtime keeps the old skip/restart path until REQ-016, the pilot cannot prove `palette-refresh` end-to-end, and the old restart/skip policy (including capture's exit-0 race) remains longer than the program claims.
3. The bar is outside discovery. AD-30 fixes it as the only restart app, but AD-26 says the runtime discovers running apps and reads each manifest. Nothing says whether the bar is found by `<install>/config/ags/app.manifest.json`, by a fixed bar entry, or by hardcoded behavior. If hardcoded, AD-26's “no hardcoded runtime app list” is false for the one app that matters most.

**Recommendation:** add an explicit activation rule to AD-26/AD-32, e.g.:
- the runtime reads manifests for every discovered app;
- an app with no manifest follows a **named, shrinking legacy behavior** derived from the old role's exclusion/live list, or is explicitly left stale with a structured log;
- the legacy set is removed at REQ-016;
- the bar is a named exception with a defined discovery path (`<install>/config/ags` or an explicit `bar` entry) and its manifest mode is read (or the ADR states restart is hardcoded).
Add a fake-runtime test for the transition and the bar path. Align REQ-015 (its acceptance still says the bar child chooses live/restart, while AD-30 already decides restart).

**Disposition:** discuss + autofix; also update REQ-015 (see F5).

#### F3 — Theme provider replacement is Deferred while the spine mandates new live consumers (HIGH)

**Where:** AD-27 (`:94-100`), AD-30 (`:133-137`), Deferred (`:348-350`), Workstreams (`:333`), inherited AD-13 (parent `:134-138`).

**Evidence:**
- The parent AD-13 makes Theme the only palette path; the SPIKE proves the current adapter calls `app.apply_css`, which creates a provider, adds it, and never removes the previous one; the three existing live apps call it on every `done`/`error` (`SPIKE-001` §“Extra finding”, lines 265-275; `/usr/share/ags/js/lib/gtk4/app.ts:170-210`).
- The new spine adds live refresh to clipboard, capture, and btop (AD-30: “every other app is live”), so six apps will use the leaking port.
- The Deferred entry says the replacement is “a separate existing bug; required before new live refresh work is considered safe for provider accumulation.” That is a blocking prerequisite, not a deferrable concern.
- The Workstreams table assigns “Theme provider replacement” to `ags-platform`, but no AD, cutover gate, or acceptance condition makes it a prerequisite for REQ-009/010/011.

**Divergence this lets in:** each app can land a live path on a port that accumulates one CSS provider per palette change. Some apps may compensate with their own provider (violating AD-13), some may leak, and the platform helper may be fixed later in an incompatible way. The known bug is the exact thing the spine says must be fixed before the new live work is safe.

**Recommendation:** make it a blocking prerequisite in the contract, not only in Deferred:
- add an AD-27 clause that every live app must use one dedicated palette provider (add-new/remove-old) until the port replacement lands, with a provider-count conformance test;
- or promote an AD that the `ags-platform` Theme replacement is a hard gate for REQ-009/010/011 cutovers;
- add the gate to the Workstreams/REQ dependency tables and the cutover checklist.
If the replacement is genuinely out of this program, then AD-30 cannot say “every other app is live” until it is done; the affected apps should stay restart or be explicitly blocked.

**Disposition:** discuss; autofix the Deferred/gate text.

#### F4 — Live refresh has no state-preservation rule; `holdsUnsavedState` only forbids restart (HIGH)

**Where:** AD-26 (`:80-87`), AD-27 (`:94-100`), AD-30 (`:133-137`), EPIC-002 done-when (`tickets/EPIC-002.../ticket.md:100`).

**Evidence:**
- AD-26 declares `holdsUnsavedState: boolean`; AD-30 uses it only to invalidate `mode: restart`.
- AD-27 says the command is idempotent, returns `{"ok":true}`/`{"ok":false}`, and is invoked after the palette repoint. It says nothing about preserving in-memory state or in-flight UI.
- EPIC-002's done-when: “`btop-theme-studio` never loses pending edits on a wallpaper change.”
- Brownfield: btop's pending edits live only in an in-memory map until Save (`btop-theme-studio/ui/StudioWindow.tsx:87-113,453-462`); REQ-010 explicitly requires the live handler to preserve pending edits and report a stale/generated base. Capture's `palette-refresh` must also not disrupt an open capture/settings surface (REQ-011).

**Divergence this lets in:** an app can satisfy AD-27 by reloading `colors.yaml`/the generated map and rebuilding its reactive state, clearing the pending map, and returning `{"ok":true}`. The runtime cannot tell. The epic's core data-loss invariant would then depend on each app's ticket, not on the shared contract. The same applies to capture (a live refresh could rebuild the window set while a capture/settings interaction is open) and to the bar if it ever moves live.

**Recommendation:** add a shared rule in AD-27 (or AD-30):
- a live `palette-refresh` MUST preserve in-memory unsaved state and in-flight user interactions;
- `holdsUnsavedState: true` requires a preservation test in the app's conformance suite and a documented pending policy (refresh chrome + mark generated base stale, or block the generated-base reload while pending);
- the handler must not rebuild or destroy the user's active surfaces as a side effect of applying the palette.
The exact btop policy can stay in REQ-010; the invariant is shared and belongs in the spine.

**Disposition:** autofix AD-27 + template/conformance requirement; discuss the exact btop policy in REQ-010 (already scoped).

#### F5 — The spine supersedes EPIC/REQ clauses but records only the GUIDE/parent-Deferred supersession (HIGH)

**Where:** Supersedes (`:59-62`); AD-26 (`:80-87`), AD-30 (`:133-137`), AD-32 (`:160-162`), AD-35 (`:185-194`).

**Evidence — the level below still says the opposite:**
- EPIC-002 contract (`tickets/EPIC-002.../ticket.md:56-72`): manifest declares a **transient-obligation** flag and a command name; “no manifest means legacy restart”; “`restart` is allowed only as an explicit, change-gated fallback”; open decisions `:130-138` include whether restart is permanent, whether the bar is migrated, and what `ags-apps` becomes.
- REQ-008 acceptance (`tickets/REQ-008.../ticket.md:48-50`): prototype “no-manifest legacy”.
- REQ-009 (`tickets/REQ-009.../ticket.md:16-33`): “Keep the deployed config directory `ags-hypr-pano` and the AGS instance name `hypr-pano` unchanged”; manifest declares `refresh: live`.
- REQ-010 (`:25-32`) and REQ-011 (`:24-36`): use `refresh: live`, `holdsUnsavedState`, and (REQ-011) “the transient-obligation flag”; REQ-011 still offers live **or** restart.
- REQ-015 (`:18-33`): the bar child makes the live-vs-restart decision.
- REQ-016 (`:24-31`): decide whether `ags-apps` becomes a meta repo or is archived.
- The spine instead fixes `mode: live|restart` (AD-26), a fixed command name (AD-26), no legacy path (AD-26), bar restart (AD-30), archive (AD-32), and the full clipboard rename (AD-35).

**Divergence this lets in:** the child implementers are the “level below”. If they read their tickets (as the ticket flow requires), they will implement the old contract: keep `hypr-pano` names, use `refresh`, expect a legacy manifest path, leave the bar's mode open, and leave the archive open. The spine's AD-35 rename cannot land through a REQ-009 that explicitly requires stable names. This is the most direct handoff failure in the document.

**Recommendation:** add a **“Supersedes (program-level)”** table to the spine listing the exact clauses and their replacements:

| Superseded | Replacement |
| --- | --- |
| EPIC-002 contract `:56-72` transient flag/no-manifest legacy/restart fallback | AD-26 `mode`, `holdsUnsavedState`, no legacy; AD-30 all-times-safe restart |
| EPIC-002 open decisions `:130-138` | AD-30 bar restart; AD-32 archive |
| REQ-008 acceptance `:48-50` no-manifest legacy | AD-26 |
| REQ-009 `:16-33` stable `hypr-pano`/`ags-hypr-pano`, `refresh: live` | AD-35 rename; AD-26 `mode: live` |
| REQ-010/REQ-011 `refresh`/transient flag/choice | AD-26 `mode`; AD-30 fixed live for capture |
| REQ-015 bar choice | AD-30 bar restart |
| REQ-016 meta-vs-archive | AD-32 archive |

Then amend the child tickets (or add a “must read the spine” gate to each child's triage) before they start. The spine can be authoritative without editing every ticket now, but it must name the supersessions so the parent can dispatch the updates.

**Disposition:** autofix the supersession table; update child tickets (or add the gate) before REQ-009 starts.

#### F6 — Inherited gate discipline is narrowed without an explicit supersession (HIGH, governance)

**Where:** AD-33 (`:164-173`), Inherited table (`:53-57`), parent AD-19 (`ARCHITECTURE-SPINE.md:170-174`), parent AD-23 (`:194-202`).

**Evidence:**
- AD-33: “typecheck is local, pure tests run in stock CI.”
- Parent AD-19: “before extraction begins, `bar-typecheck` and `ags-typecheck` must cover the extracted surface and **run in `gates-ci`**; the per-app drift/symbol suites run in the root gate.”
- Parent AD-23: “CI on GitHub Actions — a stock runner for pure gates and a **self-hosted linux runner for desktop-stack typechecks**”; “`ags-platform` runs typecheck + tests; `ags-apps` runs typecheck + the per-app drift/symbol suites.”
- The new spine says the parent is “binding read-only except where this spine explicitly supersedes its Deferred items” (`:43-44`), then rephrases AD-19/23 in the Inherited table as “every app repo and consumer repo gates its own change” / “per-repo CI, pinned installs, fresh-host verification” — dropping the typecheck/self-hosted clauses without a supersession.
- Brownfield: `ags-apps/AGENTS.md` §4 says typecheck is local and there are **0** registered self-hosted runners; `.github/workflows/*` are all `ubuntu-latest`. The parent AD-23 clause is stale, but it is still `status: final` and binding.

**Divergence this lets in:** “green” means different things in the parent and the new spine. Each app repo can decide whether typecheck is a merge gate; a local-only gate has no CI enforcement for agent/PR work; the parent's AD-19 “run in `gates-ci`” is not met by a pure-test CI. The spine cannot both inherit AD-19/23 and adopt local typecheck without saying which clause wins.

**Recommendation:** explicitly supersede the two parent clauses with the brownfield evidence and the replacement enforcement:
- AD-23 self-hosted typecheck clause → stock-runner CI only; desktop typecheck is a local gate.
- AD-19 `gates-ci` typecheck clause → each app repo's `make <app>-typecheck` is a local merge gate; CI runs the pure tests + drift/conformance gates; the cutover evidence records the local typecheck result (command + exit) before merge.
Add the supersession to the parent spine or a “Supersedes” note in the new spine, and add the local-gate evidence requirement to AD-33/REQ acceptance. This is a straightforward autofix once the decision is recorded.

**Disposition:** autofix (record the supersession) + discuss whether the local gate is enforced by a pre-push hook or only by agent discipline.

### 4.2 Medium

#### M1 — AD-29 leaves the CLI palette-hash gate undecided and does not define partial-failure semantics

**Where:** AD-29 (`:121-126`); AD-27 no `ok:false`; `reconcile.py:81,325-347`; SPIKE-001 `:199-203`.
**Evidence:** AD-29 says the CLI needs “its own palette-hash gate **or** an explicit no-reload mode for login”, but a fresh CLI process has no last-applied hash; `last-converged.json` is daemon-only (SPIKE); the current `reload_failures` is a list of reloader class names, not per-app state.
**Divergence:** the core “no-op reconcile must not restart” behavior can be implemented two different ways with different semantics (gate vs skip); a partially failed refresh has no “last applied” definition, so a failed app either retries on the next no-op (violating “no retry”) or stays stale until the next real palette change (unstated). The gate's state store is a shared daemon/CLI concern, not a runtime-local detail.
**Recommendation:** decide the mechanism (persisted palette-applied record, or explicit `--no-reload` for login), define per-app last-success/failure semantics, and state the no-op completion event. Add a fake-runtime test: unchanged palette + one previously failed app → no refresh, no restart, failure remains visible.
**Disposition:** discuss + autofix.

#### M2 — AD-32's cutover is not atomic across repos and the old exclusion list is a second source of truth

**Where:** AD-32 (`:153-162`), AD-31 (`:145-151`), current `ags_apps` role (`dotfiles-provision/.../ags_apps/{vars,tasks}`), `dotfiles-v3/dotfiles/provisioning/installer.pin`, `dotfiles-v3/scripts/deploy-coverage.py`, `gui_tools/vars/main.yml:200-235`.
**Evidence:** the old role is in `dotfiles-provision`; the per-app list is in `dotfiles-v3`; the installer pin selects the engine; `deploy-coverage.py` reads the cached engine checkout. AD-32 says “one commit set” adds the dotfiles-v3 list entry, adds the old role's exclusion, removes the old link, and verifies one owner. Those edits span at least two repos.
**Divergence:** the “exactly one owner at every commit” invariant cannot be true across two independent repos; a zero-owner or two-owner window exists unless the activation commit and the installer-pin bump are ordered explicitly. The manual exclusion list duplicates the per-app list — exactly the “second source of truth” pattern AD-34 is meant to prevent. The launch/always-on entries (`gui_tools_ags_instances`) are a third list not covered by AD-31.
**Recommendation:** derive the old role's exclusions from the same per-app list (or add a one-owner assertion in `deploy-coverage.py` that reads both); define the activation order (old role excludes + engine tag → dotfiles-v3 installer pin bump + list entry in one commit); add the launch policy to the per-app list or explicitly state `gui_tools` remains the launch owner; add a fake cutover test for the zero/two-owner window.
**Disposition:** autofix/design.

#### M3 — The failure contract omits `{"ok":false}` and `reload_failures` is reloader-level, not per-app

**Where:** AD-27 (`:96-100`), AD-28 (`:108-114`), `contracts/event-contract.json:92-102`, `reconcile.py:81,325-347`, `notifications/ui/NotificationsWindow.tsx:361-362`, `hypr-pano/lib/requests.ts:37-53`.
**Evidence:** AD-27 says the app returns `{"ok":true}` or `{"ok":false,"error":"..."}`, then lists “malformed/empty response, non-zero exit, or 5-second timeout” as failures — **not** `ok:false`. The current event contract carries `reload_failures` as an array of strings; the runtime populates it with reloader class names (`AgsReloader`), not app instances. Existing handlers return plain `"ok"` strings, so the new JSON contract is a behavior change.
**Divergence:** an implementer can treat `ok:false` as success because the CLI exits 0; the notification card can show one opaque `AgsReloader` string instead of the failed apps; per-app structured logs and the event summary can disagree.
**Recommendation:** add `{"ok":false}` explicitly to the failure list; define stdout parsing (exactly one JSON object; ignore stderr/log lines), define the per-app failure record shape (or a documented encoding in the existing string array), and update the `wallpaper.state` note. Add an app-handler test with `ok:false` and a malformed response.
**Disposition:** autofix AD-27/28 + update `contracts` (M11).

#### M4 — The clipboard rename retires names that the runtime daemon and app data still need

**Where:** AD-35 (`:185-194`); `hypr-pano/lib/history.ts:15-17`; `dotfiles-runtime/src/runtime/adapters/clipboard_config.py:31-35`; `json_history_store.py:53-59`.
**Evidence:** the app reads `~/.local/state/hypr-pano/history.json`; the runtime daemon reads `~/.config/hypr-pano/config.json` and writes `~/.local/state/hypr-pano/history.json` / `~/.cache/hypr-pano/`; AD-35 says “The runtime clipboard daemon keeps its name” but also “The old `hypr-pano` names are retired.”
**Divergence:** an implementer who “retires” the data paths breaks the app/daemon contract or splits history; an implementer who keeps them leaves the rename incomplete. The user-visible config file and history are not covered by the AD's field/instance/window/launcher list.
**Recommendation:** enumerate the retained paths as explicit exceptions (runtime daemon config, state, cache; app history read path), or define a one-time migration and ownership. Add a cutover check that history survives the rename and the daemon/app still agree on the path. Update AD-35 and REQ-009.
**Disposition:** autofix + discuss (data migration).

#### M5 — Manifest schema evolution and cross-field validation are undefined

**Where:** AD-26 (`:80-87`), AD-34 (`:179-183`), parent AD-16 (`:152-156`).
**Evidence:** `schemaVersion: 1` is fixed; no rule for additive vs breaking changes, unknown versions, or validation of `configDir` against the discovered directory and `instance` against the live D-Bus name. AD-34 says the runtime validates “against the pinned contract”, but the manifest schema is new and has no drift gate comparable to the event contract's regenerate-and-diff (parent AD-6).
**Divergence:** app A and app B can ship different field sets under the same `schemaVersion`; a future v2 manifest can be silently treated as invalid and the app left stale; a mismatched `configDir` can make the runtime read the wrong manifest or invoke the wrong instance.
**Recommendation:** define the evolution rule (additive stays v1; removed/retyped/newly-required bumps), unknown-version behavior (no-op + structured log, not crash), and the cross-field checks (`configDir == discovered dir name`, `instance == live instance`). Add a manifest-schema drift test in `contracts`/app conformance. Put the evolution rule in AD-34.
**Disposition:** autofix.

#### M6 — The template does not say how an app repo obtains `ags-platform`/`contracts` for local typecheck and stock CI

**Where:** AD-33 (`:164-173`), AD-34 (`:179-183`), template seed (`:248-264`), parent Open Question (`:317`), current `ags-apps/Makefile:32-35,103-130`, `.github/workflows/hypr-pano.yml:31-40`.
**Evidence:** the current repo fetches `ags-platform v0.2.0` into `.dev/ags-platform/<tag>` and symlinks it from `node_modules`; the Makefile comment records the Node type-stripping constraint (`ERR_UNSUPPORTED_NODE_MODULES_TYPE_STRIPPING`) and the symlink-outside-node_modules workaround. The per-app seed has no `.dev`, package.json, tsconfig, or CI contract checkout; the current workflows check out `contracts` at the default branch (no `ref`).
**Divergence:** each app repo can invent its own acquisition (submodule, script, sibling checkout, unpinned CI checkout), so `make typecheck`/pure tests are not reproducible and the conformance test may run against a different contracts commit than the runtime.
**Recommendation:** add the dev acquisition and CI checkout to the template seed/AD-33: fetch `.dev/ags-platform/<tag>` (or the configured platform pin) and `.dev/contracts/<commit>`, create the `node_modules/ags-platform` symlink outside node_modules, and check out the pinned contracts commit in CI. Add a template-conformance check (or a generator later) so the six copies don't drift.
**Disposition:** autofix/design.

#### M7 — The operational envelope is still silent on AGS pinning, rollback, existing-host migration, repo visibility, and log destination

**Where:** Stack (`:212-221`), Deferred (`:342-358`), parent AD-23 (`:194-202`), parent Open Questions (`:315-320`), current `ags_platform` role (`vars/main.yml:32`), `dotfiles-v3/dotfiles/provisioning/installer.pin`, `ags_apps/tasks/main.yml:12-19`.
**Evidence:** the parent open questions explicitly include AGS/Astal version pinning, the TypeScript pin, the package boundary/Node type-stripping, and framework unit versioning/rollback. The new spine names AGS 3.1.0/3.1.2 in Stack but does not pin the host package, does not define per-app rollback, does not describe the existing-host migration from `<install>/ags-apps/<tag>` to `<install>/apps/<app>/<tag>`, does not say whether new app repos are public or private (and which credential path), and does not say where the structured log records go or how long they are kept.
**Divergence:** a fresh host and an existing host can end up with different layouts/links; an AGS update can break `ags request` for every app; an app rollback can leave the shared platform/contracts mismatched; logs can be unreadable or lost; private app repos can fail provisioning.
**Recommendation:** add an “Operational Envelope” subsection with decided/deferred/open entries for: AGS/Astal pin policy (and the revisit condition), platform/contracts compatibility (F1), per-app rollback (repoint config link; keep version dirs), existing-host migration (old dirs/links/backups), repo visibility/credentials/branch protection, log sink/retention, the bar's restart-failure recovery, and the restart lane's bound plus its interaction with autostart's concurrent `ags run` (the shared-bundle race). Carry the parent open questions with their revisit conditions rather than dropping them.
**Disposition:** discuss + autofix.

#### M8 — Direct `app → contracts` pins blur inherited AD-1

**Where:** parent AD-1 (`ARCHITECTURE-SPINE.md:44-48`), new Inherited table (`:48`), AD-34 (`:179-183`).
**Evidence:** the parent rule is `contracts ← ags-platform ← ags-apps` and “an app depends on the platform (and, transitively, contracts)”. AD-34 says each app repo pins `ags-platform` **and** `contracts`.
**Divergence:** a direct app→contracts dependency can be either a test-only conformance dependency or a runtime import. If runtime, the parent diagram/rule needs a supersession; if test-only, the spine should say so, or apps will import `contracts` directly and the platform's role as the single consumer narrows.
**Recommendation:** state “apps consume contracts only for manifest/type conformance tests, never at runtime; all runtime contract access goes through `ags-platform`” — or add contracts as a permitted direct edge and update AD-1/the diagram.
**Disposition:** autofix.

#### M9 — “Idempotent by palette hash” and the 5-second timeout have no defined semantics

**Where:** AD-27 (`:96-100`), AD-28 (`:108-114`), AGS `app.ts:272-296`.
**Evidence:** the contract does not say whether the app must cache the hash and skip re-application, or merely be safe to re-apply. A 5-second client timeout kills the `ags request` CLI while the app may still be applying; the app's `res` callback may be lost; the next refresh can overlap. Existing handlers return plain strings, so there is no reuse precedent.
**Divergence:** some apps skip, some re-apply; the skip path can miss a provider fix; the timeout can leave a half-applied palette and a later refresh racing it.
**Recommendation:** define same-hash behavior (prefer: the handler compares the hash and returns `{"ok":true}` without re-applying; the app stores its last applied hash), define that a timeout is a client-side abandonment and the app must make the apply atomic or re-check the hash before mutating, and add a test for a timed-out handler.
**Disposition:** autofix/design.

#### M10 — The supersession of the GUIDE decision does not account for its exit gate or the skew-tax risk

**Where:** Supersedes (`:59-62`), GUIDE §7 (`docs/GUIDE-ags-app-repos-refinement.md:83-95`), parent Open Questions (`:315-320`), memlog `:31`.
**Evidence:** the GUIDE's decision to stay at three repos was conditional: “Exit gate for a future per-app split: AD-6 + AD-17 + AD-21 closed, `ags-bar-validate` green in provisioning, and one pilot proves the harness/install cost. Until then, independent lifecycles alone do not earn the tax.” The spine says the pilot proves the harness/install and the per-app split is the decision of record, but does not say which of AD-6/17/21 are closed, does not show `ags-bar-validate` (the bar is last), and does not address the skew-tax caution.
**Divergence:** the superseding decision record is incomplete; a future reader cannot tell whether the exit gate was met or consciously waived. The skew tax is exactly F1.
**Recommendation:** add a short “Why now / exit-gate accounting” subsection: what changed (user direction, pilot-first, per-app template, install topology), which exit-gate items are met/unmet, and the mitigations for skew/rollback. Or record the same in Deferred/Open.
**Disposition:** autofix.

#### M11 — The canonical `wallpaper.state` note still claims it drives live refresh

**Where:** `contracts/event-contract.json:92-102`, AD-27 (`:99-100`), AD-34 (`:179-183`).
**Evidence:** the note says the topic “drives the wallpaper selector's progress indicator and **LIVE refresh**”; AD-27 says it is the progress/UI event, not the palette-refresh trigger, and live refresh must not subscribe to it for palette.
**Divergence:** app and runtime implementers reading the canonical contract will implement the old trigger; the drift test may not catch a semantic note mismatch.
**Recommendation:** add the contract-note update to AD-27/AD-34 and the `contracts` workstream; add a check that no app's palette path subscribes to `wallpaper.state` (the progress path may still subscribe).
**Disposition:** autofix.

#### M12 — The per-app install list omits launch/always-on policy, which today lives in `gui_tools`

**Where:** AD-31 (`:145-151`), `gui_tools/vars/main.yml:200-235`, AD-32 (`:153-162`), AD-35 (`:185-194`).
**Evidence:** `gui_tools_ags_instances` carries `always_on` and the exact `ags run` launch for notifications and the bar; the other apps are on-demand. AD-31's per-app list has repo/tag/config link/optional bin link/bar palette pointer only.
**Divergence:** the generic per-app loop can install an app but not start it; if `gui_tools` remains the launch owner, the cutover has two lists and the clipboard rename can leave a stale `hypr-pano` instance entry; if the launch policy moves, AD-31's list is incomplete.
**Recommendation:** decide and document the launch owner. Either add `always_on`/launch to the per-app list (and have the generic loop emit the instance entries), or state that `gui_tools_ags_instances` stays the single launch source and add the clipboard rename to AD-35/REQ-009 and a deploy-coverage check for the instance set.
**Disposition:** discuss/autofix.

### 4.3 Low

- **L1 — AD-28 wording:** “Every app emits a structured log record” is the runtime's act; the app emits the JSON response. Reword to “the runtime emits one record per app”. (`:108-114`.)
- **L2 — Stack specificity:** replace “existing pinned tag/contract” with the actual platform tag (`v0.2.0`) and contracts commit (`dbdc5b8`), or move them to Deferred/Open with the compatibility rule. (`:219-220`.)
- **L3 — Discovery order:** AD-28 orders the summary by “discovery order”; `/proc` order is not stable. Define sorted-by-instance or config-dir order. (`:110`; `ags_reloader.py:110-148`.)
- **L4 — Workstreams duplicate:** `dotfiles-runtime` appears twice (`:334` and `:340`). Editorial.
- **L5 — AD-25 link wording:** “The deployed config link points at the repo root” should say “the installed app root (`<install>/apps/<app>/<tag>/`)”, matching AD-31. (`:72-73`.)
- **L6 — AD-32 “test that app”:** define the minimum cutover test (bundle + typecheck + pure tests + deploy-coverage + a manual/GUI-free smoke), rather than a vague “test that app”. (`:160`.)
- **L7 — Old resolution shortcuts:** AD-31 creates `<install>/apps/node_modules/ags-platform` but does not say the old per-unit `<unit>/node_modules/ags-platform` and `<install>/config/node_modules/ags-platform` shortcuts are removed/ignored. Two shortcuts can drift. (`dotfiles-provision/.../ags_apps/tasks/main.yml:19,154`; `ags_platform/vars/main.yml:59-66`.)

---

## 5. What the spine gets right

This is not a weak draft; it is a strong app-level contract with program-level seams.

- **Clear paradigm and layer table** (`:23-39`): the process contract is a real new layer, and the table places it correctly.
- **Inherited-invariants table + explicit supersession** (`:41-62`): the parent is read-only, the GUIDE/Deferred override is named, and the parent ADs are mapped. (The supersession list needs to be wider — F5/F6 — but the mechanism is right.)
- **Manifest is small and concrete** (`:76-87`): instance, config dir, mode, unsaved flag, one fixed command. No `restartReason`; the ADR carries the human justification.
- **Command/response/timeout/failure/summary** (`:89-114`): the shape is testable; the 5s parallel lane, per-app structured record, discovery-order summary, no retry/no fallback, and “stale, not dead” failure surface are exactly what the spike recommended.
- **Restart semantics are sharp and user-aligned** (`:128-138`): explicit mode, all-times-safe assertion, invalid for editors/unsaved, never a fallback, bar-only final set.
- **Install topology absorbs the real esbuild finding** (`:140-151`, `:225-246`): moving all app checkouts under `<install>/apps/` makes `<install>/apps/node_modules` an ancestor of every real path; the brownfield per-unit shortcut was a workaround for the old `config/node_modules` placement. This is the best technical call in the document.
- **One-owner cutover with a shrink-only old role** (`:153-162`): the right strangler-fig invariant, even if the cross-repo mechanics need M2.
- **Per-repo dev flow and stock-CI reality** (`:164-173`): AGENTS, tickets, worktree guard, Makefile, CI, README, annotated tags, local typecheck, pure stock tests — all match the brownfield.
- **Contract ownership/versioning** (`:175-183`): contracts owns the schema/protocol, platform supplies types/helper, runtime validates, app repos pin and conformance-test, schemaVersion starts at 1, git tags/no registry.
- **Clipboard rename is end-to-end** (`:185-194`): repo/config/instance/window/launcher/keybind, with the runtime daemon explicitly exempted. (The data paths need M4.)
- **Capability map / Workstreams / Deferred / Evidence** (`:316-370`): the document is navigable and the claims point at real artifacts.
- **Mechanical lint is clean.** No placeholders, duplicate AD ids, or missing Binds/Prevents/Rule.

---

## 6. Bottom line

**Verdict: revise.**

The spine is close on the app-level contract and should not be rewritten. It needs four program-level decisions before handoff:

1. **F1** — one platform/contracts version per host, or per-app resolution; define the compatibility gate.
2. **F2** — the runtime activation/transition rule across the migration, plus the bar's manifest/discovery path.
3. **F3** — make the Theme provider replacement a blocking prerequisite (or an AD-27 workaround) before new live consumers.
4. **F4** — add the live-refresh state-preservation invariant (btop/capture) to AD-27.

Then the handoff fixes:

5. **F5** — a program-level supersession table, and amend the child tickets before REQ-009 starts.
6. **F6** — explicitly supersede the parent AD-19/AD-23 CI clauses with the brownfield evidence and the local-gate enforcement.

The medium tail (M1–M12) is mostly contract completeness: the CLI gate state, cross-repo cutover atomicity, per-app failure records, clipboard data paths, manifest schema evolution, template acquisition, operational envelope, AD-1 clarity, idempotency, the GUIDE exit-gate accounting, the `wallpaper.state` note, and launch policy. None requires a new paradigm; all are fixable in the spine or in the child tickets it governs.

With F1–F4 resolved and F5/F6 recorded, this spine would pass the rubric: it fixes the real divergence points for the level below, every AD would be enforceable, the Deferred list would contain no unit-diverging item, and the operational envelope would be decided or explicitly open.
