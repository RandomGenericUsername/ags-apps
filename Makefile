.PHONY: help typecheck test bar-types ags-platform-dev bar-typecheck ags-test ags-test-deps gates-ci \
	hypr-pano-types hypr-pano-typecheck hypr-pano-drift-test \
	notifications-typecheck notifications-tests notifications-drift-test speedtest-no-new-architecture \
	capture-tool-types capture-tool-typecheck capture-tool-tests capture-tool-tests-deps \
	wallpaper-selector-types wallpaper-selector-typecheck wallpaper-selector-tests \
	wallpaper-selector-drift-test \
	icons-json-drift wifi-mock-parity bluetooth-mock-parity battery-mock-parity audio-mock-parity \
	ags-symbol-check audio-core-test audio-presentation-test pipewire-adapter-test \
	audio-session-runtime-test audio-panel-render-test audio-icons-test audio-seek-stability-test \
	audio-panel-gates

BAR_DIR := bar
PANO_DIR := hypr-pano
NOTIF_DIR := notifications
CAPTURE_DIR := capture-tool
WALLPAPER_DIR := wallpaper-selector
AGS_TESTS := $(BAR_DIR)/tests
AGS_TS_TESTS := $(AGS_TESTS)/ts
AGS_TSCONFIG_TESTS := $(AGS_TESTS)/tsconfig.tests.json

# The platform the bar consumes by bare specifier (spine AD-17).
# Default: the pinned published unit, fetched shallow+anonymous into the
# gitignored $(AGS_PLATFORM_FETCH_DIR) on demand. Override
# AGS_PLATFORM_DEV=/path/to/ags-platform to test against a local checkout
# while iterating on the platform itself.
AGS_PLATFORM_VERSION := v0.2.0
AGS_PLATFORM_REPO := https://github.com/RandomGenericUsername/ags-platform.git
AGS_PLATFORM_DEV ?=
AGS_PLATFORM_FETCH_DIR := $(CURDIR)/.dev/ags-platform/$(AGS_PLATFORM_VERSION)
AGS_PLATFORM_SRC := $(if $(AGS_PLATFORM_DEV),$(AGS_PLATFORM_DEV),$(AGS_PLATFORM_FETCH_DIR))

help:
	@echo "bar-typecheck   tsc --noEmit on bar/ (needs the desktop stack)"
	@echo "ags-test        Pure-module unit tests for bar/ (stock runner)"
	@echo "gates-ci        Stock-runner subset (== CI stock jobs)"
	@echo "typecheck       Alias for bar-typecheck"
	@echo "test            Alias for ags-test"
	@echo ""
	@echo "hypr-pano (REQ-004, slice 3):"
	@echo "hypr-pano-typecheck     tsc --noEmit on hypr-pano/ (needs the desktop stack)"
	@echo "hypr-pano-drift-test    shared event client <-> contracts drift + clipboard helpers"
	@echo ""
	@echo "notifications (REQ-002, slice 4):"
	@echo "notifications-typecheck     tsc --noEmit on notifications/ (needs the desktop stack)"
	@echo "notifications-tests         pure-module unit tests (stock runner)"
	@echo "notifications-drift-test    shared event client <-> contracts drift + card model"
	@echo "speedtest-no-new-architecture   re-homed notifications architecture guard"
	@echo ""
	@echo "capture-tool (REQ-003, slice 5):"
	@echo "capture-tool-typecheck      tsc --noEmit on capture-tool/ (needs the desktop stack)"
	@echo "capture-tool-tests          domain unit tests + platform-consumption acceptance (stock runner)"
	@echo ""
	@echo "wallpaper-selector (REQ-005, slice 6):"
	@echo "wallpaper-selector-typecheck     tsc --noEmit on wallpaper-selector/ (needs the desktop stack)"
	@echo "wallpaper-selector-tests         pure-model unit tests (stock runner)"
	@echo "wallpaper-selector-drift-test    shared event client <-> contracts drift (stock runner)"
	@echo ""
	@echo "re-homed bar guards (ticket/bar7-rehome-guards):"
	@echo "icons-json-drift        bar/icons.json == role projection of icons.yaml"
	@echo "wifi/bluetooth/battery/audio-mock-parity   mock<->code class parity"
	@echo "ags-symbol-check        import/export + undefined-call check over bar/"
	@echo "audio-panel-gates       audio unit suites + parity + symbol + bar-typecheck"
	@echo "audio-*-test            individual audio panel suites"

typecheck: bar-typecheck

test: ags-test

# ---------------------------------------------------------------------------
# bar-types -- generate this machine's GIR declarations in-tree.
#
# `ags types -d bar -u` writes bar/@girs/ (~49 MB, machine-specific) +
# bar/env.d.ts + bar/tsconfig.json (colliding: the committed config is
# tsconfig.bar.json precisely so it survives). Skips when already generated.
# Needs the desktop stack (ags on PATH, Astal/GIR libraries installed).
bar-types:
	@if [ -d "$(BAR_DIR)/@girs" ]; then \
		echo "==> bar-types: @girs/ already generated, skipping (rm -rf $(BAR_DIR)/@girs to force)"; \
	else \
		echo "==> bar-types: generating GIR types (~2-4 min, needs network, requires the desktop stack)"; \
		ags types -d "$(CURDIR)/$(BAR_DIR)" -u || exit 1; \
	fi

# ---------------------------------------------------------------------------
# ags-platform-dev -- the dev-time `node_modules/ags-platform` shortcut.
#
# The bar consumes the platform by the BARE SPECIFIER `ags-platform`
# (spine AD-17). The DEV tree needs the same shortcut so the typecheck gate
# and the pure test suite resolve the specifier in the repo.
#
# IT MUST POINT OUTSIDE node_modules. Node refuses to type-strip `.ts` under a
# real `node_modules` directory (ERR_UNSUPPORTED_NODE_MODULES_TYPE_STRIPPING),
# so Node realpaths a SYMLINK whose target sits outside node_modules and
# type-strips fine -- verified by `make ags-test` running the bar's pure
# suite through this link with `node --test`.
ags-platform-dev:
	@if [ -n "$(AGS_PLATFORM_DEV)" ] && [ ! -f "$(AGS_PLATFORM_DEV)/index.ts" ]; then \
		echo "FAIL: ags-platform-dev: AGS_PLATFORM_DEV=$(AGS_PLATFORM_DEV) has no index.ts" >&2; \
		exit 1; \
	fi
	@if [ -z "$(AGS_PLATFORM_DEV)" ] && [ ! -f "$(AGS_PLATFORM_FETCH_DIR)/index.ts" ]; then \
		echo "==> ags-platform-dev: fetching ags-platform $(AGS_PLATFORM_VERSION) (shallow, anonymous HTTPS)"; \
		rm -rf "$(AGS_PLATFORM_FETCH_DIR)"; \
		mkdir -p "$$(dirname '$(AGS_PLATFORM_FETCH_DIR)')"; \
		git clone --depth 1 --branch $(AGS_PLATFORM_VERSION) $(AGS_PLATFORM_REPO) "$(AGS_PLATFORM_FETCH_DIR)" || exit 1; \
		rm -rf "$(AGS_PLATFORM_FETCH_DIR)/.git"; \
	fi
	@mkdir -p "$(BAR_DIR)/node_modules"
	@ln -sfn "$(AGS_PLATFORM_SRC)" "$(BAR_DIR)/node_modules/ags-platform"
	@mkdir -p node_modules
	@ln -sfn "$(AGS_PLATFORM_SRC)" node_modules/ags-platform
	@echo "==> ags-platform-dev: $(BAR_DIR)/node_modules/ags-platform + node_modules/ags-platform -> $(AGS_PLATFORM_SRC)"

# ---------------------------------------------------------------------------
# bar-typecheck -- ZERO errors allowed in bar/.
#
# WHY THIS GATE EXISTS: `ags bundle` TRANSPILES WITHOUT TYPE CHECKING, so a
# type error is a bar that builds and fails at runtime. Needs the desktop
# stack (`ags` on PATH, Astal/GIR libraries): `make bar-types` generates the
# machine-specific declarations, and the `ags`/`gnim` dev symlinks below give
# per-directory module resolution the same shape `ags types` creates.
#
# Error buckets mirror dotfiles-v3's bar-typecheck: fail on errors in THIS
# repo's tree; tolerate and count the AGS runtime's own (/usr/share/ags/js/)
# errors (machine/GIR-version dependent) and the external platform unit's
# (AD-17: platform errors are the platform repo's gate, not this repo's).
bar-typecheck: ags-platform-dev bar-types
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> bar-typecheck: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@mkdir -p "$(BAR_DIR)/node_modules"
	@[ -e "$(BAR_DIR)/node_modules/ags" ] || ln -sfn /usr/share/ags/js "$(BAR_DIR)/node_modules/ags"
	@[ -e "$(BAR_DIR)/node_modules/gnim" ] || ln -sfn /usr/share/ags/js/node_modules/gnim "$(BAR_DIR)/node_modules/gnim"
	@echo "==> bar-typecheck: tsc --noEmit -p $(BAR_DIR)/tsconfig.bar.json"
	@log=$$(mktemp); \
	npx tsc --noEmit -p "$(BAR_DIR)/tsconfig.bar.json" > "$$log" 2>&1; \
	ours=$$(grep 'error TS' "$$log" | grep -F "$(BAR_DIR)/" | grep -vF 'ags-platform/' || true); \
	thirdparty=$$(grep 'error TS' "$$log" | grep -F '/usr/share/ags/js/' || true); \
	platform=$$(grep 'error TS' "$$log" | grep -F 'ags-platform/' || true); \
	other=$$(grep 'error TS' "$$log" | grep -vF "$(BAR_DIR)/" | grep -vF '/usr/share/ags/js/' | grep -vF 'ags-platform/' || true); \
	echo "    tolerated third-party errors (/usr/share/ags/js): $$(printf '%s\n' "$$thirdparty" | grep -c . || true)"; \
	echo "    tolerated ags-platform errors (external unit, AD-17): $$(printf '%s\n' "$$platform" | grep -c . || true)"; \
	if [ -n "$$other" ]; then \
		echo "FAIL: errors in neither the bar tree nor the known ags runtime:"; \
		printf '%s\n' "$$other"; rm -f "$$log"; exit 1; \
	fi; \
	if [ -n "$$ours" ]; then \
		echo "FAIL: type errors in $(BAR_DIR):"; \
		printf '%s\n' "$$ours"; rm -f "$$log"; exit 1; \
	fi; \
	echo "    OK: 0 errors in $(BAR_DIR)"; \
	rm -f "$$log"

# ---------------------------------------------------------------------------
# ags-test -- unit tests for the bar's PURE modules.
#
# The module list in $(AGS_TSCONFIG_TESTS) is EXPLICIT precisely so this suite
# needs no desktop stack: nothing reachable from it imports `gi://*` or
# `ags/*`, so plain `node --test` runs it on a stock runner. Bar modules that
# need a platform TYPE import it by bare specifier as `import type` (erased at
# runtime); the two suites importing platform VALUES resolve through the dev
# `node_modules/ags-platform` shortcut `make ags-platform-dev` creates.
#
# @types/node MUST LAND UNDER $(AGS_TESTS)/ AND NOWHERE ELSE: it must be a
# sibling of $(AGS_TSCONFIG_TESTS) (tsc's default typeRoots walk starts at the
# config's own directory and walks UP) and must never widen a future app
# config's ambient surface. The separate npm project (--prefix, no
# package.json) means this install cannot prune the root one.
ags-test-deps:
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> ags-test: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@if [ ! -d $(AGS_TESTS)/node_modules/@types/node ]; then \
		echo "==> ags-test: installing @types/node under $(AGS_TESTS)/ (gitignored)"; \
		npm install --no-save --no-package-lock --prefix $(AGS_TESTS) @types/node@24 >/dev/null || exit 1; \
	fi

# NO SILENT SKIPS. If node or npx cannot be resolved, or tsc is absent after
# ags-test-deps, that is a FAILURE and this target exits non-zero.
ags-test: ags-platform-dev ags-test-deps
	@command -v node >/dev/null || { echo "FAIL: ags-test: node is not on PATH" >&2; exit 1; }
	@command -v npx  >/dev/null || { echo "FAIL: ags-test: npx is not on PATH" >&2;  exit 1; }
	@[ -x node_modules/.bin/tsc ] || { echo "FAIL: ags-test: typescript missing after ags-test-deps" >&2; exit 1; }
	@[ -d $(AGS_TESTS)/node_modules/@types/node ] || { echo "FAIL: ags-test: @types/node missing after ags-test-deps" >&2; exit 1; }
	@echo "==> ags-test: node --test $(AGS_TS_TESTS)"
	node --import ./$(AGS_TS_TESTS)/resolve-hooks.mjs --test $(AGS_TS_TESTS)/*.test.ts
	@echo "==> ags-test: tsc --noEmit -p $(AGS_TSCONFIG_TESTS)"
	npx tsc --noEmit -p "$(AGS_TSCONFIG_TESTS)" || exit 1
	@echo "    OK: 0 type errors in the bar pure-module unit tests"

# ---------------------------------------------------------------------------
# hypr-pano (REQ-004, slice 3) -- per-app typecheck + drift gate.
#
# The app-local Makefile was dropped on the move (bar/ ships none): the gates
# live here, mirroring bar. `hypr-pano-typecheck` needs the desktop stack
# (machine-specific @girs/), so it runs on the self-hosted CI job;
# `hypr-pano-drift-test` is pure (node + the shared client) and runs on a stock
# runner.
# ---------------------------------------------------------------------------

# hypr-pano-types -- generate this machine's GIR declarations in-tree, the same
# shape as bar-types. `ags types -d hypr-pano -u` writes hypr-pano/@girs/,
# hypr-pano/env.d.ts and a colliding hypr-pano/tsconfig.json (the committed
# config is tsconfig.pano.json precisely so it survives).
hypr-pano-types:
	@if [ -d "$(PANO_DIR)/@girs" ]; then \
		echo "==> hypr-pano-types: @girs/ already generated, skipping (rm -rf $(PANO_DIR)/@girs to force)"; \
	else \
		echo "==> hypr-pano-types: generating GIR types (~2-4 min, needs network, requires the desktop stack)"; \
		ags types -d "$(CURDIR)/$(PANO_DIR)" -u || exit 1; \
	fi

# hypr-pano-typecheck -- ZERO errors allowed in hypr-pano/. Error buckets mirror
# bar-typecheck: fail on errors in THIS repo's tree; tolerate and count the AGS
# runtime's own (/usr/share/ags/js/) and the external platform unit's (AD-17).
hypr-pano-typecheck: ags-platform-dev hypr-pano-types
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> hypr-pano-typecheck: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@mkdir -p "$(PANO_DIR)/node_modules"
	@[ -e "$(PANO_DIR)/node_modules/ags" ] || ln -sfn /usr/share/ags/js "$(PANO_DIR)/node_modules/ags"
	@[ -e "$(PANO_DIR)/node_modules/gnim" ] || ln -sfn /usr/share/ags/js/node_modules/gnim "$(PANO_DIR)/node_modules/gnim"
	@echo "==> hypr-pano-typecheck: tsc --noEmit -p $(PANO_DIR)/tsconfig.pano.json"
	@log=$$(mktemp); \
	npx tsc --noEmit -p "$(PANO_DIR)/tsconfig.pano.json" > "$$log" 2>&1; \
	ours=$$(grep 'error TS' "$$log" | grep -F "$(PANO_DIR)/" | grep -vF 'ags-platform/' || true); \
	thirdparty=$$(grep 'error TS' "$$log" | grep -F '/usr/share/ags/js/' || true); \
	platform=$$(grep 'error TS' "$$log" | grep -F 'ags-platform/' || true); \
	other=$$(grep 'error TS' "$$log" | grep -vF "$(PANO_DIR)/" | grep -vF '/usr/share/ags/js/' | grep -vF 'ags-platform/' || true); \
	echo "    tolerated third-party errors (/usr/share/ags/js): $$(printf '%s\n' "$$thirdparty" | grep -c . || true)"; \
	echo "    tolerated ags-platform errors (external unit, AD-17): $$(printf '%s\n' "$$platform" | grep -c . || true)"; \
	if [ -n "$$other" ]; then \
		echo "FAIL: errors in neither the hypr-pano tree nor the known ags runtime:"; \
		printf '%s\n' "$$other"; rm -f "$$log"; exit 1; \
	fi; \
	if [ -n "$$ours" ]; then \
		echo "FAIL: type errors in $(PANO_DIR):"; \
		printf '%s\n' "$$ours"; rm -f "$$log"; exit 1; \
	fi; \
	echo "    OK: 0 errors in $(PANO_DIR)"; \
	rm -f "$$log"

# hypr-pano-drift-test -- the repointed drift gate. Pins the SHARED platform
# event client (AD-5) against the canonical contract and exercises its
# hydration state machine + the app's pure clipboard helpers. Pure: no desktop
# stack, so it runs on a stock runner. The contract lives in the sibling
# `contracts` repo (CONTRACTS_ROOT; the test also self-searches) and a missing
# contract FAILS -- never a silent skip.
hypr-pano-drift-test: ags-platform-dev
	@command -v node >/dev/null || { echo "FAIL: hypr-pano-drift-test: node is not on PATH" >&2; exit 1; }
	CONTRACTS_REPO="$(CONTRACTS_ROOT)" node $(PANO_DIR)/tests/event-contract-drift.mjs

# ---------------------------------------------------------------------------
# notifications (REQ-002, slice 4) -- per-app typecheck + tests + drift gates.
#
# Mirrors bar/ and hypr-pano/: the app-local Makefile was dropped on the move.
# `notifications-typecheck` needs the desktop stack (machine-specific @girs/),
# so it runs on the self-hosted CI job; `notifications-tests` and
# `notifications-drift-test` are pure (node + the shared client) and run on a
# stock runner.
# ---------------------------------------------------------------------------

NOTIF_TESTS := $(NOTIF_DIR)/tests
NOTIF_TSCONFIG_TESTS := $(NOTIF_TESTS)/tsconfig.tests.json

# notifications-types -- generate this machine's GIR declarations in-tree, the
# same shape as bar-types / hypr-pano-types. `ags types -d notifications -u`
# writes notifications/@girs/, notifications/env.d.ts and a colliding
# notifications/tsconfig.json (the committed config is
# tsconfig.notifications.json precisely so it survives).
notifications-types:
	@if [ -d "$(NOTIF_DIR)/@girs" ]; then \
		echo "==> notifications-types: @girs/ already generated, skipping (rm -rf $(NOTIF_DIR)/@girs to force)"; \
	else \
		echo "==> notifications-types: generating GIR types (~2-4 min, needs network, requires the desktop stack)"; \
		ags types -d "$(CURDIR)/$(NOTIF_DIR)" -u || exit 1; \
	fi

# notifications-typecheck -- ZERO errors allowed in notifications/. Error
# buckets mirror bar-typecheck: fail on errors in THIS repo's tree; tolerate and
# count the AGS runtime's own (/usr/share/ags/js/) and the external platform
# unit's (AD-17).
notifications-typecheck: ags-platform-dev notifications-types
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> notifications-typecheck: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@mkdir -p "$(NOTIF_DIR)/node_modules"
	@[ -e "$(NOTIF_DIR)/node_modules/ags" ] || ln -sfn /usr/share/ags/js "$(NOTIF_DIR)/node_modules/ags"
	@[ -e "$(NOTIF_DIR)/node_modules/gnim" ] || ln -sfn /usr/share/ags/js/node_modules/gnim "$(NOTIF_DIR)/node_modules/gnim"
	@echo "==> notifications-typecheck: tsc --noEmit -p $(NOTIF_DIR)/tsconfig.notifications.json"
	@log=$$(mktemp); \
	npx tsc --noEmit -p "$(NOTIF_DIR)/tsconfig.notifications.json" > "$$log" 2>&1; \
	ours=$$(grep 'error TS' "$$log" | grep -F "$(NOTIF_DIR)/" | grep -vF 'ags-platform/' || true); \
	thirdparty=$$(grep 'error TS' "$$log" | grep -F '/usr/share/ags/js/' || true); \
	platform=$$(grep 'error TS' "$$log" | grep -F 'ags-platform/' || true); \
	other=$$(grep 'error TS' "$$log" | grep -vF "$(NOTIF_DIR)/" | grep -vF '/usr/share/ags/js/' | grep -vF 'ags-platform/' || true); \
	echo "    tolerated third-party errors (/usr/share/ags/js): $$(printf '%s\n' "$$thirdparty" | grep -c . || true)"; \
	echo "    tolerated ags-platform errors (external unit, AD-17): $$(printf '%s\n' "$$platform" | grep -c . || true)"; \
	if [ -n "$$other" ]; then \
		echo "FAIL: errors in neither the notifications tree nor the known ags runtime:"; \
		printf '%s\n' "$$other"; rm -f "$$log"; exit 1; \
	fi; \
	if [ -n "$$ours" ]; then \
		echo "FAIL: type errors in $(NOTIF_DIR):"; \
		printf '%s\n' "$$ours"; rm -f "$$log"; exit 1; \
	fi; \
	echo "    OK: 0 errors in $(NOTIF_DIR)"; \
	rm -f "$$log"

# notifications-tests-deps -- @types/node under $(NOTIF_TESTS)/, a SIBLING of
# $(NOTIF_TSCONFIG_TESTS) so tsc's typeRoots walk finds it (TS2688 otherwise).
# The separate npm project (--prefix, no package.json) cannot prune the root
# one. Gitignored.
notifications-tests-deps:
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> notifications-tests: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@if [ ! -d $(NOTIF_TESTS)/node_modules/@types/node ]; then \
		echo "==> notifications-tests: installing @types/node under $(NOTIF_TESTS)/ (gitignored)"; \
		npm install --no-save --no-package-lock --prefix $(NOTIF_TESTS) @types/node@24 >/dev/null || exit 1; \
	fi

# notifications-tests -- the cards' PURE model. No desktop stack and no
# platform: card-model.ts imports nothing, so plain `node --test` runs the
# suite on a stock runner (no resolve hook needed).
notifications-tests: notifications-tests-deps
	@command -v node >/dev/null || { echo "FAIL: notifications-tests: node is not on PATH" >&2; exit 1; }
	@[ -x node_modules/.bin/tsc ] || { echo "FAIL: notifications-tests: typescript missing after notifications-tests-deps" >&2; exit 1; }
	@[ -d $(NOTIF_TESTS)/node_modules/@types/node ] || { echo "FAIL: notifications-tests: @types/node missing after notifications-tests-deps" >&2; exit 1; }
	@echo "==> notifications-tests: node --test $(NOTIF_TESTS)/*.test.ts"
	node --test $(NOTIF_TESTS)/*.test.ts
	@echo "==> notifications-tests: tsc --noEmit -p $(NOTIF_TSCONFIG_TESTS)"
	npx tsc --noEmit -p "$(NOTIF_TSCONFIG_TESTS)" || exit 1
	@echo "    OK: 0 type errors in the notifications pure-module unit tests"

# notifications-drift-test -- the repointed drift gate. Pins the SHARED platform
# event client (AD-5) against the canonical contract, exercises its
# subscribe-before-read hydration state machine for wallpaper.state /
# speedtest.state, and asserts the app still hosts
# org.freedesktop.Notifications. Pure: no desktop stack, so it runs on a stock
# runner. The contract lives in the sibling `contracts` repo (CONTRACTS_ROOT;
# the test also self-searches) and a missing contract FAILS -- never a silent
# skip.
notifications-drift-test: ags-platform-dev
	@command -v node >/dev/null || { echo "FAIL: notifications-drift-test: node is not on PATH" >&2; exit 1; }
	CONTRACTS_REPO="$(CONTRACTS_ROOT)" node $(NOTIF_DIR)/tests/event-contract-drift.mjs

# ---------------------------------------------------------------------------
# capture-tool (REQ-003, slice 5) -- per-app typecheck + tests gates.
#
# Mirrors bar/ / hypr-pano/ / notifications/: the app-local Makefile was dropped
# on the move. `capture-tool-typecheck` needs the desktop stack (machine-specific
# @girs/), so it runs on the self-hosted CI job; `capture-tool-tests` is pure
# (node --test over the app's domain modules + source-text acceptance checks) and
# runs on a stock runner.
#
# NO DRIFT GATE. hypr-pano / notifications each carry an
# `event-contract-drift.mjs` because they CONSUME the shared event client (AD-5).
# capture-tool has no event reader -- it neither publishes nor subscribes to a
# contract topic -- so there is no client<->contract surface to pin. The one
# event client (AD-5) is the platform's; capture-tool would import it if it ever
# needed a topic. `capture-tool/tests/ts/platform-consumption.test.ts` pins that
# no bespoke event client grows here.
# ---------------------------------------------------------------------------

CAPTURE_TESTS := $(CAPTURE_DIR)/tests
CAPTURE_TSCONFIG_TESTS := $(CAPTURE_TESTS)/tsconfig.tests.json

# capture-tool-types -- generate this machine's GIR declarations in-tree, the
# same shape as bar-types / hypr-pano-types / notifications-types. `ags types -d
# capture-tool -u` writes capture-tool/@girs/, capture-tool/env.d.ts and a
# colliding capture-tool/tsconfig.json (the committed config is
# tsconfig.capture.json precisely so it survives).
capture-tool-types:
	@if [ -d "$(CAPTURE_DIR)/@girs" ]; then \
		echo "==> capture-tool-types: @girs/ already generated, skipping (rm -rf $(CAPTURE_DIR)/@girs to force)"; \
	else \
		echo "==> capture-tool-types: generating GIR types (~2-4 min, needs network, requires the desktop stack)"; \
		ags types -d "$(CURDIR)/$(CAPTURE_DIR)" -u || exit 1; \
	fi

# capture-tool-typecheck -- ZERO errors allowed in capture-tool/. Error buckets
# mirror bar-typecheck: fail on errors in THIS repo's tree; tolerate and count
# the AGS runtime's own (/usr/share/ags/js/) and the external platform unit's
# (AD-17). capture-tool's committed config resolves `ags`/`gnim` through the
# per-directory node_modules symlinks below (it carries no `paths` map, unlike
# the bar/pano/notifications configs).
capture-tool-typecheck: ags-platform-dev capture-tool-types
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> capture-tool-typecheck: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@mkdir -p "$(CAPTURE_DIR)/node_modules"
	@[ -e "$(CAPTURE_DIR)/node_modules/ags" ] || ln -sfn /usr/share/ags/js "$(CAPTURE_DIR)/node_modules/ags"
	@[ -e "$(CAPTURE_DIR)/node_modules/gnim" ] || ln -sfn /usr/share/ags/js/node_modules/gnim "$(CAPTURE_DIR)/node_modules/gnim"
	@echo "==> capture-tool-typecheck: tsc --noEmit -p $(CAPTURE_DIR)/tsconfig.capture.json"
	@log=$$(mktemp); \
	npx tsc --noEmit -p "$(CAPTURE_DIR)/tsconfig.capture.json" > "$$log" 2>&1; \
	ours=$$(grep 'error TS' "$$log" | grep -F "$(CAPTURE_DIR)/" | grep -vF 'ags-platform/' || true); \
	thirdparty=$$(grep 'error TS' "$$log" | grep -F '/usr/share/ags/js/' || true); \
	platform=$$(grep 'error TS' "$$log" | grep -F 'ags-platform/' || true); \
	other=$$(grep 'error TS' "$$log" | grep -vF "$(CAPTURE_DIR)/" | grep -vF '/usr/share/ags/js/' | grep -vF 'ags-platform/' || true); \
	echo "    tolerated third-party errors (/usr/share/ags/js): $$(printf '%s\n' "$$thirdparty" | grep -c . || true)"; \
	echo "    tolerated ags-platform errors (external unit, AD-17): $$(printf '%s\n' "$$platform" | grep -c . || true)"; \
	if [ -n "$$other" ]; then \
		echo "FAIL: errors in neither the capture-tool tree nor the known ags runtime:"; \
		printf '%s\n' "$$other"; rm -f "$$log"; exit 1; \
	fi; \
	if [ -n "$$ours" ]; then \
		echo "FAIL: type errors in $(CAPTURE_DIR):"; \
		printf '%s\n' "$$ours"; rm -f "$$log"; exit 1; \
	fi; \
	echo "    OK: 0 errors in $(CAPTURE_DIR)"; \
	rm -f "$$log"

# capture-tool-tests-deps -- @types/node under $(CAPTURE_TESTS)/, a SIBLING of
# $(CAPTURE_TSCONFIG_TESTS) so tsc's typeRoots walk finds it (TS2688 otherwise).
# The app config pins `"types": []` (it runs under GJS), so this install must
# also stay OUT of the app config's upward typeRoots walk — a sibling of the
# tests config, below the app config's own directory, is exactly that. The
# separate npm project (--prefix, no package.json) cannot prune the root one.
# Gitignored.
capture-tool-tests-deps:
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> capture-tool-tests: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@if [ ! -d $(CAPTURE_TESTS)/node_modules/@types/node ]; then \
		echo "==> capture-tool-tests: installing @types/node under $(CAPTURE_TESTS)/ (gitignored)"; \
		npm install --no-save --no-package-lock --prefix "$(CURDIR)/$(CAPTURE_TESTS)" @types/node@24 >/dev/null || exit 1; \
	fi

# capture-tool-tests -- the app's PURE domain unit tests (settings, ui-state,
# cli-args, monitor-registry) plus the window-identity / state-ownership /
# custom-duration wiring checks and the REQ-003 platform-consumption acceptance.
# No desktop stack: the domain modules import nothing from `ags/*` or `gi://*`,
# and the wiring checks read the app's own source text. `resolve-hooks.mjs`
# teaches `node --test` the extensionless relative imports `ags bundle` already
# resolves. The app config's `--listFiles` compiler-evidence case needs only the
# tests config's @types/node (the positive control); it tolerates a missing
# @girs/ the same way it does today.
capture-tool-tests: capture-tool-tests-deps
	@command -v node >/dev/null || { echo "FAIL: capture-tool-tests: node is not on PATH" >&2; exit 1; }
	@[ -x node_modules/.bin/tsc ] || { echo "FAIL: capture-tool-tests: typescript missing after capture-tool-tests-deps" >&2; exit 1; }
	@[ -d $(CAPTURE_TESTS)/node_modules/@types/node ] || { echo "FAIL: capture-tool-tests: @types/node missing after capture-tool-tests-deps" >&2; exit 1; }
	@echo "==> capture-tool-tests: node --import $(CAPTURE_TESTS)/ts/resolve-hooks.mjs --test $(CAPTURE_TESTS)/ts/*.test.ts"
	node --import ./$(CAPTURE_TESTS)/ts/resolve-hooks.mjs --test $(CAPTURE_TESTS)/ts/*.test.ts
	@echo "==> capture-tool-tests: tsc --noEmit -p $(CAPTURE_TSCONFIG_TESTS)"
	npx tsc --noEmit -p "$(CAPTURE_TSCONFIG_TESTS)" || exit 1
	@echo "    OK: 0 type errors in the capture-tool pure-module unit tests"

# ---------------------------------------------------------------------------
# wallpaper-selector (REQ-005, slice 6) -- per-app typecheck + tests + drift.
#
# Mirrors bar/ / hypr-pano/ / notifications/ / capture-tool/: the app-local
# Makefile was dropped on the move. `wallpaper-selector-typecheck` needs the
# desktop stack (machine-specific @girs/), so it runs on the self-hosted CI job;
# `wallpaper-selector-tests` and `wallpaper-selector-drift-test` are pure (node +
# the shared client) and run on a stock runner.
# ---------------------------------------------------------------------------

WALLPAPER_TESTS := $(WALLPAPER_DIR)/tests

# wallpaper-selector-types -- generate this machine's GIR declarations in-tree,
# the same shape as bar-types / hypr-pano-types / notifications-types. `ags types
# -d wallpaper-selector -u` writes wallpaper-selector/@girs/,
# wallpaper-selector/env.d.ts and a colliding wallpaper-selector/tsconfig.json
# (the committed config is tsconfig.wallpaper.json precisely so it survives).
wallpaper-selector-types:
	@if [ -d "$(WALLPAPER_DIR)/@girs" ]; then \
		echo "==> wallpaper-selector-types: @girs/ already generated, skipping (rm -rf $(WALLPAPER_DIR)/@girs to force)"; \
	else \
		echo "==> wallpaper-selector-types: generating GIR types (~2-4 min, needs network, requires the desktop stack)"; \
		ags types -d "$(CURDIR)/$(WALLPAPER_DIR)" -u || exit 1; \
	fi

# wallpaper-selector-typecheck -- ZERO errors allowed in wallpaper-selector/.
# Error buckets mirror bar-typecheck: fail on errors in THIS repo's tree;
# tolerate and count the AGS runtime's own (/usr/share/ags/js/) and the external
# platform unit's (AD-17).
wallpaper-selector-typecheck: ags-platform-dev wallpaper-selector-types
	@if [ ! -x node_modules/.bin/tsc ]; then \
		echo "==> wallpaper-selector-typecheck: installing typescript (npm install --no-save, ignored by git)"; \
		npm install --no-save --no-package-lock typescript@5.9 >/dev/null || exit 1; \
	fi
	@mkdir -p "$(WALLPAPER_DIR)/node_modules"
	@[ -e "$(WALLPAPER_DIR)/node_modules/ags" ] || ln -sfn /usr/share/ags/js "$(WALLPAPER_DIR)/node_modules/ags"
	@[ -e "$(WALLPAPER_DIR)/node_modules/gnim" ] || ln -sfn /usr/share/ags/js/node_modules/gnim "$(WALLPAPER_DIR)/node_modules/gnim"
	@echo "==> wallpaper-selector-typecheck: tsc --noEmit -p $(WALLPAPER_DIR)/tsconfig.wallpaper.json"
	@log=$$(mktemp); \
	npx tsc --noEmit -p "$(WALLPAPER_DIR)/tsconfig.wallpaper.json" > "$$log" 2>&1; \
	ours=$$(grep 'error TS' "$$log" | grep -F "$(WALLPAPER_DIR)/" | grep -vF 'ags-platform/' || true); \
	thirdparty=$$(grep 'error TS' "$$log" | grep -F '/usr/share/ags/js/' || true); \
	platform=$$(grep 'error TS' "$$log" | grep -F 'ags-platform/' || true); \
	other=$$(grep 'error TS' "$$log" | grep -vF "$(WALLPAPER_DIR)/" | grep -vF '/usr/share/ags/js/' | grep -vF 'ags-platform/' || true); \
	echo "    tolerated third-party errors (/usr/share/ags/js): $$(printf '%s\n' "$$thirdparty" | grep -c . || true)"; \
	echo "    tolerated ags-platform errors (external unit, AD-17): $$(printf '%s\n' "$$platform" | grep -c . || true)"; \
	if [ -n "$$other" ]; then \
		echo "FAIL: errors in neither the wallpaper-selector tree nor the known ags runtime:"; \
		printf '%s\n' "$$other"; rm -f "$$log"; exit 1; \
	fi; \
	if [ -n "$$ours" ]; then \
		echo "FAIL: type errors in $(WALLPAPER_DIR):"; \
		printf '%s\n' "$$ours"; rm -f "$$log"; exit 1; \
	fi; \
	echo "    OK: 0 errors in $(WALLPAPER_DIR)"; \
	rm -f "$$log"

# wallpaper-selector-tests -- the selector's PURE model (grouping, filtering,
# zero-hash spine mapping, live pinning, contrast helpers). No desktop stack and
# no platform: model.ts imports nothing, so plain `node` runs the suite on a
# stock runner (same shape as the bar's audio `.mjs` validation suites).
wallpaper-selector-tests:
	@command -v node >/dev/null || { echo "FAIL: wallpaper-selector-tests: node is not on PATH" >&2; exit 1; }
	@echo "==> wallpaper-selector-tests: node $(WALLPAPER_TESTS)/model.test.mjs"
	node $(WALLPAPER_TESTS)/model.test.mjs

# wallpaper-selector-drift-test -- the repointed drift gate. Pins the SHARED
# platform event client (AD-5) against the canonical contract, exercises its
# subscribe-before-read hydration state machine for `wallpaper.state` (including
# the optional stage/reload_failures members), and asserts the app consumes the
# ONE platform event client + IconProvider + Theme port (no app-local copies).
# Pure: no desktop stack, so it runs on a stock runner. The contract lives in the
# sibling `contracts` repo (CONTRACTS_ROOT; the test also self-searches) and a
# missing contract FAILS -- never a silent skip.
wallpaper-selector-drift-test: ags-platform-dev
	@command -v node >/dev/null || { echo "FAIL: wallpaper-selector-drift-test: node is not on PATH" >&2; exit 1; }
	CONTRACTS_REPO="$(CONTRACTS_ROOT)" node $(WALLPAPER_DIR)/tests/event-contract-drift.mjs

# ---------------------------------------------------------------------------
# Re-homed notifications guard (REQ-002, slice 4; ticket/notif4-migrate).
#
# `speedtest-no-new-architecture` was authored in dotfiles-v3 against
# `src/gui-tools/notifications/` and retired there with the app. It polices the
# speed-test notification path: no freedesktop Notify/replaces_id, no new AGS
# instance name, no app-local event-bus client (AD-5), no new well-known D-Bus
# name. Re-homed here with the paths rewritten to `notifications/`; the
# `speedtest-events.ts` "no polling" leg retired with that module (the platform's
# shared client owns the subscribe-before-read shape now).
# ---------------------------------------------------------------------------

speedtest-no-new-architecture:
	$(PY) scripts/speedtest-no-new-architecture.py --root "$(CURDIR)"

# ---------------------------------------------------------------------------
# Re-homed bar guards (ticket/bar7-rehome-guards).
#
# dotfiles-v3 is retiring the bar-scoped gates that used to run against
# `dotfiles/config/ags/`. The AGS tree now lives here as `bar/`, so the guards
# moved with it -- otherwise the coverage those gates provided (icons.json
# projection drift, mock<->code parity, the audio panel suites, the AGS symbol
# check) is silently lost. Paths were rewritten `dotfiles/config/ags` -> `bar`.
#
# The notifications-scoped guards were NOT ported here: they police the
# notifications app (`src/gui-tools/notifications/`), which had not migrated to
# this repo when the bar guards moved (REQ-002). They move with that app's
# slice. `speedtest-no-new-architecture` is re-homed in the section below
# (`notifications` slice, ticket/notif4-migrate). `speedtest-mock-parity` is
# still pending: its subject is the mock HTML under dotfiles-v3's
# `openspec/changes/add-speedtest-notifications/`, so it moves when that mock
# does.
# ---------------------------------------------------------------------------

PY := python3

# icons-json-drift: bar/icons.json must equal the role's projection of
# icons.yaml + the role's schemaVersion. The authored YAML and the schema-version
# var stay in dotfiles-v3, which OWNS the provisioning that generates the
# manifest; this target reads them READ-ONLY (owner decision 2026-10-16). The
# upward search finds the sibling checkout from both the repo root and a
# worktree; override DOTFILES_ROOT / ICON_MAPPINGS_YAML / ICON_MAPPINGS_ROLE_VARS
# when it lives elsewhere. Fails loudly (never skips) when an input is missing.
DOTFILES_ROOT ?= $(shell d="$(CURDIR)"; for i in 1 2 3 4 5 6; do d="$$(dirname "$$d")"; if [ -f "$$d/dotfiles-v3/dotfiles/config/icon-template-color-scheme-mappings/icons.yaml" ]; then echo "$$d/dotfiles-v3"; break; fi; done)
ICON_MAPPINGS_YAML ?= $(DOTFILES_ROOT)/dotfiles/config/icon-template-color-scheme-mappings/icons.yaml
ICON_MAPPINGS_ROLE_VARS ?= $(DOTFILES_ROOT)/src/provisioning/ansible/roles/compositor_configs/vars/main.yml

# The canonical event contract lives in the sibling `contracts` repo (AGENTS:
# every app depends on ags-platform and contracts). hypr-pano's drift gate reads
# it READ-ONLY, mirroring icons-json-drift's cross-repo read. Override
# CONTRACTS_ROOT when it lives elsewhere; the gate also self-searches and FAILS
# (never skips) when the contract is missing.
CONTRACTS_ROOT ?= $(shell d="$(CURDIR)"; for i in 1 2 3 4 5 6; do d="$$(dirname "$$d")"; if [ -f "$$d/contracts/event-contract.json" ]; then echo "$$d/contracts"; break; fi; done)

icons-json-drift:
	$(PY) scripts/icons-json-drift.py --root "$(CURDIR)" \
		--yaml "$(ICON_MAPPINGS_YAML)" --role-vars "$(ICON_MAPPINGS_ROLE_VARS)"

# Mock<->code parity: every class token in each anchored mock state must resolve
# to bar/style.css (or bar/audio/audio-panel.css), to the state's mapped TSX, to
# an allowlisted scaffold, or to a tracked known gap. The mock HTML moved into
# bar/tests/mocks/ (it is the acceptance contract for a bar feature, so it now
# lives with the bar rather than with the retired openspec change).
wifi-mock-parity:
	$(PY) scripts/wifi-mock-parity.py --root "$(CURDIR)"

bluetooth-mock-parity:
	$(PY) scripts/bluetooth-mock-parity.py --root "$(CURDIR)"

battery-mock-parity:
	$(PY) scripts/battery-mock-parity.py --root "$(CURDIR)"

audio-mock-parity:
	$(PY) scripts/audio-mock-parity.py --root "$(CURDIR)"

# ags-symbol-check: every named import must exist as an export where it is
# imported from, and every free call must be defined/imported -- the
# `ReferenceError` class that `ags bundle` exit 0 does NOT catch.
ags-symbol-check:
	@command -v node >/dev/null || { echo "FAIL: ags-symbol-check: node is not on PATH" >&2; exit 1; }
	node bar/tests/ags-symbol-check.mjs

# Audio panel suites (re-homed from redesign-ags-audio-panel/validation). Pure
# modules only -- no desktop stack -- so each runs on a stock runner.
AUDIO_VALIDATION := bar/tests/validation

audio-core-test:
	node $(AUDIO_VALIDATION)/audio-core.test.mjs

audio-presentation-test:
	node $(AUDIO_VALIDATION)/audio-presentation.test.mjs

pipewire-adapter-test:
	node $(AUDIO_VALIDATION)/pipewire-adapter.test.mjs

audio-session-runtime-test:
	node $(AUDIO_VALIDATION)/audio-session-runtime.test.mjs

audio-panel-render-test:
	node $(AUDIO_VALIDATION)/audio-panel-render.test.mjs

audio-icons-test:
	node $(AUDIO_VALIDATION)/audio-icons.test.mjs

audio-seek-stability-test:
	node $(AUDIO_VALIDATION)/audio-seek-stability.test.mjs

# The full audio-panel gate: the unit suites, then mock/code parity, then the
# render gate, then the symbol check, then the tree typecheck. Mirrors dotfiles'
# audio-panel-gates, with `ags-typecheck` mapped to this repo's `bar-typecheck`.
# NOT in gates-ci: bar-typecheck needs the desktop stack (machine-specific
# @girs/), so it runs on the self-hosted CI job, never on the stock runner.
audio-panel-gates: audio-core-test audio-presentation-test pipewire-adapter-test \
	audio-session-runtime-test audio-panel-render-test audio-icons-test audio-seek-stability-test \
	audio-mock-parity ags-symbol-check bar-typecheck

# The stock-runner subset: every gate that can run without the desktop stack.
# bar-typecheck needs `ags` + Astal/GIR libraries (machine-specific @girs/),
# so it runs on the self-hosted CI job, never here.
#
# NOTE: icons-json-drift reads the authored icons.yaml + role var from a sibling
# dotfiles-v3 checkout (read-only) and needs PyYAML; see that target. Every other
# guard here is pure node/python-stdlib.
BAR_GUARDS := icons-json-drift wifi-mock-parity bluetooth-mock-parity battery-mock-parity \
	audio-mock-parity ags-symbol-check \
	audio-core-test audio-presentation-test pipewire-adapter-test audio-session-runtime-test \
	audio-panel-render-test audio-icons-test audio-seek-stability-test

# hypr-pano's pure gate (REQ-004): the repointed drift test needs only node + the
# shared client, so it belongs on the stock runner. `hypr-pano-typecheck` needs
# the desktop stack and runs on the self-hosted CI job, never here.
PANO_GUARDS := hypr-pano-drift-test

# The notifications pure gates (REQ-002): the re-homed architecture guard (and,
# once wired, the drift/unit gates) need only node/python-stdlib, so they belong
# on the stock runner. `notifications-typecheck` needs the desktop stack and
# runs on the self-hosted CI job, never here.
NOTIF_GUARDS := speedtest-no-new-architecture notifications-tests notifications-drift-test

# The capture-tool pure gate (REQ-003): the domain unit tests + the
# platform-consumption acceptance need only node + the app's own sources, so it
# belongs on the stock runner. `capture-tool-typecheck` needs the desktop stack
# and runs on the self-hosted CI job, never here. There is no drift gate: the
# app consumes no contract topic (see the capture-tool Makefile section).
CAPTURE_GUARDS := capture-tool-tests

# The wallpaper-selector pure gates (REQ-005): the model unit suite and the
# repointed drift gate need only node + the shared client, so they belong on the
# stock runner. `wallpaper-selector-typecheck` needs the desktop stack and runs
# on the self-hosted CI job, never here.
WALLPAPER_GUARDS := wallpaper-selector-tests wallpaper-selector-drift-test

gates-ci: ags-test $(BAR_GUARDS) $(PANO_GUARDS) $(NOTIF_GUARDS) $(CAPTURE_GUARDS) $(WALLPAPER_GUARDS)
