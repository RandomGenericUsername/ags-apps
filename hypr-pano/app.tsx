import app from "ags/gtk4/app"
import style from "./style.css"
import { theme } from "ags-platform/adapters/theme"
import { PanoWindow } from "./ui/PanoWindow"

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
      app.add_window(PanoWindow(monitor))
    }
  },
})
