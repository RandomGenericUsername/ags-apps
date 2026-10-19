import assert from "node:assert/strict"
import { test } from "node:test"
import {
  createSurfaceMount,
  createSurfaceRegistry,
  surfaceContentSignature,
} from "../../kit/surface.ts"
import type { SurfaceSpec } from "../../kit/surface.ts"
import { overlays } from "../../kit/overlay.ts"
import { createOverlayLifecycle } from "ags-platform/ports/overlay-lifecycle"

/**
 * The AD-10 mount policy, proven without GTK.
 *
 * `createSurfaceMount` is the pure decision `PopupHost` drives from its
 * visibility accessor: the body is built only while visible and dropped when
 * hidden. These tests pin the two claims the spine makes — the body is mounted
 * lazily, and (wired to the one overlay coordinator) at most one body is live.
 */

test("a surface body is built only while visible and dropped when hidden", () => {
  let builds = 0
  let teardowns = 0
  const mount = createSurfaceMount(
    () => ({ n: ++builds }),
    () => { teardowns += 1 },
  )

  assert.equal(mount.isMounted(), false)
  assert.equal(mount.render(false), null)
  assert.equal(builds, 0, "the factory must not run while hidden")
  assert.equal(teardowns, 0)

  const first = mount.render(true)
  assert.deepEqual(first, { n: 1 })
  assert.equal(builds, 1, "showing builds exactly one body")
  assert.equal(mount.isMounted(), true)

  // Idempotent while visible: an unrelated re-render returns the same instance.
  assert.equal(mount.render(true), first)
  assert.equal(builds, 1, "a re-render must not rebuild a visible body")

  mount.render(false)
  assert.equal(teardowns, 1, "hiding tears the body down")
  assert.equal(mount.isMounted(), false)

  const second = mount.render(true)
  assert.deepEqual(second, { n: 2 }, "a re-show builds a fresh body")
  assert.equal(builds, 2)
})

test("wired to the overlay coordinator, at most one surface body is live", () => {
  let aOpen = false
  let bOpen = false
  overlays.register({
    id: "surface-mount-test-a",
    isOpen: () => aOpen,
    open: () => { aOpen = true },
    close: () => { aOpen = false },
  })
  overlays.register({
    id: "surface-mount-test-b",
    isOpen: () => bOpen,
    open: () => { bOpen = true },
    close: () => { bOpen = false },
  })

  const a = createSurfaceMount(() => ({ id: "a" }))
  const b = createSurfaceMount(() => ({ id: "b" }))
  const live = () =>
    [
      a.render(overlays.isOpen("surface-mount-test-a")),
      b.render(overlays.isOpen("surface-mount-test-b")),
    ].filter((body) => body !== null).length

  overlays.open("surface-mount-test-a")
  assert.equal(live(), 1)
  assert.equal(a.isMounted(), true)
  assert.equal(b.isMounted(), false)

  overlays.open("surface-mount-test-b")
  assert.equal(live(), 1, "exactly one body is live after the swap")
  assert.equal(a.isMounted(), false, "opening B must close A")
  assert.equal(b.isMounted(), true)

  overlays.closeAll()
  assert.equal(live(), 0)
})

test("the registry looks up surfaces by id", () => {
  const spec: SurfaceSpec<string> = { id: "demo", body: () => "body" }
  const registry = createSurfaceRegistry([spec])

  assert.equal(registry.get("demo"), spec)
  assert.deepEqual(registry.all(), [spec])
  assert.equal(registry.get("missing"), undefined)
})

/**
 * The AD-24 open path at the bar's `PopupHost`, driven through the platform
 * primitive with a stub scheduler so it is provable on a stock runner.
 *
 * `PopupHost` presents the window through its own `visible` binding, defers the
 * body build to the idle queue, and — because AD-10 tears the body down on hide
 * — moves the signature to the next mount generation on close. These tests pin
 * both halves: the build is deferred (not on the open path), and an unchanged
 * reopen still rebuilds because the body was dropped.
 */
function stubLifecycle(key: () => string) {
  const queued: (() => void)[] = []
  let builds = 0
  const lifecycle = createOverlayLifecycle(
    {
      present: () => {},
      hydrate: () => {},
      build: () => {
        builds += 1
      },
      key,
    },
    { defer: (task) => queued.push(task) },
  )
  const drain = () => {
    while (queued.length > 0) queued.shift()!()
  }
  return { lifecycle, drain, builds: () => builds }
}

test("the bar's surface build is deferred, not run on the open path", () => {
  const h = stubLifecycle(() => surfaceContentSignature("wifi", 0))
  h.lifecycle.open()
  assert.equal(h.builds(), 0, "open() must not build synchronously")
  h.drain()
  assert.equal(h.builds(), 1, "the idle callback runs the build")
})

test("a bar surface rebuilds on every open: AD-10 tears the body down", () => {
  let generation = 0
  const h = stubLifecycle(() => surfaceContentSignature("wifi", generation))

  h.lifecycle.open()
  h.drain()
  assert.equal(h.builds(), 1)

  // Close and reopen with the SAME content. The body was dropped, so the mount
  // generation advances and the build runs again.
  h.lifecycle.close()
  generation += 1
  h.lifecycle.open()
  h.drain()
  assert.equal(h.builds(), 2, "an unchanged reopen rebuilds (no reusable body)")
})

test("without the generation the unchanged signature would skip, leaving an empty surface", () => {
  // The trap `surfaceContentSignature` exists to avoid: a content-only key makes
  // the primitive skip the reopen against a body that AD-10 already tore down.
  const h = stubLifecycle(() => surfaceContentSignature("wifi", 0))
  h.lifecycle.open()
  h.drain()
  h.lifecycle.close()
  h.lifecycle.open()
  h.drain()
  assert.equal(h.builds(), 1, "the stale signature skips the rebuild — the bug")
})
