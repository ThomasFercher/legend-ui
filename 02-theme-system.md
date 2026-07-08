# Nomo UI Kit — Theme System

> Documentation of the legacy theme system in `/Users/thomas/src/legend-ui` (package `nomo_ui_kit` v0.0.36), written as rewrite preparation. Companion document: `03-code-generation.md`.
>
> Note: the repo root **is** the UI-kit package (`lib/` at root). The `CLAUDE.md` claim of a `/packages/nomo-ui-kit/` monorepo layout does not match this checkout.

## 1. High-level architecture

The theme system is split into **two InheritedWidgets** plus a **ChangeNotifier**:

| Piece | File | Role |
|---|---|---|
| `NomoThemeData` | `lib/theme/nomo_theme.dart` | Immutable snapshot of the whole theme (colors + sizing + typography + constants). |
| `NomoTheme` (InheritedWidget) | `lib/theme/nomo_theme.dart` | Distributes the *current, possibly mid-animation* `NomoThemeData` down the tree. All widgets read from this. |
| `ThemeNotifier` (ChangeNotifier) | `lib/theme/theme_provider.dart` | Owns the theme state; switches color/sizing modes; built from a `NomoThemeDelegate`. |
| `ThemeProvider` (InheritedWidget) | `lib/theme/theme_provider.dart` | Exposes the notifier (mode switching API) to the tree; **not** what widgets read colors from. |
| `NomoThemeDelegate<C, S>` | `lib/theme/nomo_theme.dart` | Abstract class the *app* implements: declares all color themes, sizing themes, typography, constants, and responsive breakpoints. |
| `ThemeAnimator` | `lib/app/animator.dart` | Rebuilds `NomoTheme` with a lerped `NomoThemeData` while animating between themes. |
| `MetricReactor` | `lib/app/metric_reactor.dart` | Listens to window metrics and drives responsive sizing-theme switching. |
| `NomoApp` | `lib/app/nomo_app.dart` | Wires everything together. |

### 1.1 Widget-tree wiring (from `NomoApp.build`)

```
NomoApp (StatefulWidget, owns ThemeNotifier(themeDelegate))
└─ ThemeProvider(notifier: themeNotifier)          // mode-switch API
   └─ ScrollConfiguration / NomoTextTranslator / ScaffoldMessenger / InAppNotification
      └─ MetricReactor(sizingThemeBuilder: delegate.sizingThemeBuilder)
         └─ ThemeAnimator(notifier: themeNotifier)
            └─ ListenableBuilder(listenable: notifier)
               └─ TweenAnimationBuilder<NomoThemeData>(NomoThemeDataTween, 400ms easeInOut)
                  └─ NomoTheme(value: lerpedTheme, colorMode, sizingMode)
                     └─ NomoDefaultTextStyle(style: theme.typography.b1)
                        └─ WidgetsApp.router(...)
```

Key constants in `lib/app/nomo_app.dart`:
```dart
const kThemeChangeDuration = Duration(milliseconds: 400);
const kThemeChangeCurve = Curves.easeInOut;
```

### 1.2 Update / notification flow

1. App code calls `context.themeProvider.changeColorTheme(ColorMode.DARK)` (or `changeSizingTheme`).
2. `ThemeProvider` forwards to `ThemeNotifier.changeColorTheme(mode)`, which:
   - stores the new `colorMode`,
   - rebuilds `_theme = _theme.copyWith(colorTheme: _colorThemes[mode])`,
   - calls `notifyListeners()`,
   - then invokes delegate hooks `onColorThemeChanged(...)` and `onThemeChanged(...)`.
   (`changeColorTheme` does **not** early-return on same mode — the `if (colorMode == mode) return;` is commented out; `changeSizingTheme` does early-return.)
3. `ThemeAnimator`'s `ListenableBuilder` fires; it starts a `TweenAnimationBuilder` from the last theme to `notifier.theme` using `NomoThemeData.lerp` — **the entire theme (all component themes) is lerped every animation frame** and pushed into a fresh `NomoTheme` InheritedWidget.
4. Every widget that called `NomoTheme.of(context)` (directly or through `getFromContext` / `context.colors` etc.) rebuilds because `NomoTheme.updateShouldNotify` compares `oldWidget.value != value`.
   - Caveat: `NomoColorThemeData` / `NomoSizingThemeData` implement `==`/`hashCode` **by `key` only** (`lib/theme/sub/nomo_color_theme.dart:164-170`). Equality of the composite `NomoThemeData` is default identity, so in practice every animation frame notifies (new instance), but two theme datas with the same keys would be "equal" at the sub-theme level.
5. `ThemeProvider.updateShouldNotify` only fires when `colorMode` or `sizingMode` changed — it exists for widgets that depend on the *mode*, not on theme values.

Responsive flow: `MetricReactor` (a `WidgetsBindingObserver`) recomputes `MediaQueryData.fromView` on `didChangeMetrics`, then calls `ThemeProvider.of(context).changeSizingTheme(sizingThemeBuilder(width))`. The delegate's `sizingThemeBuilder(double width)` maps window width → sizing-mode enum. `MetricReactor` also pins `textScaler: TextScaler.noScaling` for the whole app.

### 1.3 `NomoThemeData` (`lib/theme/nomo_theme.dart`)

```dart
class NomoThemeData {
  final NomoColorThemeData colorTheme;
  final NomoTypographyTheme typography;   // derived: textTheme.copyWith(colors:…, sizes:…)
  final NomoSizingThemeData sizingTheme;
  final NomoComponentConstants constants;
  // convenience getters:
  NomoColors get colors; NomoComponentColors get componentColors;
  NomoSizes get sizes;   NomoComponentSizes get componentSizes;
  static NomoThemeData lerp(a, b, t);     // lerps color+sizing; typography/constants snap at t=0.5
  NomoThemeData copyWith({...});
}
```

Important detail: the constructor *re-derives typography* — `typography = textTheme.copyWith(colors: colorTheme.colors, sizes: sizingTheme.sizes)` — so text colors/sizes always track the active color and sizing themes (see §5).

Also defined at top of `nomo_theme.dart` (used as generated-code defaults, see 03 doc):
```dart
const primaryColor = Color(0xFFBCA570);
const secondary   = Color(0xffd1af72);
```

### 1.4 `NomoTheme` static API

- `NomoTheme.of(context)` → `NomoThemeData` (asserts non-null)
- `NomoTheme.maybeOf(context)` → `NomoThemeData?` (used by all generated resolvers so widgets work without a theme)
- `NomoTheme.themeOf(context)` → the `NomoTheme` widget itself (to read `colorMode` / `sizingMode`, typed as `Object`)

## 2. `NomoThemeDelegate<C, S>` — how apps compose themes

`C` and `S` are app-defined enums (e.g. `ColorMode { LIGHT, DARK }`, `SizingMode { SMALL, MEDIUM, LARGE }` in `example/lib/theme.dart`). The delegate is the single place an app defines its theming:

| Member | Purpose |
|---|---|
| `Map<C, NomoColorThemeDataNullable> getColorThemes()` | One entry per color theme (light/dark/…). Each supplies a `NomoColors` core palette + optional per-theme component overrides via `buildComponents`. |
| `C initialColorTheme()` | Startup color mode. |
| `NomoComponentColorsNullable defaultComponentsColor(NomoColors core)` | App-level component color defaults applied to *every* color theme (derived from the core palette). |
| `Map<S, NomoSizingThemeDataNullable> getSizingThemes()` | One entry per sizing theme; core `NomoSizes` + optional component sizing overrides. |
| `NomoComponentSizesNullable defaultComponentsSize(NomoSizes core)` | App-level component sizing defaults for every sizing theme. |
| `S sizingThemeBuilder(double width)` | Responsive breakpoint mapping (width → sizing mode). |
| `NomoTypographyTheme get typography` | Base text styles (font families/weights; sizes+colors get injected). |
| `NomoConstantsThemeData get constants` | Non-lerped component constants (durations, curves…). |
| `onThemeChanged / onColorThemeChanged / onSizingThemeChanged` | Optional hooks (e.g. persistence). |
| `reloadThemeData()` | Recomputes the theme maps (exposed via `ThemeProvider.reloadThemeData`). |

### 2.1 Theme-map construction (`_createColorThemes`, `nomo_theme.dart:150-160`)

For each entry of `getColorThemes()`:

```dart
final defComponents = predefinedComponentColors(value.colors)   // kit defaults from core palette
    .overrideWith(defaultComponentsColor(value.colors));        // app-wide defaults
map[key] = NomoColorThemeDataNullable.convert(value, defComponents);
// convert(): components = defComponents.overrideWith(value.components)  // per-theme overrides
```

Same shape for sizing with `predefinedComponentSizes` / `defaultComponentsSize`. So the **global component theme** for a given mode is a three-layer merge (lowest first):

1. Generated per-component defaults (annotation default values — every field of `NomoComponentColors` defaults to `const XColorData()`).
2. `predefinedComponentColors(colors)` / `predefinedComponentSizes(sizes)` — handwritten kit-level mapping from the core palette to components (`lib/theme/sub/nomo_color_theme.dart:64-136`, `nomo_sizing_theme.dart:133-142`). E.g. `appBarColor.backgroundColor = colors.surface`, `primaryButtonColor.backgroundColor = colors.primary`, splash/hover/focus/highlight derived as `colors.primary.withValues(alpha: …)`.
3. Delegate `defaultComponentsColor(core)` then per-theme `buildComponents(core)` (both `…Nullable`, merged with generated `overrideWith`).

## 3. Color system — `lib/theme/sub/nomo_color_theme.dart`

### 3.1 `NomoColors` (core palette)

All fields `required`, `const`-constructible, with `copyWith`, `lerp`, `fromJson`/`toJson` (hex-string serialization via `_parseColor`/`toHexColor`), and full value `==`/`hashCode`.

| Field | Type | Purpose (as used by `predefinedComponentColors` / components) |
|---|---|---|
| `brightness` | `Brightness` | Light/dark flag; drives e.g. `getCardDecoration` shadow-vs-border logic. Snaps at t=0.5 in lerp. |
| `primary` | `Color` | Brand color; primary button bg, selected foregrounds, loading indicator, splash/hover/focus/highlight tints. |
| `onPrimary` | `Color` | Foreground on `primary` (primary button text). |
| `primaryContainer` | `Color` | Tinted container (vertical-menu selected background). |
| `secondary` | `Color` | Secondary brand color; secondary button bg. |
| `onSecondary` | `Color` | Foreground on `secondary`. |
| `secondaryContainer` | `Color` | Tinted secondary container. |
| `background1` | `Color` | App/scaffold background (level 1). |
| `background2` | `Color` | Level-2 background: inputs, outline containers. |
| `background3` | `Color` | Level-3 background (deepest). |
| `surface` | `Color` | Elevated surfaces: app bar, sider, cards, dialogs, bottom bar, vertical menu. |
| `error` | `Color` | Error/danger color (input errors, `ActionType.danger` buttons). |
| `disabled` | `Color` | Disabled-control background. |
| `onDisabled` | `Color` | Foreground on disabled controls. |
| `foreground1` | `Color` | Primary text/icon color (b1, h1–h3, buttons, menus). |
| `foreground2` | `Color` | Secondary text color (b2). |
| `foreground3` | `Color` | Tertiary text color (b3). |

### 3.2 `NomoColorThemeData` / `NomoColorThemeDataNullable`

```dart
class NomoColorThemeData implements NomoColorThemeDataNullable {
  final NomoColors colors;              // core palette
  final NomoComponentColors components; // fully-resolved per-component color data
  final ValueKey<Object> key;           // identity; == and hashCode use ONLY key
  factory NomoColorThemeData.lerp(a, b, t); // lerps colors + all component data
}

class NomoColorThemeDataNullable {
  final NomoColors colors;
  final NomoComponentColorsNullable? components; // built via buildComponents(colors)
  final ValueKey<Object> key;
  static NomoColorThemeData convert(data, defaultComponents); // merge, see §2.1
}
```

`NomoComponentColors` / `NomoComponentColorsNullable` / `lerpNomoComponentColors` / `overrideWith` are **generated** into `nomo_color_theme.g.dart` from the `@NomoThemeUtils('NomoComponentColors')` annotation on a const list of the 25 per-component `*ColorData` classes (see 03 doc). Field names are derived from the class names: `NomoAppBarColorData` → `appBarColor`, `PrimaryNomoButtonColorData` → `primaryButtonColor`, etc.

Component color slots (25): `outlineContainerColor, appBarColor, scaffoldColor, bottomBarColor, siderColor, verticalMenuColor, primaryButtonColor, secondaryButtonColor, textButtonColor, linkButtonColor, loadingColor, shimmerColor, expandableColor, inputColor, dialogColor, cardColor, dividerColor, infoItemColor, notificationColor, routeBodyColor, snackBarColor, dropDownButtonColor, elevationColor, dropDownMenuColor, switchColor`.

## 4. Sizing system — `lib/theme/sub/nomo_sizing_theme.dart`

### 4.1 `NomoSizes` (core sizes)

Const class with `lerp`, `fromJson`, `toJson`.

| Field | Type | Purpose |
|---|---|---|
| `maxContentWidth` | `double?` | Optional max width for route bodies / content centering (only set on large sizing themes). |
| `fontSizeB1` / `fontSizeB2` / `fontSizeB3` | `double` | Body text sizes 1–3; injected into typography. |
| `fontSizeH1` / `fontSizeH2` / `fontSizeH3` | `double` | Heading sizes 1–3; injected into typography. |
| `spacing1` / `spacing2` / `spacing3` | `double` | Spacing scale (small/medium/large). |

### 4.2 `NomoSizingThemeData` / `NomoSizingThemeDataNullable`

Mirror image of the color side: `sizes` + generated `NomoComponentSizes components` + `ValueKey key` (== by key only), `lerp` via generated `lerpNomoComponentSizes`, nullable variant with `buildComponents(NomoSizes core)` and `convert(...)` merge.

Component sizing slots (23, generated in `nomo_sizing_theme.g.dart` from `@NomoThemeUtils('NomoComponentSizes')`): `outlineContainerSizing, appBarSizing, scaffoldSizing, bottomBarSizing, siderSizing, verticalMenuSizing, routeBodySizing, primaryButtonSizing, secondaryButtonSizing, textButtonSizing, linkButtonSizing, expandableSizing, inputSizing, dialogSizing, cardSizing, dividerSizing, infoItemSizing, notificationSizing, snackBarSizing, dropDownButtonSizing, elevationSizing, dropDownMenuSizing, switchSizing`.

Kit-level `predefinedComponentSizes(core)` only pins two things: primary-button padding `EdgeInsets.symmetric(vertical: 12, horizontal: 24)` and dialog `borderRadius: 6 / padding: 16`; everything else falls back to generated annotation defaults.

Note that "sizing" fields are not strictly geometric — e.g. `NomoScaffoldSizingData.showSider` / `showBottomBar` are `bool`s used for responsive layout switching per sizing theme (small screens: `showSider: false`, see `example/lib/theme.dart`).

## 5. Typography — `lib/theme/sub/nomo_typography_theme.dart` (part of `nomo_theme.dart`)

```dart
class NomoTypographyTheme {
  final TextStyle b1; final TextStyle b2; final TextStyle b3;  // body
  final TextStyle h1; final TextStyle h2; final TextStyle h3;  // headings
  NomoTypographyTheme copyWith({NomoColors? colors, NomoSizes? sizes});
}
```

Only six styles. The app supplies base styles (typically just font families, e.g. `GoogleFonts.roboto()` for body, `GoogleFonts.inter()` for headings in the example). `copyWith` then stamps **color and fontSize** from the active themes:

| Style | Color source | Font size source |
|---|---|---|
| `b1` | `colors.foreground1` | `sizes.fontSizeB1` |
| `b2` | `colors.foreground2` | `sizes.fontSizeB2` |
| `b3` | `colors.foreground3` | `sizes.fontSizeB3` |
| `h1` | `colors.foreground1` | `sizes.fontSizeH1` |
| `h2` | `colors.foreground1` | `sizes.fontSizeH2` |
| `h3` | `colors.foreground1` | `sizes.fontSizeH3` |

There is no `lerp` for typography — `NomoThemeData.lerp` snaps typography at `t < 0.5`, but since `NomoThemeData`'s constructor re-derives it from the (lerped) colors/sizes, text still animates. `ThemeAnimator` sets `NomoDefaultTextStyle(style: theme.typography.b1)` as the app-wide default text style.

## 6. Constants — `lib/theme/sub/nomo_constants.dart`

Constants are theme values that are **never lerped** (durations, curves, misc numbers).

```dart
class NomoConstants {}                       // empty core marker (no global constants exist)
class NomoComponentConstants {               // HANDWRITTEN registry (unlike colors/sizes)
  final NomoInputConstants inputTheme;                       // default const NomoInputConstants()
  final NomoInfoItemConstants infoItemTheme;
  final NomoVerticalListTileConstants verticalListTileTheme;
  final NomoNotificationConstants notificationTheme;
  final NomoSnackBarConstants snackBarTheme;
  final NomoElevationConstants elevationTheme;
}
class NomoConstantsThemeData {
  final NomoConstants constants;
  final NomoComponentConstants componentConstants;  // built via componentConstantsBuilder(constants)
}
```

Only 6 of the 26 components have constants. The per-component `*Constants` classes are generated (from `@NomoConstant` fields, e.g. `NomoInputConstants(duration: 200ms, curve: Curves.easeInOut, titleSpacing: 2.0)`), but this aggregate registry is maintained **by hand**, and the generated resolver looks constants up by the naming convention `constants.<themeName>Theme` (e.g. `inputTheme`) — a silent coupling between generator output and handwritten code.

Constants are not part of mode maps: one global `NomoConstantsThemeData` from the delegate, stored once in `NomoThemeData.constants`, snapped (not lerped) during animation.

## 7. Context extensions — `lib/theme/theme_extension.dart` (part of `nomo_theme.dart`)

`extension ThemeContextExtension on BuildContext`:

| Getter | Returns |
|---|---|
| `context.theme` | `NomoThemeData` (`NomoTheme.of`) |
| `context.themeProvider` | `ThemeProvider` (mode switching: `changeColorTheme` / `changeSizingTheme` / `reloadThemeData` / `getColorThemeForMode` / `getSizingThemeForMode`) |
| `context.colors` | `NomoColors` core palette |
| `context.componentColors` | `NomoComponentColors` |
| `context.colorTheme` / `context.sizingTheme` | full sub-theme data |
| `context.getColorMode<T>()` / `context.getSizingMode<T>()` | current mode enums (stored as `Object`, cast to `T`) |
| `context.typography` | `NomoTypographyTheme` |
| `context.sizes` / `context.componentSizes` | core / component sizes |
| `context.mediaQuery`, `context.width`, `context.height`, `context.pixelRatio`, `context.insetTop` | MediaQuery conveniences |

Also in that file:
- `extension ThemeUtil on NomoThemeData` — `getCardDecoration(...)`: shadow in light mode, white24 border in dark mode.
- `extension ColorUtils on Color` — `darken([amount])` / `lighten([amount])` via HSL.
- `extension BrightnessUtils on Brightness` — `opposite`, `isLight`, `isDark`.
- `extension IfUtils<T> on T` — `ifElseNull(cond)`, `ifElse(cond, other:)`.

## 8. Per-component theme resolution — the precedence chain

Every annotated component gets a generated top-level resolver `getFromContext(BuildContext, Widget)` in its `*.theme_data.g.dart` (see 03 doc for anatomy). Called at the top of `build()`:

```dart
// lib/components/buttons/primary/nomo_primary_button.dart
final theme = getFromContext(context, this);   // PrimaryNomoButtonThemeData, all fields resolved
```

Resolution, highest precedence first:

1. **Widget constructor parameter** — e.g. `PrimaryNomoButton(backgroundColor: …)`. Applied last: `widget.field ?? themeData.field`.
2. **Local subtree override** — nearest `<Component>ThemeOverride` InheritedWidget carrying a `<Component>ThemeDataNullable` (e.g. `PrimaryNomoButtonThemeOverride(data: PrimaryNomoButtonThemeDataNullable(...))`). Applied via `themeData.copyWith(themeOverride)`.
3. **Global theme** — `NomoTheme.maybeOf(context)?.componentColors.<name>Color` / `.componentSizes.<name>Sizing` / `.constants.<name>Theme`. This value is itself the 3-layer merge described in §2.1 (per-theme `buildComponents` > delegate defaults > kit `predefinedComponent…` > annotation defaults).
4. **Generated defaults** — if no `NomoTheme` is in scope at all, `const <Component>ColorData()` / `SizingData()` / `Constants()` whose constructor defaults are the literal values from the `@NomoColorField/@NomoSizingField/@NomoConstant` annotations (e.g. primary button `backgroundColor = primaryColor`, the hardcoded `0xFFBCA570`).

Generated resolver excerpt (`nomo_primary_button.theme_data.g.dart:254-280`):

```dart
final globalColorTheme  = NomoTheme.maybeOf(context)?.componentColors.primaryButtonColor
    ?? const PrimaryNomoButtonColorData();
final globalSizingTheme = NomoTheme.maybeOf(context)?.componentSizes.primaryButtonSizing
    ?? const PrimaryNomoButtonSizingData();
const globalConstants   = PrimaryNomoButtonConstants();          // no @NomoConstant fields
final themeOverride     = PrimaryNomoButtonThemeOverride.maybeOf(context);
final themeData = PrimaryNomoButtonThemeData
    .from(globalColorTheme, globalSizingTheme, globalConstants)
    .copyWith(themeOverride);
return PrimaryNomoButtonThemeData(
  backgroundColor: widget.backgroundColor ?? themeData.backgroundColor,
  /* … every field … */);
```

Widgets may still post-process resolved values (e.g. `PrimaryNomoButton` swaps in `context.colors.error` for `ActionType.danger` and `context.colors.disabled/onDisabled` for disabled states — these bypass the component theme).

## 9. Light/dark/custom theme composition — worked example

From `example/lib/theme.dart` (`AppThemeDelegate extends NomoThemeDelegate<ColorMode, SizingMode>`):

- `getColorThemes()` returns `{LIGHT: NomoColorThemeDataNullable(key: ValueKey('light'), colors: NomoColors(...)), DARK: …}`. Light and dark differ only in their `NomoColors` values; component looks follow automatically through `predefinedComponentColors(core)`.
- Per-theme component tweaks go in `buildComponents:` (e.g. a dark theme could set `cardColor: NomoCardColorDataNullable(border: …)`).
- `getSizingThemes()` returns SMALL/MEDIUM/LARGE with escalating font sizes/spacings; SMALL sets `scaffoldSizing: NomoScaffoldSizingDataNullable(showSider: false)`, MEDIUM/LARGE set `siderSizing.width = 200`, LARGE sets `maxContentWidth: 1000`.
- `sizingThemeBuilder(width)` → `<600: SMALL, <1080: MEDIUM, else LARGE`.
- Theme keys (`ValueKey('light')` etc.) are the identity used for `==`; switching modes animates via `NomoThemeData.lerp` over 400 ms.

Switching at runtime: `context.themeProvider.changeColorTheme(ColorMode.DARK)`. Current mode: `context.getColorMode<ColorMode>()`.

## 10. Observations relevant to a rewrite

- Two parallel InheritedWidgets (`ThemeProvider` for control, `NomoTheme` for data) with different notify semantics is easy to misuse; `themeOf` exposes modes as `Object` requiring unchecked casts.
- Sub-theme equality by `ValueKey` only means value changes under the same key are invisible to `==`; conversely the animator creates a new `NomoThemeData` per frame, so effectively **every themed widget rebuilds every frame of the 400 ms transition**, and lerp walks all ~48 component data classes per frame.
- The color/sizing split is semantically arbitrary in places (`borderRadius`, `margin`, `elevation` are "color" fields; `showSider` is a "sizing" field) — it exists because color themes and sizing themes are switched on independent axes (mode vs. breakpoint).
- Constants registry (`NomoComponentConstants`) is handwritten and convention-coupled to generated lookups (`constants.inputTheme`), unlike the generated color/sizing registries.
- `NomoColors.fromJson/toJson` exists only on the core palette (used by the Nomo app for persisted custom themes) — component overrides are not serializable.
