---
id: SPIKE-001
title: "AGS refresh patterns: why some apps live-refresh while others restart (incl. btop-theme-studio)"
kind: spike
status: reported
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
answered:
  - "All seven apps have a documented input/cache/refresh row; see the matrix."
  - "btop-theme-studio consumes the runtime palette for chrome plus the generated btop theme/palette, but has no live refresh and is absent from the skip list — a running studio is restarted and loses unsaved edits."
  - "The skip set matches the three documented live-refresh apps; btop-theme-studio is the only missing app. The bar is outside discovery and is restarted separately."
  - "Login reconciles are an intentional recovery command, but their AGS reload leg is unconditional and not gated by last-converged.json/watch-health.json."
  - "capture exit 0 is duplicate-instance delegation racing the asynchronous quit; AgsReloader misclassifies a clean exit as failure."
  - "The two hypr-pano processes are two wrappers racing on the shared /run/user/$UID/ags.js bundle; only one owns io.Astal.hypr-pano, and a pano wrapper is actually running the capture bundle."
  - "The proposed contract is: live refresh when only palette-derived CSS/data can be replaced in place; restart only on palette-generation change, serialized and with a confirmed quit; never restart an editor with unsaved state."
open:
  - "btop-theme-studio live-refresh semantics when pending edits exist (refresh chrome only, mark the generated base stale, or block refresh) — needs a product/design call in the implementation ticket."
  - "Whether login reconcile should reload consumers at all, or delegate consumer lifecycle to Hyprland autostart (recommendation: change-gated or --no-reload; final call in the runtime ticket)."
  - "Whether AGS 3.1.0 can be made per-instance-bundle safe without serialization (no --outfile flag exists in 3.1.0); serialization is the safe fix investigated here."
  - "The measured impact of the Theme-port provider accumulation (the doc says one dedicated provider; the code adds a provider per refresh) — leak is proven, cost is not measured."
  - "Whether a missing ~/.config/dotfiles/desired.json parent should make watch-health.json 'degraded' when desired state is optional; currently it does."
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
- All claims below carry their own `Evidence:` / `Verify:` lines. Where a claim could not be measured, it says so.

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

## Scope and method

Read-only investigation. No app, bar, wlogout, greeter, runtime, or docs code was changed; this ticket directory and `tickets/INDEX.md` are the only artifacts. The host was observed live (session started ~08:35 local), and the repos were read at these revisions:

| Repo | Revision | Date |
|---|---|---|
| `ags-apps` | `0503fdb` (worktree `ticket/SPIKE-001-ags-refresh-patterns`) | 2026-10-26 |
| `dotfiles-runtime` | `0bfe1b5` | 2026-10-26 |
| `dotfiles-v3` | `7b806d1` | 2026-10-26 |
| AGS | `/usr/bin/ags` 3.1.0; JS package 3.1.2 | upstream tag `v3.1.0` = `e64452220ce19c8f761eb24a1949d751cc27fdfe` |

Evidence: `git -C dotfiles-runtime rev-parse HEAD`, `git -C dotfiles-v3 rev-parse HEAD`, `ags --version`, `grep '"version"' /usr/share/ags/js/package.json`.
Verify: `git -C /home/inumaki/Development/dotfiles/dotfiles-runtime rev-parse --short HEAD; git -C /home/inumaki/Development/dotfiles/dotfiles-v3 rev-parse --short HEAD; ags --version; grep '"version"' /usr/share/ags/js/package.json`

## Executive answer

The split is real and mostly correct, but it is not fully documented and its restart leg is unsafe:

- **Live refresh** (notifications, wallpaper-selector, icme) is event-driven on `wallpaper.state done/error`; each re-applies the stable `colors.css` pointer and updates its palette-derived icon/UI state in place. They are in `DEFAULT_SKIP_CONFIG_DIRS`.
- **Restart** (bar, hypr-pano, capture-tool) is used where the palette is not the only stale input (bar service/widget tree, pano's palette-token + texture caches, capture's built icons/window set), or where the app has no live path. The bar is restarted outside discovery; pano/capture are discovered from `/proc`.
- **btop-theme-studio** is the gap: it consumes the runtime palette for chrome and the generated btop theme/palette for its authoring model, has **no** live refresh, and is **not** in the skip list. A wallpaper change therefore restarts a running studio and discards unsaved pending edits. It should be skipped and given a live refresh path.
- **Login reconcile** is an intentional one-shot recovery command from Hyprland autostart, but its AGS reload is unconditional: it restarts the bar and every non-skipped running tool on every login, even when the palette/state hashes are unchanged. Neither `last-converged.json` (daemon-only backstop) nor `watch-health.json` (daemon watch-set health) gates it.
- **capture exit 0** is not a crash: AGS launches a second process while the old instance still owns `io.Astal.capture`; the second becomes a remote GApplication instance, forwards the activation, and exits 0. The reloader treats that clean exit as a failure. The same race can leave the intended instance dead.
- **Two hypr-pano processes** are two pano wrappers racing on AGS's single shared bundle path `/run/user/$UID/ags.js`. Only one owns `io.Astal.hypr-pano`; the other wrapper's `gjs` is actually running the capture bundle. `ags list` hides the mismatch because it lists D-Bus instance names, not wrapper command lines.

## App refresh matrix

`doc:` below is shorthand for `dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md`. `DEFAULT_SKIP_CONFIG_DIRS` is compared against the **deployed config-dir name** (`AgsReloader` checks `app.config_dir.name`), not the source directory name. The deployed btop directory is `~/.config/ags-btop-studio` (source dir `btop-theme-studio`).

| App | Inputs consumed | Cached state that outlives a CSS refresh | Actual refresh mechanism | Why this mechanism (evidence) | In skip list? |
|---|---|---|---|---|---|
| **bar** | `colors.css` palette; generated icon renders via `icons.json`; bar backdrop; live `capture.state` (not palette) | Whole widget/window tree; bar services (wifi/bt/audio); CSS providers; icon images loaded at build; popup state | **Process restart**, unconditional on every `AgsReloader.reload()` (bare `ags run`, no `-d`, so it never appears in `/proc` discovery) | Doc: "AGS bar — session-wide widgets and services — keep the existing bar reload behavior" (`doc:73`); reloader docstring: bar restarted unconditionally (`ags_reloader.py:13-15`); AGS has no native hot reload (`run.go:145` TODO) | **No** (separate unconditional restart) |
| **notifications** | `colors.css` palette; generated `wallpaper-progress` icon files; `wallpaper.state` (`applying`/`visible`/`done`/`error`); `speedtest.state`; owns `org.freedesktop.Notifications` | Active notification cards; the wallpaper progress card; expiry/pulse timers; icon images refreshed on `done` | **Live event handler**: `done` re-applies the stable palette pointer (`theme.apply()`) and reloads progress icons; card is never dropped through the set | Doc row (`doc:68`); runtime comment: restart would discard the progress card (`ags_reloader.py:57-60`); commit `f63e460`/`512cd5f9`; subscribe at `NotificationsWindow.tsx:982` | **Yes** (`ags-notifications`) |
| **wallpaper-selector** | `colors.css` palette; generated search icon; wallpaper/effects spine; contrast prefs; `wallpaper.state` | Visible-on-start draft window; thumbnail memory/disk caches; busy/status; search icon widget | **Live event handler**: `done`/`error` re-applies palette, rebuilds the search icon, rescans, invalidates contrast prefs, flushes deferred regenerate; no restart | Runtime comment: restart would pop the visible-on-start dialog back open (`ags_reloader.py:55-59`); README lifecycle (`wallpaper-selector/README.md:75-81`); commit `598ecb2` | **Yes** (`ags-wallpaper-selector`) |
| **icme** | `colors.css` palette; icon mappings/show; generated icons; `wallpaper.state`; publishes `icme.saved` | Unsaved pending edits/staging maps; loaded show; preview CSS providers | **Live event handler**: `done`/`error` re-applies palette and rebuilds the show if the scheme fingerprint moved, preserving pending edits; no restart | Runtime comment: editor may hold unsaved edits (`ags_reloader.py:53-54`); README (`icme/README.md:72-81`); subscribe + fingerprint at `EditorWindow.tsx:172-215` | **Yes** (`ags-icme`) |
| **hypr-pano** | `colors.css` palette at startup; **palette tokens read from `colors.css` and cached**; generated icons rasterized into a texture cache; `clipboard.state`/`clipboard.update` | `tokenCache` (never invalidated); `textureCache`; card/window tree; icon textures | **Process restart** for palette; clipboard events are live but palette/icon state is not | Doc: "caches palette-derived icon data and GTK image snapshots" (`doc:71`); code: `tokenCache` at `ItemCard.tsx:89-115`, `textureCache` at `ItemCard.tsx:20-40`; restart intent `87bdd55` | **No** (`ags-hypr-pano`) |
| **capture-tool** | `colors.css` palette at startup; generated capture icons resolved into `Gtk.Image` at widget build; settings/UI-state files; monitor topology; **no `wallpaper.state`** | Per-monitor window set; built icon widgets; in-flight UI/settings state; capture backend is external | **Process restart** for palette; no live palette path | Doc: "event-sensitive capture UI and generated image assets — keep until proven refreshable" (`doc:72`); icons built via `Gtk.Image.new_from_file` (`ui/shared/icons.ts:27-54`); restart intent `87bdd55` | **No** (`ags-capture`) |
| **btop-theme-studio** | `colors.css` chrome; `current/colors.yaml` palette snapshot; `current/colors.btop.theme` generated btop map; authored theme files; **no contract topic** | **Unsaved pending edits**; theme library/current theme; palette object; generated map; live-preview process; widget tree | **Startup only** (`theme.apply()`, `loadPalette()`, `loadGeneratedMap()`); no `wallpaper.state`; because it is not skipped, the runtime restart is the effective palette refresh — and it loses pending edits | `btop-theme-studio/app.tsx:24-37`; `README.md:17-25` ("consumes no contract topic"); `StudioWindow.tsx:87-112`, pending-edit warning `:453-462`; **not in `doc:64-75`**; runtime set `ags_reloader.py:61-63` | **No** (`ags-btop-studio`) — **gap** |

### Skip-list audit (question 3)

Current set: `{"ags-icme", "ags-wallpaper-selector", "ags-notifications"}` (`ags_reloader.py:61-63`).

Deployed config dirs on this host:

```
ags-notifications        -> .../ags-apps/v0.4.2/notifications
ags-icme                 -> .../ags-apps/v0.4.2/icme
ags-wallpaper-selector   -> .../ags-apps/v0.4.2/wallpaper-selector
ags-hypr-pano            -> .../ags-apps/v0.4.2/hypr-pano
ags-capture              -> .../ags-apps/v0.4.2/capture-tool
ags-btop-studio          -> .../ags-apps/v0.4.2/btop-theme-studio
```

- The three skipped names match their deployed dirs. The doc's three live apps match the set for notifications/selector/icme (`doc:68-70`).
- **Missing from the set:** `ags-btop-studio`. It is a running AGS consumer and will be restarted; it should not be (unsaved edits).
- **Extra restarts:** `ags-hypr-pano` and `ags-capture` are intentionally in the restart set per the doc (`doc:71-72`); the bar is restarted outside discovery (`ags_reloader.py:107-112, 184`).
- **Name trap:** a skip entry must be the deployed dir name. Adding `btop-theme-studio` would not match; `/proc` discovery sees `-d $HOME/.config/ags-btop-studio` (`~/.local/bin/btop-theme-studio` launcher) and checks `config_dir.name == "ags-btop-studio"`.

Evidence: `PYTHONPATH=src python3 -c "from runtime.adapters.ags_reloader import DEFAULT_SKIP_CONFIG_DIRS; print(sorted(DEFAULT_SKIP_CONFIG_DIRS))"` → `['ags-icme', 'ags-notifications', 'ags-wallpaper-selector']`; `readlink -f ~/.config/ags-btop-studio` → `.../ags-apps/v0.4.2/btop-theme-studio`; `grep -n 'DIR=' ~/.local/bin/btop-theme-studio` → `DIR="${HOME}/.config/ags-btop-studio"`.
Verify: `for d in ags-notifications ags-icme ags-wallpaper-selector ags-hypr-pano ags-capture ags-btop-studio; do printf '%-24s ' "$d"; readlink -f "$HOME/.config/$d"; done`

Prototype proof that the reloader restarts btop while skipping icme (fake app lister + mocked subprocesses; no GUI, no processes killed):

```text
ags-btop-studio reload_ok= True quit=[bar quit, ags-btop-studio quit] run=[bar run, ags run -d .../ags-btop-studio]
ags-icme        reload_ok= True quit=[bar quit]                       run=[bar run]
ags-capture     reload_ok= True quit=[bar quit, ags-capture quit]     run=[bar run, ags run -d .../ags-capture]
ags-hypr-pano   reload_ok= True quit=[bar quit, ags-hypr-pano quit]   run=[bar run, ags run -d .../ags-hypr-pano]
```

Evidence: prototype run in `dotfiles-runtime` with `PYTHONPATH=src` and `unittest.mock` (output above), using `AgsReloader(ags_path=Path('/bin/true'), app_lister=...)`.
Verify: rerun the snippet in the `## Verification log`, step 6.

## btop-theme-studio pattern (question 2)

**It consumes both the runtime palette and btop themes, but only at startup.**

1. **Chrome** — `app.tsx` calls `theme.apply()` at startup (`btop-theme-studio/app.tsx:24-37`); `style.css` is token-bound to `@color_*` from `colors.css` (`style.css:3-22`). This is the same Theme port as the other apps.
2. **Authoring model** — `loadPalette()` reads `current/colors.yaml` once and builds the 16-color/ramp palette used by swatches and diagnosis (`StudioWindow.tsx:87-103`); `loadGeneratedMap()` reads `current/colors.btop.theme` once and seeds the generated theme library (`StudioWindow.tsx:104-113`). Both are snapshots taken when the window is constructed.
3. **Authored btop themes** — read/written as files (`lib/targets.ts`), previewed by the real btop binary on a pty; the preview reloads btop with `SIGUSR2` (`README.md:79-95`, `StudioWindow.tsx:194-210`). This is independent of the AGS app's own palette.
4. **No contract topic** — the README explicitly says the app "consumes no contract topic: it reads and writes files locally" (`README.md:23-25`); there is no `domainEvents` import in the app. The acceptance test pins that it does not grow one (`tests/platform-consumption.mjs`).
5. **Unsaved state** — edits accumulate in an in-memory pending map; the diff says "Pending edits — nothing written until you save" (`StudioWindow.tsx:453-462`). A restart destroys that map.
6. **Current effective behavior** — the app is **not** in `DEFAULT_SKIP_CONFIG_DIRS`, so a wallpaper change restarts it. That refreshes chrome/palette/generated map by accident, but discards pending edits. This is exactly the class of loss the ICME skip was created to prevent (`ags_reloader.py:53-54`).
7. **Why the doc misses it** — the design doc was written 2026-09-23 (`512cd5f9`), before btop-theme-studio moved into this unit and adopted the Theme port (2026-10-19, `64411c0`/`94515b4`); the doc was never extended. `git log` for the doc has only the creation and an asset-path edit (`512cd5f9`, `a0e4ada2`).

**Recommended pattern:** add `ags-btop-studio` to the skip list, add a live `wallpaper.state done/error` path that re-applies `theme.apply()` and reloads `palette` + the generated `colors.btop` map (preserving pending edits; if the current theme is the generated one and edits are pending, either refresh only chrome or mark the generated base stale), and add the row to `ags-restart-vs-live-theme-refresh.md`. This is a follow-up ticket, not part of this spike.

Evidence: files/lines above; `rg -n "domainEvents|wallpaper.state" btop-theme-studio --glob '!**/node_modules/**'` → no matches; `rg -n "ags-btop-studio" dotfiles-runtime/src` → no matches; `git -C ags-apps log -1 --format='%h %ad %s' --date=iso 94515b4`.
Verify: `rg -n 'theme.apply|loadPalette|loadGeneratedMap|Pending edits' btop-theme-studio/app.tsx btop-theme-studio/ui/StudioWindow.tsx; rg -n 'ags-btop-studio' dotfiles-runtime/src` → no matches (the unrelated `BtopReloader` in `adapters/btop_reloader.py` signals the btop process, not the studio).

## Root causes

### 1. Login reconciles restart consumers because the CLI reconcile reloads unconditionally (question 4)

**What runs:** Hyprland autostart starts one `dotfiles-runtime reconcile` per session after the hyprpaper socket appears; it is backgrounded, fail-open, and appends to `login-reconcile.log` (`~/.local/share/dotfiles/config/hypr/autostart.lua:10-16`).

**Why it restarts:** the CLI `reconcile` command composes `ReconcileDesktopStateUseCase` with `_build_reloaders()` (`dotfiles-runtime/src/runtime/cli/main.py:1285-1299`). Step 6 of the use case loops over every injected reloader unconditionally (`reconcile.py:333-341`); there is no "did anything change?" check before the reload. The autostart comment calls this "re-fires all reloaders idempotently" (`autostart.lua:12-13`), but the reload leg has process-level side effects even when nothing changed.

**It is not the daemon:** the daemon's reactive path is change-gated by `last-converged.json` (`converge.py:73-83`); its startup log at 08:33:59 says `outcome=unchanged input_hash=9134caa9fb8c ran=False source=startup` (journal). The 08:35:03 reconcile is the CLI command from autostart.

**The four reconciles:** `history.jsonl` for 2026-10-26 (UTC; local = UTC-5):

```text
2026-10-26T13:30:05.183453Z reconcile 22b0a2e03c75 5d5dd1140d6e   # 08:30:05
2026-10-26T13:30:45.685266Z set       5c6a380c77c9 1c5051e1ed35   # 08:30:45
2026-10-26T13:31:38.623589Z reconcile 5c6a380c77c9 1c5051e1ed35   # 08:31:38
2026-10-26T13:33:59.729036Z reconcile 5c6a380c77c9 1c5051e1ed35   # 08:33:59
2026-10-26T13:35:03.418000Z reconcile 5c6a380c77c9 1c5051e1ed35   # 08:35:03
```

Three consecutive reconciles have identical wallpaper/palette hashes and still restart the bar/tools. These are four separate session/logins in a short development window, not a retry loop.

Evidence: the history output above (reproduced by the Python query in the `## Verification log`, step 4); `systemctl --user status dotfiles-runtime-daemon.service` shows the daemon start and `unchanged` line; docstrings `reconcile.py:98-107`.
Verify: rerun the `## Verification log`, step 4 query.

**`last-converged.json` role:** daemon-only input-hash backstop. It stores the hash of the AD-39 watched inputs plus the last-converged timestamp; absent/corrupt means "treat as changed"; it lives under `state_root` so writes cannot re-trigger the watcher (`converge_backstop.py:1-20`, `converge.py:73-83`). The **CLI** `reconcile` never reads or writes it: `_run_reconcile` wires no backstop (`main.py:1285-1299`), and the file's mtime is 2026-10-21 17:55 while the last CLI reconcile was 2026-10-26 08:35.

**`watch-health.json` role:** daemon watch-set health. It persists the latest `WatchStatus` (degraded flag, failed roots, last error) for `inspect daemon`/`doctor`, again under `state_root`; absent/corrupt = unknown, never fatal (`watch_health.py:1-13, 31`). The daemon writes it via `on_status=watch_health.write` (`main.py:2206`). Current contents: `degraded: true`, `failed_roots: ["~/.config/dotfiles/desired.json"]`, `last_error: "parent missing"` — the parent directory does not exist. This is unrelated to the AGS restart policy; it only means the daemon cannot watch the optional desired-state file.

**Verdict:** intentional recovery, unconditional reload. The recovery part (repoint symlinks, re-apply wallpaper) is desirable at login; the reload part should be change-gated (or `--no-reload` for the autostart invocation), because autostart is already starting the consumers.

### 2. `capture` exits 0 because the relaunch becomes a remote GApplication instance (question 5)

`AgsReloader._restart` does:

1. `ags quit -i <instance>` and treats a non-zero exit as "no live instance" (`ags_reloader.py:203-225`). The code itself notes "teardown is asynchronous" (`:224-225`).
2. Immediately `Popen([...ags, run, ...])` (`:227-235`).
3. Polls the wrapper for ≤ 2 s (`8 × 0.25 s`); **any** exit, including 0, is logged as `AGS restart failed for <instance>: process exited with code 0` and returns False (`:236-243, 50-51`).

AGS 3.1.0's app is a `Gtk.Application` with `HANDLES_COMMAND_LINE` (`/usr/share/ags/js/lib/gtk4/app.ts:229`), an application id of `io.Astal.<instance>` (`:313`), and a remote command-line path: if the name is already owned, the second process calls the primary's `request` handler and `cmd.done()`, then returns 0 (`:279-296`). If the app has no request handler, the primary logs `instance "<name>" has no request handler implemented` (`:271-277`).

Capture has **no** `requestHandler` (`capture-tool/app.tsx:44-88`; `rg -n requestHandler capture-tool/app.tsx` → none), so the duplicate launches produce exactly the log line seen in `capture.log`:

```text
instance "capture" has no request handler implemented
```

The reloader then sees the duplicate wrapper exit 0 and reports a restart failure. It is **not a real crash**: capture's code never calls `app.quit()` at startup (`rg -n 'quit' capture-tool/app.tsx` → none), so a clean exit can only come from the GApplication hand-off (or an external quit). The consequence is still real: if the old instance is still alive, the "restart" did not happen; if it exits a moment later, the intended instance can be left dead. In the observed session there is no capture wrapper process, while `io.Astal.capture` is owned by a pano wrapper's `gjs` (see next section).

Counts in the cumulative log: `29` capture exit-0 warnings, `3` bar exit-0 warnings, `30` `ReloadError: reload failed for: AgsReloader` lines.

Evidence: the log/code lines above; `grep -c 'AGS restart failed for capture: process exited with code 0' ~/.local/state/dotfiles/login-reconcile.log` → 29; `grep -c 'AGS restart failed for bar: process exited with code 0' ...` → 3; `grep -c 'ReloadError: reload failed for: AgsReloader' ...` → 30.
Verify: `grep -n 'instance "capture" has no request handler' ~/.local/state/ags/capture.log | tail -3; grep -c 'AGS restart failed for capture: process exited with code 0' ~/.local/state/dotfiles/login-reconcile.log`

### 3. Two `hypr-pano` processes: shared bundle path + autostart/reconcile race (question 6)

**AGS has one bundle output path per user.** `ags run` bundles the app to `filepath.Join(XDG_RUNTIME_DIR, "ags.js")` (`cli/cmd/run.go:65-72` at tag v3.1.0), starts `gjs -m <that path>` (`:121-148`), and has no per-instance output flag (`ags run --help` shows only `-d`, `--define`, `-g`, `--log-file`). Concurrent `ags run` invocations overwrite each other's bundle. The repo's own autostart comments know this and stagger the apps ("two concurrent `ags run` invocations collide on /run/user/$UID/ags.js", `autostart.lua:21-22, 29-31`).

**Timeline (local 2026-10-26; `/proc` start times):**

| Time | Event | Evidence |
|---|---|---|
| 08:35:01 | autostart wrappers for notifications (`20925`) and hypr-pano (`20952`) start | `ps -eo pid,ppid,lstart,args` |
| 08:35:02 | bar (`21451`) starts | same |
| ~08:35:03 | login reconcile starts (history line 13:35:03.418Z); the capture autostart (`sleep 2` after session start) is in the same launch window | `autostart.lua:27`; `history.jsonl` |
| 08:35:03–04 | reconcile discovers pano wrapper `20952` but its `gjs` has not registered `io.Astal.hypr-pano` yet (gjs starts 08:35:04); `ags quit -i hypr-pano` finds no live instance (tolerated); reloader spawns a second pano wrapper `23203` | `ps`; reloader `:222-225` |
| 08:35:04 | `gjs 23133` (child of `20952`) and `gjs 23224` (child of `23203`) both start from the shared `/run/user/1000/ags.js` | `ps`; `busctl` |
| 08:35:05 | `23133` owns `io.Astal.capture`; its capture window messages appear in **hypr-pano.log** at 08:35:05.376 | `busctl`; `grep 'capture:' ~/.local/state/ags/hypr-pano.log` |
| 08:35:06 | the shared bundle's last writer leaves `instanceName: "notifications"` in `/run/user/1000/ags.js` | `grep -o 'instanceName: "[^"]*"' /run/user/1000/ags.js` |
| observed later | `23224` owns `io.Astal.hypr-pano`; `23133` still owns `io.Astal.capture`; **no capture wrapper process exists** | `ps`, `busctl`, `ags list` |

Observed process/bus mapping (snapshot at ~10:30 local):

```text
ags run -d .../ags-notifications  (pid 20925, ppid Hyprland)
  gjs 23321 -> io.Astal.notifications
ags run -d .../ags-hypr-pano      (pid 20952, ppid Hyprland)
  gjs 23133 -> io.Astal.capture        <-- pano wrapper running the capture bundle
/usr/bin/ags run                  (pid 21451, bar)
  gjs 21470 -> io.Astal.ags
ags run -d .../ags-hypr-pano      (pid 23203, ppid systemd, detached by reconcile)
  gjs 23224 -> io.Astal.hypr-pano
```

`ags list` prints `ags`, `capture`, `hypr-pano`, `notifications` because it lists `io.Astal.*` bus names (`cli/lib/astal.go:41-66`); it cannot show that `capture` is owned by a pano wrapper. The two pano wrappers are three seconds apart because the first was cold-bundling while the reconcile raced it, not because two pano instances were intentionally started.

**Verdict:** duplicate-pano is a launcher/bundle race, not the restart policy alone. The restart policy makes it reachable at every login because the autostart and reconcile run concurrently. The queue is: quit before registration → no-op → spawn a second wrapper → both bundle to one path → `gjs` children load whichever app was written last.

Evidence: files/lines above; the `ps`/`busctl` snapshot; `grep -o 'instanceName: "[^"]*"' /run/user/1000/ags.js` → `instanceName: "notifications"`; `stat -c '%y' /run/user/1000/ags.js` → 08:35:06.
Verify: `ps -eo pid,ppid,lstart,args | grep '[a]gs run'; for p in $(pgrep -x gjs); do ...; done` (the `## Verification log`, step 5); `ags list; busctl --user list | grep io.Astal`.

## Extra finding: the Theme port violates the documented palette-provider contract

The design doc says `app.apply_css()` is not the refresh API because each call adds a provider and retains it, and that the three live apps own one dedicated provider that is added before the previous is removed (`doc:9-24`). The current ags-platform Theme adapter does exactly what the doc warns against:

- `ags-platform/adapters/theme.ts:24-31` installs `app.apply_css(path)` as the CSS sink;
- AGS `apply_css` creates a new provider, adds it, and pushes it into `#cssProviders`; only `reset_css()` removes them (`/usr/share/ags/js/lib/gtk4/app.ts:170-210`);
- notifications/selector/icme call `theme.apply()` on every `done`/`error` (`NotificationsWindow.tsx:357`, `WallpaperSelectorWindow.tsx:786`, `EditorWindow.tsx:183`), so each wallpaper change adds a provider and leaves the old palette provider installed.

This is a regression from the original implementation: `512cd5f9` added `lib/theme.ts` with `let paletteProvider` + add-new/remove-old in notifications, wallpaper-selector, and icme; the platform migration commits (`4296c3d`, `863661a`, `65b7b43`) deleted those copies and replaced them with `theme.apply()`. The doc was not updated.

Visual refresh still appears to work (the newest provider wins), but the provider list grows and the documented contract is false. The cost was not measured; it is listed as an open question and a proposed follow-up.

Evidence: `rg -n 'paletteProvider|remove_provider_for_display' notifications wallpaper-selector icme bar .dev/ags-platform/v0.2.0` → no matches; `git -C dotfiles-v3 show 512cd5f9:src/gui-tools/notifications/lib/theme.ts` shows the old dedicated provider; `git -C ags-apps show 4296c3d` shows the deletion.
Verify: `sed -n '9,24p' dotfiles-v3/docs/ags-restart-vs-live-theme-refresh.md; sed -n '20,35p' ags-apps/.dev/ags-platform/v0.2.0/adapters/theme.ts; sed -n '183,210p' /usr/share/ags/js/lib/gtk4/app.ts`

## Recommendation (question 7)

### Keep / restrict / remove

| App | Current | Recommendation | Reason |
|---|---|---|---|
| **bar** | Unconditional restart every reconcile | **Keep, restrict** | Session-wide widgets/services cannot be safely rebuilt in place today. Restart only when the palette generation actually changed (`set`, regenerate, or a reconcile that repointed/changed the palette), not on an unchanged login reconcile. A live `wallpaper.state` path is a larger future change. |
| **notifications** | Skip + live | **Keep skip** | Progress card must survive the set; live path already works. |
| **wallpaper-selector** | Skip + live | **Keep skip** | Visible-on-start; restart would pop it open. Live path already works. |
| **icme** | Skip + live | **Keep skip** | Protects unsaved edits; live path already works. |
| **hypr-pano** | Restart | **Keep for now, restrict** | Token/texture caches have no invalidation path; restart is the safe refresh. Restrict to palette changes and fix the launcher race. Follow-up: invalidate caches/rebuild cards on `wallpaper.state done` and then move to skip. |
| **capture-tool** | Restart | **Restrict** | Palette is the only runtime input; restart is needed only to rebuild built icons/chrome. Restrict to palette changes; fix the exit-0 detection. A later live path (rebuild window set/icons) can move it to skip. |
| **btop-theme-studio** | Restart (by omission) | **Remove from restart set → add skip + live refresh** | On-demand authoring tool with unsaved pending edits; same rationale as ICME. Add `ags-btop-studio` (deployed name), not `btop-theme-studio`. |

### Liveness / quit / idempotency fix

1. **Confirm the quit before spawning.** After `ags quit -i <instance>`, wait (bounded) for `io.Astal.<instance>` to disappear (D-Bus name owner / `ags list`) or for the wrapper pid to exit; do not spawn while the old name is still owned. `ags quit` returning 0 only means the method was delivered; teardown is asynchronous (`ags_reloader.py:222-225`).
2. **Serialize AGS launches.** Because AGS 3.1.0 has one bundle path per user (`run.go:65-72`), start one instance at a time and wait until its `io.Astal.<instance>` name is registered before starting the next. This prevents `/run/user/$UID/ags.js` from being overwritten between bundle and `gjs` load. If a future AGS supports a per-instance output path, that is a better long-term fix.
3. **Do not equate a clean exit with failure.** If `ags run` exits 0 because it delegated to a live instance, report that explicitly ("handed off to existing instance") and verify whether the old instance is still the intended one. If the old instance survived, the restart did not happen and must be retried/failed with an actionable message; it should not be silently counted as success.
4. **Gate the reconcile reload.** `ReconcileDesktopStateUseCase` should reload only when the palette/state actually changed (or accept a `--no-reload` mode); the Hyprland autostart invocation should use that mode because autostart owns the consumer starts. Keep the symlink/wallpaper recovery unconditional.
5. **Do not restart editors/unsaved-state apps.** Add `ags-btop-studio` to the skip set now; give it a live refresh so its chrome/generated map do not go stale.

Acceptance check for the fix (proposed): run `dotfiles-runtime reconcile` while autostart is still bundling; `login-reconcile.log` must contain no `process exited with code 0` warnings, `ps` must show exactly one wrapper per intended instance, `busctl` must map each wrapper's child to its own instance name, and `ags list` must match the wrapper set. This is the repro for the follow-up ticket.

## Proposed follow-up tickets (not created)

> Per the plan, a genuine bug found by the spike is proposed here; no implementation ticket was created. The plan only authorizes this spike.

### BUG-003 (primary, `dotfiles-runtime`): AGS restart is not idempotent — quit/relaunch race + shared-bundle collision + exit-0 misclassified

- `kind:` bug, `severity:` high (can leave an instance dead or running another app's bundle; login reconcile exits non-zero).
- `repro:` `~/.local/state/dotfiles/login-reconcile.log` has `AGS restart failed for capture: process exited with code 0`; `ps -eo pid,ppid,lstart,args | grep '[a]gs run'` shows two `--directory .../ags-hypr-pano` wrappers; `busctl --user list | grep io.Astal` maps `io.Astal.capture` to a child of the pano wrapper. A deterministic test can use a fake `ags` + two overlapping `ags run` wrappers, or a deliberate `dotfiles-runtime reconcile` during autostart.
- `observed:` the two pano wrappers, the capture name owned by a pano wrapper's gjs, no capture wrapper, `capture` exit-0 warning, and `ReloadError: reload failed for: AgsReloader`.
- `expected:` one wrapper per intended instance; the reloader waits for quit, serializes launches, and distinguishes "delegated to a live instance" from a failed restart; reconcile exits 0 when the desktop converged, or fails with a real reason.
- Scope: `src/runtime/adapters/ags_reloader.py`, `src/runtime/application/reconcile.py` (reload gate), `src/runtime/cli/main.py` (`--no-reload`/wiring), plus the Hyprland autostart invocation (`dotfiles-assets`/`dotfiles-v3` config, whichever owns the line) and runtime tests. No app changes required for the liveness fix.
- Evidence: the three root-cause sections above; `87bdd55` (standalone-tool restart introduction) and `f63e460` (notification skip) show the policy has grown without a liveness contract.

### BUG-004 (`ags-apps`): btop-theme-studio is restarted by the runtime and loses unsaved edits

- `kind:` bug, `severity:` medium. Proposed repro (not run in this spike; running it would drive the GUI):
- `repro:` open the studio (`SUPER+B`), make a pending edit, run `dotfiles-runtime wallpaper set <other-image>`, then inspect `ps`/the studio; the process is gone and the edit is not in any file.
- `observed:` the studio is discovered as `ags run -d ~/.config/ags-btop-studio`, is not in `DEFAULT_SKIP_CONFIG_DIRS`, and is quit/relaunched; pending edits are in-memory only (`StudioWindow.tsx:453-462`).
- `expected:` a wallpaper change must never discard unsaved edits; add `ags-btop-studio` to the skip list and add a live `wallpaper.state` refresh for chrome + generated map (or document the staleness trade), with tests. Update `docs/ags-restart-vs-live-theme-refresh.md` with the btop row.
- Evidence: the btop pattern section; `btop-theme-studio/app.tsx:24-37`, `README.md:17-25`, `StudioWindow.tsx:87-113, 194-210, 453-462`; `ags_reloader.py:61-63`.
- Note: the doc update is allowed in the later implementation ticket (`02-runtime...md:66-68`), not in this spike.

### BUG-005 (`ags-platform`): Theme adapter adds a CSS provider per refresh instead of replacing one

- `kind:` bug, `severity:` low (provider accumulation; visual behavior currently appears correct).
- `repro:` `rg -n 'paletteProvider|remove_provider_for_display' notifications wallpaper-selector icme .dev/ags-platform/v0.2.0` → no matches; inspect the provider list after repeated `theme.apply()` calls (or instrument `apply_css`).
- `observed:` `theme.apply()` → `app.apply_css()`, which creates a provider, adds it, and retains it (`app.ts:183-210`); the old palette provider is never removed. The design doc says the three apps own one dedicated provider (`doc:9-24`).
- `expected:` one dedicated palette provider per app, added before the previous is removed (or an explicit replace API); the doc and code agree; a test pins the provider count/refresh behavior.
- Evidence: the extra finding above; `512cd5f9` (original implementation), `4296c3d`/`863661a`/`65b7b43` (migration to the platform port), `theme.ts:24-31`.

## Open questions

1. **btop live-refresh semantics with pending edits.** Refresh chrome only, reload the generated base and mark it stale, or block live refresh while pending? Recommendation: preserve pending edits; if the current theme is `generated`, reload its base only when there are no pending edits, otherwise show "palette changed — fork/reload to rebase". Needs a product/design decision.
2. **Should login reconcile reload at all?** Recommendation: no reload for the autostart invocation (`--no-reload` or change-gated); autostart owns consumer starts. This is a policy call for the runtime ticket.
3. **Per-instance bundle output.** AGS 3.1.0 has no `--outfile`; serialization is the safe fix investigated. Confirm whether upgrading AGS or patching upstream is preferable before relying on it long-term.
4. **Provider-leak cost.** The leak is proven; the memory/style-resolution cost after hundreds of wallpaper changes was not measured. Measure in the platform ticket.
5. **`watch-health.json` degraded for an absent optional `desired.json`.** The daemon logs "file root parent missing, not watched" and persists `degraded: true` (`watch_health.py:1-13`; journal 08:33:59). If desired state is optional, "degraded" may be misleading; this is a separate runtime/health question, not a restart cause.

## Verification log

Run from the stated repo roots.

```sh
# 1. Worktree / branch / clean main
cd /home/inumaki/Development/dotfiles/ags-apps
bash scripts/worktree-guard.sh check-clean; echo "exit=$?"        # exit=0
bash scripts/worktree-guard.sh create SPIKE-001 ags-refresh-patterns
# -> worktree=.worktrees/SPIKE-001/ branch=ticket/SPIKE-001-ags-refresh-patterns

# 2. Skip list
cd /home/inumaki/Development/dotfiles/dotfiles-runtime
PYTHONPATH=src python3 -c 'from runtime.adapters.ags_reloader import DEFAULT_SKIP_CONFIG_DIRS as S; print(sorted(S))'
# -> ['ags-icme', 'ags-notifications', 'ags-wallpaper-selector']

# 3. Deployed dirs
for d in ags-notifications ags-icme ags-wallpaper-selector ags-hypr-pano ags-capture ags-btop-studio; do
  printf '%-24s ' "$d"; readlink -f "$HOME/.config/$d"; done

# 4. Login-reconcile history (UTC; local = UTC-5)
python3 - <<'EOF'
import json
from pathlib import Path
for line in (Path.home()/'.local/state/dotfiles/history.jsonl').read_text().splitlines():
    r=json.loads(line)
    if r.get('ts','').startswith('2026-10-26T13:3'):
        print(r['ts'], r['trigger'], r['wallpaper'][:12], r['palette'][:12])
EOF

# 5. Live symptom snapshot
ps -eo pid,ppid,lstart,args | grep '[a]gs run'
ags list
busctl --user list | grep io.Astal
grep -o 'instanceName: "[^"]*"' /run/user/1000/ags.js | sort | uniq -c   # -> 1 instanceName: "notifications"
grep -c 'AGS restart failed for capture: process exited with code 0' ~/.local/state/dotfiles/login-reconcile.log  # -> 29
grep -c 'AGS restart failed for bar: process exited with code 0' ~/.local/state/dotfiles/login-reconcile.log      # -> 3
grep -c 'ReloadError: reload failed for: AgsReloader' ~/.local/state/dotfiles/login-reconcile.log                 # -> 30

# 6. Prototype skip-list behavior (fake lister, mocked subprocesses; no GUI / no kills)
cd /home/inumaki/Development/dotfiles/dotfiles-runtime
PYTHONPATH=src python3 - <<'EOF'
from pathlib import Path
from unittest.mock import patch
from runtime.adapters.ags_reloader import AgsReloader, AgsAppProcess
class Alive:
    returncode = None
    def poll(self): return None
def run_for(dirname):
    app = AgsAppProcess(1, ("ags","run","-d",f"/home/u/.config/{dirname}"), Path(f"/home/u/.config/{dirname}"), dirname)
    r = AgsReloader(ags_path=Path("/bin/true"), app_lister=lambda: [app])
    with patch("runtime.adapters.ags_reloader.subprocess.run") as q, \
         patch("runtime.adapters.ags_reloader.subprocess.Popen", return_value=Alive()) as p, \
         patch("runtime.adapters.ags_reloader.time.sleep"):
        ok = r.reload()
    print(dirname, "reload_ok=", ok, "quit=", q.call_args_list, "run=", [c.args[0] for c in p.call_args_list])
for d in ("ags-btop-studio", "ags-icme", "ags-capture", "ags-hypr-pano"):
    run_for(d)
EOF

# 7. Docs/stock gates in the worktree (docs-only change; no typecheck needed)
cd /home/inumaki/Development/dotfiles/ags-apps/.worktrees/SPIKE-001
make gates-ci    # exit 0 (observed)
```

Observed `make gates-ci` tail: all pure suites + guards green (`GATES_EXIT=0`), including notifications, wallpaper-selector, icme, btop-theme-studio, and the drift gates. No typecheck was run: this spike changes no TypeScript, and `*-typecheck` is a local desktop-stack gate per `AGENTS.md:34-41`.

## Answered / open summary

- **Answered:** all seven questions above — matrix, btop pattern, skip-list audit, login-reconcile cause + file roles, capture exit-0 cause, duplicate-pano timeline/owner, forward contract.
- **Open:** btop live-refresh semantics with pending edits; whether login reconcile should reload at all; per-instance bundle support in AGS; measured provider-leak cost; `watch-health` degraded semantics for an optional desired state.
- **No implementation:** no app, bar, wlogout, greeter, runtime, or docs code changed; no tag, release, or pin bump. Follow-up tickets are proposed only.
