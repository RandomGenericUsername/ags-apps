# Evidence and version review — standalone AGS app contract

**Reviewer:** BMAD architecture reviewer gate, evidence/version lens
**Date:** 2026-10-26
**Spine:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/architecture-standalone-app-contract.md`
**Decision log:** `_bmad-output/initiative-ags-standalone-apps/architecture-standalone-app-contract/.memlog.md`
**Verdict:** **CHANGES REQUIRED** (not ready to freeze)

---

## Verdict

The contract is directionally coherent — one manifest, one `palette-refresh`
command, parallel live requests, and a per-app install tree is the right shape —
and the central resolution claim is correct: **the proposed
`<install>/apps/node_modules/ags-platform` ancestor really does resolve through
AGS 3.1.0's embedded esbuild, including when the app is launched through a
`config/ags-*` symlink**. I proved that end to end, not by inspection.

It is not ready to freeze. Five high-severity issues remain: the decision
reverses the prior explicit exit gate without a pilot or measured cost; the
pilot ticket contradicts AD-35/AD-26 on names and manifest fields; per-app
`ags-platform` pins contradict a single shared platform ancestor; the
one-owner cutover cannot be “one commit set” across the pinned engine/composition
split; and the manifest-driven runtime has no defined way to discover — or even
safely survive the pre-cutover period with — the bar, which is the only restart
app. The `ags request`/GApplication details are also underspecified: a handler
must return a **string**, not a JSON object, and AGS exits 0 for “no handler” and
“unknown request”, so the runtime’s malformed-response rule is load-bearing.
Finally, several cited evidence sources are already stale: btop is now in the
runtime skip set, and the restart-policy doc and REQ-008 ticket still describe
the superseded legacy/restart rules.

No code outside this review was changed.

---

## 1. What was checked and confirmed

### 1.1 AGS version and request/GApplication behaviour — ACCURATE

- `ags --version` → `ags version 3.1.0`; `/usr/share/ags/js/package.json` →
  `"version": "3.1.2"`. This matches the spine’s “AGS CLI / JS package
  3.1.0 / 3.1.2” (`architecture-standalone-app-contract.md:216`).
- Upstream `v3.1.2` is the latest AGS release (published 2026-04-08); its
  `cli/version` still says `3.1.0`, so the split is expected, not drift.
- `ags request palette-refresh <hash> -i <instance>` works: `ags request` is
  `ArbitraryArgs` with an `-i/--instance` flag (`cli/cmd/request.go` at
  `v3.1.0`), and pflag accepts the flag after positional arguments. Verified
  against a running instance:
  `ags request show -i hypr-pano` → `ok`, exit 0.
- The request reaches the app’s `requestHandler(argv, res)` through the
  `io.Astal.Application.Request` D-Bus method (`/usr/share/ags/js/lib/app/dbus.ts:29-31`,
  `/usr/share/ags/js/lib/gtk4/app.ts:305-307`), and the app’s `argv` is
  `["palette-refresh", "<hash>"]`.
- `ags request` waits for one response, prints it with `fmt.Println`, and exits
  0. A missing instance exits 1. There is no built-in timeout; the 5 s timeout
  must be imposed by the runtime. All confirmed by command.
- `ags request` does **not** bundle; only `ags run` does. Parallel live requests
  are therefore consistent with AGS 3.1.0. The shared-bundle constraint applies
  to `ags run`/restarts, not to the live lane (see F5).
- Astal is not versioned by the spine. The installed stack is
  `libastal-*-git r986`, and the AGS JS package declares `gnim ^1.9.1`
  (installed `1.9.1`). No contradiction; the architecture simply does not pin
  Astal, which is appropriate if it follows the distro package.

### 1.2 Python and TypeScript — mostly accurate, one wording defect

- Python 3.14.7 is installed; `dotfiles-runtime` requires `>=3.14`
  (`dotfiles-runtime/pyproject.toml:8`). The Python claim fits.
- TypeScript 5.9.3 is present under `ags-apps/node_modules`, and the Makefile
  installs it on demand with `npm install --no-save --no-package-lock
  typescript@5.9` (`ags-apps/Makefile:146-148`). It is **not** a repo pin:
  there is no root `package.json` or lockfile, and the version is a floating
  5.9 range. See F7.

### 1.3 Per-app install topology and esbuild resolution — VERIFIED WORKING

I built the exact proposed tree in `/tmp/opencode/ags-topology-test`:

```text
apps/reqapp/v1/app.tsx
apps/node_modules/ags-platform -> .../ags-platform
config/ags-req -> ../apps/reqapp/v1
```

`app.tsx` imported `ags-platform/adapters/theme`; the app was started through
the config symlink:

```sh
ags run -d /tmp/opencode/ags-topology-test/config/ags-req &
ags request palette-refresh deadbeef -i topology-evidence
```

Result: exit 0, stdout
`{"ok":true,"cmd":"palette-refresh","arg":"deadbeef","theme":"function"}`.

Negative control — the same tree with the shortcut only at
`<base>/config/node_modules/ags-platform` and none under `apps/` — failed:

```text
✘ [ERROR] Could not resolve "ags-platform/adapters/theme"
  .../apps/reqapp/v1/app.tsx:2:22
exit=1
```

This is direct proof of AD-31’s resolution premise. AGS’s esbuild realpaths the
entry point; the real app path is under `apps/`, so `apps/node_modules` is the
working shared ancestor. The existing installer’s comment that the old
`config/node_modules` shortcut is not an ancestor is correct
(`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml:326-330`).

### 1.4 Git-tag distribution — real enough to proceed

`ags-platform`, `contracts`, `ags-apps` and `dotfiles-runtime` are public
GitHub repos; their tags are annotated (`git for-each-ref` → all `tag`
objects). The existing pins are real (`ags-platform v0.2.0`,
`contracts v0.2.0`, `ags-apps v0.4.3`). The app repos are not publicly visible yet
(the public GitHub API returns 404 for all seven), which is expected at
architecture stage but is also why the pilot/exit-gate claim is unproven.

### 1.5 Current runtime facts the spine relies on — partly accurate, partly stale

- The bar is deliberately excluded from `/proc` discovery because it runs bare
  `ags run` with no `-d`
  (`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:110-115,130-139`).
- The current skip set now includes `ags-btop-studio`
  (`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:53-66`), added by
  commit `87245f2` and included in released `v0.2.2`
  (`git merge-base --is-ancestor 87245f2 v0.2.2` → 0).
- The current restart path quits and relaunches without waiting for a confirmed
  quit (`ags_reloader.py:206-238`); any early exit, including 0, is logged as a
  failure. BUG-003 is still the relevant prerequisite.

---

## 2. Findings

### F1 — HIGH: The prior exit gate is reversed without a pilot or measured cost

**Claim:** the spine supersedes the 2026-10-16 three-repo decision because
“the pilot in REQ-009 is the harness/install exit-gate proof; the per-app split
is now the decision of record”
(`architecture-standalone-app-contract.md:59-62`).

**Reality:** the superseded decision explicitly made the pilot a *precondition*
for a per-app split, not a post-hoc proof:

- `dotfiles-v3/docs/GUIDE-ags-app-repos-refinement.md:90-95`: “Why not 7 now:
  7× harness/CI/release cost with no CI template or repo-creation script yet;
  platform surface not frozen … `dotfiles` N-unit install/rollback unsolved.”
  “Exit gate for a future per-app split: AD-6 + AD-17 + AD-21 closed,
  `ags-bar-validate` green in provisioning, and one pilot … proves the
  harness/install cost. Until then, independent lifecycles alone do not earn
  the tax.”
- No app repo is publicly visible yet; `REQ-009` is not started; there is no pilot, no
  repo-creation script, and no fake-app cutover test. The only cutover artifact
  is a Mermaid diagram (`architecture-standalone-app-contract.md:290-302`).
- The REQ-008 acceptance explicitly requires the cutover recipe to be “tested
  on a fake app” (`tickets/REQ-008-standalone-app-contract/ticket.md:53-55`).
  No such cutover test exists in the worktree; the only matches for
  `fake app|one owner` outside the spine are the unchecked acceptance line and
  review artifacts — no implementation, harness, or fixture.

**Why it matters:** the architecture may still be the right decision, but this
review cannot say it was reality-checked. It converts a measured exit gate into
an assumption, and the rest of the design inherits unmeasured harness, CI, and
N-unit rollback costs. The `ags-platform`/`contracts` tags that would freeze the
surface do not yet contain the manifest helper/schema (F7), so the “surface
frozen” premise is also not closed.

**Recommendation:** either (a) record the cost measurement/pilot that justifies
overriding the 2026-10-16 gate, or (b) keep this spine as a target architecture
and mark the per-app split contingent on the pilot exit criteria, with the
seven-repo decision explicitly conditional. In either case, add the fake-app
cutover test before approval.

**Evidence:** `dotfiles-v3/docs/GUIDE-ags-app-repos-refinement.md:90-95`;
`architecture-standalone-app-contract.md:59-62`;
`tickets/REQ-008-standalone-app-contract/ticket.md:53-55`;
`https://api.github.com/repos/RandomGenericUsername/ags-clipboard` → 404 for
all seven proposed app repos.
**Verify:** `sed -n '90,95p' dotfiles-v3/docs/GUIDE-ags-app-repos-refinement.md;
rg -n 'fake app|one owner' ags-apps/.worktrees/REQ-008/tickets;
curl -s -o /dev/null -w '%{http_code}' https://api.github.com/repos/RandomGenericUsername/ags-clipboard`

---

### F2 — HIGH: A single shared `apps/node_modules/ags-platform` cannot satisfy “each app repo pins its own” platform version

**Claim:** AD-17 is extended so every per-app unit shares
`<install>/apps/node_modules/ags-platform`
(`architecture-standalone-app-contract.md:52,145-150`), while AD-34 says “Each
app repo pins `ags-platform` and `contracts` by git tag/commit”
(`:181-183`), and the Stack table says “`ags-platform` … existing pinned tag;
each app repo pins its own” (`:219-220`).

**Reality:** the deployed bundle resolves exactly one shared symlink. The
current installer already models this as one platform version for the whole
unit and locks it to the platform role:

- `dotfiles-provision/ansible/roles/ags_apps/vars/main.yml:314-320`:
  `ags_apps_platform_version: v0.2.0` “MUST equal `ags_platform_version` …
  locked by `test_ags_apps_role.py`”.
- `tests/unit/test_ags_apps_role.py:288-291` asserts the equality.
- The platform repo’s own package exports no manifest helper at `v0.2.0`
  (`git show v0.2.0:package.json` exports only `.`, `./ports/*`,
  `./adapters/*`); a new tag is required anyway.

If app A pins platform `v0.2.0` for its CI and app B pins `v0.3.0` (because
`v0.2.0` lacks the manifest helper), the production symlink can only point at
one of them. The app’s CI/conformance test can pass against a different platform
than the deployed app resolves. The same skew applies to `contracts`: the runtime
validates against its own pin, while each app may pin another. This is exactly
the “multi-repo/version-skew tax” the prior guide warned about
(`GUIDE-ags-app-repos-refinement.md:90-92`).

**Recommendation:** make the deployed platform/contracts versions
composition-owned and single-valued (one tag per install generation), and have
every app repo’s CI pin that exact tag for conformance. If per-app platform
versions are truly required, the shared-ancestor topology must change (per-app
`node_modules`), which contradicts AD-17/AD-31. State the chosen rule in AD-34
and add a version-skew gate.

**Evidence:** `architecture-standalone-app-contract.md:52,145-150,181-183,219-220`;
`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml:314-320`;
`dotfiles-provision/tests/unit/test_ags_apps_role.py:288-291`;
`git -C ags-platform show v0.2.0:package.json`;
`contracts/schemas/` contains only `current`, `history`, `last-converged` and `meta` — no manifest schema.
**Verify:** `git -C ags-platform show v0.2.0:package.json | sed -n '1,25p';
grep -n 'ags_apps_platform_version' dotfiles-provision/ansible/roles/ags_apps/vars/main.yml
dotfiles-provision/tests/unit/test_ags_apps_role.py`

---

### F3 — HIGH: The one-owner cutover is not implementable as “one commit set”; the engine and composition are separate pinned repos

**Claim:** “each cutover is one commit set: add the app to the `dotfiles-v3`
list, add it to the old `ags_apps` role’s exclusion list, remove its old link,
and verify the union has exactly one owner per app”
(`architecture-standalone-app-contract.md:158-162`).

**Reality:** the old role is in the engine, not in `dotfiles-v3`, and the engine
is consumed as an immutable tag:

- `dotfiles-v3/dotfiles/provisioning/installer.pin` = `v0.1.16`.
- `dotfiles-v3/docs/WORKSPACE.md:30` says `dotfiles-provision` owns the Ansible
  roles/playbooks; `dotfiles-v3` owns composition manifests.
- `dotfiles-provision/ansible/roles/ags_apps/` has no exclusion list; every app
  link is hardcoded (`tasks/main.yml` link tasks), and the role has one
  monorepo pin (`vars/main.yml:102`). `verify/vars/main.yml` separately mirrors
  the old pin and links.
- The composition manifest reader has a closed kind set
  (`dotfiles-provision/src/provisioning/domain/enums.py:63-75`:
  `packages`, `assets`, `filesystem`, `config-copies`, `cli-tools`) and rejects
  unknown kinds (`_read_kind` in `yaml_manifest_reader.py`). A new
  dotfiles-v3 per-app list is not just a new YAML file; it needs a new
  `ManifestKind`, schema, fixture, reader tests, and a data path into Ansible.
- The current engine design says “Ansible never reads the manifest; the role
  mirrors it and a parity test locks the mirror”
  (`yaml_manifest_reader.py:1-14`). There is no existing mechanism for the
  `ags_apps` role or `verify` to consume a dotfiles-v3 app list directly.
- The gate that asserts the current topology is a hardcoded composition script
  (`dotfiles-v3/scripts/deploy-coverage.py` docstring, sections (c)-(j)),
  not data-driven.

A realistic cutover therefore requires at least: a new app repo/tag; an engine
change to the old role (exclusion or generic list) plus a new engine tag; a
`dotfiles-v3` installer-pin bump and composition list; and possibly the app’s
launch/keybind entries in `dotfiles-assets`/`cli_tools`. If the old-role
exclusion list lives in engine vars, **every one of the six remaining cutovers
also needs a new engine release**. That is the opposite of a one-commit cutover.

**Recommendation:** put the exclusion/ownership data in composition-owned data
that the engine can read through an explicit, tested seam (new manifest kind or
a documented `include_vars` path), so app cutovers do not require engine
releases; or accept a documented multi-repo change set with ordering and
rollback. Add the fake-app test: deploy a fake app through both owners, assert
exactly one link target, remove the old owner, and assert the new owner remains.
Do not mark AD-32 approved until that test exists.

**Evidence:** `architecture-standalone-app-contract.md:158-162`;
`dotfiles-v3/dotfiles/provisioning/installer.pin`;
`dotfiles-v3/docs/WORKSPACE.md:30,43-50`;
`dotfiles-provision/ansible/roles/ags_apps/tasks/main.yml` (no exclusion list);
`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml:102`;
`dotfiles-provision/src/provisioning/domain/enums.py:63-75`;
`dotfiles-provision/src/provisioning/adapters/yaml_manifest_reader.py:1-14`;
`dotfiles-v3/scripts/deploy-coverage.py` (top docstring).
**Verify:** `cat dotfiles-v3/dotfiles/provisioning/installer.pin;
rg -n 'exclusion|excluded|ags_apps_' dotfiles-provision/ansible/roles/ags_apps;
sed -n '63,75p' dotfiles-provision/src/provisioning/domain/enums.py`

---

### F4 — HIGH: Manifest-driven discovery cannot find the bar, and the no-legacy runtime cannot be rolled out during the app-by-app migration

**Claim:** the runtime “discovers running apps and reads each app.manifest.json”
and has no hardcoded app list (`architecture-standalone-app-contract.md:78-87`);
the bar is the only restart app (`:136-138`) and is migrated last
(`:308`). A missing manifest means the runtime does nothing and the app is stale
(`:85-86`).

**Reality:** the current bar is invisible to discovery and is launched without a
manifest-bearing directory:

- `dotfiles-runtime/src/runtime/adapters/ags_reloader.py:110-115`: “The bar runs
  as a bare `ags run` with no config dir; it is restarted separately and never
  appears here.”
- `dotfiles-assets/configs/hypr/autostart.lua:19`: `hl.exec_cmd("ags run")`.
- `dotfiles-provision/ansible/roles/gui_tools/vars/main.yml:203`: bar launch is
  `"ags run"` (no `-d`).
- Discovery is `/proc`-based and requires an `-d`/`--directory` argument
  (`ags_reloader.py:130-139`); `ags run` alone is skipped.

The spine neither changes the bar launch to `ags run -d ~/.config/ags` nor
defines a discovery rule for the default config dir / `ags` instance. If the new
runtime is deployed for the pilot (REQ-009, first app), the bar and every
unmigrated app have no manifest yet. Under AD-26 the runtime does nothing to
them; under the old runtime they were restarted. The bar would go stale on every
palette change from the pilot until the bar cutover (last app), which is
session-critical and contradicts the “bar stays restart but safe” premise. If
the runtime is instead deployed only after the bar cutover, the pilot cannot
exercise the real live-refresh runtime. There is no stated rollout gate.

Additionally, the `/proc` discovery race observed by SPIKE-001 (wrapper exists
before `io.Astal.<instance>` registers) means a request can fail with “instance
is not running” even for a valid app. The new design should discover by
`ags list`/D-Bus names or wait for registration, not reuse the current
`/proc` path blindly.

**Recommendation:** decide and record one of:
1. change the bar launch to `ags run -d ~/.config/ags` in autostart and
   `gui_tools`, so the same manifest discovery finds it; or
2. define a contract-level default-config-dir discovery rule (and a conformance
   test), acknowledging that the bar is a well-known default instance.

Then define the runtime rollout gate: deploy manifests for all apps before the
no-legacy runtime, or keep a narrowly scoped migration mode that is removed at a
named cutover. Add a test for the bar’s manifest discovery and for discovery
during the startup registration window.

**Evidence:** `architecture-standalone-app-contract.md:78-87,136-138,308`;
`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:110-115,130-139`;
`dotfiles-assets/configs/hypr/autostart.lua:19`;
`dotfiles-provision/ansible/roles/gui_tools/vars/main.yml:203`;
`tickets/SPIKE-001-ags-refresh-patterns/ticket.md` (discovery race).
**Verify:** `sed -n '110,139p' dotfiles-runtime/src/runtime/adapters/ags_reloader.py;
sed -n '19p' dotfiles-assets/configs/hypr/autostart.lua;
sed -n '200,225p' dotfiles-provision/ansible/roles/gui_tools/vars/main.yml`

---

### F5 — MEDIUM: `ags request`/GApplication response and restart semantics are underspecified

**Claim:** “The app returns JSON `{"ok":true}` … A malformed/empty response,
non-zero exit, or 5-second timeout is a failure”
(`architecture-standalone-app-contract.md:94-100`). The restart lane promises
“confirmed quit, no concurrent `ags run`, no exit-0 misclassification”
(`:111-114`).

**Reality (request):**

- The D-Bus method is declared `Request(as) → s`
  (`/usr/share/ags/js/lib/app/dbus.ts:29-31`). A handler that calls
  `res({ok:true})` does **not** return JSON; it fails D-Bus marshalling:
  temp app observed `exit=1`, stderr
  `gjs.JSError.Error: Expected type string for argument 'string' but got type Object`.
  `res(JSON.stringify({ok:true}))` returned exit 0 and
  `{"ok":true,...}`. The contract/helper must require a string, or the helper
  must serialize the result object.
- AGS prints the handler’s response with `fmt.Println`
  (`cli/cmd/request.go` at v3.1.0), so the runtime must tolerate the trailing
  newline. It exits 0 for an app with no handler and for an unknown command:
  - `ags request palette-refresh abc -i notifications` → exit 0, stdout
    `instance "notifications" has no request handler implemented`;
  - `ags request bogus -i hypr-pano` → exit 0, stdout `unknown request: bogus`.
  The malformed-response rule is therefore the only thing that catches these;
  it must be treated as mandatory, not a nice-to-have.
- There is no built-in CLI timeout; a handler that never calls `res` blocked
  until the external `timeout 8` killed it (exit 124). The 5 s value is a
  runtime policy; it has no measurement support in the spine.

**Reality (restart):**

- AGS 3.1.0 has one bundle output path per user:
  `$XDG_RUNTIME_DIR/ags.js` (`cli/cmd/run.go:65-72,121-136` at v3.1.0).
  Concurrent `ags run` invocations overwrite each other. The repo’s own
  autostart comments know this and stagger launches
  (`dotfiles-assets/configs/hypr/autostart.lua:21-22,29-31`). SPIKE-001 observed
  two pano wrappers and `io.Astal.capture` owned by a pano wrapper.
- The current reloader does not confirm quit: it calls `ags quit`, then
  immediately `Popen`s `ags run` and polls liveness; any early exit is logged as
  failure (`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:206-238`).
  That is the BUG-003 mechanism the spine defers.
- “No concurrent `ags run`” cannot be guaranteed by serializing the runtime’s
  own restart lane: keybind launchers (`capture-ui`, `hypr-pano-ui`, etc.) and
  autostart also call `ags run` directly
  (`dotfiles-provision/ansible/roles/cli_tools/templates/capture-ui.j2`;
  `hypr-pano-ui.j2`). A bar restart on a wallpaper change can race a user’s
  capture launch and run the wrong bundle.

**Recommendation:** write the protocol precisely:
- `requestHandler` must call `res(JSON.stringify(result))`; `ags-platform`’s
  helper should accept an object and serialize it; add a conformance test that
  passes an object and a string.
- State that exit 0 + `"no request handler"`/`unknown request` is a JSON
  malformed-response failure in the runtime, and test it.
- Define whether the runtime strips a trailing newline; test empty/whitespace.
- Define the 5 s budget with a measured p95 or make it configurable.
- Make BUG-003 a hard gate before the bar cutover; specify confirmed quit
  (poll `io.Astal.<instance>` disappearance / wrapper PID) and a global launch
  serialization strategy, or state that AGS 3.1.0 cannot guarantee it and that
  the bar restart is unsafe until AGS supports per-instance bundles.

**Evidence:** `architecture-standalone-app-contract.md:94-114`;
`/usr/share/ags/js/lib/app/dbus.ts:29-31`;
`/usr/share/ags/js/lib/gtk4/app.ts:271-307`;
AGS `v3.1.0 cli/cmd/request.go`, `cli/cmd/run.go:65-72,121-136`;
`dotfiles-assets/configs/hypr/autostart.lua:21-22,29-31`;
`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:206-238`;
`dotfiles-provision/ansible/roles/cli_tools/templates/capture-ui.j2`,
`hypr-pano-ui.j2`.
**Verify:** `tmp=$(mktemp -d); ...` (the temp-app recipe in §1.1/§1.3) or
`printf 'instance with no handler: '; ags request palette-refresh abc -i notifications; echo exit=$?`;
`printf 'unknown: '; ags request bogus -i hypr-pano; echo exit=$?`;
`timeout 2 ags request never -i <instance-with-no-response>; echo exit=$?`;
`sed -n '65,72p' /tmp/opencode/ags-run.go` (fetched from the v3.1.0 tag).

---

### F6 — MEDIUM: The install topology works, but the platform role and the provisioning gates still point at `config/node_modules`

**Claim:** AD-31 replaces the old shortcut with
`<install>/apps/node_modules/ags-platform`
(`architecture-standalone-app-contract.md:140-151`).

**Reality:** the resolution itself works (verified in §1.3). The migration is
not specified:

- `dotfiles-provision/ansible/roles/ags_platform/vars/main.yml:14-17` still
  claims `<install>/config/node_modules/ags-platform` is “a shared ancestor on
  every app’s resolution path” and “esbuild realpaths … so the shortcut resolves
  from the real config tree.” That is false for the current unit tree, as the
  `ags_apps` role itself explains (`ags_apps/vars/main.yml:326-330`); the
  current unit works only because the app role creates `<unit>/node_modules`.
- The platform role still creates the dead `config/node_modules` shortcut
  (`ags_platform/tasks/main.yml:77-88`). The spine does not say to retire it or
  move it. If both exist, esbuild finds `apps/node_modules` first; no break, but
  there are two “shared” shortcuts and the old one is unowned.
- `dotfiles-v3/scripts/deploy-coverage.py` and the engine `verify` role assert
  the old `<unit>/node_modules` and `<install>/config/node_modules` shapes.
  AD-31 says verify consumes the same data, but the actual verify role is
  hardcoded per app and per pin (`verify/vars/main.yml`, `verify/tasks/main.yml`).

**Recommendation:** in AD-31/AD-32, explicitly retire the platform role’s
`config/node_modules` shortcut (or prove why it must stay), create the apps
shortcut in exactly one role, and update `verify`/`deploy-coverage` together.
Add the negative control from §1.3 to the provisioning test suite; it is the
cheapest guard against a future path regression.

**Evidence:** `architecture-standalone-app-contract.md:140-151`;
`dotfiles-provision/ansible/roles/ags_platform/vars/main.yml:14-17,59-66`;
`dotfiles-provision/ansible/roles/ags_platform/tasks/main.yml:77-88`;
`dotfiles-provision/ansible/roles/ags_apps/vars/main.yml:326-330`;
`dotfiles-v3/scripts/deploy-coverage.py` docstring (c)-(j).
**Verify:** `sed -n '14,17p;59,66p' dotfiles-provision/ansible/roles/ags_platform/vars/main.yml;
sed -n '77,88p' dotfiles-provision/ansible/roles/ags_platform/tasks/main.yml;
sed -n '326,330p' dotfiles-provision/ansible/roles/ags_apps/vars/main.yml`

---

### F7 — MEDIUM: Version/distribution claims are only partly grounded; the required new tags are missing

**Claim:** Stack says “`ags-platform` existing pinned tag; each app repo pins its
own” and “`contracts` existing pinned contract; each app repo pins its own”
(`architecture-standalone-app-contract.md:219-220`); AD-34 assigns manifest
schema/helper to those repos (`:179-183`).

**Reality:**

- `contracts v0.2.0` has `current.schema.json`, `history.schema.json`,
  `last-converged.schema.json`, `meta.schema.json` — no manifest schema.
- `ags-platform v0.2.0` exports `.`, `./ports/*`, `./adapters/*` — no manifest
  helper/types.
- A new `contracts` tag and a new `ags-platform` tag are required before the
  pilot can pin them. The spine does not name those versions or make them
  prerequisites in the workstream order.
- TypeScript is not a repo pin: no root `package.json`/lockfile; the Makefile
  installs `typescript@5.9` with `--no-save --no-package-lock`. Current 5.9.3
  works, but “5.9 repo pin” is inaccurate. TypeScript 7.0.2 is the current
  upstream release (not a recommendation to move; just a note that the repo is
  on a 5.9 line by local install, not by a lock).
- AGS 3.1.0/3.1.2 and Python 3.14.7 are accurate (see §1.1-1.2).

**Recommendation:** add a version plan: the exact new `contracts` and
`ags-platform` tags that carry the manifest schema/helper; a single deployed
platform/contracts tag per install; and a real TypeScript pin (`package.json` +
lockfile, or a documented install script with an exact version) in the app repo
template. Keep the AGS/Python claims as confirmed.

**Evidence:** `architecture-standalone-app-contract.md:179-183,212-221`;
`contracts/schemas/` (four existing schemas, no manifest);
`git -C ags-platform show v0.2.0:package.json`;
`ags-apps/Makefile:146-148,189-191`;
`https://api.github.com/repos/microsoft/TypeScript/releases/latest` → v7.0.2;
`https://api.github.com/repos/Aylur/ags/releases/latest` → v3.1.2.
**Verify:** `ls contracts/schemas; git -C ags-platform show v0.2.0:package.json;
sed -n '146,148p' ags-apps/Makefile; test -f ags-apps/package.json; echo package_json=$?`

---

### F8 — MEDIUM: Cited evidence is stale and one source directly contradicts the spine

**Claim:** the Evidence table cites SPIKE-001 for the “btop gap” and
`dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md` as a source
(`architecture-standalone-app-contract.md:362-369`).

**Reality:**

- SPIKE-001 says btop-theme-studio is **not** in `DEFAULT_SKIP_CONFIG_DIRS` and
  is restarted, losing edits. Current runtime `v0.2.2` includes
  `"ags-btop-studio"` in the skip set (`ags_reloader.py:53-66`; commit
  `87245f2`, ancestor of `v0.2.2`). The “restart loses edits” claim is no longer
  current; the current gap is “skipped and stale, no live refresh” — which is
  what the spine’s `mode: live` for btop must solve. The evidence citation
  should be updated, not repeated as current.
- `dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md:7` lists only three
  skipped apps and `:72-76` says hypr-pano/capture stay restart. The spine says
  capture and clipboard/hypr-pano are live and the only restart app is the bar
  (`architecture-standalone-app-contract.md:136-138,306-314`). The doc is not
  marked superseded.
- The same doc `:13-24` says the three live apps own one dedicated palette
  provider and add-before-remove. Current `ags-platform/adapters/theme.ts:24-31`
  uses `app.apply_css()` without removal, and AGS `apply_css` retains every
  provider (`/usr/share/ags/js/lib/gtk4/app.ts:183-209`). The spine’s Deferred
  item acknowledges the provider bug, but the evidence table still cites the
  doc as if its provider contract were current.
- `tickets/REQ-008-standalone-app-contract/ticket.md:23-31,48-50` still requires
  a transient-obligation flag and “no manifest means legacy restart”; the spine
  says no legacy path and no transient flag (`:80-87`). `EPIC-002` repeats the
  same legacy/transient text (`tickets/EPIC-002-apps-standalone-repos/ticket.md:56-72`).
  These are the acceptance criteria for the very ticket this spine binds.

**Recommendation:** update the evidence table and source docs, or add explicit
“superseded by AD-xx” notes. The architecture must not leave two normative
statements (legacy restart vs no legacy) in the ticket the implementation will
be checked against. Replace the btop evidence with the current skip-set state
and the open pending-edit/live-refresh semantics.

**Evidence:** `architecture-standalone-app-contract.md:362-369`;
`tickets/SPIKE-001-ags-refresh-patterns/ticket.md` (btop section);
`dotfiles-runtime/src/runtime/adapters/ags_reloader.py:53-66`;
`git -C dotfiles-runtime log -1 --format='%h %ad %s' --date=iso 87245f2`;
`git -C dotfiles-runtime merge-base --is-ancestor 87245f2 v0.2.2; echo $?` → 0;
`dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md:7,13-24,72-77`;
`ags-platform/adapters/theme.ts:24-31`;
`/usr/share/ags/js/lib/gtk4/app.ts:183-209`;
`tickets/REQ-008-standalone-app-contract/ticket.md:23-31,48-50`;
`tickets/EPIC-002-apps-standalone-repos/ticket.md:56-72`.
**Verify:** `sed -n '53,66p' dotfiles-runtime/src/runtime/adapters/ags_reloader.py;
sed -n '72,77p' dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md;
sed -n '23,31p' tickets/REQ-008-standalone-app-contract/ticket.md`

---

### F9 — LOW: The app-repo seed omits the TypeScript/typecheck substrate, and the manifest/app instance relationship is untested

**Claim:** the app repo seed is `app.tsx`, `app.manifest.json`, `style.css`,
`AGENTS.md`, `tickets/`, `scripts/worktree-guard.sh`, `Makefile`,
`.github/workflows/`, `tests/` (`architecture-standalone-app-contract.md:248-264`).

**Reality:** a standalone AGS app cannot typecheck with that seed alone. The
current monorepo needs per-app `tsconfig.json`/`tsconfig.<app>.json`, `env.d.ts`,
a generated `@girs` tree, and `node_modules/ags` + `node_modules/gnim` links
(`ags-apps/Makefile` typecheck targets; `bar/tsconfig.bar.json:35-58`). The
per-app repos will need `package.json`/`tsconfig`/type generation or a Makefile
that creates them. The seed is a sketch, but AD-33 says the pilot is the template
and the template must prove the harness; this is part of that cost.

The manifest also declares `instance` and `configDir`, while AGS’s actual
instance is set in `app.tsx` (`app.start({ instanceName })`). AD-34’s
“conformance test for its manifest and handler” should explicitly assert
`app.tsx` instance == manifest `instance` and deployed link name ==
`configDir`; otherwise the runtime can read a valid manifest and send
`-i <instance>` to the wrong bus name. No such test is specified.

**Recommendation:** add `tsconfig`, `package.json`/lock or exact install
script, `env.d.ts`, and `@girs` generation to the template/seed; add the
manifest↔app instance conformance assertion to AD-34.

**Evidence:** `architecture-standalone-app-contract.md:248-264,179-183`;
`ags-apps/Makefile:146-152` and per-app typecheck targets;
`ags-apps/bar/tsconfig.bar.json:35-58`;
`/usr/share/ags/js/lib/gtk4/app.ts:299-315`.
**Verify:** `find ags-apps/bar -maxdepth 2 -name 'tsconfig*' -o -name 'env.d.ts';
grep -n 'node_modules/ags\|typescript@' ags-apps/Makefile | head`

---

### F10 — LOW: The 5 s timeout and palette-hash definitions are asserted, not measured

**Claim:** 5 s per live app; “idempotent by palette hash”
(`architecture-standalone-app-contract.md:94-114,205`).

**Reality:** no timing measurement or definition of which hash is passed exists
in the spine or memlog. The runtime already has a 64-hex palette entry hash
(`dotfiles-runtime/src/runtime/adapters/hashing.py:267-274`), but the spine does
not say it is that value vs `colors.css` content hash. The app only needs a
stable token for idempotence, but the runtime and app must share the definition.
5 s may be fine for CSS-only refreshes and too short for btop/notification
icon reloads; no p95 data.

**Recommendation:** name the exact hash source (likely the CSG palette entry
hash), add it to the structured log schema, and either measure the 5 s budget or
state it is a configurable policy with a documented default. Add a slow-handler
test (response after the timeout) to prove the app stays running and is marked
stale.

**Evidence:** `architecture-standalone-app-contract.md:94-114,205`;
`dotfiles-runtime/src/runtime/adapters/hashing.py:267-274`;
no timing data in `tickets/SPIKE-001-ags-refresh-patterns/ticket.md`.
**Verify:** `rg -n 'palette_hash' dotfiles-runtime/src/runtime/adapters/hashing.py;
rg -n '5 s|5s|timeout' tickets/SPIKE-001-ags-refresh-patterns/ticket.md`

---

### F11 — LOW: “No `ags-apps` pin remains” conflicts with the incremental cutover wording

**Claim:** AD-31 says “No `ags-apps` pin remains”
(`architecture-standalone-app-contract.md:151`), while AD-32 says the old role
shrinks and its pin is deleted only when the last app moves (`:158-162`).

**Reality:** during the migration the old pin must remain for the unmigrated
apps. The final state is pin-free; the intermediate state is not. As written,
AD-31 can be read as an immediate condition and contradicts AD-32 and the
current pin table (`dotfiles-v3/docs/WORKSPACE.md:48-49`).

**Recommendation:** reword AD-31 to “no `ags-apps` pin remains at the end of the
program” and add the intermediate-state rule to AD-32.

**Evidence:** `architecture-standalone-app-contract.md:151,158-162`;
`dotfiles-v3/docs/WORKSPACE.md:48-49`.
**Verify:** `sed -n '145,162p' _bmad-output/.../architecture-standalone-app-contract.md`

---

### F12 — HIGH: AD-35 conflicts with the pilot ticket and the EPIC’s same-name cutover rule

**Claim:** AD-35 renames the clipboard app end to end: repo `ags-clipboard`,
config dir `ags-clipboard`, AGS instance `clipboard`, window
`clipboard-window`, launcher `clipboard-ui`; “the old `hypr-pano` names are
retired” (`architecture-standalone-app-contract.md:185-194`). AD-26 fixes the
manifest field as `mode: live | restart` (`:80-83`). AD-33 names
`ags-clipboard` the pilot (`:169-172`).

**Reality:** the pilot ticket says the opposite and uses a different field:

- `tickets/REQ-009-migrate-hypr-pano-standalone/ticket.md:18-22`: “Keep the
  deployed config directory `ags-hypr-pano` and the AGS instance name
  `hypr-pano` unchanged. The app declares `refresh: live` …”.
- `:36-39`: acceptance requires deployed config dir still `ags-hypr-pano`,
  instance still `hypr-pano`, and “Manifest declares `refresh: live`”.
- `tickets/EPIC-002-apps-standalone-repos/ticket.md:46-48`: “The deployed
  config directory and AGS instance name stay identical during a cutover”.
- The spine’s sources do not list REQ-009, and it never says AD-35 supersedes
  the EPIC same-name rule or the pilot’s `refresh` field.

An app cannot satisfy AD-35 (`configDir: ags-clipboard`, `instance:
clipboard`, `mode: live`) and REQ-009 (`ags-hypr-pano`, `hypr-pano`,
`refresh: live`) at the same time. The old launcher/autostart (`hypr-pano-ui`,
`~/.config/ags-hypr-pano`, `dotfiles-assets/configs/hypr/autostart.lua:51`)
would start a second instance or the wrong config dir. AD-32’s cutover steps do
not include updating `dotfiles-assets`/launchers/autostart, so the rename cannot
be completed by the stated recipe.

**Recommendation:** choose one rule and propagate it before the pilot:
- If AD-35 wins, rewrite REQ-009/EPIC-002 acceptance to the new names and
  `mode`, add `dotfiles-assets` (autostart/keybind/launcher) to the cutover
  steps, and define the old-link removal/rollback.
- If same-name cutover wins, revise AD-35 to keep `ags-hypr-pano` / `hypr-pano`
  for the pilot (and rename later), and use `mode` in the ticket.

Also add REQ-009 to the spine sources (or explicitly mark it superseded) so the
pilot’s binding ticket is not a competing source of truth.

**Evidence:** `architecture-standalone-app-contract.md:80-83,169-172,185-194`;
`tickets/REQ-009-migrate-hypr-pano-standalone/ticket.md:18-22,36-39`;
`tickets/EPIC-002-apps-standalone-repos/ticket.md:46-48`;
`dotfiles-assets/configs/hypr/autostart.lua:51`.
**Verify:** `sed -n '18,22p;36,39p' tickets/REQ-009-migrate-hypr-pano-standalone/ticket.md;
sed -n '46,48p' tickets/EPIC-002-apps-standalone-repos/ticket.md;
sed -n '185,194p' _bmad-output/.../architecture-standalone-app-contract.md`


## 3. Summary

| # | Severity | Finding | Outcome |
| --- | --- | --- | --- |
| F1 | **High** | Prior exit gate reversed without pilot/cost evidence | Asserted; add pilot or make split contingent |
| F2 | **High** | One shared platform symlink vs per-app `ags-platform`/`contracts` pins | Version-skew; choose single deploy pin or per-app isolation |
| F3 | **High** | “One commit set” cutover across pinned engine + composition | Not implementable as stated; needs data seam or multi-repo change set + fake-app test |
| F4 | **High** | Bar is undiscoverable as bare `ags run`; runtime rollout conflicts with app-by-app order | Change launch/discovery and define runtime gate |
| F5 | **Medium** | `ags request` must return a string; exit 0 for no-handler/unknown; no built-in timeout; restart lane cannot globally serialize `ags run`; BUG-003 unresolved | Pin serialization/response semantics; hard-gate BUG-003 |
| F6 | **Medium** | Install topology works, but platform role/gates still use `config/node_modules` | Retire old shortcut; test new path |
| F7 | **Medium** | `contracts`/`ags-platform` existing tags lack manifest schema/helper; TS not actually pinned | Name new tags; add real TS pin |
| F8 | **Medium** | Stale btop evidence; restart doc and REQ/EPIC tickets contradict spine | Update/supersede sources |
| F9 | **Low** | App seed lacks tsconfig/package/env/girs; manifest↔instance conformance unspecified | Extend template; add conformance test |
| F10 | **Low** | 5 s timeout and palette hash undefined/unmeasured | Define hash; measure/config timeout |
| F11 | **Low** | “No ags-apps pin” vs incremental cutover wording | Clarify final vs intermediate |
| F12 | **High** | AD-35 rename/`mode` vs REQ-009 same-name/`refresh` | Rewrite pilot/EPIC or AD-35; include assets in cutover |

**Overall:** the install-resolution architecture is sound and verified. The
contract is not ready to freeze because the versioning, cutover, bar/rollout,
and AGS command/serialization details are either unimplemented or contradictory.
Address F1-F5 and F12 before locking specs/epics; F6-F11 are required cleanups.

---

## 4. What would change the verdict

1. A recorded pilot (or fake-app harness) that proves repo creation, per-app
   pinning, N-unit install/rollback, and one-owner cutover.
2. A single-version platform/contracts deployment rule that is consistent with
   app CI pins, plus the new tags that carry the manifest schema/helper.
3. A composition-owned cutover data seam (or an explicit multi-repo release
   sequence) with a tested fake-app cutover.
4. A bar discovery/launch decision and a runtime rollout gate that prevents
   stale bar/unmigrated apps.
5. A pinned `palette-refresh` response/error contract (`res(JSON.stringify(...))`),
   measured/configurable timeout, and a BUG-003 hard gate for the bar.
