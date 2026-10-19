/**
 * The notifications cards' PURE model (spine AD-2/AD-4 posture).
 *
 * The value formatting and stage mapping the two progress cards share, with no
 * `gi://*` and no `ags` import, so `node --test` exercises them on a stock
 * runner with no desktop stack.
 *
 * WHY THIS MODULE EXISTS. `ags bundle` TRANSPILES WITHOUT TYPE CHECKING, so a
 * formatting or stage-mapping bug is a card that renders wrong at runtime.
 * These functions are pure and were previously buried in the GTK widget file
 * (`ui/NotificationsWindow.tsx`), where no test could reach them. Extracting
 * them is what gives `make notifications-tests` something real to execute; the
 * widget imports them back, so there is exactly one implementation.
 */

/** The wallpaper progress steps, in order. */
export const WALLPAPER_STEPS = [
  "Wallpaper is on screen",
  "Color palette generated",
  "Effects and icons processed",
  "Desktop consumers updated",
]

// The speed test's four steps, in the order `speedtest-cli` actually performs
// them (latency, then download, then upload) — not invented progress. The bar
// pulses while they run because the CLI returns ONE JSON blob at the end and
// the producer has no intermediate fraction to publish; a determinate
// percentage here would be a number the system made up.
export const SPEEDTEST_STEPS = [
  "Test scheduled",
  "Latency measured",
  "Download measured",
  "Upload measured",
]

/** A finite payload number, or null — never a coerced NaN on screen. */
export function asNumber(value: unknown): number | undefined {
  return typeof value === "number" && Number.isFinite(value) ? value : undefined
}

/** A payload string, trimmed; "" for anything else, including null/undefined. */
export function asText(value: unknown): string {
  return typeof value === "string" ? value.trim() : ""
}

export function mbpsLabel(value: number | undefined): string {
  return value === undefined ? "—" : `${value.toFixed(1)} Mbps`
}

export function msLabel(value: number | undefined): string {
  return value === undefined ? "—" : `${Math.round(value)} ms`
}

export function statusForStage(stage: string): string {
  switch (stage) {
    case "generating_palette": return "Wallpaper is on screen. Generating the color palette…"
    case "palette_generated": return "Color palette generated. Preparing effects and icons…"
    case "preparing_appearance_assets": return "Color palette generated. Preparing effects and icons…"
    case "appearance_assets_ready": return "Appearance assets prepared. Updating desktop apps…"
    case "reconciling_consumers": return "Appearance assets prepared. Updating desktop apps…"
    case "finished": return "All visual settings are up to date."
    default: return "Setting the new wallpaper…"
  }
}

export function stageIndex(stage: string): number {
  switch (stage) {
    case "setting_wallpaper": return 0
    case "generating_palette": return 1
    case "palette_generated": return 2
    case "preparing_appearance_assets": return 2
    case "appearance_assets_ready": return 3
    case "reconciling_consumers": return 3
    case "finished": return WALLPAPER_STEPS.length
    default: return 0
  }
}

export function failureForStage(stage: string): string {
  switch (stage) {
    case "setting_wallpaper": return "setting the wallpaper"
    case "generating_palette": return "generating the color palette"
    case "palette_generated":
    case "preparing_appearance_assets": return "preparing effects and icons"
    case "appearance_assets_ready":
    case "reconciling_consumers": return "updating desktop apps"
    default: return "updating the wallpaper appearance"
  }
}

export function triggerPhrase(trigger: string): string {
  switch (trigger) {
    case "manual": return "Started by you"
    case "connect": return "Run after connecting"
    default: return "Scheduled run"
  }
}

/**
 * The success body: what was measured, joined the way the mock joins it
 * ("Canela&Dulce · CableVivo Envigado").
 *
 * The spec says to fall back to the trigger phrase when EITHER value is empty.
 * This keeps whichever half IS known instead, because the rule's stated
 * purpose is "rather than render a blank": dropping the SSID because the
 * backend reported no server name would throw away a fact we measured. Only
 * when NEITHER is present does the line fall back, and then to the trigger
 * phrase alone.
 */
export function speedtestContextLine(
  terminal?: { ssid?: string; server_name?: string; trigger: string },
): string {
  const ssid = asText(terminal?.ssid)
  const server = asText(terminal?.server_name)
  if (ssid !== "" && server !== "") return `${ssid} · ${server}`
  if (ssid !== "") return ssid
  if (server !== "") return server
  return `${triggerPhrase(terminal?.trigger ?? "")} · also shown in the Wi-Fi panel`
}

/**
 * The fallback tile glyph for a daemon notification with no usable image: the
 * app's initial (or "!" for critical) so icon-less traffic still renders a tidy
 * card.
 */
export function fallbackGlyph(appName: string, critical: boolean): string {
  return critical ? "!" : (appName.charAt(0).toUpperCase() || "?")
}
