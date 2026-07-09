# Legend UI Gallery

Living documentation of every component in the rewrite — no empty stubs
(a legacy anti-pattern this app exists to prevent).

```bash
flutter run -d chrome
```

Doubles as the consumer-workflow reference: it consumes only
`package:legend_ui/legend_ui.dart` and demonstrates theme overrides at
the constructor, subtree, and app-theme levels, plus the animated
light/dark token switch and the breakpoint-driven shell (resize the
window: the sider swaps for a bottom bar below 600 px).
