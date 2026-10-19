import { Gtk } from "ags/gtk4"
// The platform's registry-backed IconProvider (spine AD-4/AD-7) replaces the
// app-local lib/icon-registry.ts copy: the same rendered-icon pipeline the bar
// and hypr-pano consume, so a palette change restyles this window too. The
// provider answers with a tagged `IconSource` — a rendered `file` or a symbolic
// `name` (AD-18); only a file is usable here.
import { registryProvider } from "ags-platform/adapters/icon"

// ---------------------------------------------------------------------------
// Icons: resolved through the platform icon provider. Every button keeps its
// text label, so a missing manifest/render degrades to text — never a crash.
// ---------------------------------------------------------------------------

// Frozen `capture-tool` icon variants (design.md §1).
export type IconVariant =
  | "camera"
  | "video"
  | "region"
  | "monitor"
  | "window"
  | "clipboard"
  | "save"
  | "speaker"
  | "mic"
  | "info"

export function captureIcon(variant: IconVariant, size: number): Gtk.Widget | null {
  // The provider returns an `IconSource`; a symbolic `name` (bare desktop, no
  // rendered art) has no path to load here, so it falls back to the text label.
  const source = registryProvider.resolve("capture-tool", variant)
  const path = source !== null && source.kind === "file" ? source.path : null
  if (path === null) return null
  try {
    // Gtk.Image + pixel_size (bar precedent): forces the SVG to render at
    // exactly `size` px. Gtk.Picture + set_size_request is NOT equivalent —
    // the request is only a minimum and the 1024px SVG natural size still
    // drives measurement, inflating every tile to screen scale.
    const image = Gtk.Image.new_from_file(path)
    image.set_pixel_size(size)
    image.set_halign(Gtk.Align.CENTER)
    image.set_valign(Gtk.Align.CENTER)
    return image
  } catch (error) {
    console.error(`capture-tool: cannot load icon ${path}: ${error}`)
    return null
  }
}

/** Prepend the resolved icon to a button-content box (label stays as fallback). */
export function withIcon(variant: IconVariant, size: number) {
  return (self: Gtk.Box) => {
    const icon = captureIcon(variant, size)
    if (icon !== null) self.prepend(icon)
  }
}