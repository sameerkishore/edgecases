# EdgeCases

Slide along the edges of your MacBook trackpad to change brightness (left edge) and volume
(right edge). Lives in the menu bar. A personal project, inspired by [EdgeBar](https://edgebar.xyz/).

See [ROADMAP.md](ROADMAP.md) for what's built and what's next.

## Run

```bash
./scripts/run.sh        # debug build, launches from build/
```

Requires Xcode and XcodeGen (`brew install xcodegen`). The Xcode project is generated from
`project.yml`; run `xcodegen generate` to open it in Xcode. Gesture engine tests:
`cd Packages/EdgeCore && swift test`.

On first launch, allow EdgeCases in System Settings → Privacy & Security → Accessibility. It needs
that to post brightness and volume key events. If the toggle is on but nothing happens, remove the
entry with − and add it again: macOS ties the grant to the app's signature.

## Layout

| Path | What |
|---|---|
| `Packages/EdgeCore` | The edge gesture engine: trackpad frames in, slides and steps out (`swift test`) |
| `EdgeCases/Touch` | Bridge to the private MultitouchSupport framework, and the monitor that feeds the engine |
| `EdgeCases/System` | Media keys, cursor lock, Accessibility |
| `EdgeCases/App` | App delegate, menu bar, and the controller that maps slides to actions |

Logs: `/usr/bin/log stream --level info --predicate 'subsystem == "app.edgecases.EdgeCases"'`

## Credits

© 2026 Sameer Kishore. Made with ❤️ by Sameer (and Claude).
