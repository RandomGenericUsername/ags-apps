#!/usr/bin/env python3
"""bar/icons.json == to_nice_json(icons.yaml) + schemaVersion drift gate.

RE-HOMED FROM dotfiles-v3 (ticket/bar7-rehome-guards). The AGS tree moved into
this repo as ``bar/``; this guard moved with it so the projection cannot rot
silently now that the bar is the source of truth. The behaviour is the same as
``dotfiles-v3/scripts/icons-json-drift.py`` -- only the artifact path and the
input locations changed:

  * the generated artifact is now ``bar/icons.json`` (was
    ``dotfiles/config/ags/icons.json``);
  * the authored source (``icons.yaml``) is the pinned ``dotfiles-assets``
    icons class, and the role's schema-version variable is the pinned
    ``dotfiles-provision`` engine role. This gate reads those two files
    READ-ONLY (owner decision 2026-10-16: re-homing the guard is fine; the
    asset and its provisioning owner are unchanged). They are therefore found
    by an upward search for the sibling ``dotfiles-assets`` /
    ``dotfiles-provision`` checkouts, or overridden with ``--yaml`` /
    ``--role-vars``.

``bar/icons.json`` is GENERATED OUTPUT, not a source. It is written by the
``compositor_configs`` role with exactly this expression
(``roles/compositor_configs/tasks/main.yml``):

    {{ (from_yaml) | combine({'schemaVersion': <role var>}) | to_nice_json(indent=2) }}

...appended with a trailing newline. Nothing asserted that relationship, so the
committed projection could rot silently in either direction: a hand edit that
provisioning overwrites at the next bootstrap, or -- what actually happened -- a
change to ``icons.yaml`` that was never regenerated, leaving ``icons.json``
disagreeing with its own source forever.

THE VERSION COMES FROM THE ROLE (spine AD-16/AD-21). The manifest is one
artifact, one owner, one shape, and it carries its own ``schemaVersion``. This
gate reads ``compositor_configs_icon_manifest_schema_version`` from the role's
own vars file rather than hard-coding a copy, so the committed artifact, the
generated artifact, and the comparison cannot disagree; a missing variable fails
the gate rather than defaulting.

WHY IT USES ANSIBLE'S OWN FILTER rather than ``json.dumps``. ``to_nice_json`` is
``json.dumps(a, indent=indent, sort_keys=True, separators=(',', ': '))`` with
ansible's encoder layered on, and the role emits through it. Comparing against
an approximation of the generator is how a file regenerated "the same way" ends
up differing from what provisioning actually writes on the next run. So the
filter is imported and called WHEN ANSIBLE IS IMPORTABLE (run it through the
provisioning project, as dotfiles did):

    uv run --directory ../dotfiles-provision python scripts/icons-json-drift.py

THIS REPO HAS NO PROVISIONING PROJECT, so when ansible is NOT importable the
gate falls back to the documented equivalence
``json.dumps(data, indent=2, sort_keys=True, separators=(',', ': '))`` and prints
a NOTE saying so. That is a deliberate, verified deviation from the dotfiles
original (which FAILS without ansible): the equivalence was checked byte-for-byte
against the committed manifest (2026-10-16, ``--check-equivalence`` proves it),
and the only thing ``to_nice_json`` adds is ansible's encoder for
ansible-specific scalar types, which a ``yaml.safe_load`` of this file never
produces. PyYAML is required either way.

Usage:
    python3 scripts/icons-json-drift.py [--root REPO_ROOT] [--yaml YAML]
                                        [--role-vars VARS] [--json JSON]
                                        [--update] [--check-equivalence]
Exit 0 = bar/icons.json is exactly what the role would write.
Exit 1 = drift (with a diff), or a missing/unreadable input.
"""

from __future__ import annotations

import argparse
import difflib
import json
import sys
from pathlib import Path

JSON_FILE = "bar/icons.json"

# The authored source + the role vars that own the artifact's schema version.
# Since the assets/engine split they live in the sibling `dotfiles-assets`
# (icons class) and `dotfiles-provision` (engine role) checkouts, read-only.
ASSETS_ROOT_DIRNAME = "dotfiles-assets"
ENGINE_ROOT_DIRNAME = "dotfiles-provision"
YAML_RELPATH = "icons/mappings/icons.yaml"
ROLE_VARS_RELPATH = "ansible/roles/compositor_configs/vars/main.yml"
SCHEMA_VERSION_VAR = "compositor_configs_icon_manifest_schema_version"

# The role writes `content: "{{ ... | to_nice_json(indent=2) }}\n"` -- the
# trailing newline is part of the template, not of the filter's output.
TRAILING_NEWLINE = "\n"


def render(json_text: str) -> str:
    return json_text + TRAILING_NEWLINE


def _nice_json(data: object) -> str:
    """The role's ``to_nice_json(indent=2)``.

    Prefers ansible's OWN filter so the comparison is against the generator, not
    an approximation. Falls back to the documented equivalence when this repo
    (which has no provisioning project) cannot import ansible -- printing a NOTE
    so the fallback is never silent.
    """
    try:
        from ansible.plugins.filter.core import to_nice_json  # type: ignore[import-not-found]
    except ImportError:
        print(
            "NOTE: ansible is not importable; using the documented to_nice_json "
            "equivalence (json.dumps indent=2, sort_keys=True, separators=(',', ': ')). "
            "Run through the dotfiles provisioning project for the role's own filter."
        )
        return json.dumps(data, indent=2, sort_keys=True, separators=(",", ": "))
    return to_nice_json(data, indent=2)


def _find_sibling_input(root: Path, dirname: str, relpath: str) -> Path | None:
    """Walk up from ``root`` looking for a sibling checkout's input file.

    ``root`` may be the repo root or a worktree under ``.worktrees/<id>/``, so a
    fixed ``../<repo>`` is wrong for worktrees. The search makes the read-only
    inputs reachable from both.
    """
    d = root
    for _ in range(6):
        candidate = d / dirname / relpath
        if candidate.is_file():
            return candidate
        if d.parent == d:
            break
        d = d.parent
    return None


def main() -> int:
    ap = argparse.ArgumentParser(description="bar/icons.json projection drift gate")
    ap.add_argument("--root", default=None, help="repo root (default: parent of scripts/)")
    ap.add_argument(
        "--yaml",
        default=None,
        help=f"authored icons.yaml (default: sibling {ASSETS_ROOT_DIRNAME}/{YAML_RELPATH})",
    )
    ap.add_argument(
        "--role-vars",
        default=None,
        help=f"compositor_configs vars file (default: sibling {ENGINE_ROOT_DIRNAME}/{ROLE_VARS_RELPATH})",
    )
    ap.add_argument("--json", default=None, help=f"generated manifest (default: {JSON_FILE})")
    ap.add_argument(
        "--update",
        action="store_true",
        help="rewrite the manifest from the YAML and exit (the regeneration, for the "
        "author who just changed the YAML -- the gate itself never writes)",
    )
    ap.add_argument(
        "--check-equivalence",
        action="store_true",
        help="assert the documented json.dumps equivalence agrees with ansible's "
        "to_nice_json on the loaded data (only meaningful when ansible is importable)",
    )
    args = ap.parse_args()

    root = Path(args.root) if args.root else Path(__file__).resolve().parent.parent
    json_path = root / (args.json or JSON_FILE)

    yaml_path = (
        Path(args.yaml)
        if args.yaml
        else _find_sibling_input(root, ASSETS_ROOT_DIRNAME, YAML_RELPATH)
    )
    role_vars_path = (
        Path(args.role_vars)
        if args.role_vars
        else _find_sibling_input(root, ENGINE_ROOT_DIRNAME, ROLE_VARS_RELPATH)
    )

    if yaml_path is None:
        print(
            f"MISSING source manifest: no {YAML_RELPATH} found under a sibling "
            f"{ASSETS_ROOT_DIRNAME}/ checkout. Pass --yaml, or check out "
            f"dotfiles-assets beside this repo."
        )
        return 1
    if not yaml_path.is_file():
        print(f"MISSING source manifest: {yaml_path}")
        return 1
    if not json_path.is_file() and not args.update:
        print(f"MISSING generated manifest: {json_path}")
        return 1
    if role_vars_path is None or not role_vars_path.is_file():
        print(
            f"MISSING provisioning role vars: {role_vars_path or ROLE_VARS_RELPATH}. This "
            f"gate stamps the version the role itself would write (spine AD-21) and must "
            f"not guess it. Pass --role-vars, or check out dotfiles-provision beside this repo."
        )
        return 1

    try:
        import yaml  # PyYAML (dotfiles provisioning dep; present on dev machines)
    except ImportError as exc:
        print(f"FAIL: PyYAML is not importable ({exc}); this gate parses the YAML source.")
        return 1

    try:
        role_vars = yaml.safe_load(role_vars_path.read_text()) or {}
    except yaml.YAMLError as exc:
        print(f"FAIL: cannot parse {role_vars_path}: {exc}")
        return 1
    if SCHEMA_VERSION_VAR not in role_vars:
        print(
            f"FAIL: {role_vars_path} has no {SCHEMA_VERSION_VAR}. This gate stamps the "
            f"version the role itself would write (spine AD-21: one manifest, one "
            f"owner, one shape) and must not guess it. Add the var to the role and "
            f"regenerate with --update."
        )
        return 1

    data = yaml.safe_load(yaml_path.read_text())
    # AD-21: the generated artifact is the group map PLUS the artifact's own
    # schemaVersion. The role stamps the same key with `combine`, so the two
    # must agree; a missing var is a failure above, never a silent default.
    data = {"schemaVersion": role_vars[SCHEMA_VERSION_VAR], **data}

    if args.check_equivalence:
        try:
            from ansible.plugins.filter.core import to_nice_json  # type: ignore[import-not-found]
        except ImportError:
            print("check-equivalence: SKIP (ansible not importable)")
        else:
            faithful = to_nice_json(data, indent=2)
            equivalent = json.dumps(data, indent=2, sort_keys=True, separators=(",", ": "))
            if faithful != equivalent:
                print("FAIL: the json.dumps equivalence does NOT match ansible's to_nice_json")
                return 1
            print("check-equivalence: PASS (json.dumps equivalence == ansible to_nice_json)")

    expected = render(_nice_json(data))

    if args.update:
        json_path.write_text(expected)
        print(f"icons-json-drift: WROTE {json_path} from {yaml_path}")
        return 0

    actual = json_path.read_text()
    if actual == expected:
        print(
            f"icons-json-drift: PASS ({json_path} is exactly "
            f"to_nice_json({yaml_path}, indent=2) + schemaVersion "
            f"{role_vars[SCHEMA_VERSION_VAR]})"
        )
        return 0

    diff = list(
        difflib.unified_diff(
            actual.splitlines(keepends=True),
            expected.splitlines(keepends=True),
            fromfile=f"{json_path} (committed)",
            tofile=f"{json_path} (regenerated from {yaml_path})",
        )
    )
    print(
        f"FAIL: {json_path} has DRIFTED from {yaml_path}.\n"
        f"  It is generated output: `compositor_configs` overwrites it with\n"
        f"  `(from_yaml) | combine({{'schemaVersion': ...}}) | to_nice_json(indent=2)`,\n"
        f"  so a stale projection is silently reverted at the next bootstrap -- and\n"
        f"  nothing else noticed.\n"
        f"  Regenerate with:\n"
        f"    python3 scripts/icons-json-drift.py --update"
    )
    sys.stdout.writelines(diff)
    return 1


if __name__ == "__main__":
    sys.exit(main())
