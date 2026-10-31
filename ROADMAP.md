# EdgeCases roadmap

A personal menu bar app that turns the edges of the MacBook trackpad into controls: slide along
the left edge for brightness, the right edge for volume, and more. Inspired by
[EdgeBar](https://edgebar.xyz/); not a copy of it. Not for sale. Planned to be open source.

Each phase ends with something usable that gets committed. Phase 4's list is open: it is where our
own changes and additions go.

## Phase 0 — Foundations ✅

- [x] Git repo, XcodeGen `project.yml`, `scripts/build.sh` and `scripts/run.sh`
- [x] Stable self-signed code signature ("EdgeCases Signing"), so the Accessibility grant survives rebuilds
- [x] Menu bar shell: no Dock icon, status menu with Enabled and Quit
- [x] Accessibility check and prompt
- [x] Read raw trackpad touches through MultitouchSupport (private framework, loaded with `dlopen`)
- [x] Restart the touch stream after the Mac wakes from sleep
- [x] `EdgeCore` package: the edge gesture engine as pure Swift, with tests

## Phase 1 — Core slide (prototype) ✅

- [x] Slide on the left edge for brightness, the right edge for volume
- [x] Use synthetic media keys, so we get the system's own on-screen display and step sizes
- [x] Cursor freeze: the pointer snaps back to where it was and stays put while you slide
- [x] Haptic tick on each step
- [x] Pausing via Enabled in the menu

**Done when:** sliding feels reliable in daily use and never interferes with normal pointing.

## Phase 2 — More gestures and tuning 🧪 built, in hands-on testing

- [x] Separate "EdgeCases Signing" certificate
- [x] Haptic strength: Off, Light, Medium, Strong, played on the trackpad's actuator (private API) instead of
      the faint public haptics. Debug → Play Haptic Waveform tries the other waveforms.
- [x] Fine control: Shift-Option for quarter steps (the modifier also works on the real keys)
- [x] Quick Mute: double-tap the top-right corner
- [x] Media Strip: slide along the bottom edge for the next or previous track (one skip per slide)
- [x] Tap the bottom edge to play or pause (optional, off by default); a physical click there is not a tap
- [x] Swap sides (brightness on the right)
- [x] Bottom Quarter Only: side slides only start in the lowest 25%
- [x] Require a modifier (Fn or ⌥) to slide
- [x] Freeze Cursor can be turned off
- [x] Sensitivity and edge width settings
- [x] Settings saved in `UserDefaults`, set from the menu for now
- [x] Accidental touches:
  - [x] Ignore touches that start within 0.5 s of a key press (hands on the keyboard)
  - [x] A key press during a touch cancels it
  - [x] A touch that rests 0.6 s without sliding is a resting finger or palm, not a slide
  - [x] A physical click during a touch cancels it
- [x] Engine tests replay traces; Debug → Record Touches saves real ones to `~/Library/Application Support/EdgeCases/Traces`
- [ ] Record a trace of typing with accidental triggers, turn it into a test, and tune (contact size may tell palms apart)
- [ ] Check the swallowing of tap-to-click's click after an edge tap (only matters with Tap to Click on; untested)

## Phase 3 — Menu bar panel and Settings

- [ ] SwiftUI panel: live brightness and volume levels drawn on the edges that control them
- [ ] Everyday toggles up front: haptics, Quick Mute, Media Strip, Tap to Play
- [ ] Sensitivity and edge width sliders
- [ ] A separate Settings page for set-once options
- [ ] Light and Dark appearance
- [ ] Open at Login (`SMAppService`)
- [ ] First-run guide: grant Accessibility, try your first slide
- [ ] App icon

## Phase 4 — Our own changes and additions (to decide)

Ideas so far; we pick from these and add our own:

- [ ] Brightness for external monitors (DDC, as MonitorControl does)
- [ ] Magic Trackpad support, including plugging it in and out
- [ ] Choose any action per edge or corner (keyboard backlight, app switching, scrolling, Mission Control, shortcuts)
- [ ] Profiles per app or display setup
- [ ] Our own on-screen display as an alternative to the system one

## Phase 5 — Release and open source

- [ ] Install script for `/Applications` (needed for Open at Login)
- [ ] Sparkle updates from GitHub releases (same setup as Tamil Calendar)
- [ ] DMG packaging
- [ ] LICENSE, README with screenshots, contribution notes
- [ ] Optional: a Developer ID signature and notarization, so others don't need "Open Anyway"

## Known risks

- MultitouchSupport and DisplayServices are private frameworks. Apple can change them in any macOS release.
  Both work on macOS 27.2, Apple Silicon.
- The app can't be sandboxed, so it can't go on the Mac App Store. That's fine for personal and open source use.
- Gesture conflicts, such as the two-finger swipe from the right edge for Notification Center, need care.
