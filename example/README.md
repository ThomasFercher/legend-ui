# Legend UI — docs site & playground

The documentation site for Legend UI, itself a Legend UI app: eleven doc
pages (descriptions, live demos, code snippets, themed-property tables)
plus a live theme playground — presets, brand colors, corner radius,
density, and a per-component override editor, all animating through
`AnimatedLegendTheme`.

```bash
flutter run -d chrome
```

Doubles as the consumer-workflow reference: it consumes only
`package:legend_ui/legend_ui.dart`, builds its `LegendThemeData` with
plain token `copyWith` calls, and registers component overrides in the
open `components` map — exactly what a real app would do. Resize the
window to see the breakpoint-driven shell flip between sider and
compact navigation.
