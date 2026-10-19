// Pure-module unit tests for the notifications cards' model.
//
// `ags bundle` transpiles without type-checking, so a formatting or
// stage-mapping bug is a card that renders wrong at runtime. These functions
// are pure (`notifications/lib/card-model.ts` imports no `gi://*` and no `ags`),
// so `node --test` runs them on a stock runner with no desktop stack.
//
// The explicit `.ts` suffix is load-bearing: Node's ESM resolver does no
// extensionless lookup, and `tsconfig.tests.json` sets
// `allowImportingTsExtensions` so tsc agrees. `card-model.ts` imports nothing,
// so no resolve hook is needed (unlike the bar's suite).

import { test } from "node:test"
import assert from "node:assert/strict"

import {
  SPEEDTEST_STEPS,
  WALLPAPER_STEPS,
  asNumber,
  asText,
  failureForStage,
  fallbackGlyph,
  mbpsLabel,
  msLabel,
  speedtestContextLine,
  stageIndex,
  statusForStage,
  triggerPhrase,
} from "../lib/card-model.ts"

test("asNumber accepts a finite number and rejects everything else", () => {
  assert.equal(asNumber(12.5), 12.5)
  assert.equal(asNumber(0), 0)
  assert.equal(asNumber(Number.NaN), undefined)
  assert.equal(asNumber(Number.POSITIVE_INFINITY), undefined)
  assert.equal(asNumber("7"), undefined)
  assert.equal(asNumber(null), undefined)
  assert.equal(asNumber(undefined), undefined)
})

test("asText trims a string and blanks anything else", () => {
  assert.equal(asText("  Canela&Dulce "), "Canela&Dulce")
  assert.equal(asText(""), "")
  assert.equal(asText(7), "")
  assert.equal(asText(null), "")
  assert.equal(asText(undefined), "")
})

test("mbpsLabel / msLabel render an em dash for a missing value", () => {
  assert.equal(mbpsLabel(undefined), "—")
  assert.equal(mbpsLabel(93.44), "93.4 Mbps")
  assert.equal(msLabel(undefined), "—")
  assert.equal(msLabel(18.6), "19 ms")
})

test("stageIndex maps every contract stage and clamps the unknown to 0", () => {
  assert.equal(stageIndex("setting_wallpaper"), 0)
  assert.equal(stageIndex("generating_palette"), 1)
  assert.equal(stageIndex("palette_generated"), 2)
  assert.equal(stageIndex("preparing_appearance_assets"), 2)
  assert.equal(stageIndex("appearance_assets_ready"), 3)
  assert.equal(stageIndex("reconciling_consumers"), 3)
  assert.equal(stageIndex("finished"), WALLPAPER_STEPS.length)
  assert.equal(stageIndex("nonsense"), 0)
})

test("statusForStage names the shipped copy and falls back safely", () => {
  assert.equal(statusForStage("finished"), "All visual settings are up to date.")
  assert.equal(
    statusForStage("generating_palette"),
    "Wallpaper is on screen. Generating the color palette…",
  )
  assert.equal(statusForStage("nonsense"), "Setting the new wallpaper…")
})

test("failureForStage names the step and falls back safely", () => {
  assert.equal(failureForStage("setting_wallpaper"), "setting the wallpaper")
  assert.equal(failureForStage("preparing_appearance_assets"), "preparing effects and icons")
  assert.equal(failureForStage("reconciling_consumers"), "updating desktop apps")
  assert.equal(failureForStage("nonsense"), "updating the wallpaper appearance")
})

test("triggerPhrase distinguishes manual / connect / scheduled", () => {
  assert.equal(triggerPhrase("manual"), "Started by you")
  assert.equal(triggerPhrase("connect"), "Run after connecting")
  assert.equal(triggerPhrase("scheduled"), "Scheduled run")
  assert.equal(triggerPhrase(""), "Scheduled run")
})

test("speedtestContextLine keeps whichever half is known", () => {
  assert.equal(
    speedtestContextLine({ ssid: "Canela&Dulce", server_name: "CableVivo", trigger: "manual" }),
    "Canela&Dulce · CableVivo",
  )
  assert.equal(
    speedtestContextLine({ ssid: "Canela&Dulce", server_name: "", trigger: "manual" }),
    "Canela&Dulce",
  )
  assert.equal(
    speedtestContextLine({ ssid: "", server_name: "CableVivo", trigger: "manual" }),
    "CableVivo",
  )
  assert.equal(
    speedtestContextLine({ ssid: "", server_name: "", trigger: "manual" }),
    "Started by you · also shown in the Wi-Fi panel",
  )
  assert.equal(
    speedtestContextLine(undefined),
    "Scheduled run · also shown in the Wi-Fi panel",
  )
})

test("fallbackGlyph uses the initial, or ! for critical, or ? for no name", () => {
  assert.equal(fallbackGlyph("Spotify", false), "S")
  assert.equal(fallbackGlyph("spotify", false), "S")
  assert.equal(fallbackGlyph("", false), "?")
  assert.equal(fallbackGlyph("Spotify", true), "!")
})

test("the step lists are the four shipped steps, in order", () => {
  assert.deepEqual(WALLPAPER_STEPS, [
    "Wallpaper is on screen",
    "Color palette generated",
    "Effects and icons processed",
    "Desktop consumers updated",
  ])
  assert.deepEqual(SPEEDTEST_STEPS, [
    "Test scheduled",
    "Latency measured",
    "Download measured",
    "Upload measured",
  ])
})
