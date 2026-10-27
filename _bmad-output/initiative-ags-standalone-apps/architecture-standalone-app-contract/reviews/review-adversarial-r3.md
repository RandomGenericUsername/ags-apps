# Adversarial Consistency Review — Third Pass (Final Gate)

- **Reviewer lens:** adversarial-consistency, final pass. The test is unchanged: construct two units one level down (an app repo, `dotfiles-runtime`, `dotfiles-v3`, `dotfiles-provision`, `ags-apps`) that each obey every AD to the letter, yet still build, deploy, or drive the desktop incompatibly.
- **Target:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md` (draft, 2026-10-26, 551 lines), `.memlog.md`, `tickets/EPIC-002-apps-standalone-repos/ticket.md`, `tickets/REQ-008…REQ-016/ticket.md`, and the r2 findings `reviews/review-adversarial-r2.md`.
- **Codebase read (read-only):** `ags-apps`, `dotfiles-runtime`, `dotfiles-provision`, `dotfiles-v3`, `dotfiles-assets`, `contracts`, `ags-platform`; AGS 3.1.0 CLI / 3.1.2 JS.
- **Date:** 2026-10-26
- **Shorthand:** `SPINE` = the target spine; `EPIC` = EPIC-002; `REQ008`/`REQ009`/… = those tickets; `PROVISION` = `dotfiles-provision`; `V3` = `dotfiles-v3`; `ASSETS` = `dotfiles-assets`.

**Verdict: BLOCK — do not freeze and do not start the pilot (REQ-009) until H1–H3 are fixed.**

The revision closes the r2 critical adoption gap (N1) and most of the spatial contract: install-path identity, restart-app-down discovery, cutover ordering/rollback, deferred status/ledger retry, the every-`ags run` lock, template ownership, the `dotfiles-assets` tuple, and the app-list ownership fields. N3–N12 are resolved at the contract level, with the medium residuals listed in §4.

Two things stop the freeze:

1. **N2 is only half closed.** The monorepo is now re-pinned to the program tuple (the version-skew half is fixed), but `AD-32` step 2 still says platform/contracts/assets prerequisites are released and pinned **per cutover epoch**, while the Stack says the exact tuple tags are set at the REQ-008 release. There is still no single machine-readable tuple record, so no verify unit can enforce AD-34's equality. A later cutover can legitimately pin T2 against a T1 install.
2. **The fixes introduced new high contradictions.** The explicit "the bar has no handler" rule now collides with AD-32's handler verification, AD-33's "every app repo carries … handler" template-conformance rule, and EPIC's "(including the bar)" handler adoption. Separately, the new "scaffold-to-green … with one command" pilot threshold collides with the Deferred "automated repo generator is deferred until the pilot proves the copy."

N9's overbroad-looking discovery wording ("every deployed link under `<install>/config`") is **not** a live break today: the non-AGS spine entries are directories, not links (evidence in §4.3). The remaining N9 gaps are the `--include-dev` contradiction and the bar's bare `ags run` default; both are medium, not freeze blockers.

---

## 1. Summary

| # | r2 finding | Severity after r3 | r3 status | Primary evidence |
| --- | --- | --- | --- | --- |
| N1 | Manifest adoption lacks `palette-refresh`; runtime switch breaks live apps | CRITICAL | **RESOLVED** | `SPINE:301-313`; `EPIC:45-48,83-85`; `REQ008:72-74` |
| N2 | One tuple is not migration-aware; per-cutover drift | CRITICAL | **PARTIAL** | `SPINE:201-206,222-224,359`; `AD-31:208-213` has no tuple fields; brownfield four pins |
| N3 | Install path `<app>` vs seed `capture-tool` | HIGH | **RESOLVED** | `SPINE:197-199,208-213,368-384` |
| N4 | `colors.css` seeder-owned inside the read-only tag | HIGH | **RESOLVED (M)** | `SPINE:320-324`; residual actor/order note |
| N5 | `icons.json` input not in tuple; relocation after capture cutover | HIGH | **RESOLVED (M)** | `SPINE:201-206,325-327`; residual REQ-008 acceptance note |
| N6 | Ownership predicate covers surfaces the app-list schema cannot name | HIGH | **RESOLVED** | `SPINE:208-213,236-240,347` |
| N7 | "Failed restart retried" vs "bar down → no hidden launch" | HIGH | **RESOLVED** | `SPINE:106-107,183-190` |
| N8 | Cutover list flip/install before stop; no confirmed quit/new-instance check | HIGH | **RESOLVED** | `SPINE:221-240`; plus H1 handler wording |
| N9 | Discovery "valid manifest" vs invalid failure; dev instance can be refreshed | HIGH | **RESOLVED (M)** | `SPINE:100-110`; medium residuals in §4.3 |
| N10 | "preserve or defer" vs "`ok:true` means applied" | HIGH | **RESOLVED** | `SPINE:122-124,166-170,341-343` |
| N11 | Launch lock does not cover on-demand launchers | HIGH | **RESOLVED (M)** | `SPINE:151-153,348`; residual lock lifetime note |
| N12 | Pilot gate has no thresholds; template defined by the pilot | HIGH | **RESOLVED (M)** | `SPINE:247-261`; `REQ008:81-83`; plus H2 "one command" conflict |
| H1 | Bar "no handler" vs universal handler verification/template/EPIC | **HIGH (new)** | **OPEN** | `SPINE:230-231,250-252,306-308`; `EPIC:83-85` |
| H2 | Pilot one-command scaffold vs deferred generator | **HIGH (new)** | **OPEN** | `SPINE:256-261,529-530`; `REQ009:68-72` |
| H3 | N2 residual: per-epoch tuple release + no tuple record | **HIGH (residual)** | **OPEN** | `SPINE:222-224,359`; four brownfield pins; legacy shortcut |

The rest of this review verifies N1–N12 in §2, details the new high contradictions in §3, records medium residuals in §4, credits the closed fixes in §5, and records the check in §6.

---

## 2. N1–N12 verification

### N1 — Manifest + handler adoption before the runtime switch

**Status: RESOLVED.**

`AD-36` now requires the monorepo to be re-pinned and released, every currently deployed app (including the bar and every still-monorepo app) to receive `app.manifest.json`, and **every live app to receive a `palette-refresh` handler in the same monorepo release**; the bar is explicitly `restart` with no handler (`SPINE:301-313`). EPIC says the manifests and live handlers are adopted before the runtime is enabled (`EPIC:45-48`), and REQ-008 makes the adoption an acceptance item (`REQ008:72-74`). The r2 two-unit construction — Unit A adds only manifests, Unit B invokes the command after the switch — is closed: the same adoption release now carries the handler.

The one remaining defect is the **bar exception** and is counted as H1, not re-opened here.

### N2 — One program tuple, no per-cutover drift

**Status: PARTIAL. The legacy version-skew half is fixed; the drift/tuple-record half is not.**

**Closed:**

- `AD-31` now states the deployment has **one program tuple** — `ags-platform`, `contracts`, and `dotfiles-assets` — owned by `dotfiles-v3`, and that the current `ags-apps` monorepo is re-pinned to the same tuple during adoption (`SPINE:201-206`). `AD-34` repeats the re-pin and requires app CI/install equality (`SPINE:268-275`). `AD-36` step 1 repeats it again (`SPINE:302-304`). The r2 critical "legacy apps resolve v0.2.0 while new apps resolve v0.3.0" version skew is closed **provided the old role's `ags_apps_platform_version` is actually bumped to the program tuple** in the adoption release; the contract now says it must be.
- `dotfiles-assets` is in the tuple (`SPINE:201-206,359`), so the icon source is no longer the r2 exception.

**Open — H3:**

1. **Per-epoch drift is still licensed.** `AD-32` step 2 says "the engine/runtime/platform/contracts/assets prerequisites are released and pinned" at each cutover epoch (`SPINE:222-224`). The Stack says the exact `ags-platform`/`contracts`/`dotfiles-assets` tags are set at the REQ-008 release (`SPINE:359`). A conforming V3 unit can read the Stack and pin T1 for the program; a conforming installer unit can read `AD-32` step 2 and release T2 for a later epoch. The app-list schema has no `platformTag`/`contractsTag`/`assetsTag` field (`SPINE:208-213`), and no `program-tuple.yaml` is named, so AD-34's "install gate requires equality" (`SPINE:271-275`) has no record to compare against. The brownfield still has four independent pins: `V3/dotfiles/provisioning/installer.pin` (`v0.1.16`), `V3/dotfiles/provisioning/cli-tools.yaml` (runtime `v0.2.2`), `PROVISION/ansible/roles/ags_platform/vars/main.yml` (`v0.2.0`), and `RUNTIME/src/runtime/adapters/CONTRACT_PIN` (`dbdc5b8`). A verify unit cannot know which is "the program tuple."
2. **The legacy checkout is outside the shared ancestor.** The old role installs at `<install>/ags-apps/<tag>/` and creates a per-unit `<unit>/node_modules/ags-platform` shortcut (`PROVISION/ansible/roles/ags_apps/vars/main.yml:59-73,104-112,314-336`). `AD-31` requires "exactly one shared `<install>/apps/node_modules/ags-platform` shortcut, an ancestor of every app checkout" (`SPINE:200-204`). Re-pinning the monorepo to the same tuple removes the version skew, but it does not make the legacy checkout a descendant of `<install>/apps`, and it does not remove the second shortcut. A verify that enforces "exactly one shortcut" fails during the whole migration; a verify that ignores the second shortcut cannot enforce the rule. The contract needs an explicit migration exception (one tuple, two resolution paths, same target) or a statement that the legacy unit moves under `<install>/apps` before the runtime switch.

**Two-unit construction:** Unit A (`V3`) pins the program tuple T1 as the Stack requires and records it nowhere machine-readable. Unit B (`dotfiles-provision` epoch for a later app) follows `AD-32` step 2, releases platform/contracts/assets T2, and builds the app against T2. The install has one shared ancestor and can point at only T1 or T2. If T1, the T2 app fails AD-34's equality/bundle check; if T2, every earlier cut-over app's T1 pin fails equality. Both units obeyed every written AD. This is the original F1/N2 build incompatibility moved from "per-app pins" to "per-epoch pins."

**Fix:** State the program tuple is immutable for the duration of EPIC-002; `AD-32` step 2 may release a new **engine/runtime** (the bar restart fix is a real example) but not a new platform/contracts/assets tuple without a program-wide revalidation/retag epoch. Add `platformTag`/`contractsTag`/`assetsTag` to one named `program-tuple.yaml` or to the app-list schema; have the installer, runtime, and verify read that one record. State the legacy shortcut exception or move the legacy unit under `<install>/apps`.

### N3 — `installDir` disambiguation

**Status: RESOLVED.**

`AD-31` changes the install path to `<install>/apps/<installDir>/<tag>/`, defines `installDir` as a list field, and explicitly makes it the disambiguator (`SPINE:197-199,208-213`). The topology seed uses `capture/<tag>` and links `config/ags-capture -> ../apps/capture/<tag>` (`SPINE:368-384`); the app map's `capture` / `ags-capture-tool` split is therefore single-valued at deployment. A V3 unit can no longer derive `apps/capture-tool` from the repo stem.

Residual medium: the conventions table still says repo names are `ags-<app>` (`SPINE:336`), while the app map has `ags-capture-tool` for `capture` (`SPINE:480`). This is M12 and does not affect `installDir`; it should be aligned before the capture repo is created.

### N4 — `colors.css` stable pointer outside the immutable tag

**Status: RESOLVED (with a medium sequencing note).**

`AD-37` now says `colors.css` is a symlink created once at install inside the tag, pointing to a **stable runtime pointer outside the tag**; the runtime seeder updates that pointer, never the tag, and provisioning verifies it (`SPINE:320-324`). This is the r2 proposed fix: the tag no longer contains the writable pointer, and the seeder has one external target.

Residual medium: the sentence "after provisioning clones a tag, `<install>/apps/<installDir>/<tag>/` is read-only" (`SPINE:320-321`) and "colors.css is a symlink created once at install inside the tag" (`SPINE:322-323`) do not say **when** the read-only seal is applied or who creates the link. Read literally, provisioning seals the tag immediately after clone and then "only verifies it" (`SPINE:324`), leaving no actor to create the symlink; read the other way, provisioning writes inside a tag it just declared read-only. State the sequence: clone → provisioning creates the symlink → seal read-only; or move the link outside the tag. This is a first-install clarity issue, not a two-unit production divergence.

### N5 — Icons single producer + assets tuple before the pilot

**Status: RESOLVED (with a medium acceptance note).**

`dotfiles-assets` is now part of the program tuple (`SPINE:201-206,359`), and `AD-37` gives `icons.json` one producer: the platform artifact generated from that pinned tuple, with provisioning verifying byte equality and never writing it; app repos do not hand-author a second one (`SPINE:325-327`). The platform repo already carries `ags-platform/icons.json` (`ags-platform/icons.json`), so the "platform artifact" is a real producer, not a new app-side copy. The r2 failure mode — app CI pins assets A, provisioning uses assets B, bytes differ — is closed by the tuple.

Residual medium: `Deferred` says the exact icon artifact path/generator is a "REQ-008 acceptance detail" (`SPINE:536-537`), but REQ-008's acceptance list does not mention the icon artifact path or the producer handoff (`REQ008:49-84`). Add it to REQ-008 acceptance before the capture cutover (REQ-011), or the first app can pass while the deployed path is still the old `compositor_configs` write path.

### N6 — App-list schema/ownership surfaces

**Status: RESOLVED.**

`AD-31`'s field list now includes `installDir`, `configLink`, `spineLink`, `xdgLink`, `binLink?`, `launcher?`, `autostart?`, `launch`, `barPalettePointer?`, and `cutoverId` (`SPINE:208-213`). `AD-32` states the ownership predicate covers source checkout, spine link, XDG link, bin link, launcher, autostart entry, running process, and D-Bus name (`SPINE:236-238`); the conventions table repeats it (`SPINE:347`). The r2 gap — a schema-valid list with `launch: on-demand` that lets a stale `hypr-pano-ui` launcher/autostart entry survive — is closed at the contract level: the verifier can enumerate the declared surfaces and reject an unexpected owner.

Residual medium: the seed still pre-flips clipboard to `owner: standalone` with a `v0.1.0` tag before the pilot, and the bar entry lacks `instance`, `configDir`, and `cutoverId` (`SPINE:389-412`). This is M1: a unit that copies the seed literally deploys a repo/tag that does not exist and removes the old owner. Label the seed illustrative or show the pre-cutover state, and complete the bar entry.

### N7 — Configured restart app included when down

**Status: RESOLVED.**

`AD-26` now says live apps are invoked only when running, while restart apps are included from the configured link even when the process is down (`SPINE:106-107`). `AD-30` repeats that the configured restart app is included when down so the lane can recover a failed bar, and that a failed restart is recorded in the ledger and retried on the next trigger (`SPINE:186-190`). This removes the r2 contradiction between "retry a down bar" and "no hidden launch": the restart lane is the explicit launch path, and the ledger retry is defined as recovery, not a live fallback.

### N8 — Cutover quiesce → flip → install/start → verify, rollback

**Status: RESOLVED.**

`AD-32` now orders the epoch as: tag against the program tuple → release/pin prerequisites → **installer quiesces the old instance (confirmed quit, no process, no D-Bus name) before any link change** → owner flip in one composition commit → installer installs the new tag, repoints the link, starts the new instance, verifies identity/manifest/handler and ownership on every surface → end-to-end test/launcher/autostart/assets → old role shrinks (`SPINE:221-240`). The fake-app fixture proves the forward sequence and the reverse rollback (`SPINE:238-239`), and the launch-lock rule covers the installer's start (`SPINE:151-153`). This closes the r2 N8 ordering/hot-swap/confirmed-quit points.

The handler wording in step 5 is part of H1: it is not mode-aware for the bar.

### N9 — Deployed-link discovery, invalid manifests, foreign name owners

**Status: RESOLVED for the three named defects; two medium wording gaps remain.**

`AD-26` now enumerates **every deployed link** under `<install>/config` (including `config/ags`) and reads its manifest; a missing or invalid manifest is a structured failure entry, not a silent skip or restart (`SPINE:100-103`). Running status comes from `ags list`/`/proc`, and the owner process must resolve to the same deployed link/config dir; a foreign or dev instance that owns a deployed name is a structured conflict and is never refreshed (`SPINE:103-106`). Duplicate names/links are failures (`SPINE:108-109`). This closes the r2 "valid manifests only" and "dev instance can be refreshed" constructions.

The "every deployed link" wording is **not** overbroad today: the non-AGS entries under `<install>/config` are directories, not symlinks. `PROVISION/ansible/roles/config_links/vars/main.yml:59-107` lists the managed dirs (`hypr`, `hyprpaper`, `nvim`, `starship`, `wlogout`, `zsh`, `kitty`, `color-scheme-generator`, `weg`, `itr`, `gtk-3.0`, `gtk-4.0`, `rofi`, `btop`), and the current host has only the seven `ags*` entries as symlinks under `<install>/config` (`find ~/.local/share/dotfiles/config -maxdepth 1 -type l`). The rule should still say `config/ags*` as hardening, but it does not currently flag non-AGS configs.

Medium gaps: (a) "dev/worktree instances are ignored unless `--include-dev`" (`SPINE:107-108`) contradicts "a foreign or dev instance that owns a deployed name ... is never refreshed" (`SPINE:104-106`); a worktree app reuses the deployed `instanceName`, so `--include-dev` can never refresh the running case it was added for. Define include-dev as a separate discovery root with a distinct instance, or remove the flag. (b) The bar is launched bare `ags run` by autostart (`ASSETS/configs/hypr/autostart.lua:19`) and has no explicit `instanceName` (`bar/app.tsx:37`; AGS default `ags`). The owner-process check must define that an absent `-d` resolves to the AGS default `$XDG_CONFIG_HOME/ags`, or the running bar cannot satisfy the "same deployed link/config dir" rule. These are medium, not freeze blockers.

### N10 — Deferred status and ledger retry

**Status: RESOLVED.**

`AD-27` now permits `{"ok":true,"deferred":"reason"}` (accepted but not applied yet) alongside `{"ok":true}` and `{"ok":false,...}`, and says `ok:true` without `deferred` means applied, not scheduled (`SPINE:122-128`). `AD-29` records `applied|deferred|failed|skipped` and refreshes an app when its last successful hash differs or its last result is `failed`/`deferred` (`SPINE:166-170`); the conventions table repeats the deferred/failed retry (`SPINE:341-343`). The r2 contradiction — defer returning `ok:true` while `ok:true` meant applied — is closed: deferred is a distinct, retryable status.

### N11 — Shared launch lock on every `ags run`

**Status: RESOLVED textually (with a medium lock-lifetime note).**

`AD-28` now says **every** `ags run` invocation — runtime restart, provisioning, autostart, and on-demand launchers — holds the same per-user AGS launch lock (`SPINE:151-153`), and the conventions table repeats it (`SPINE:348`). REQ-015 requires it in the restart lane, autostart, and every on-demand launcher (`REQ015:57-58`), and REQ-016 checks every path (`REQ016`). This closes the r2 scope gap.

Residual medium: the contract does not say when the lock is **released**. If "holds" is read as "for the lifetime of the `ags run` process," a conforming autostart wrapper (`flock … ags run`) holds the lock forever and every later app launch blocks; the login sequence starts only the first app. Define the lock as held until the instance has published its D-Bus name/bundle and then released, with a bounded wait and a clear failure. This was a first-review recommendation and is now an operational, not textual, gap.

### N12 — Template fixture + measurable exit thresholds

**Status: RESOLVED with H2.**

`AD-33` now names the template fixture at `ags-apps/templates/ags-app/`, makes the pilot its first consumer with a frozen copy at `ags-clipboard/templates/ags-app/`, requires the conformance gate, and gives measurable thresholds: scaffold-to-green ≤ 30 min with one command; CI/release ≤ 10 min per app; install ≤ 2 min; rollback ≤ 2 min; zero duplicate/missing ownership surfaces; no app restart except the bar; no bespoke provisioning code (`SPINE:247-261`). REQ-008 makes the fixture/gate/thresholds an acceptance item (`REQ008:81-83`), and REQ-009 carries the measured gate (`REQ009:68-72`). The r2 "pilot can pass arbitrarily" is closed.

The "with one command" phrase is H2: it conflicts with the Deferred generator.

---

## 3. New high contradictions introduced by the fixes

### H1 — The bar has "no handler," but the universal handler rules still apply to it

**Severity: HIGH (new).**

`AD-36` says every live app receives a `palette-refresh` handler and "the bar has no handler and is `restart`" (`SPINE:306-308`). That is correct for the bar's mode, but three other binding texts still require a handler for **every** app/cutover:

- `AD-32` step 5: the installer "verifies identity/manifest/handler and ownership on every surface" after the cutover (`SPINE:230-231`). REQ-015 is the bar cutover (`REQ015:42-43`), so a mode-agnostic verifier fails it.
- `AD-33`: "Every app repo carries … manifest, handler and tests" (`SPINE:250-252`), and the template-conformance gate validates the required files (`SPINE:252-253`). REQ-015 requires the bar repo to be created from the template and pass template conformance (`REQ015:42-43`). A gate that requires a `palette-refresh` handler file fails `ags-bar`.
- `EPIC` step 2: "adopt manifests and live `palette-refresh` handlers in the current deployment (including the bar)" (`EPIC:83-85`). This reads as requiring a bar handler, directly contradicting `AD-36`. REQ-008 is correct — the bar gets a manifest and remains `restart` (`REQ008:72-74`) — so the EPIC wording is the outlier.

The bar does have a `requestHandler` for popup-close/settings-close (`bar/app.tsx:52`), so the contradiction is caused by the unqualified word "handler." If "handler" means palette-refresh, the bar fails; if it means any request handler, AD-36's "no handler" is false. Either reading produces a different conforming unit.

**Two units:**

- Installer A applies `AD-32` step 5 literally and checks a `palette-refresh` handler after the bar cutover → fails. Installer B reads `AD-36` and skips the handler check for `mode: restart` → passes. Both obey the spine.
- Template gate A requires a handler file in every repo (`AD-33`) → `ags-bar` fails conformance. Gate B makes the handler requirement mode-aware → passes.
- EPIC unit C adds a bar `palette-refresh` handler to satisfy step 2 → contradicts `AD-36` and the bar's restart rationale.

**Fix:** Qualify every use: "live apps carry a `palette-refresh` handler; restart apps have no `palette-refresh` handler." Make AD-32 step 5 verify "handler for live; restart procedure/ownership for restart." Make AD-33 template conformance mode-aware (live: handler + JSON-string test; restart: restart-path test). Change EPIC step 2 to "adopt manifests (including the bar) and live handlers." Add "no `palette-refresh` handler" to REQ-015 acceptance.

### H2 — The pilot exit gate requires "one command," but the only automation is Deferred until after the pilot

**Severity: HIGH (new).**

`AD-33` sets the pilot gate as "scaffold-to-green ≤ 30 min with one command" (`SPINE:256-257`). The Deferred list says "Template generator — the template fixture and conformance gate are required; an automated repo generator is deferred until the pilot proves the copy" (`SPINE:529-530`). The pilot is the first consumer of the template (`SPINE:247-249`), and the gate is the program stop condition (`SPINE:260-261`; `REQ009:68-72`).

The two requirements cannot both be met without a new decision:

- **Pilot A** builds a one-command scaffold script/target to meet "with one command." That script is an automated repo generator; it violates the Deferred boundary ("deferred until the pilot proves the copy").
- **Pilot B** copies the fixture manually and runs the gates, respecting the Deferred generator. It cannot claim "scaffold-to-green … with one command," so the gate fails and the program stops by AD-33's own rule.

REQ-009's acceptance drops "with one command" and says only "scaffold-to-green ≤ 30 min" (`REQ009:68-69`), so the ticket and spine also disagree on the measurement.

**Fix:** Define the one command as a template-local copy target delivered by REQ-008 (for example `make scaffold-app DEST=../ags-clipboard`), and state explicitly that it is the template's copy command, not the deferred multi-repo generator. Or remove "with one command" and measure manual copy + green. Align REQ-009.

### H3 — N2 residual: per-epoch tuple release and no single tuple record

**Severity: HIGH (residual; the original N2 was CRITICAL).**

Detailed in §2/N2. The two direct contradictions are:

- `AD-32` step 2 releases/pins platform/contracts/assets per epoch (`SPINE:222-224`); the Stack sets the exact tuple tags at the REQ-008 release (`SPINE:359`).
- `AD-34` requires the install gate to prove equality with "the program tuple" (`SPINE:271-275`), but the app-list schema has no tuple fields (`SPINE:208-213`) and no `program-tuple.yaml` is named. The brownfield has four pins: `installer.pin` v0.1.16, `cli-tools.yaml` runtime v0.2.2, `ags_platform` v0.2.0, `CONTRACT_PIN` dbdc5b8.

**Two units:** V3 pins T1 for the program; a later installer epoch releases T2 and builds an app against it; the one shared ancestor can only be T1 or T2; AD-34 equality breaks for one side. Both units obey the written ADs. **Fix:** freeze the program tuple for EPIC-002, allow per-epoch **engine/runtime** releases only, and record `platformTag`/`contractsTag`/`assetsTag` in one machine-readable file or the app-list schema.

---

## 4. Medium residuals (not freeze blockers)

### 4.1 N4 — colors.css actor/order

`AD-37` says the tag is read-only after clone (`SPINE:320-321`), the symlink is "created once at install inside the tag" (`SPINE:322-323`), and provisioning "only verifies it" (`SPINE:324`). State the creation point and actor, or move the link outside the tag. The external target rule itself is correct.

### 4.2 N5 — icon artifact path not in REQ-008 acceptance

`Deferred` assigns the exact path/generator to REQ-008 acceptance (`SPINE:536-537`), but `REQ008:49-84` does not list it. Add the path, producer, and byte-equality verify to REQ-008 before REQ-011.

### 4.3 N9 — include-dev and the bar default

- `AD-26:104-108` simultaneously says a foreign/dev instance that owns a deployed name is never refreshed and that dev/worktree instances are included with `--include-dev`. Because a worktree app reuses the deployed `instanceName`, the flag cannot refresh the running case. Define a distinct dev discovery root/instance or remove the flag.
- The bar is launched bare `ags run` (`ASSETS/configs/hypr/autostart.lua:19`) with no explicit `instanceName` (`bar/app.tsx:37`; default `ags`). The owner-process check must define absent `-d` as `$XDG_CONFIG_HOME/ags` or require `-d`. This is the M2/J2 class.
- Scope the enumeration to `config/ags*` as hardening. Today the other `<install>/config` entries are directories, not links (`PROVISION/ansible/roles/config_links/vars/main.yml:59-107`), so this is not a live break.

### 4.4 N11 — launch lock lifetime

"Every `ags run` holds the lock" (`SPINE:151-153`) has no release point, bounded wait, or failure mode. Define: lock held until the instance has published its D-Bus name/bundle is ready, then released; a blocked launcher waits a bounded time and reports failure. Without this, a literal `flock … ags run` wrapper serializes the process lifetime and deadlocks the login sequence.

### 4.5 Other medium items carried from r2

- **App-list seed (M1):** clipboard is pre-flipped to `standalone` with a `v0.1.0` tag before REQ-009, and the bar entry lacks `instance`, `configDir`, `cutoverId` (`SPINE:389-412`). Label the seed illustrative or show the pre-cutover state.
- **`wallpaper.state` removal (M11):** `AD-36` says live handlers "wrap existing refresh behavior" (`SPINE:306-307`), while `AD-27` says live apps no longer subscribe to `wallpaper.state` for palette (`SPINE:132-134`). The adoption release must remove the palette event path, not just add a handler; add it to REQ-008 acceptance and the REQ-012/013/014 acceptance.
- **Bar default instance (M2):** `AD-26` says `app.tsx instanceName`; the bar has none and defaults to `ags`. Say "effective instance name (default `ags` when omitted)."
- **Transient obligation (M3):** `AD-27` says "active transient surface" but the manifest has only `holdsUnsavedState`. Add `transientObligation`/`stateClass` or state the boolean is sufficient.
- **Archive timing (M9):** `AD-32` step 7 archives when the last app moves (`SPINE:234-235`); REQ-016 is the final consumption cutover after REQ-015. Move archive to REQ-016 close.
- **Memlog drift:** `.memlog.md:19` says "No retry" and `:30` says the runtime "discovers running apps"; the spine now retries failed/deferred (`AD-29`) and includes down restart apps (`AD-26`). Update the memlog at freeze so the decision log matches the contract.

---

## 5. What the revision actually closed

Credit where due; these are real, testable tightenings:

- **N1.** The adoption release now carries `palette-refresh` handlers for every live app, not just manifests (`SPINE:301-313`; `EPIC:45-48`; `REQ008:72-74`). The r2 runtime-switch break is closed.
- **N2 (half).** The monorepo is re-pinned to the same program tuple (`SPINE:201-206,268-275,302-304`), and `dotfiles-assets` is in the tuple (`SPINE:201-206,359`). The legacy/new version skew and the Theme-provider skew are closed.
- **N3.** `installDir` makes the install path single-valued and resolves the `capture`/`ags-capture-tool` seam (`SPINE:197-199,208-213,368-384`).
- **N4.** The colors pointer target is outside the tag and the seeder never writes the tag (`SPINE:320-324`).
- **N5.** The icons source is in the program tuple and the artifact has one producer (`SPINE:201-206,325-327`).
- **N6.** The app-list schema now names the source/link/launcher/autostart/process/D-Bus surfaces and the cutover predicate checks all of them (`SPINE:208-213,236-240,347`).
- **N7.** The configured restart app is included when down, and the ledger retry is explicit (`SPINE:106-107,186-190`).
- **N8.** The cutover now quiesces before any link change, flips the owner, installs/starts/verifies, and has a reverse rollback fixture (`SPINE:221-240`).
- **N9.** Discovery enumerates all deployed links, invalid manifests are failures, and foreign/dev name owners are conflicts (`SPINE:100-110`).
- **N10.** Deferred is a first-class response and ledger status with a next-trigger retry (`SPINE:122-124,166-170,341-343`).
- **N11.** Every `ags run` path is named, including on-demand launchers (`SPINE:151-153,348`; `REQ015:57-58`).
- **N12.** The template fixture, conformance gate, and measurable thresholds exist (`SPINE:247-261`; `REQ008:81-83`; `REQ009:68-72`).

The remaining findings are not a rejection of the direction. They are the per-epoch tuple seam, one mode-agnostic handler rule, and one pilot-gate measurement that the revision introduced.

---

## 6. Check performed

- Read the revised `SPINE` (551 lines), `.memlog.md` (31 lines), `EPIC-002`, `REQ-008` through `REQ-016`, and the r2 findings (`review-adversarial-r2.md`).
- Rechecked the brownfield facts that decide the remaining findings:
  - `PROVISION/ansible/roles/ags_apps/vars/main.yml:59-73,104-112,314-336` — legacy unit at `<install>/ags-apps/<tag>`, per-unit `node_modules/ags-platform` shortcut, `ags_apps_platform_version: v0.2.0`.
  - `PROVISION/ansible/roles/ags_platform/vars/main.yml:25-45` — platform pin `v0.2.0`.
  - `V3/dotfiles/provisioning/installer.pin` — `v0.1.16`; `V3/dotfiles/provisioning/cli-tools.yaml` — runtime `v0.2.2`; `RUNTIME/src/runtime/adapters/CONTRACT_PIN` — `dbdc5b8`; `contracts/schemas/` — only `current`, `history`, `last-converged`, `meta` (no app-list/tuple schema).
  - `PROVISION/ansible/roles/config_links/vars/main.yml:59-107` — non-AGS managed config dirs are directories; only `ags*` are links under `<install>/config` (confirmed with `find ~/.local/share/dotfiles/config -maxdepth 1 -type l`).
  - `ASSETS/configs/hypr/autostart.lua:19` — bar launched bare `ags run`; `bar/app.tsx:37` — no explicit `instanceName`; `bar/app.tsx:52` — a request handler exists (popup-close/settings-close), but no `palette-refresh`.
  - `grep -n 'requestHandler' ags-apps/*/app.tsx` → only `bar/app.tsx:52` and `hypr-pano/app.tsx:33`; the other live apps still need the N1 adoption handler.
- Verified the r2 N1–N12 and H1–H3 line references against the current spine, EPIC, and REQ tickets.
- No files were modified except this review.

---

## 7. Required change set (ordered by freeze blocker)

1. **H3/N2 — freeze the tuple and record it.** State the program tuple is immutable for EPIC-002; `AD-32` step 2 may release engine/runtime only. Add `platformTag`/`contractsTag`/`assetsTag` to a named `program-tuple.yaml` or the app-list schema. Add the legacy-shortcut migration exception or move the legacy unit under `<install>/apps`.
2. **H1 — make "handler" mode-aware.** Qualify `AD-36` as `palette-refresh` handler; make `AD-32` step 5 and `AD-33` template conformance mode-aware; remove "(including the bar)" from EPIC's live-handler sentence; add "no `palette-refresh` handler" to REQ-015 acceptance.
3. **H2 — reconcile the pilot's one command with the Deferred generator.** Define the template-local copy command as REQ-008's deliverable and state it is not the deferred generator, or drop "with one command" and measure manual copy + green. Align REQ-009.
4. **Mediums before the first cutover:** N4 creation sequence; N5 icon path in REQ-008 acceptance; N9 include-dev/bar default/`ags*` scope; N11 lock lifetime; seed M1/M2; `wallpaper.state` removal in the adoption release; memlog drift.

---

*End of review.*
