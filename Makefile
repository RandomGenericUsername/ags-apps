.PHONY: help typecheck test bar-types ags-platform-dev bar-typecheck ags-test ags-test-deps gates-ci \
	icons-json-drift wifi-mock-parity bluetooth-mock-parity battery-mock-parity audio-mock-parity \
	ags-symbol-check audio-core-test audio-presentation-test pipewire-adapter-test \
	audio-session-runtime-test audio-panel-render-test audio-icons-test audio-seek-stability-test \
	audio-panel-gates

BAR_DIR := bar
AGS_TESTS := $(BAR_DIR)/tests
AGS_TS_TESTS := $(AGS_TESTS)/ts
AGS_TSCONFIG_TESTS := $(AGS_TESTS)/tsconfig.tests.json

# The platform the bar consumes by bare specifier (spine AD-17).
# Default: the pinned published unit, fetched shallow+anonymous into the
# gitignored $(AGS_PLATFORM_FETCH_DIR) on demand. Override
# AGS_PLATFORM_DEV=/path/to/ags-platform to test against a local checkout
# while iterating on the platform itself.
AGS_PLATFORM_VERSION := v0.1.0
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
# Re-homed bar guards (ticket/bar7-rehome-guards).
#
# dotfiles-v3 is retiring the bar-scoped gates that used to run against
# `dotfiles/config/ags/`. The AGS tree now lives here as `bar/`, so the guards
# moved with it -- otherwise the coverage those gates provided (icons.json
# projection drift, mock<->code parity, the audio panel suites, the AGS symbol
# check) is silently lost. Paths were rewritten `dotfiles/config/ags` -> `bar`.
#
# The two guards that are NOT bar-scoped are deliberately NOT ported:
#   * speedtest-mock-parity and speedtest-no-new-architecture police the
#     notifications app (`src/gui-tools/notifications/`), which has not
#     migrated to this repo yet (REQ-002). Only one mapped file is in the bar
#     (WifiContent.tsx); the rest is the notifications app. They move with that
#     app's slice, not here.
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

gates-ci: ags-test $(BAR_GUARDS)
