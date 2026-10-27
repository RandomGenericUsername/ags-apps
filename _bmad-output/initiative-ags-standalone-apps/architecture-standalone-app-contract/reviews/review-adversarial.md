# Adversarial Consistency Review — Standalone AGS app contract

- **Reviewer lens:** adversarial-consistency. Construct two units one level down (an app repo, `dotfiles-runtime`, `dotfiles-v3`, `dotfiles-provision`) that each obey every AD to the letter, yet still build or deploy incompatibly.
- **Target:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md` (draft, 2026-10-26, 370 lines) and `.memlog.md`.
- **Codebase read (read-only):** `/home/inumaki/Development/dotfiles/{ags-apps,dotfiles-runtime,dotfiles-provision,dotfiles-v3,contracts}`; AGS 3.1.0 CLI / 3.1.2 JS.
- **Date:** 2026-10-26
- **Shorthand:** `SPINE` = the target spine; `EPIC` = `tickets/EPIC-002-apps-standalone-repos/ticket.md`; `REQ008`/`REQ009` = those tickets; `RUNTIME` = `dotfiles-runtime`; `PROVISION` = `dotfiles-provision`; `V3` = `dotfiles-v3`.

**Verdict: BLOCK — do not freeze and do not start the pilot (REQ-009).** The spine makes the right *directional* decision (one repo per app, one manifest, one runtime trigger, one-owner cutover), but it does not yet make the contract **single-valued**. Four findings are critical and each is reachable with every written AD satisfied: two app repos can build against different `ags-platform` tags under one shared resolver; two runtimes can implement two different “last applied” gates and two different failure outcomes; two provisioning repos can each perform its half of a “one commit set” cutover and leave the app unowned; and the pilot’s own binding tickets still require the old `hypr-pano` names and a `refresh` field. A fifth finding lets the runtime refresh the wrong AGS instance from a schema-valid manifest. The remaining findings are real but narrower: artifact ownership, wire encoding, log/result shape, link-swap versus running code, AGS launch concurrency, restart procedure, unsaved-state safety, pin mutability, and conformance fixtures.

The spine does **not** need a re-think of AD-25/AD-33’s direction. It needs a small number of hard choices and tightened ADs. The critical decisions, if taken before authoring the implementation, keep the current ownership model intact.

---

## Summary

| # | Finding | Severity | Primary ADs | Disposition |
| --- | --- | --- | --- | --- |
| F1 | One shared `ags-platform`/`contracts` ancestor vs per-app pins | CRITICAL | AD-17, AD-31, AD-34, Stack | Tighten AD-31/AD-34; add one program pin |
| F2 | Palette gate has no single owner/state; “no retry” makes failure permanent | CRITICAL | AD-28, AD-29 | Tighten AD-29; new applied-appearance ledger |
| F3 | Cutover is not a transaction; app list has no schema; runtime/engine prerequisites missing | CRITICAL | AD-31, AD-32 | New cutover/ownership AD; app-list schema |
| F4 | Pilot’s binding tickets conflict with AD-35 on names, field shape, and missing-manifest behavior | CRITICAL | AD-26, AD-33, AD-35 | Tighten AD-35 supersession; rewrite REQ-009/EPIC |
| F5 | Manifest identity, path resolution, and discovery are undefined; wrong-instance refresh is schema-valid | CRITICAL | AD-26, AD-27 | Tighten AD-26; new discovery AD |
| F6 | `colors.css`/`icons.json` have two owners; user state lives in the versioned tag | HIGH | AD-21, AD-25, AD-31 | New single-producer/code-state AD |
| F7 | AGS request response is a string, not an object; exactly-once, timeout and cancellation are unspecified | HIGH | AD-27, AD-28 | Tighten AD-27; wire protocol AD |
| F8 | “Every app emits” a log record is impossible; `reload_failures`, order, and exit code are unshaped | HIGH | AD-28 | Tighten AD-28; result/log schema |
| F9 | Repointing a config link can pair a new manifest with old running code | HIGH | AD-31, AD-32 | New link-swap transaction AD |
| F10 | AGS has one shared bundle; launch serialization is local to the runtime restart lane | HIGH | AD-25, AD-28 | New per-user launch lock/lifecycle AD |
| F11 | “Confirmed quit” and “safe restart” are slogans; restore down-state and stopped-app semantics | HIGH | AD-28, AD-30 | New restart-procedure AD |
| F12 | Live refresh is mandated before its two known hazards are removed; “already live” tickets assume packaging-only | HIGH | AD-13, AD-27, AD-30 | Promote provider gate; update REQ-012/13/14 |
| F13 | `holdsUnsavedState` does not constrain live handlers; transient obligation is missing; apply is not atomic | HIGH | AD-26, AD-30 | Tighten AD-26/AD-30; state-class rule |
| F14 | Release tags are mutable; manifest/protocol version negotiation is absent | MEDIUM | AD-33, AD-34 | New pin/version AD |
| F15 | Handler tests are unshareable; conformance fixtures and deployed `node_modules` isolation are missing | MEDIUM | AD-33, AD-34 | Tighten AD-33/AD-34 |

Evidence base for every finding is the current tree at the revisions above; the repository-level `Verify:` lines are the one-command checks an implementer can rerun. Where a claim is about a future unit, the construction is explicitly labelled “Unit A / Unit B.”

---

## F1 — One shared platform/contracts ancestor vs per-app pins

**Severity: CRITICAL — two app repos can typecheck/pass CI against different platform versions, while the deployed resolver can use only one.**

**The two units:**

- **Unit A — `ags-notifications` app repo.** Follows AD-34: pins `ags-platform` at `v0.3.0` and `contracts` at commit `c2`, runs its local typecheck and pure tests against that pair, and implements the new one-provider Theme helper added in `v0.3.0`.
- **Unit B — `ags-bar` app repo.** Follows AD-34: pins `ags-platform` at `v0.2.0` and `contracts` at `c1`, and passes its own typecheck/tests against that pair.
- **Deployment — `dotfiles-provision`.** Follows AD-31: installs both checkouts under `<install>/apps/<app>/<tag>/` and creates exactly one shared shortcut, `<install>/apps/node_modules/ags-platform`, so esbuild resolves one platform version for every app.

**ADs each obeys:** AD-34 (“Each app repo pins `ags-platform` and `contracts` by git tag/commit and runs a conformance test”), AD-33 (local typecheck, pure CI), AD-31 (one shared ancestor), inherited AD-17 (one versioned platform unit at a shared ancestor). The Stack table states the contradiction literally: “`ags-platform` | existing pinned tag; each app repo pins its own” (`SPINE:219`).

**The incompatibility (exact):** There is one `node_modules/ags-platform` symlink, so esbuild can resolve only one tag at runtime. If provisioning points it at `v0.2.0`, Unit A’s `v0.3.0` import either fails to bundle or silently binds a different implementation; if it points at `v0.3.0`, Unit B was never typechecked against it. Both app repos did exactly what AD-34 says; both installs did exactly what AD-31 says; the pair is still not build-compatible. The same split exists for `contracts`: the runtime validates each deployed manifest against its own pinned contract (`SPINE:181-183`), while each app repo validates against its own. A manifest that passes app CI can be rejected by the runtime — and because AD-26 says an invalid manifest means “do nothing,” the app is silently stale.

The same resolution hole also lets a deployed tag shadow the shared ancestor. If an app repo commits or installs a `node_modules/ags-platform` inside its tag (a natural way to make local typecheck reproducible), esbuild finds it before `<install>/apps/node_modules` and the per-app pin wins. AD-31 never forbids that; AD-34 never forbids a non-shared pin.

**Evidence:** `SPINE:140-151` (single shared shortcut), `SPINE:175-183` (per-app pins, runtime validates own contract), `SPINE:219-220` (Stack says each app pins its own); `PROVISION/ansible/roles/ags_platform/vars/main.yml:118-140` (shared ancestor); `PROVISION/ansible/roles/ags_apps/vars/main.yml:314-336` (per-unit shortcut, platform version v0.2.0); current app packages have no platform pin yet, so this is a new-repo decision, not a migration constraint.

**Verify:** `grep -n 'ags-platform\|each app repo pins' SPINE; sed -n '314,336p' PROVISION/ansible/roles/ags_apps/vars/main.yml; rg -n '\"ags-platform\"' <app-repo>/package.json`. Then install the shared shortcut at v0.2.0 and run `ags bundle` in an app built against a v0.3.0-only API; the bundle fails or resolves the old implementation.

**Proposed (tighten AD-31 and AD-34, and add a program pin):** Add one `platform_tag` and one `contracts_tag` to the program’s release tuple (owned by `dotfiles-v3`, recorded in the per-app list). The shared ancestor points at that platform tag; every app repo must pin exactly that tag for CI and typecheck; provisioning verifies the tuple in each deployed tag. App repos may declare a supported range, but the range is checked against the program tuple at install and at app CI. The deployed tag must contain no `node_modules` or vendored platform copy; provisioning’s verify role rejects one. The runtime and provisioning use the same contracts tag/schema. If the project instead wants genuinely independent app pins, the shared ancestor must be abandoned in favor of per-app platform installs — but then AD-17/AD-31’s “shared ancestor” rule must be superseded, not left in place.

---

## F2 — The palette gate has no single owner/state, and “no retry” makes failure permanent

**Severity: CRITICAL — two conforming runtimes can double-refresh on a no-op, or skip a failed app forever.**

**The two units:**

- **Unit A — `dotfiles-runtime` daemon.** Follows AD-29 and the existing daemon behavior: stores `input_hash` in `last-converged.json`, compares the current input hash to it, and runs the reconcile only when different. The input hash is `sha256` over the watched inputs (wallpaper + templates + effects + icons), not the palette hash.
- **Unit B — `dotfiles-runtime` CLI.** Follows AD-29’s sentence “the CLI needs its own palette-hash gate or an explicit no-reload mode for login” by creating a separate `last-palette.json`, comparing the current palette hash to it, and writing it immediately after the palette cache/pointer is repointed.

**ADs each obeys:** AD-29 says compare “the current palette hash with the last applied hash” and explicitly permits a CLI-specific gate; AD-28 says no retry and no fallback; AD-26 says apps apply palette at startup. Nothing in AD-29 says where the “last applied hash” lives, who writes it, when it is written, or whether it is per app or global. AD-29’s “or” is not a decision: the two branches have observably different login behavior.

**The incompatibility (exact):**

1. **The daemon’s record is not a palette hash.** `last-converged.json` requires `input_hash` and forbids additional properties (`contracts/schemas/last-converged.schema.json:6-13`; `RUNTIME/src/runtime/adapters/converge_backstop.py:42-48,85-100`). If Unit A implements AD-29 literally, it compares a 64-hex palette hash to an input hash; they are never equal, so every reconcile is “changed” — the exact login restart storm AD-29 exists to prevent. If Unit B writes a second file, the daemon and CLI never see each other’s decision: same palette can be refreshed twice (double restart/provider churn), or the CLI can skip when the daemon had a failed run.
2. **Writing the gate before the lanes makes failures permanent.** Unit B writes “last applied” immediately after the palette repoint; an app’s `palette-refresh` then fails. AD-28 says “No retry, no fallback.” The next reconcile with the same palette sees an unchanged hash and publishes “no refresh, no restart”; the app is stale until the *next palette change*. If the failed app is the bar (restart lane), the bar stays down until login or a manual command. The consistency table’s “Failure surface … app stays running/stale” (`SPINE:208`) is false for a restart-mode app: it can be down.
3. **Icons-only changes bypass the gate.** AD-29 is palette-only. `dotfiles-runtime regenerate` (icon contrast toggle) regenerates `current/icons` and repoints consumer links without changing the palette hash; live apps that render generated icons are not refreshed. `regenerate` is not in AD-29’s covered triggers and still wires `AgsReloader` in the current CLI (`RUNTIME/src/runtime/cli/main.py:980-1050`). Two units can legitimately treat “palette hash unchanged” as “no work” or as “still refresh icons,” producing different UI.
4. **No single-flight.** AD-29 covers CLI `reconcile`, `wallpaper set`, and the daemon reactive path, but not their concurrency. Two triggers can read the same last hash, both run lanes, and an older operation can write its hash after a newer one. There is no runtime operation lock; the current seed lock is released before reload and does not serialize reloads (`RUNTIME/src/runtime/application/reconcile.py:333-354`).

**Evidence:** `SPINE:116-126` (AD-29), `SPINE:102-114` (no retry; failures enter `reload_failures`), `SPINE:205-208` (timeout/failure conventions); `contracts/schemas/last-converged.schema.json:6-13`; `RUNTIME/src/runtime/adapters/converge_backstop.py:42-48,85-100`; `RUNTIME/src/runtime/application/converge.py:73-83` (daemon gate); `RUNTIME/src/runtime/application/reconcile.py:333-354` (reloads); `RUNTIME/src/runtime/cli/main.py:405-413,993-1047` (AgsReloader in reconcile and regenerate); `V3/docs/ags-restart-vs-live-theme-refresh.md:60` (“command still exits non-zero for those failures”).

**Verify:** `sed -n '116,126p' SPINE; cat contracts/schemas/last-converged.schema.json; rg -n 'last_converged|input_hash' RUNTIME/src/runtime/application; dotfiles-runtime reconcile` twice with the same palette and no app changes — the second run still restarts consumers because the CLI has no gate; the daemon’s record is an input hash, not a palette hash.

**Proposed (tighten AD-29 and add an applied-appearance ledger):** Introduce one persisted *applied appearance* record under `$XDG_STATE_HOME/dotfiles/` (or extend `last-converged` with a version bump) containing at minimum `appearance_hash` (palette + icons + effects inputs), `operation_id`, `completed_at`, and a `per_app` map of `{instance, mode, status: applied|failed|skipped, reason}`. It has one writer (the runtime), is written atomically after the lanes settle, and is read by the daemon and CLI alike. The gate is per app: an app marked `failed` is retried on the next trigger or an explicit `dotfiles-runtime reconcile --repair`, while successful apps are not re-refreshed. “No retry” is defined as “no automatic retry within the same operation,” not “no recovery until the palette changes.” `regenerate`/icons-only and `wallpaper set` use the same ledger. A single runtime operation lock covers daemon + CLI + wallpaper set. If the pointer moved during the operation, do not record that hash as applied. Add the ledger schema to `contracts`.

---

## F3 — The cutover is not a transaction, the app list has no schema, and the runtime/engine prerequisites are missing

**Severity: CRITICAL — every cutover can be applied as “old owner” or “new owner” depending on which repo’s commit lands first; both can leave zero or two owners.**

**The two units:**

- **Unit A — `dotfiles-v3`.** Follows AD-31/AD-32 by adding an entry to the per-app list (repo, tag, config link, optional bin link, bar palette pointer) and recording the app as new-owner; the physical old-link removal belongs to Unit B.
- **Unit B — `dotfiles-provision`.** Follows AD-31/AD-32 by adding the generic per-app loop, adding the app to the old `ags_apps` role’s exclusion list, removing the old link, and releasing a new pinned engine tag.

**ADs each obeys:** AD-31 (“`dotfiles-v3` owns the per-app list … `dotfiles-provision` runs one generic loop and its verify role consumes the same data”), AD-32 (“each cutover is one commit set: add the app to the `dotfiles-v3` list, add it to the old `ags_apps` role’s exclusion list, remove its old link, and verify the union has exactly one owner per app”), AD-19 (each repo gates its own change; tree green).

**The incompatibility (exact):**

1. **A git commit cannot span the repos AD-32 names.** `dotfiles-v3` owns the list; `dotfiles-provision` owns the role and exclusion; the app repo owns the tag; `dotfiles-runtime` owns the invocation; `dotfiles-assets` owns the launcher/autostart rename. AD-32’s “one commit set” is at least a four-repo release transaction. Between the engine release and the `dotfiles-v3` pin/list bump, the list exists but the engine cannot read it (no app installed); between the list entry and the old exclusion, both roles link the app (two owners). The reverse order leaves zero owners. Both units can claim they did their half of AD-32.
2. **The engine is a separate pinned tool.** `dotfiles-v3/dotfiles/provisioning/installer.pin` is `v0.1.16`; the generic app role is new code and must be released as a new engine tag before `dotfiles-v3` can bump the pin. AD-31 never mentions the engine release; AD-32’s “one commit set” does not include it. `PROVISION/ansible/inventory/group_vars/all.yml:13-20` shows `manifests_dir` is a path seam, not a versioned contract.
3. **The app list has no schema or transport.** AD-31 says “same data” but never names the file, fields, types, or whether `dotfiles-provision` reads `apps.yaml` directly, through a generated artifact, or through a submodule. Unit A can write `{app, repo, tag, config_dir, bin}`; Unit B can expect `{name, repo_url, version, link_name, bin_link}`. Both are reasonable readings; the list is not machine-checkable against a common schema. `dotfiles-provision`’s own tests cannot validate a real list without a fixture contract.
4. **The runtime prerequisite is absent.** `dotfiles-v3/dotfiles/provisioning/cli-tools.yaml:30-32` pins `dotfiles-runtime v0.2.2`. That runtime’s `AgsReloader` restarts every non-skip app, and the new clipboard config dir is not in `DEFAULT_SKIP_CONFIG_DIRS` (`RUNTIME/src/runtime/adapters/ags_reloader.py:64-66,187-196`). If the first app cuts over before the manifest-aware runtime is released, pinned, and the daemon restarted, a `live` app is restarted on the first palette change — exactly what AD-27/AD-30 forbid. AD-32’s cutover set does not include the runtime pin or a daemon restart.
5. **The “old link” is not the only old owner.** `PROVISION/ansible/roles/config_links/vars/main.yml:86-95` still manages `ags-hypr-pano`; `gui_tools` still owns AGS-instance launch/quit entries; `cli_tools` still provisions `hypr-pano-ui`; `dotfiles-assets/configs/hypr/autostart.lua:51` still starts `~/.config/ags-hypr-pano`; `V3/scripts/deploy-coverage.py:201-207,705-775` still asserts the old `ags_apps` structure. Removing only the `ags_apps` link leaves a dangling `~/.config/ags-hypr-pano` (config_links creates links to missing spine paths), an autostart that starts a second instance, and a gate that fails because it still expects the old unit. AD-32’s singular “remove its old link” is incomplete.
6. **“Exactly one owner” is undefined.** Owner can mean: the source clone under `<install>/`, the `config/ags-*` link, the `~/.config` link, the bin link, the launcher template, the autostart line, the AGS instance on D-Bus, or the running process. Unit A can count config links and pass; Unit B can count cloned units and pass; both can coexist with two running instances. AD-32 does not define the ownership predicate.
7. **The old-role exclusion is a deny-list.** A new app defaults to “old owner” unless someone remembers to add it to the exclusion. “The old role may only shrink” is therefore not structurally enforced. A positive allow-list of *remaining* old apps would make double deployment impossible.
8. **The absolute “No `ags-apps` pin remains” (`SPINE:151`) contradicts AD-32’s “keep the old role/pin until the last app moves” (`SPINE:160-161`).** One unit can remove the pin early and break every unmigrated app; the other keeps it and violates the absolute. It should read “no pin remains at program completion.”

**Evidence:** `SPINE:140-162` (AD-31/AD-32), `SPINE:151` (absolute no pin), `V3/dotfiles/provisioning/installer.pin` (`v0.1.16`), `PROVISION/ansible/inventory/group_vars/all.yml:13-20`, `V3/dotfiles/provisioning/cli-tools.yaml:30-32`, `RUNTIME/src/runtime/adapters/ags_reloader.py:64-66,187-196`, `PROVISION/ansible/roles/config_links/vars/main.yml:86-95`, `PROVISION/ansible/roles/config_links/tasks/_link_one.yml:33-61` (links a missing spine target), `PROVISION/ansible/roles/gui_tools/tasks/main.yml:130-196`, `PROVISION/ansible/roles/cli_tools/templates/hypr-pano-ui.j2:26-28`, `dotfiles-assets/configs/hypr/autostart.lua:51`, `V3/scripts/deploy-coverage.py:201-207,705-775`.

**Verify:** `cat V3/dotfiles/provisioning/installer.pin; grep -n 'dotfiles-runtime' -A2 V3/dotfiles/provisioning/cli-tools.yaml; grep -n 'ags-hypr-pano' PROVISION/ansible/roles/config_links/vars/main.yml PROVISION/ansible/roles/gui_tools/tasks/main.yml dotfiles-assets/configs/hypr/autostart.lua; grep -n 'ags_apps' V3/scripts/deploy-coverage.py | head`. Then write two plausible `apps.yaml` shapes and diff the fields; both are absent from the repo today.

**Proposed (tighten AD-32 and add a cutover/ownership AD):** Define one machine-readable app list (recommended `dotfiles-v3/dotfiles/provisioning/apps.yaml`) with a JSON Schema owned by `contracts` and fields at least `app`, `repo`, `tag`, `instance`, `configDir`, `configLink`, `binLink?`, `mode`, `owner: old|new`, `cutoverId`. Define a cutover epoch: app tag → engine release (with generic role) → runtime release (manifest lanes) → `dotfiles-v3` pin/list → old-role allow-list shrink → `dotfiles-assets`/launcher/autostart update. The old role deploys an explicit allow-list of remaining apps, not an exclusion list. The cutover gate asserts **all** ownership surfaces (source tree, spine link, XDG link, bin link, launcher, autostart entry, running instance/D-Bus name) and fails on zero or two owners. Rollback is the reverse epoch with the same gate. Update AD-31’s absolute pin sentence to “at program completion.” Make `dotfiles-runtime` and the new engine tag explicit prerequisites, not implicit.

---

## F4 — The pilot’s binding tickets conflict with AD-35 on names, field shape, and missing-manifest behavior

**Severity: CRITICAL — the pilot cannot satisfy AD-35 and REQ-009 at the same time.**

**The two units:**

- **Unit A — app repo `ags-clipboard`.** Follows AD-33/AD-35: repo `ags-clipboard`; manifest `{schemaVersion: 1, instance: "clipboard", configDir: "ags-clipboard", mode: "live", holdsUnsavedState: false}`; window `clipboard-window`; launcher `clipboard-ui`; config link `config/ags-clipboard`.
- **Unit B — `dotfiles-assets` / `dotfiles-provision` consumers.** Follow epics/tickets: EPIC-002 says “The deployed config directory and AGS instance name stay identical during a cutover” (`EPIC:46`); REQ-009 says “Keep the deployed config directory `ags-hypr-pano` and the AGS instance name `hypr-pano` unchanged” (`REQ009:18-20`) and its acceptance repeats the old names and “Manifest declares `refresh: live`” (`REQ009:36-39`). Unit B keeps `~/.config/ags-hypr-pano`, `hypr-pano`, `hypr-pano-ui`, and autostart at `$HOME/.config/ags-hypr-pano` (`dotfiles-assets/configs/hypr/autostart.lua:51`).

**ADs each obeys:** Unit A obeys AD-35 (“repo `ags-clipboard`; config dir `ags-clipboard`; AGS instance `clipboard`; window `clipboard-window`; launcher `clipboard-ui`; … old `hypr-pano` names are retired”) and AD-33 (`ags-clipboard` is the template). Unit B obeys EPIC-002/REQ-009’s same-name cutover rule and REQ-008’s “same config dir and instance” cutover acceptance (`REQ008:34,53-54`). The spine never says AD-35 supersedes EPIC-002’s same-name rule or REQ-009’s acceptance; its Sources list does not even include REQ-009.

**The incompatibility (exact):** The app starts on a manifest that the old launcher/autostart never uses. The runtime looks for `config/ags-clipboard`, the keybind starts `hypr-pano-ui`, and autostart launches `~/.config/ags-hypr-pano`; the result is either no clipboard overlay or two instances, one old and one new. If Unit B instead follows AD-35, it must rename the keybind/launcher/autostart in the same cutover — but AD-32’s cutover recipe does not list `dotfiles-assets` or a rename step. The pilot is also misnamed: AD-33 calls `ags-clipboard` the pilot, while EPIC-002 and REQ-009 call `hypr-pano` the pilot.

There is a second, independent document conflict in the same pair. EPIC-002 says “No manifest means legacy restart” (`EPIC:67`) and “`restart` is allowed only as an explicit, change-gated fallback” (`EPIC:70`); AD-26 says “There is no legacy path. Apps apply … at startup” and “missing or invalid manifest means the runtime does nothing” (`SPINE:86-87`); AD-30 says restart is never a fallback (`SPINE:128-138`). A runtime implementer following EPIC and one following the spine produce opposite behavior for a running app whose manifest is absent — and for the bar during the program, before REQ-015 adds its manifest. REQ-009 also uses `refresh: live`; AD-26/AD-35 use `mode`. `contracts` will reject one of them.

**Evidence:** `SPINE:164-194` (AD-33/AD-35), `SPINE:76-100` (AD-26/AD-27), `EPIC:46,58-70,97,102,110,117`, `REQ009:18-20,36-39`, `REQ008:23-24,34,53-54`, `dotfiles-assets/configs/hypr/autostart.lua:51`, `PROVISION/ansible/roles/cli_tools/templates/hypr-pano-ui.j2:26-28`.

**Verify:** `grep -n 'ags-hypr-pano\|hypr-pano\|refresh:' REQ009; grep -n 'ags-clipboard\|clipboard' SPINE | sed -n '1,20p'; grep -n 'No manifest\|legacy\|fallback' EPIC SPINE`. Then write the two manifests; one has `mode`/`ags-clipboard`, the other `refresh`/`ags-hypr-pano`; only one validates.

**Proposed (tighten AD-35 and the supersession section):** Make the supersession explicit: AD-35 supersedes EPIC-002’s “names stay identical” rule and REQ-009’s same-name acceptance for the clipboard app. Rewrite REQ-009’s title/acceptance to `ags-clipboard`/`ags-clipboard`/`clipboard`/`mode` and add the `dotfiles-assets` launcher/autostart/keybind rename to the cutover entry. Alternatively, if the program wants a low-risk pilot, defer the rename until after REQ-009 and let the pilot keep `hypr-pano` names in the new repo; then AD-35 applies to a later cutover. Pick one; do not leave both documents binding. Also update EPIC-002: “No manifest means the app is not refreshed; no legacy restart”; restart is an explicit mode, not a fallback; the manifest field is `mode`.

---

## F5 — Manifest identity, path resolution, and discovery are undefined; the runtime can refresh the wrong instance

**Severity: CRITICAL — a schema-valid manifest can point `-i` at a different app or read a different manifest than the one deployed.**

**The two units:**

- **Unit A — app repo `ags-notifications`.** Manifest `{schemaVersion: 1, instance: "ags-notifications", configDir: "ags-notifications", mode: "live", holdsUnsavedState: false}`; its `app.tsx` still has `instanceName: "notifications"` (the current name). AD-26 says the manifest declares `instance`; it never says it must equal `app.tsx`’s `instanceName`. CI validates the manifest schema and the handler; it passes.
- **Unit B — runtime.** Uses the manifest `instance` for `ags request palette-refresh <hash> -i <instance>` (`SPINE:96-98`). AGS routes the request by D-Bus name `io.Astal.<instance>`. The request goes to an instance that does not exist, or to the default `ags` bar if the name is empty/defaulted. Alternatively, Unit B reads the manifest from `configDir` while the process was launched with `-d` pointing at a dev worktree or a realpath with a different manifest; it reads the dev manifest and refreshes the deployed app or vice versa.

**ADs each obeys:** AD-26 (manifest fields at repo root, deployed with the app), AD-27 (`-i <instance>`), AD-31 (config links), AD-34 (runtime validates the deployed manifest). No AD defines the identity relation between `manifest.instance`, `app.tsx`’s `instanceName`, the `config/ags-*` link basename, the manifest’s `configDir`, and the `-d` argv. No AD defines whether “running app” is discovered by `/proc` argv, `ags list`, deployed config links, or a registry.

**The incompatibility (exact):**

- **Instance mismatch is schema-valid.** The manifest is the declaration; `app.tsx` is the implementation. Both can be valid and disagree. AGS’s `requestHandler` is attached to `app.start({ instanceName })`; the manifest is not read by the app. The runtime has no way to know the manifest is lying without cross-checking the process or `ags list`.
- **Discovery is undefined.** The current runtime scans `/proc` for `argv[0].name === "ags" && argv[1] === "run"`, then only accepts a separate `-d`/`--directory` argument (`RUNTIME/src/runtime/adapters/ags_reloader.py:110-148`). It misses `bash -lc 'ags run -d …'` (the actual autostart form), `uwsm app -- ags …`, `env ags …`, `--directory=…`, relative paths, and symlinked/wrapped binaries. A unit that instead uses `ags list` (AGS has this command) sees the real D-Bus owners but not config dirs; a unit that scans `<install>/config/*/app.manifest.json` sees deployed apps but not dev instances. All are “discover running apps.” The SPIKE-001 evidence shows two wrappers racing on one bundle; `/proc` sees both, `ags list` sees one, and no rule says which is the app.
- **Bar is special-cased in the current runtime, not in the manifest.** The bar is launched as bare `ags run` (no `-d`), so `/proc` discovery excludes it and `AgsReloader` restarts it separately (`RUNTIME/src/runtime/adapters/ags_reloader.py:13-15,110-115,187`). AD-30 says the bar is the only restart app; AD-26 says the manifest is the declaration. Unit runtime A treats the bar via its `config/ags/app.manifest.json`; Unit runtime B hardcodes it. If the bar manifest is missing during migration, AD-26 says “do nothing” while AD-30 says “restart the bar”; both are written rules.
- **Duplicate instances are possible.** SPIKE-001 documented two hypr-pano wrappers, only one owning the D-Bus name. A `/proc`-based unit can invoke the wrong config dir/manifest or refresh twice; an `ags list`-based unit can miss the second process. No dedupe/ambiguity rule exists.
- **Path traversal is not forbidden.** `configDir` is a free string; an absolute path or `..` could read a manifest outside the install/config root. The schema in `contracts` does not exist yet, so even a strict validator has no pattern to enforce.

**Evidence:** `SPINE:76-100` (AD-26/AD-27), `SPINE:304-314` (app map: instance/config dir), `RUNTIME/src/runtime/adapters/ags_reloader.py:68-107,110-148` (regex instance, `/proc` discovery), `/usr/share/ags/js/lib/gtk4/app.ts:300-320` (`instanceName` from app config), `ags list --help`, `ags-apps/tickets/SPIKE-001-ags-refresh-patterns/ticket.md` (two wrappers, bundle race), current `app.tsx` instance names (`notifications`, `capture`, `wallpaper-selector`, `icon-color-mapping-editor`, `btop-theme-studio`, `hypr-pano`), `dotfiles-assets/configs/hypr/autostart.lua:19-51` (staggered launches; bare bar).

**Verify:** `grep -n 'instanceName' ags-apps/*/app.tsx; grep -n 'instance\|configDir' SPINE | sed -n '1,25p'; sed -n '110,148p' RUNTIME/src/runtime/adapters/ags_reloader.py; ags list`. Then set a manifest `instance` different from `app.tsx` and call `ags request palette-refresh deadbeef -i <manifest-instance>`; it fails while the app is running under the other name.

**Proposed (tighten AD-26 and add a discovery/identity AD):** Define the identity tuple explicitly: `app` id, `instance`, `configDir`, `configLink`. Require `manifest.instance === app.tsx instanceName === ags list name` and `manifest.configDir === config link basename`, single path segment, lowercase `[a-z0-9-]+`. The runtime discovers **deployed** config links under `<install>/config` that contain a valid manifest, intersects with `ags list`, dedupes by `instance`, and fails/logs on duplicates. It reads the manifest from the resolved deployed link, never from `-d` argv. It ignores dev/worktree instances unless an explicit `--include-dev` flag is passed. The bar is included through its manifest; no hardcoded bar exception. Missing/invalid manifest is a structured failure entry (not a silent no-op) and does not fall through to a legacy restart. Sort discovery for the summary.

---

## F6 — `colors.css`/`icons.json` have two owners; user state lives in the versioned tag

**Severity: HIGH — concurrent writers race on the same symlink, and a tag bump can silently reset user settings.**

**The two units:**

- **Unit A — `dotfiles-provision`.** Follows AD-31: creates the bar palette pointer `<install>/apps/bar/<tag>/colors.css` pointing at the runtime state pointer (`PROVISION/ansible/roles/ags_apps/tasks/main.yml:256-267`). Also runs `compositor_configs`, which writes `<install>/config/ags/icons.json` and `<install>/config/ags-capture/icons.json` (`.../compositor_configs/vars/main.yml:210-219`, `tasks/main.yml:101-115`). Through the `config/ags` symlink those are `<bar tag>/icons.json` and `<capture tag>/icons.json`.
- **Unit B — `dotfiles-runtime`.** Follows the inherited consumer-pointer contract: the seeder owns `<install>/config/ags/colors.css` → `current/colors.gtk.css` and repoints it on every reconcile (`RUNTIME/src/runtime/adapters/consumer_path_spec.py:6-8,48-57`; `seeder.py:776-796`). That is the **same file** as Unit A’s `<bar tag>/colors.css` through the `config/ags` symlink. The bar repo also tracks `bar/icons.json` (build-time import) and `bar/wifi-speedtest.json` (user config); `bar/services/speedtest-service.ts` writes `~/.config/ags/wifi-speedtest.json` and `~/.config/ags/wifi-speedtest-last.json` (`ags-apps/bar/services/speedtest-service.ts:64,72`), i.e. into the installed tag through the `config/ags` symlink.

**ADs each obeys:** AD-31 (provisioning owns the per-app list and the bar palette pointer), AD-21 (one icon manifest; the app repo’s committed `bar/icons.json` is the committed manifest), inherited consumer-pointer rule (runtime seeder owns the `config/ags/colors.css` pointer). No AD says which unit is the *only* writer, or that installed tags are immutable.

**The incompatibility (exact):**

- **Same path, two writers, different target forms.** Provisioning creates `colors.css` as a symlink to `<state>/dotfiles/current/colors.gtk.css`; the seeder repoints the same path to `<state_root>/current/colors.gtk.css`. On a fresh tag, provisioning may create it before/after the seeder; on a tag bump, the old target is inherited (`ags_apps_pre_colors_readlink`), then the seeder repoints. If the two run concurrently during a reconcile, the last writer wins; if provisioning writes after the runtime, the target form may differ but resolve to the same artifact today — until one changes its derivation. The deploy and reconcile paths have no ordering/lock relationship.
- **`icons.json` has a committed copy and a generated copy.** The app repo tracks `bar/icons.json`; provisioning generates the same path through the live link. The committed copy is what app CI/bundle uses; the generated copy is what the running bar reads after provisioning. A stale committed manifest can pass app CI and be replaced at deploy; a generated manifest can be replaced by the next clone/tag. The spine’s AD-21 says “one icon manifest” but the new topology gives the app repo and provisioning each an ownership claim.
- **User state is inside the code tag.** `wifi-speedtest.json` is tracked as a default and written as user config; `wifi-speedtest-last.json` is written into the same tag. On the next per-app tag bump, the new checkout has the committed default and no last-run file; the user’s interval/server mode resets. The same pattern applies to any app that writes under its `config/` root (the app root is the config dir). The current monorepo already has this shape, but the per-app split with `<app>/<tag>/` dirs makes it a permanent property of every app repo rather than a migration artifact.
- **Rollback reads stale state.** Repointing `config/ags` to an older tag restores older code but not the user state that was written under the newer tag. AD-31 promises tag-dir rollback but not state migration.

**Evidence:** `SPINE:140-151,196-208`; `PROVISION/ansible/roles/ags_apps/tasks/main.yml:256-267`; `PROVISION/ansible/roles/compositor_configs/vars/main.yml:210-219`, `tasks/main.yml:101-115`; `RUNTIME/src/runtime/adapters/consumer_path_spec.py:6-8,48-57`; `RUNTIME/src/runtime/adapters/seeder.py:776-796`; `git -C ags-apps ls-files bar/icons.json bar/wifi-speedtest.json` → both tracked; `ags-apps/bar/services/speedtest-service.ts:64,72`; `V3/scripts/deploy-coverage.py:201-207` (old unit icon ownership).

**Verify:** `readlink -f ~/.config/ags/colors.css; readlink -f <install>/apps/bar/<tag>/colors.css` (same path); `git -C ags-apps ls-files bar/icons.json bar/wifi-speedtest.json`; `stat -c '%N' <install>/apps/bar/<tag>/colors.css` after provision and after `dotfiles-runtime reconcile`; bump the bar tag and diff `~/.config/ags/wifi-speedtest.json` against the committed file.

**Proposed (add a single-producer/code-state AD):** Installed tag directories are immutable after install: no runtime or provisioning writes into `<install>/apps/<app>/<tag>/` except a one-time, explicitly listed generated-artifact seed performed by the producer. All writable user state lives under `$XDG_CONFIG_HOME/<app>` or `$XDG_STATE_HOME/<app>` outside the install tree. `colors.css` has one owner: recommend the runtime seeder, with provisioning only verifying the pointer (no create). `icons.json` has one owner: recommend provisioning generates it into a state/config artifact path (or the app repo stops tracking it and the runtime generates it); in either case the app repo never commits a generated manifest. Migrate `wifi-speedtest.json` out of the bar repo before REQ-015 and add a tag-bump test that asserts user state survives.

---

## F7 — The wire response is a string, not an object; exactly-once, timeout, and cancellation are unspecified

**Severity: HIGH — a literal implementation of AD-27’s JSON example can make every live refresh fail.**

**The two units:**

- **Unit A — app repo `ags-clipboard`.** Reads AD-27’s “returns JSON `{"ok":true}`” and implements `requestHandler(argv, res) { … res({ ok: true }) }`. AGS’s request callback is typed `(response: string) => void` and `vfunc_command_line` does `cmd.print_literal(str + "\n")`; the object coerces to `[object Object]\n`. The runtime sees malformed JSON and records failure even though the app applied the palette.
- **Unit B — app repo `ags-notifications`.** Reads the same prose but implements `res(JSON.stringify({ ok: true }))`; the runtime gets `{"ok":true}\n` and succeeds.

**ADs each obeys:** AD-27 says the app returns JSON, gives the two object literals, and says malformed/empty response is a failure. AD-28 says a 5-second timeout. Neither says “JSON-encoded string,” “exactly one response,” “respond only after apply,” “no response after an error path,” or “handler must not defer.”

**The incompatibility (exact):**

- **Object vs string.** AGS’s transport is a D-Bus string (`/usr/share/ags/js/lib/app/dbus.ts:7` `request(argv): Promise<string>`); the app callback’s declared type is string (`/usr/share/ags/js/lib/gtk4/app.ts:272-282`). `res({ok:true})` does not serialize to JSON; it stringifies via `+ "\n"`. Unit A is following the shape literally; Unit B is following the transport. Only B works.
- **Missing response = hang.** If a handler branch returns without calling `res` (e.g., unknown command, validation error before the response, or an exception caught and swallowed), AGS leaves the D-Bus request open. The runtime’s 5s timeout kills the `ags request` CLI, not the app handler; the handler may complete later, after the runtime has reported failure. The contract has no exactly-once rule and no “all paths respond.”
- **Response timing.** AD-27 does not say whether `ok:true` means “palette fully applied” or “request accepted.” Unit A can schedule an async apply and respond immediately; Unit B applies then responds. Both “return ok”; the runtime’s success log is a lie for A, and a second refresh can overlap the first.
- **Timeout cancellation.** `subprocess.run(timeout=5)` kills only the `ags` CLI; the app’s request handler is not cancelled. Unit A’s handler may mutate palette state after the runtime recorded a timeout. Unit B may use a client-side deadline but still cannot cancel the app. Idempotence-by-hash helps a full repeat, not a partial apply.
- **stdout/stderr.** `ags request` prints the response; an app that logs to stdout could contaminate the response if the transport ever shares it, and no rule says app logs go to stderr/AGS log. (The current separate-process transport keeps app stdout separate, but the contract should pin response-only stdout anyway.)

**Evidence:** `SPINE:89-100` (AD-27), `SPINE:102-114` (AD-28); `/usr/share/ags/js/lib/gtk4/app.ts:272-282`; `/usr/share/ags/js/lib/app/dbus.ts:7`; `ags request --help` (no timeout flag); current handlers call `res("ok")` (e.g., `ags-apps/hypr-pano/lib/requests.ts:40-53`), proving the transport is string-returning.

**Verify:** `sed -n '272,282p' /usr/share/ags/js/lib/gtk4/app.ts; sed -n '1,12p' /usr/share/ags/js/lib/app/dbus.ts; ags request --help`. Then a fake handler `res({ok:true})` prints `[object Object]`; `res(JSON.stringify({ok:true}))` prints the JSON. A handler that returns without `res` hangs until the caller times out.

**Proposed (tighten AD-27):** The response is a **single UTF-8 JSON-encoded string on stdout**, exactly once per request, and only after the palette is fully applied (or after a complete failure). Object-literal responses are forbidden; the contract’s example is `res(JSON.stringify({ok:true}))`. Every code path, including unknown command and error, must call `res` exactly once. `ok:true` means applied, not scheduled. The runtime captures stdout only, logs stderr separately, kills the `ags request` process group on timeout, records the timeout, and does not treat a late handler completion as success. The app must be re-entrant or return `{"ok":false,"error":"busy"}` if a second request overlaps. Add success/false/malformed/hang fixtures (see F15).

---

## F8 — “Every app emits” a log record is impossible; `reload_failures`, order, and exit code are unshaped

**Severity: HIGH — two conforming runtimes produce incompatible observability and failure surfaces.**

**The two units:**

- **Unit A — runtime.** Emits one JSON log record per invocation from the runtime, because only the runtime knows `argv`, exit code, start/end, duration, and the response. It writes to journald and appends one `"AgsReloader"` string to `reload_failures` if any app fails.
- **Unit B — app repo.** Reads AD-28 literally (“Every app emits a structured log record containing instance, config dir, palette hash, start/end, duration, argv, exit code, JSON response, and error”) and emits its own JSON record from the handler with instance/configDir/hash/start/end/ok. It cannot know argv/exit code, so those fields are absent or fabricated. The runtime also emits a summary. Both are “structured logs.”

**ADs each obeys:** AD-28’s fields and “every app emits”; the consistency table’s one-record-per-app and discovery-order summary (`SPINE:205-208`). No AD defines the emitter, sink, schema, field names/types, run correlation id, or the `reload_failures` element shape.

**The incompatibility (exact):**

- **Duplicate, different records.** A log consumer sees one app-emitted record (no argv/exit) and one runtime record (argv/exit), or only one depending on which unit implemented “emits.” There is no stable schema to parse.
- **`reload_failures` is a string list in the current code.** `ReconcileResult.reload_failures: list[str]` is appended with reloader class names (`RUNTIME/src/runtime/application/reconcile.py:81,333-354`). AD-28 says failures enter it, but a per-app failure has no representation. Unit A appends one adapter name for all apps; Unit B appends `"clipboard: timeout"` or a dict. The notification card checks `Array.isArray` and renders strings (`ags-apps/notifications/ui/NotificationsWindow.tsx:361-362`), so a dict would be filtered out or show `[object Object]`.
- **Summary order.** “Discovery order” is undefined when discovery is `/proc` directory order (nondeterministic), `ags list` order (not specified), or a config-link scan. Unit A sorts by instance; Unit B uses `iterdir()` order. Both are “discovery order.”
- **No run id.** Two operations with the same palette hash (e.g., a retry, two triggers) cannot be correlated across app records. Start/end timestamps are not enough under concurrency.
- **CLI exit code.** `V3/docs/ags-restart-vs-live-theme-refresh.md:60` says the command exits non-zero for `reload_failures`; AD-28 says `wallpaper.state done` is published after both lanes settle and failures enter `reload_failures`, but does not say the CLI exit. Unit A exits 0 (the palette was applied); Unit B exits 1 (an app failed). Keybinds/scripts see different results.
- **Missing-manifest errors.** AD-26 says log a structured error and do nothing. Is that a `reload_failures` entry (visible) or only a log? Unit A hides it; Unit B surfaces it. The user has different feedback for the same invalid state.

**Evidence:** `SPINE:102-114,196-210`; `RUNTIME/src/runtime/application/reconcile.py:81,333-354`; `ags-apps/notifications/ui/NotificationsWindow.tsx:361-362`; `V3/docs/ags-restart-vs-live-theme-refresh.md:60`; current `AgsReloader` logs only debug/warning lines, no per-app record (`RUNTIME/src/runtime/adapters/ags_reloader.py:187-257`).

**Verify:** `sed -n '102,114p' SPINE; sed -n '81,90p' RUNTIME/src/runtime/application/reconcile.py; rg -n 'reload_failures' RUNTIME/src/runtime/application/reconcile.py ags-apps/notifications/ui/NotificationsWindow.tsx; grep -n 'exits non-zero' V3/docs/ags-restart-vs-live-theme-refresh.md`.

**Proposed (tighten AD-28):** The **runtime** is the sole emitter of the per-app contract record. One record per app per operation, JSON Lines, schema in `contracts`, fields at least `runId`, `app`, `instance`, `configDir`, `mode`, `phase`, `paletteHash` (or appearanceHash), `startedAt`, `endedAt`, `durationMs`, `argv`, `exitCode`, `response`, `error`, `timeout`, `discoveryIndex`. App-internal logs remain app logs and are not the contract record. `reload_failures` becomes a structured list (preserve a string-compatible view for the card) of `{app, instance, mode, reason, detail}`. Define summary order as ascending `discoveryIndex`/`instance`. Define the CLI exit code explicitly (recommend 0 when the palette was applied, non-zero when any app failed, with `done` still published), and include invalid-manifest entries in the failure surface.

---

## F9 — Repointing a config link can pair a new manifest with old running code

**Severity: HIGH — the first palette change after a cutover can invoke a command the running app does not implement.**

**The two units:**

- **Unit A — `dotfiles-provision`.** Follows AD-31: installs the new tag and atomically repoints `config/ags-*` to `<install>/apps/<app>/<tag>`. It does not stop the running instance; AD-31 only says clone/link/verify.
- **Unit B — runtime.** Follows AD-26/AD-27: reads the manifest from the deployed link and invokes `palette-refresh` on the running app. The running app is still the old tag’s bundle, loaded under the old manifest (or no manifest). If the new tag adds the command, the old code returns “unknown request” or has no handler; if the mode changed, the runtime’s decision is based on the new declaration but the old code is what runs.

**ADs each obeys:** AD-31 (link topology), AD-26 (deployed manifest), AD-27 (invoke the running app), AD-32 (“test that app” after cutover). No AD says a link repoint is a process transition.

**The incompatibility (exact):** The runtime’s unit of truth is the deployed manifest; the app’s unit of truth is the loaded bundle. A link swap changes one without the other. A cutover from “no manifest” to “live manifest” is the worst case: the runtime now sees a valid manifest and calls the command; the old app has no handler, returns a non-JSON string or hangs, and the runtime records a failure. The app stays stale until it is restarted or relaunched — but AD-28 says no retry, and AD-29 may gate the next attempt. A rollback has the same mismatch in reverse. The current `ags_apps` role only links; `gui_tools` quits instances on provision, but the new generic loop has no lifecycle step in the spine.

**Evidence:** `SPINE:140-162`; `PROVISION/ansible/roles/ags_apps/tasks/main.yml` (link-only; no quit/start), `PROVISION/ansible/roles/gui_tools/tasks/main.yml:130-196` (separate quit/start loop), `RUNTIME/src/runtime/adapters/ags_reloader.py:230-238` (relaunch uses old argv), `/usr/share/ags/js/lib/gtk4/app.ts:272-282` (request handler is in the loaded app).

**Verify:** `grep -n 'state: link\|ags quit\|ags run' PROVISION/ansible/roles/ags_apps/tasks/main.yml PROVISION/ansible/roles/gui_tools/tasks/main.yml`; then deploy a tag that adds `palette-refresh` while the old tag is running and send the command; the running app answers with the old handler’s unknown-request string.

**Proposed (tighten AD-31/AD-32 and add a link-swap transaction AD):** A link swap is a transaction: confirmed quit (if running) → repoint link → verify manifest/tag → relaunch if it was running, with the same launch record; if it was stopped, leave it stopped. The provisioning loop owns the lifecycle transition, or explicitly records “stopped” so the runtime never operates on a mixed version. The runtime verifies the running instance’s config-dir realpath equals the current link target before invoking; a mismatch is a failure/restart, not a refresh. Add a fake-app cutover test where the new tag adds the handler.

---

## F10 — AGS has one shared bundle; launch serialization is local to the runtime restart lane

**Severity: HIGH — separate repos do not remove the shared `/run/user/$UID/ags.js`; any two `ags run` callers can still collide.**

**The two units:**

- **Unit A — `dotfiles-assets` autostart.** Starts the bar immediately, capture at +2s, clipboard at +3s, notifications at +4s; the comments explicitly say concurrent `ags run` invocations collide on `/run/user/$UID/ags.js` (`dotfiles-assets/configs/hypr/autostart.lua:19-51`).
- **Unit B — runtime restart lane.** During a palette change, quits and relaunches the bar with `ags run` (`RUNTIME/src/runtime/adapters/ags_reloader.py:187,230-238`), while live `ags request` calls run in parallel. AD-28 says “no concurrent `ags run`” only within the restart lane; “the lanes may overlap because live refresh does not bundle.” A third caller — `gui_tools` provisioning (`PROVISION/ansible/roles/gui_tools/tasks/main.yml:184-196`), an on-demand launcher, or a user keybind — can start another `ags run` during the restart window.

**ADs each obeys:** AD-28 (serialized restart lane, lanes may overlap), AD-25 (one repo per app), AD-31 (provisioning loops). No AD gives AGS a global launch lock or assigns a lifecycle owner per app. SPIKE-001 proves the failure: two wrappers race on the one bundle; only one owns the D-Bus name, and a wrapper can run the wrong bundle.

**The incompatibility (exact):** The “serialized restart lane” is a lock inside one runtime process, not a lock on AGS’s shared bundle. Login autostart, provisioning, launchers, and the runtime can each launch at the same time. The app repos are independent, but AGS is not: every app’s `ags run` writes/uses the same per-user bundle path. AD-28’s “live refresh does not bundle” is only true if `palette-refresh` handlers never invoke `ags`, bundle, or restart; no rule forbids it. Two conforming units (an autostart wrapper and a runtime restart) can still corrupt each other’s bundle.

**Evidence:** `SPINE:102-114`; `dotfiles-assets/configs/hypr/autostart.lua:19-51`; `RUNTIME/src/runtime/adapters/ags_reloader.py:187,230-238`; `PROVISION/ansible/roles/gui_tools/tasks/main.yml:158-196`; `ags-apps/tickets/SPIKE-001-ags-refresh-patterns/ticket.md` (two pano wrappers, shared bundle); `PROVISION/ansible/roles/cli_tools/templates/{capture-ui,hypr-pano-ui}.j2` (cold-start `ags run`).

**Verify:** `grep -n 'collide\|ags run' dotfiles-assets/configs/hypr/autostart.lua; rg -n 'ags run' PROVISION/ansible/roles/gui_tools PROVISION/ansible/roles/cli_tools/templates; ps -eo pid,args | grep '[a]gs run'`. Then start two `ags run` invocations within the bundle window and inspect `/run/user/$UID/ags.js` ownership and `ags list`.

**Proposed (add a launch-lock/lifecycle AD):** Define one per-user AGS launch lock (`flock $XDG_RUNTIME_DIR/ags-launch.lock`) acquired by **every** `ags run` caller — runtime restart lane, autostart wrappers, provisioning, launchers — with a bounded wait and a clear failure. `ags request` does not need the lock. Define a lifecycle owner per app (autostart, provisioning, on-demand launcher, or runtime) so no two layers start the same instance. Forbid `palette-refresh` handlers from invoking `ags`, bundling, restarting, or touching the shared bundle; they apply in-process only. If AGS gains a per-instance bundle flag, that can replace the lock (Deferred item).

---

## F11 — “Confirmed quit” and “safe restart” are slogans; restore down-state and stopped-app semantics

**Severity: HIGH — two conforming restart implementations can duplicate the bar, lose its launch context, or leave it down forever.**

**The two units:**

- **Runtime A.** Follows AD-30 by calling `ags quit` (10s), treating exit 0 as “delivered,” immediately launching `ags run`, and polling the new process for 2s. If the new process exits 0 (because the old instance is still alive and the new one delegated as a remote activation), it records failure even though the app is running. This is the current code.
- **Runtime B.** Follows AD-30 by waiting for the D-Bus name to disappear before launching, storing the original argv/cwd/log file, and relaunching exactly. It treats a stopped bar as stopped.

**ADs each obeys:** AD-28 (“confirmed quit, no concurrent `ags run`, no exit-0 misclassification”), AD-30 (“restart uses the safe procedure from AD-28”; “safe to restart at any moment”). Neither AD defines “confirmed,” a timeout, a launch record, or whether a stopped app is started. The current code is evidence that “exit 0” is not confirmation: it logs “`ags quit` delivered; teardown is asynchronous” and then immediately launches.

**The incompatibility (exact):**

- **Confirmed vs delivered.** `ags quit` returning 0 means the request was delivered, not that the process/D-Bus name is gone. A runtime that launches immediately can create a duplicate-instance delegation, which exits 0; the runtime misclassifies it as a restart failure, or worse, leaves the old instance as the only owner while the new one is gone.
- **Launch context.** The bar is launched by autostart as bare `ags run` (`dotfiles-assets/configs/hypr/autostart.lua:19`). A runtime that relaunches bare `ags run` loses the original `--log-file`, cwd, environment, and any systemd/uwsm scope. A runtime that stores the original argv preserves them. Both are “restart the bar.”
- **Stopped apps.** AD-30 says restart-mode apps run in a serialized lane; it does not say only running ones. Runtime A starts a bar the user intentionally quit on the next palette change; Runtime B leaves it stopped. The manifest `mode:restart` is not a lifecycle declaration.
- **Missing/invalid bar manifest.** AD-26 says do nothing and log; AD-30 says the bar restarts. During the program the bar may not have a manifest until REQ-015. Runtime A (manifest-driven) leaves the bar stale; Runtime B (hardcoded bar) restarts it. Both cite a rule.
- **Failure state.** AD-28 says no retry; AD-29’s gate can skip the next identical palette; the bar can stay down until login. The consistency table’s “app stays running/stale” (`SPINE:208`) is false for restart mode.

**Evidence:** `SPINE:102-114,128-138,208`; `RUNTIME/src/runtime/adapters/ags_reloader.py:205-257`; `dotfiles-assets/configs/hypr/autostart.lua:19`; `RUNTIME/src/runtime/application/reconcile.py:333-354`.

**Verify:** `sed -n '205,257p' RUNTIME/src/runtime/adapters/ags_reloader.py`; run a fake quit that returns 0 without exiting the old process, then launch the new one; the new process exits 0 and the reloader returns False. `grep -n 'ags run' dotfiles-assets/configs/hypr/autostart.lua`.

**Proposed (tighten AD-30 and add a restart-procedure AD):** Define stages and bounds: request quit ≤2s; confirm the D-Bus name/PID is gone ≤5s (poll `ags list` and `/proc`); launch with the recorded argv/cwd/env/log file ≤5s; confirm the new instance owns the D-Bus name/PID ≤5s; total per app ≤15s. Restart only instances that were running at discovery; a stopped app stays stopped unless it is explicitly session-critical and declared as such. Capture a launch record at discovery (or from the provisioning list) for the bar. The manifest is the source of `mode`; the bar’s manifest must be deployed before the bar cutover; missing/invalid manifest is a failure entry, never a silent no-op or a hardcoded fallback. A failed restart is a `down` state, surfaced; the next trigger may retry only the failed app (see F2). Define “no exit-0 misclassification” as “the new PID owns the D-Bus name,” not “the process has not exited.”

---

## F12 — Live refresh is mandated before its two known hazards are removed; “already live” tickets assume packaging-only

**Severity: HIGH — three existing live apps currently refresh on `wallpaper.state`, and the platform Theme port leaks a provider per apply.**

**The two units:**

- **App repo A — `ags-notifications` (also selector, ICME).** REQ-012/013/014 say “already live; packaging cutover.” The app keeps its existing `wallpaper.state` subscription and `theme.apply()` path (`ags-apps/notifications/ui/NotificationsWindow.tsx:352-358,982`; selector `WallpaperSelectorWindow.tsx:781-786`; ICME `EditorWindow.tsx:175-183`) and adds a `palette-refresh` handler. On a palette change the runtime command and the `wallpaper.state` event both apply the palette.
- **App repo B — a new live app.** Removes the event path and applies only through the command handler. It uses a one-provider replacement helper. Both are “live.”

**ADs each obeys:** AD-27 says “Live refresh does not subscribe to [`wallpaper.state`] for palette” — App A violates that if it keeps the subscription, but REQ-012’s acceptance says packaging-only, so the app repo following its child ticket will keep it. AD-13 says every live refresh routes through the Theme port; the platform’s Theme adapter currently adds a provider per apply (the spine’s own Deferred item says the replacement is “required before new live refresh work is considered safe for provider accumulation,” `SPINE:348-349`). No AD makes the replacement a gate or tells the child tickets to remove the event path.

**The incompatibility (exact):** A palette change triggers two applications in App A: the runtime’s command (new) and the app’s `wallpaper.state done` handler (old). If both use the platform Theme port, each apply adds a provider; repeated wallpaper changes accumulate providers and eventually degrade the app. App B applies once. Both are “live” and both may pass a handler test; the runtime cannot tell. The problem is compounded because AD-28 publishes `wallpaper.state done` after the lanes settle, so the old subscription fires *after* the command, not before. The app is never stale, but it leaks and may flicker. The spine’s Deferred says this is not safe, while AD-27/AD-30 require every non-bar app to be live now.

**Evidence:** `SPINE:89-100,128-138,348-349`; `ags-apps/notifications/ui/NotificationsWindow.tsx:352-358,982`; `ags-apps/wallpaper-selector/ui/WallpaperSelectorWindow.tsx:781-786`; `ags-apps/icme/ui/EditorWindow.tsx:175-183`; `V3/docs/ags-restart-vs-live-theme-refresh.md:68-77` (the current live set is event-driven); `REQ-012/013/014` (“already live; packaging cutover”; “The existing live behavior and trigger semantics are preserved,” e.g. `tickets/REQ-012-migrate-notifications-standalone/ticket.md:22-37`; “ags-platform provider replacement before adding more live refreshes,” `:48`); all three also still say `refresh: live`, not `mode`; `ags-platform/adapters/theme.ts` and `/usr/share/ags/js/lib/gtk4/app.ts:174-215` (provider accumulation evidence cited by the spine).

**Verify:** `rg -n 'wallpaper.state|theme.apply' ags-apps/notifications/ui/NotificationsWindow.tsx ags-apps/wallpaper-selector/ui/WallpaperSelectorWindow.tsx ags-apps/icme/ui/EditorWindow.tsx; grep -n 'already live\|packaging' tickets/REQ-01{2,3,4}-*/ticket.md; grep -n 'provider replacement\|accumulation' SPINE`.

**Proposed (tighten AD-27 and the child tickets; promote the provider gate):** The command is the only palette trigger after startup. Remove the `wallpaper.state` palette subscriptions from notifications, selector, and ICME as part of their cutovers; `wallpaper.state` remains progress/UI only. Each app CI asserts that `wallpaper.state` does not apply palette. Promote the `ags-platform` Theme provider replacement from Deferred to a blocking prerequisite for any new live app (or explicitly accept a measured provider bound and add a cleanup). Update REQ-012/013/014 from “packaging cutover” to “remove event palette path + add command handler + tests.” Add a provider-count regression test (apply N palettes, assert one live provider).

---

## F13 — `holdsUnsavedState` does not constrain live handlers; transient obligation is missing; apply is not atomic

**Severity: HIGH — an app can be `live` and still destroy the state the manifest says it holds.**

**The two units:**

- **Unit A — `ags-btop-theme-studio`.** Manifest `{mode: "live", holdsUnsavedState: true}`. Its `palette-refresh` handler rebuilds the UI to pick up colors, discarding the in-memory pending theme edits, then returns `{"ok":true}`. AD-26 only says `mode:restart` is invalid when `holdsUnsavedState` is true; it never says a live handler must preserve that state. The app obeys the schema and the handler contract.
- **Unit B — `ags-icme`.** Manifest `{mode: "live", holdsUnsavedState: true}`. Its handler swaps only the loaded show/palette and preserves the staging maps, as the current code already does. Both are live; only B honors the EPIC done-when “btop never loses pending edits.”

**ADs each obeys:** AD-26 (fields; restart invalid with unsaved state), AD-30 (restart is all-times safe; live is the alternative), AD-33 (handler/tests). No AD defines what a live handler may do to declared state, whether `ok:true` may be returned before the apply, or whether the apply must be atomic. The transient-obligation flag required by REQ-008/EPIC is absent from AD-26’s field list; `holdsUnsavedState` covers edits, not a progress card or in-flight operation.

**The incompatibility (exact):**

- **State preservation is unenforced.** Unit A’s handler is a valid live refresh by the letter; it can recreate the window/state and lose pending edits. The runtime sees `ok:true`. The user loses work. The manifest’s `holdsUnsavedState: true` gave a false assurance.
- **Transient obligation has no representation.** Notifications owns a progress card during a wallpaper set. If a future app with a transient obligation were `restart`, AD-30’s all-times-safety assertion is the only protection; there is no machine-readable flag, so the runtime cannot distinguish “safe to restart” from “safe only when idle.” REQ-008/EPIC require this flag; the spine dropped it.
- **Non-atomic apply.** A handler that removes the old provider and then fails to load the new one leaves the app unstyled and returns `{"ok":false}`. Another prepares/validates the new provider before swapping, leaving the old palette on failure. Both “report failure”; the user sees different states. AD-28 says the app stays running/stale, but a half-applied palette is neither.
- **`ok:true` before apply.** A handler can schedule the apply asynchronously and return immediately; the runtime logs success while the app is still old. The 5s timeout doesn’t help if the app responds early.

**Evidence:** `SPINE:76-87,128-138`; `EPIC:58-68,97,102`; `REQ008:23-24` (transient-obligation flag); `ags-apps/btop-theme-studio/ui/StudioWindow.tsx:87-113,453-462` (pending edits); `ags-apps/icme/ui/EditorWindow.tsx:172-183` (preserves pending edits); `V3/docs/ags-restart-vs-live-theme-refresh.md:68-77`.

**Verify:** `grep -n 'holdsUnsavedState\|transient' SPINE EPIC REQ008; grep -n 'Pending edits' ags-apps/btop-theme-studio/ui/StudioWindow.tsx; grep -n 'refreshShow\|staging' ags-apps/icme/ui/EditorWindow.tsx`. Then run a fake live handler that clears pending state and returns ok; a schema-only test passes.

**Proposed (tighten AD-26/AD-30 and add a state-class rule):** Add `stateClass: none | unsaved | transient` (or add `transientObligation: boolean` alongside `holdsUnsavedState`). `mode:restart` is invalid if either state is present. A live handler must apply in place, never quit/relaunch/recreate a state-holding surface, and preserve all declared state. `ok:true` only after the palette is fully applied. Apply is atomic: prepare and validate the new provider, then swap; on any error keep the previous palette and return `ok:false`. App CI includes a pending-state preservation test and a forced-failure atomicity test.

---

## F14 — Release tags are mutable; manifest/protocol version negotiation is absent

**Severity: MEDIUM — a “pin” can resolve to different code, and a schemaVersion bump can silently disable refresh.**

**The two units:**

- **Unit A — app repo `ags-clipboard`.** Releases annotated tag `v1.0.0`; after a bug, force-updates the tag (git permits it). `dotfiles-v3` pins `v1.0.0`. Provisioning clones it at different times and gets different code under the same pin. The verify role checks only the tag name.
- **Unit B — app repo `ags-notifications`.** Bumps `schemaVersion` to 2 and uses a new response field. The runtime pins `contracts` v1, validates the deployed manifest, sees `schemaVersion: 2` as invalid, and follows AD-26 “do nothing” — no refresh, no restart, no failure entry. The app is silently stale until someone notices. Or the runtime ignores unknown fields, and the app relies on behavior the runtime does not implement.

**ADs each obeys:** AD-33 (“releases by annotated tag”), AD-34 (“pin by git tag/commit,” “schemaVersion starts at 1,” runtime validates the deployed manifest). No AD says tags are immutable, that the pin records a commit, that `contracts`/`ags-platform` tags are program-wide (F1), or how a runtime handles a schema/protocol version it does not support. There is no `protocolVersion` distinct from the manifest `schemaVersion`; response-shape evolution is unversioned.

**The incompatibility (exact):** Two provisioning runs with the same declared pin can install different code. Two app/runtime pairs can validate against different schema versions and both claim “conformance”; the runtime’s “invalid manifest = do nothing” converts a version skew into silent staleness. A protocol change (e.g., adding a field, changing error semantics) has no version gate at all.

**Evidence:** `SPINE:164-183,209,219-221`; `contracts/schemas/last-converged.schema.json:5` (unknown version treated as changed, not fatal); `PROVISION/ansible/roles/ags_apps/tasks/main.yml:74-100` (clone by tag; no commit record); `V3/dotfiles/provisioning/cli-tools.yaml` (tag pins); `SPINE:355` (exact tags deferred).

**Verify:** `git tag -f v1.0.0 && git clone --branch v1.0.0` before/after → different trees; `grep -n 'schemaVersion\|protocol' SPINE contracts/schemas/*.json`; write a manifest with `schemaVersion: 2` and run the current runtime validator → invalid.

**Proposed (add a pin/version AD):** Release tags are immutable. The app list records `tag` **and** the resolved commit SHA; provisioning verifies `tag^{commit}` and refuses a moved tag. `contracts`/`ags-platform` pins are program-wide (F1). Define a supported manifest `schemaVersion` range and a separate `protocolVersion` (or explicitly tie protocol to schema). Unsupported versions are a structured failure entry and block install; they are never a silent no-op. Add a compatibility matrix to the program release notes. Tag signing can remain Deferred.

---

## F15 — Handler tests are unshareable; conformance fixtures and deployed `node_modules` isolation are missing

**Severity: MEDIUM — two app repos can both pass their own gates while implementing different wire behavior.**

**The two units:**

- **App repo A.** Follows AD-33 by adding tests, but the `palette-refresh` logic lives inline in `app.tsx` and imports AGS/GTK. Stock CI cannot import it, so the repo tests a pure helper or only the manifest schema. It never exercises argv/response/timeout.
- **App repo B.** Extracts `lib/palette-refresh.ts` (no AGS imports), tests it with a fake `res` and fake palette, and passes exact wire fixtures. Both repos claim AD-33/AD-34 conformance. The runtime’s tests use their own fake responses, so A and B can disagree on object-vs-string, error paths, or timeout behavior without any shared failure.

**ADs each obeys:** AD-33 (“handler, and its tests”; pure tests in stock CI), AD-34 (“conformance test for its manifest and handler”). No AD requires the handler logic to be pure/testable, names a shared fixture source, or forbids a deployed app tag from carrying its own `node_modules/ags-platform` (which shadows the shared ancestor, F1).

**The incompatibility (exact):** “Conformance test” is per repo and self-authored; there is no canonical request/response corpus. App A can return `[object Object]` and its tests pass; App B returns JSON. The runtime is the only place the two meet, at 5s in production. A deployed tag with a local `node_modules` also gets a different platform implementation than the shared one, even if both apps use the same code. Both are “green.”

**Evidence:** `SPINE:164-183`; `RUNTIME/src/runtime/adapters/ags_reloader.py` (no shared fixtures); `ags-apps` app layout (`app.tsx` at root; no `lib/` in the seed); `git ls-files` on a deployed tag would show `node_modules` if committed; AGS request callback string (F7).

**Verify:** `find <app-repo> -maxdepth 2 -name '*palette*' -o -name 'node_modules'`; `grep -n 'conformance' SPINE`; run the app’s CI without AGS installed — an inline handler test cannot import `app.tsx`.

**Proposed (tighten AD-33/AD-34):** The handler logic lives in a pure module (no AGS/GJS imports) with a thin `requestHandler` adapter in `app.tsx`. `contracts` ships shared fixtures (argv, palette hash, success/false/malformed/hang/busy vectors) and a small testkit; both app CI and runtime tests consume the same fixtures. The deployed tag must contain no `node_modules` or vendored platform; provisioning verify rejects it. The template’s seed includes `lib/` and `tests/fixtures` explicitly.

---

## Deferred items (with revisit conditions)

These are real but should not block the freeze; each needs a named revisit point. Items already in the spine are marked “keep”; new ones are marked “add.”

- **Bar live refresh (keep `SPINE:346-347`).** Revisit after REQ-015 (bar cutover) with a measured benefit and a bar-specific live handler that preserves popup/settings state. Condition: the handler passes the F7/F13 tests and the 5s budget.
- **`ags-platform` Theme provider replacement (change from Deferred to gate).** The spine currently defers it while mandating live refresh (`SPINE:348-349`). Either promote it to a blocking prerequisite for every new live app, or explicitly accept a measured provider bound and add a cleanup. Revisit at the first live app cutover (REQ-009) — not after all apps are live.
- **`ags-apps` archive timing (add).** AD-32 says archive when the last app moves; AD-33 says cross-app work stays until archived; REQ-016 is the final consumption cutover after REQ-015. Archive after REQ-016 closes and no cross-app tickets remain. Revisit at the last app cutover; do not archive before the final program ticket is closed. The absolute “no `ags-apps` pin remains” (`SPINE:151`) becomes “at program completion.”
- **AGS per-instance bundle (add).** Defer; the F10 launch lock is the near-term fix. Revisit if AGS adds a `--outfile`/per-instance bundle flag or if the lock proves insufficient under measured concurrency.
- **Tag signing (add).** Defer; tag immutability and commit recording are required now (F14). Revisit at REQ-016 or the first external contributor/supply-chain review.
- **Log retention/sink (add).** Defer the long-term sink; the contract record schema and journald emission are required now (F8). Revisit when the status surface or support workflow needs historical logs.
- **Multi-user/multi-session (add).** Defer; the runtime and app manifests assume per-user install/state. Revisit if a second session or system-level provisioning is required.
- **`res`/D-Bus cancellation (add).** AGS 3.1 has no cancellation protocol; the runtime can kill the CLI but not the handler. Defer a true cancel until AGS exposes one; require handler idempotence/atomicity now (F7/F13).
- **Exact per-app `contracts`/`ags-platform` tags (keep `SPINE:355`).** Revisit at each cutover; F1 requires the program tuple, so this becomes “record the chosen tuple,” not “let each app choose independently.”
- **Invalid-manifest UX beyond logs (keep `SPINE:356`).** Revisit after the first invalid-manifest failure; F2/F8 require it to be a failure entry, not only a log.

---

## Proposed AD change set (ordered by freeze blocker)

1. **Tighten AD-31 + AD-34 (F1):** one program `platform_tag`/`contracts_tag`; shared ancestor authoritative; all app repos pin the same tuple; no app-local `node_modules`; provisioning/runtime verify the tuple.
2. **Tighten AD-29, add applied-appearance ledger (F2):** one record, one writer, daemon+CLI+`wallpaper set`+`regenerate`; per-app statuses; failure recovery; single-flight; schema in `contracts`.
3. **Tighten AD-32, add cutover/ownership AD (F3):** `apps.yaml` schema; `owner: old|new`; cutover epoch; release order; old-role allow-list; all ownership surfaces; rollback; runtime/engine prerequisites.
4. **Tighten AD-35 + supersession (F4):** explicitly supersede EPIC-002/REQ-009 same-name rule; rewrite REQ-009 to `ags-clipboard`/`clipboard`/`mode`; add `dotfiles-assets` rename; or defer rename. Update EPIC missing-manifest/restart-fallback text.
5. **Tighten AD-26, add discovery/identity AD (F5):** identity tuple; `instance`/`configDir`/link/app.tsx equality; patterns; deployed-link + `ags list` discovery; dedupe; bar via manifest; invalid = failure entry.
6. **Add single-producer/code-state AD (F6):** installed tags immutable; state outside; `colors.css` single owner; `icons.json` single owner; no tracked generated files; tag-bump state test.
7. **Tighten AD-27, add wire AD (F7):** JSON-encoded string; exactly once; after apply; process-group timeout; busy response; no deferral.
8. **Tighten AD-28, add result/log AD (F8):** runtime emits; schema; `runId`; stable order; structured failures; CLI exit code; invalid-manifest failures.
9. **Add link-swap transaction AD (F9):** stop/repoint/start; running-version verification; rollback; fake-app cutover test.
10. **Add launch-lock/lifecycle AD (F10):** per-user `flock` for every `ags run`; lifecycle owner per app; live handler must not bundle/restart.
11. **Tighten AD-30, add restart-procedure AD (F11):** confirmed quit; stage timeouts; launch record; running-only; bar manifest; down state; retry policy.
12. **Tighten AD-27 + child tickets (F12):** remove `wallpaper.state` palette subscriptions; command is sole trigger; promote provider gate; update REQ-012/013/014.
13. **Tighten AD-26/AD-30, add state-class AD (F13):** `stateClass`/transient; in-place, state-preserving, atomic live handler; tests.
14. **Add pin/version AD (F14):** immutable tags + commit SHA; program tuple; schema/protocol ranges; unsupported = failure/block.
15. **Tighten AD-33/AD-34 (F15):** pure handler module; shared `contracts` fixtures/testkit; no deployed `node_modules`.

The first five are freeze blockers. Items 6-15 should be resolved before the first app cutover (REQ-009), not discovered during it.

---

## Check performed

- Read `SPINE` and `.memlog.md` in full.
- Read `EPIC-002`, `REQ-008`, `REQ-009`, SPIKE-001, and the current `V3/docs/ags-restart-vs-live-theme-refresh.md`.
- Read current `RUNTIME` `AgsReloader`, `ReconcileDesktopStateUseCase`, `ReactiveConvergeUseCase`, `LastConvergedBackstop`, `CacheSeeder`, `StaticConsumerPathSpec`, and CLI wiring.
- Read current `PROVISION` `ags_apps`, `ags_platform`, `config_links`, `compositor_configs`, `gui_tools`, `cli_tools` roles and the `manifests_dir` seam.
- Read `V3/dotfiles/provisioning/{cli-tools.yaml,installer.pin}` and `V3/scripts/deploy-coverage.py` cutover assumptions.
- Read `contracts/schemas/last-converged.schema.json` and the current app `instanceName`s / `wifi-speedtest` state paths.
- Checked AGS 3.1 `request` transport (`/usr/share/ags/js/lib/gtk4/app.ts`, `lib/app/dbus.ts`) and `ags request --help`.
- No files were modified except this review.

---

*End of review.*
