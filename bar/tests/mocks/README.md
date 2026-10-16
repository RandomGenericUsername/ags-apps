# bar test mocks

Owner-approved mock HTML that the mock<->code parity guards in `scripts/`
check the shipped `bar/` sources against. Each mock is the acceptance contract
for a bar surface: every `class="..."` token in an anchored state must resolve
to a class in `bar/style.css` (or `bar/audio/audio-panel.css`), to the state's
mapped TSX, to an allowlisted scaffold, or to a tracked known gap.

These files were VENDORED here from dotfiles-v3 (ticket `bar7-rehome-guards`)
so the guards and their fixtures live with the bar. The bar is now the source of
truth for these surfaces; keeping the mock in the retired dotfiles change would
have left the guard reading a fixture that change archival would eventually move
or delete.

| file | guard | original location |
| --- | --- | --- |
| `wifi-popup-mockup.html` | `scripts/wifi-mock-parity.py` | `dotfiles-v3/wifi-popup-mockup.html` |
| `battery-popup-mockup.html` | `scripts/battery-mock-parity.py` | `dotfiles-v3/battery-popup-mockup.html` |
| `bluetooth-panel.html` | `scripts/bluetooth-mock-parity.py` | `dotfiles-v3/openspec/changes/add-bluetooth-bar-popup/mockups/panel.html` |
| `audio-panel-redesign-concept.html` | `scripts/audio-mock-parity.py` | `dotfiles-v3/_bmad-output/planning-artifacts/ux-designs/ux-dotfiles-repo-v3-audio-2026-09-18/mockups/audio-panel-redesign-concept.html` |

The guards are run by `make wifi-mock-parity`, `make battery-mock-parity`,
`make bluetooth-mock-parity` and `make audio-mock-parity` (all in `gates-ci`).
