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

## Phase 2 — More gestures and tuning ✅

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
- [x] Typing no longer triggers slides in daily use (record a trace if it comes back)
- [ ] Check the swallowing of tap-to-click's click after an edge tap (only matters with Tap to Click on; untested)

## Phase 3 — Menu bar panel and Settings 🧪 built, in hands-on testing

- [x] SwiftUI panel: live brightness and volume levels drawn on the edges that control them
- [x] Everyday toggles up front: haptic strength, Quick Mute, Media Strip, Tap to Play
- [x] Sensitivity and edge width sliders, and an on/off switch
- [x] A separate Settings page for set-once options
- [x] Appearance: System, Light, or Dark
- [x] Open at Login (`SMAppService`); `scripts/install.sh` puts the app in /Applications first
- [x] First-run guide: grant Accessibility, try your first slide (it ticks off as you go)
- [x] Picks up the Accessibility grant, or its removal, without a relaunch
- [x] `-snapshot <folder>` renders the panel, Settings, and guide in light and dark, for design checks

## Phase 4 — Branding, design, and custom corner actions ✅

- [x] Branding: app icon, menu bar icon, coral accent (drawn by `scripts/make-icons.swift`); keeping the name
- [x] Design pass: row icons coral when on and grey when off, an empty menu bar glyph while paused, and an
  animated fingertip in the setup guide
- [x] Double-tap the top-left corner to run a custom action (Settings → Corners):
  - [x] A keyboard shortcut, recorded in Settings (⌘Space for Raycast, ⌃⌘Q to lock, ⌘F1 to mirror displays)
  - [x] Or open an app, mute, or play/pause
- [x] The same choice for the top-right corner, in place of the Quick Mute switch (defaults to Mute)

### Later ideas

- [ ] Brightness for external monitors (DDC, as MonitorControl does)
- [ ] Magic Trackpad support, including plugging it in and out
- [ ] Any action per edge (keyboard backlight, app switching, scrolling, Mission Control)
- [ ] Profiles per app or display setup
- [ ] Our own on-screen display as an alternative to the system one

## Phase 5 — Release and open source

- [x] Install script for `/Applications` (needed for Open at Login)
- [x] Sparkle updates from GitHub releases (same setup as Tamil Calendar, its own EdDSA key)
- [x] DMG packaging (`make_dmg.sh`, `publish_release.sh`)
- [x] LICENSE (MIT), README with screenshots, contribution notes
- [x] Create the GitHub repo, push, and publish 0.1.0
- [ ] Optional: a Developer ID signature and notarization, so others don't need "Open Anyway"

## Known risks

- MultitouchSupport and DisplayServices are private frameworks. Apple can change them in any macOS release.
  Both work on macOS 27.2, Apple Silicon.
- The app can't be sandboxed, so it can't go on the Mac App Store. That's fine for personal and open source use.
- Gesture conflicts, such as the two-finger swipe from the right edge for Notification Center, need care.
