# EdgeCases

Slide along the edges of your MacBook trackpad to change brightness (left edge) and volume
(right edge). Lives in the menu bar. A personal project, inspired by [EdgeBar](https://edgebar.xyz/).

See [ROADMAP.md](ROADMAP.md) for what's built and what's next.

## Run

```bash
./scripts/run.sh        # debug build, launches from build/
```

Requires Xcode, XcodeGen (`brew install xcodegen`), and a code signing identity named
"EdgeCases Signing" in the login Keychain (a self-signed certificate is enough; a stable signature
keeps the Accessibility grant across rebuilds). The Xcode project is generated from
`project.yml`; run `xcodegen generate` to open it in Xcode. Gesture engine tests:
`cd Packages/EdgeCore && swift test`.

On first launch, allow EdgeCases in System Settings → Privacy & Security → Accessibility. It needs
that to post brightness and volume key events. If the toggle is on but nothing happens, remove the
entry with − and add it again: macOS ties the grant to the app's signature.

## Layout

| Path | What |
|---|---|
| `Packages/EdgeCore` | The edge gesture engine: trackpad frames in, slides and steps out (`swift test`) |
| `EdgeCases/Touch` | Bridge to the private MultitouchSupport framework (touches, haptics), the monitor that feeds the engine, and the key/click tap |
| `EdgeCases/System` | Media keys, haptics, cursor lock, Accessibility |
| `EdgeCases/App` | App delegate, menu bar, preferences, and the controller that maps gestures to actions |

Debug → Record Touches saves real trackpad traces (with key presses and clicks) as JSON, for
turning tricky cases into `Trace.replay` tests.

Logs: `/usr/bin/log stream --level info --predicate 'subsystem == "app.edgecases.EdgeCases"'`

## Credits

© 2026 Sameer Kishore. Made with ❤️ by Sameer (and Claude).
