#!/usr/bin/env python3
"""No-new-architecture harness for the notifications app (REQ-002).

Re-homed from dotfiles-v3 with the app it polices (the ``notifications`` slice
of the ``ags-apps`` epic). It was authored against
``src/gui-tools/notifications/`` inside dotfiles-v3; the paths are rewritten to
the ``notifications/`` tree in this repo, and the legs whose subject moved to
the platform are retired (see below). Everything else is unchanged: same
checks, same loud-failure wording, same exit codes.

"Reuse the existing architecture" is otherwise unenforceable prose, so each
assertion here maps to a concrete way this app could quietly grow a new
surface:

  1. no ``org.freedesktop.Notifications.Notify`` call and no non-zero
     ``replaces_id`` in the speed-test consumer path -- the wallpaper progress
     model is a BESPOKE in-place card, and a ``Notify`` call is the most likely
     way to drift, because it is exactly how the capture tool does it and it
     looks perfectly reasonable. (The app HOSTS the notification daemon, so it
     legitimately *reads* the daemon -- it must never *send* a toast itself.)
  2. no new AGS instance name beyond the pre-existing set;
  3. no app-local event-bus client in the notifications app -- the ONE event
     client is the platform's (spine AD-5), so ``notifications/lib/`` must own
     no ``Gio.bus_get_sync`` / ``signal_subscribe`` surface at all. This
     supersedes the old "at most the two sibling clients" leg: both siblings
     migrated to the platform and are gone;
  4. no new well-known D-Bus name outside the contract's ``org.dotfiles.Events``
     (plus the bus daemon and the notification daemon the app already claims).

RETIRED LEG. The original ``speedtest-events.ts`` "no polling loop" check has
no subject here: that module was deleted in favour of the platform's
subscribe-before-read event client (AD-5), which owns and gates that shape in
its own repo. Policing ``GLib.timeout_add`` in the app would be wrong -- the
cards legitimately use it for the pulse animation and auto-expiry.

Usage: ``python3 scripts/speedtest-no-new-architecture.py [--root REPO_ROOT]``
Exit 0 = gate green (every check it performed is printed).
Exit 1 = at least one violation; each is printed naming file and line.

Stdlib only.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

#: The pre-existing AGS instance names. A new one means a new process holding a
#: socket slot and a bus name, which is exactly the surface this app must not
#: add. ``icon-color-mapping-editor``, ``wallpaper-selector``, and
#: ``btop-theme-studio`` are one-shot on-demand tools, not autostarted
#: instances, and are listed for completeness.
ALLOWED_INSTANCE_NAMES = frozenset(
    {"ags", "capture", "notifications", "hypr-pano", "wallpaper-selector", "icon-color-mapping-editor", "btop-theme-studio"}
)

#: The directories that hold this repo's AGS apps. The instance-name scan walks
#: these for ``app.tsx`` (the repo root also holds ``node_modules`` / ``.dev`` /
#: ``.worktrees``, which must never be scanned).
APP_DIRS = (
    "bar",
    "hypr-pano",
    "notifications",
    "capture-tool",
    "wallpaper-selector",
    "icme",
    "btop-theme-studio",
)

#: The speed-test consumer path. The PRODUCER moved to the platform
#: (``publishSpeedTestState`` in ``ags-platform/adapters/event-bus``), so only
#: the in-repo consumer is scanned; a missing producer file is not a failure.
SPEEDTEST_CONSUMER = (
    "notifications/ui/NotificationsWindow.tsx",
)

#: The notifications app's module directory. It must own NO event-bus client:
#: the platform's shared client (AD-5) is the one connection.
EVENT_CLIENT_DIR = "notifications/lib"

#: Files that may claim a well-known bus name. The app claims
#: ``org.freedesktop.Notifications`` (it is the daemon) and probes
#: ``org.freedesktop.DBus``; the event client that used to live under lib/ is
#: the platform's now.
BUS_NAME_BEARERS = (
    "notifications/app.tsx",
)

#: Well-known names the notifications path is allowed to touch. Anything else
#: is a new surface (a second notification protocol, a second hub, a private
#: bus). ``Events1`` is not a second name -- it is the contract's versioned
#: INTERFACE served by ``org.dotfiles.Events`` (``event-contract.json``
#: `interface`), so it is a contract value rather than an invented one.
ALLOWED_BUS_NAMES = frozenset(
    {
        "org.dotfiles.Events",
        "org.dotfiles.Events1",
        "org.freedesktop.DBus",
        "org.freedesktop.Notifications",
    }
)

_INSTANCE_RE = re.compile(r'instanceName:\s*"([^"]+)"')
#: A D-Bus well-known name: two or more dotted segments, first segment a domain
#: label. Catches org.dotfiles.Events, org.freedesktop.DBus, com.example.Thing.
_WELL_KNOWN_RE = re.compile(
    r"\b(?:org|com|net|io|dev)\.[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)+\b"
)
_NOTIFY_RE = re.compile(r"org\.freedesktop\.Notifications|\bNotify\b|\breplaces_id\b")
_REPLACES_NONZERO_RE = re.compile(r"replaces_?id\s*[:=]\s*[^0]")
_BUS_GET_RE = re.compile(r"Gio\.bus_get_sync|Gio\.bus_get\(")


def _read(root: Path, rel: str) -> list[str] | None:
    path = root / rel
    if not path.is_file():
        return None
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def _scan_instance_names(root: Path, offenders: list[str]) -> int:
    checked = 0
    for name in APP_DIRS:
        base = root / name
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("app.tsx")):
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
            checked += 1
            for lineno, line in enumerate(lines, start=1):
                for instance in _INSTANCE_RE.findall(line):
                    if instance not in ALLOWED_INSTANCE_NAMES:
                        offenders.append(
                            f"new AGS instance name '{instance}' at "
                            f"{path.relative_to(root)}:{lineno}"
                        )
    return checked


def _scan_notify(root: Path, offenders: list[str]) -> int:
    checked = 0
    for rel in SPEEDTEST_CONSUMER:
        lines = _read(root, rel)
        if lines is None:
            continue
        checked += 1
        for lineno, line in enumerate(lines, start=1):
            code = line.split("//", 1)[0]
            if not code.strip():
                continue
            if _NOTIFY_RE.search(code):
                offenders.append(
                    f"speed-test path calls the freedesktop notification protocol at "
                    f"{rel}:{lineno}: {line.strip()}"
                )
            if _REPLACES_NONZERO_RE.search(code):
                offenders.append(
                    f"speed-test path uses a non-zero replaces_id at {rel}:{lineno}: "
                    f"{line.strip()}"
                )
    return checked


def _scan_event_clients(root: Path, offenders: list[str]) -> int:
    """The notifications app must own NO event-bus client (AD-5)."""
    lib = root / EVENT_CLIENT_DIR
    # A missing directory is not a violation: the app legitimately owns no bus
    # client now, and the pure card helpers that live here need not exist for
    # the scan to hold. There is simply nothing to scan.
    if not lib.is_dir():
        return 0
    found: list[str] = []
    for path in sorted(lib.glob("*.ts")):
        text = path.read_text(encoding="utf-8", errors="replace")
        if _BUS_GET_RE.search(text) or "signal_subscribe" in text:
            found.append(path.name)
    for name in found:
        offenders.append(
            f"app-local event-bus client in the notifications app: "
            f"{EVENT_CLIENT_DIR}/{name} (the platform's shared client is the one "
            f"connection, spine AD-5)"
        )
    return len(list(lib.glob("*.ts")))


def _scan_bus_names(root: Path, offenders: list[str]) -> int:
    checked = 0
    for rel in BUS_NAME_BEARERS:
        lines = _read(root, rel)
        if lines is None:
            continue
        checked += 1
        for lineno, line in enumerate(lines, start=1):
            code = line.split("//", 1)[0]
            for name in _WELL_KNOWN_RE.findall(code):
                if name not in ALLOWED_BUS_NAMES:
                    offenders.append(
                        f"new well-known bus name '{name}' at {rel}:{lineno}"
                    )
    return checked


def main() -> int:
    ap = argparse.ArgumentParser(description="Notifications no-new-architecture gate")
    ap.add_argument("--root", default=None, help="repo root (default: parent of scripts/)")
    args = ap.parse_args()

    root = Path(args.root) if args.root else Path(__file__).resolve().parent.parent

    offenders: list[str] = []
    checks: list[tuple[str, int]] = [
        ("no Notify/replaces_id in the speed-test path", _scan_notify(root, offenders)),
        ("no new AGS instance name", _scan_instance_names(root, offenders)),
        ("no app-local event-bus client in the notifications app", _scan_event_clients(root, offenders)),
        ("no new well-known D-Bus name", _scan_bus_names(root, offenders)),
    ]

    for name, count in checks:
        print(f"CHECK {name} ({count} file(s) scanned)")

    if offenders:
        for offender in offenders:
            print(f"FAIL {offender}")
        print(f"speedtest-no-new-architecture: {len(offenders)} violation(s)")
        return 1

    print("speedtest-no-new-architecture: PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
