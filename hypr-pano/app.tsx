import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import style from "./style.css"
import { theme } from "ags-platform/adapters/theme"
import { PanoWindow } from "./ui/PanoWindow"

/**
 * Register one top-level window with the application.
 *
 * gnim types a JSX element — what `PanoWindow(monitor)` returns — as
 * `JSX.Element`, which it declares as the base `GObject.Object`, while AGS's
 * `app.add_window` is typed to take a `Gtk.Window`. At runtime the object a JSX
 * root call returns IS the `Gtk.Window` the tree was rooted in (the overlay
 * cannot start otherwise), so the cast states a runtime truth the compiler
 * cannot see. Same helper as `bar/app.tsx`.
 */
function addWindow(element: JSX.Element): void {
  app.add_window(element as Gtk.Window)
}

app.start({
  instanceName: "hypr-pano",
  css: style,
  main() {
    // Reuse the shell's generated palette so the overlay matches the bar.
    // Applied through the Theme port (spine AD-13): the adapter owns WHICH
    // artifact is applied — the stable `colors.css` pointer, repointed on
    // every palette change — so this file no longer reads the path itself.
    theme.apply()
    for (const monitor of app.get_monitors()) {
      addWindow(PanoWindow(monitor))
    }
  },
})
