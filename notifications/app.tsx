import app from "ags/gtk4/app"
import Gtk from "gi://Gtk?version=4.0"
import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import Notifd from "gi://AstalNotifd?version=0.1"
import style from "./style.css"
// Theming through the platform Theme port (spine AD-13): the adapter owns WHICH
// artifact is applied — the stable `colors.css` pointer, repointed on every
// palette change — so this app no longer carries its own theme.ts copy.
import { theme } from "ags-platform/adapters/theme"
import { createPaletteRefreshHandler } from "ags-platform/ports/palette-refresh"
import {
  NotificationsWindow,
  refreshNotificationCardIcons,
} from "./ui/NotificationsWindow"

//: The well-known bus name this app claims (also used by dunst).
const NOTIFICATIONS_NAME = "org.freedesktop.Notifications"

/**
 * Whether some other process already owns org.freedesktop.Notifications.
 *
 * Checked BEFORE touching AstalNotifd: when the name is taken, AstalNotifd
 * emits a GLib *warning* ("cannot get proxy: dunst is already running") and
 * then hands out an object whose signals tear down with NULL-pointer
 * criticals — warnings are not catchable, so a try/catch around get_default()
 * cannot detect this. Asking the bus daemon directly is decisive.
 */
function foreignNotificationDaemon(): boolean {
  try {
    const bus = Gio.bus_get_sync(Gio.BusType.SESSION, null)
    const reply = bus.call_sync(
      "org.freedesktop.DBus",
      "/org/freedesktop/DBus",
      "org.freedesktop.DBus",
      "NameHasOwner",
      new GLib.Variant("(s)", [NOTIFICATIONS_NAME]),
      null,
      Gio.DBusCallFlags.NONE,
      2000,
      null,
    )
    const [hasOwner] = reply.deepUnpack() as [boolean]
    return hasOwner
  } catch (error) {
    // Can't tell — proceed; AstalNotifd will surface its own failure.
    console.error(`notifications: bus probe failed: ${error}`)
    return false
  }
}

/**
 * Register one top-level window with the application.
 *
 * gnim types a JSX element — what `NotificationsWindow(monitor)` returns — as
 * `JSX.Element`, which it declares as the base `GObject.Object`, while AGS's
 * `app.add_window` is typed to take a `Gtk.Window`. At runtime the object a JSX
 * root call returns IS the `Gtk.Window` the tree was rooted in (the surface
 * cannot start otherwise), so the cast states a runtime truth the compiler
 * cannot see. Same helper as `bar/app.tsx` and `hypr-pano/app.tsx`.
 */
function addWindow(element: JSX.Element): void {
  app.add_window(element as Gtk.Window)
}

app.start({
  instanceName: "notifications",
  css: style,
  // The runtime is the only palette-refresh trigger (AD-27). Re-applying the
  // stable `colors.css` pointer and re-reading the registry-backed progress
  // icons preserves the open card stack and the daemon's notification/bus state;
  // `wallpaper.state` is now progress/status only.
  requestHandler: createPaletteRefreshHandler(() => {
    theme.apply()
    refreshNotificationCardIcons()
    return { status: "applied" }
  }),
  main() {
    try {
      theme.apply()
    } catch (error) {
      console.error(`notifications: palette CSS apply failed: ${error}`)
    }

    // A foreign daemon (dunst during the transition, or a duplicate instance)
    // holding the name means we cannot serve notifications. Exit cleanly
    // rather than lingering half-initialised; fallback behaviour is the
    // other daemon's (it keeps working) until the next login.
    if (foreignNotificationDaemon()) {
      console.error(
        `notifications: ${NOTIFICATIONS_NAME} already owned by another daemon (dunst?) — exiting without serving`,
      )
      app.quit()
      return
    }

    // Let the daemon honour declared expire-timeouts. It IGNORES them by
    // default, which is why notifications used to sit on screen forever; the
    // stack keeps its own timer as well so a sender that declares no timeout
    // still clears (see NotificationsWindow.scheduleExpiry).
    try {
      const notifd = Notifd.get_default()
      notifd.set_ignore_timeout(false)
    } catch (error) {
      console.error(`notifications: cannot acquire the notification daemon: ${error}`)
      app.quit()
      return
    }

    // A single top-right stack: every window would render the SAME daemon
    // stream, so (unlike the capture picker) this instance shows on one
    // monitor only instead of one window per monitor.
    const monitors = app.get_monitors()
    const primary = monitors[0]
    if (primary !== undefined) {
      addWindow(NotificationsWindow(primary))
    }
  },
})
