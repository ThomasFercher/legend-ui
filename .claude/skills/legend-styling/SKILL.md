---
name: legend-styling
description: Legend UI styling guideline — tokens as the only global theme, four-level resolution, seed derivation, InteractiveColors, breakpoints vs theming, and rebuild-minimization patterns with measured numbers. Invoke when styling components, authoring themes, or optimizing theme-change rebuilds.
---

# Styling in Legend UI

## Tokens are the only global theme

`LegendTokens { colors, sizes, typography, shadows, states }` — written once, swapped whole. Presets: `LegendTokens.light` / `LegendTokens.dark`. Seed derivation (RFC-002 R4):

```dart
final tokens = LegendTokens.fromSeed(LegendSeed(brand: Color(0xFF0059FF)));
final dark   = LegendTokens.fromSeed(
  LegendSeed(brand: Color(0xFF0059FF), brightness: Brightness.dark),
);
```

`fromSeed` is a **constructor, not a resolution level**: it returns plain `LegendTokens`; `copyWith` applies on top for surgical adjustments. 1–4 seed values (`brand`, optional `neutral`/`radius`/`sizeUnit`/`fontFamily`/`brightness`) replace 17 hand-picked colors; every `on*` pair clears ≥ 4.5:1 WCAG AA. Hand-authoring stays first-class: start from a preset and `copyWith` (reference: `example/lib/theme/theme_controller.dart`).

Reading tokens in a widget — a **whole-object** dependency (any theme change rebuilds the caller; fine for token consumers):

```dart
final tokens = LegendTheme.of(context).tokens;
```

## Four-level resolution, nearest wins

One concrete example per level, using `LegendDivider`:

```dart
// 1 — constructor param (always wins, never a rebuild source)
LegendDivider(color: navy)

// 2 — subtree override
LegendDividerThemeOverride(
  data: LegendDividerThemeNullable(color: navy),
  child: page,
)

// 3 — app registry (open, Type-keyed; key by the widget type)
LegendThemeData(
  tokens: LegendTokens.light,
  components: {LegendDivider: LegendDividerThemeNullable(color: navy)},
)

// 4 — the annotation default on the widget (this IS the kit default)
@Style<Color>.resolve(ColorRef.background3)
final Color? color;
```

All override data is sparse — set only what differs; unset members keep resolving downward. Component defaults *relate* to tokens through `.resolve` tear-offs, so a token override cascades into every component default that references it.

## Stateful colors: `InteractiveColors`

The predefined `@Style()` value class for hover-bearing widgets — five nullable members (`normal`, `hovered`, `pressed`, `focused`, `disabled`), each individually overridable at every level:

```dart
InteractiveColors(normal: t.colors.primary)        // hover/press/disabled derive via LegendStateOverlays
InteractiveColors(normal: brand, pressed: navy)    // a named member always wins over derivation
```

`pick(state)` falls back to `normal`; `resolve(state, overlays)` derives unset members from `normal` through the token deltas (focus resolves as `normal` — focus draws as a ring, not a fill shift). Widget interaction state is the sealed `LegendWidgetState` (`LegendStateNormal/Hovered/Pressed/Focused/Disabled`) — exhaustively switchable, single-valued.

## Sizing: breakpoints, never theme swaps

Responsiveness ≠ theming (DESIGN §2.4). Window resizes flip the tier; the theme does not change:

```dart
final tier  = LegendBreakpoints.tierOf(context);   // rebuilds only when the tier flips
final width = LegendBreakpoints.widthOf(context);  // rebuilds on any width change
if (tier == LegendTier.compact) { ... }
```

Theme switches swap `LegendTokens`; `AnimatedLegendTheme` (inside `LegendApp`) lerps the token set **once** (`LegendTokens.lerp`) — never per-component theme classes.

## Rebuild minimization (RFC-002 R12, measured)

Why it matters — the 2026-07-10 audit numbers: pre-R12, a 250 ms token lerp rebuilt **every** `LegendTheme` dependent once per frame (16× at 60 Hz), and changing **one** registry entry rebuilt **all** themed widgets. In the docs app, rebuilding children inline under the root `ListenableBuilder` rebuilt every widget 17× per theme toggle. The fix is cheap: aspect comparators cost ~310 ns/dependent/frame ≈ 0.2 % of frame budget at 100 dependents (full component resolution ~155 ns, whole-token lerp ~0.9 µs/frame).

Patterns, in order of reach:

1. **Stable home child** — build the home subtree once and reuse it, so a controller tick rebuilds only `LegendApp` and actual theme dependents (reference: `example/lib/main.dart`):

   ```dart
   late final Widget _home = _DocsShell(controller: _theme);
   // ...
   ListenableBuilder(
     listenable: _theme,
     builder: (context, _) => LegendApp(theme: _theme.data, home: _home),
   )
   ```

2. **Narrowest listener** — wrap only the widget that needs controller state in its own `ListenableBuilder` (the dark-mode switch in the docs shell), not the page around it.
3. **Generated resolvers already listen per field** — `_theme(context)` registers one rebuild aspect per `listen: true` field; the widget rebuilds only when a listened field's *resolved value* changes (registry changes are type-scoped by construction).
4. **One property → per-field accessor** — `_color(context)` registers just that field's aspect.
5. **`@Style(..., listen: false)`** — for values consumed by imperative code (painters, controllers): resolved fresh every build, never a rebuild cause.
6. **No widget rebuild at all** — the generated `XThemeListenables.<field>(source, data)` binds a distinct-until-changed `LegendThemeSelector` (a `ValueListenable`) to any theme source; dispose it when done:

   ```dart
   final color = LegendDividerThemeListenables.color(controller, () => controller.data);
   ```

7. **`LegendTheme.read(context)`** — reads the data without registering any dependency.

## Do NOT

- Give a themed constructor param a non-null default — the legacy bug (theme values become unreachable); the generator rejects it.
- Import Material (`Scaffold`, `InkWell`, `ThemeData`, `RichText`) in component code — compose the five primitives (`LegendSurface`, `LegendInteractive`, overlay engine, text core, field core); rich text goes through `LegendText.rich`.
- Swap themes per breakpoint tier — tier is `LegendBreakpoints`' job.
- Wrap themed values in ad-hoc containers — define a `@Style()` value class so members stay individually overridable, mergeable, and lerpable.
- Put functions or a `BuildContext` in theme data — themes are pure data; computed values are produced at theme-build time.
