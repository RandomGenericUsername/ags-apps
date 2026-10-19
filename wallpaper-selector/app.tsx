import app from "ags/gtk4/app";
import Gtk from "gi://Gtk?version=4.0";
import style from "./style.css";
// Theming through the platform Theme port (spine AD-13): the adapter owns WHICH
// artifact is applied — the stable `colors.css` pointer, repointed on every
// palette change — so this app no longer carries its own theme.ts copy.
import { theme } from "ags-platform/adapters/theme";
import { WallpaperSelectorWindow } from "./ui/WallpaperSelectorWindow";

/**
 * Register one top-level window with the application.
 *
 * gnim types a JSX element — what `WallpaperSelectorWindow(monitor)` returns —
 * as `JSX.Element`, which it declares as the base `GObject.Object`, while AGS's
 * `app.add_window` is typed to take a `Gtk.Window`. At runtime the object a JSX
 * root call returns IS the `Gtk.Window` the tree was rooted in (the surface
 * cannot start otherwise), so the cast states a runtime truth the compiler
 * cannot see. Same helper as `bar/app.tsx`, `hypr-pano/app.tsx` and
 * `notifications/app.tsx`.
 */
function addWindow(element: JSX.Element): void {
  app.add_window(element as Gtk.Window);
}

app.start({
  css: style,
  instanceName: "wallpaper-selector",
  main() {
    theme.apply();
    // Single centered window on the primary monitor (settings-style tool,
    // not per-monitor chrome — same pattern as the ICME editor window).
    const monitor = app.get_monitors()[0];
    if (monitor) addWindow(WallpaperSelectorWindow(monitor));
  },
});
