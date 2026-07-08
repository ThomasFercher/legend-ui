# 07 — Utilities, Icons, Entities, Animations & Public API Surface

Package: `nomo_ui_kit` v0.0.36 (repo root `/Users/thomas/src/legend-ui`).
All paths below are relative to the repo root unless absolute.

> **Repo-layout caveat:** `CLAUDE.md` describes a monorepo with `/packages/nomo-ui-kit/` and
> `/packages/nomo-ui-kit-generator/`, but this checkout **is the UI-kit package itself** — there is
> no `packages/` directory. The generator is a path dependency to a *sibling* repo
> (`pubspec.yaml`: `nomo_ui_generator: path: ../nomo-ui-kit-generator`). Any rewrite tooling must
> not assume the CLAUDE.md layout.

---

## 1. Public API surface (`lib/nomo_ui_kit_base.dart`)

The barrel file is **two lines**:

```dart
export './app/nomo_app.dart';
export './icons/nomo_icons.dart';
```

That is the *entire* curated export surface. `app/nomo_app.dart` itself contains only `import`s
(no re-`export`s), so importing the barrel gives you exactly: `NomoApp`,
`kThemeChangeDuration` / `kThemeChangeCurve`, and the full `NomoIcons` class +
`allIcons` map (via the `part` file).

**The real public API is the whole `lib/` tree.** There is **no `lib/src/`**, so every one of the
**102 Dart files** (29 of them generated `*.g.dart`) is importable and therefore public API by Dart
convention. Consumers (including the example app) deep-import
`package:nomo_ui_kit/components/...` directly. Nothing is hidden — every render box, layout
delegate, and generated theme class is reachable. This is the single biggest API-hygiene issue to
fix in a rewrite: define a curated barrel and move implementation under `src/`.

### Effective public surface, grouped by category

| Category | Files (under `lib/`) | Key public symbols |
|---|---|---|
| **App shell** | `app/nomo_app.dart`, `app/animator.dart`, `app/metric_reactor.dart`, `app/notifications/app_notification.dart` | `NomoApp`, `kThemeChangeDuration`, `kThemeChangeCurve`, animator/metric internals |
| **App components** | `components/app/app.dart`, `app_bar/*` (+ layout delegate/renderbox), `bottom_bar/*`, `routebody/*`, `scaffold/*` (+ `nomo_scaffold_layout.dart`), `sider/*` | `NomoAppBar`, `NomoBottomBar`, `NomoHorizontalTile`, `NomoRouteBody`, `NomoScaffold`, `NomoSider` |
| **Buttons** | `components/buttons/base|link|primary|secondary|text/*` | `NomoButton` (base), `NomoLinkButton`, `PrimaryNomoButton`, `SecondaryNomoButton`, `NomoTextButton` |
| **Display** | `components/card/*` (+ `card_const.dart`), `dialog/*`, `divider/*`, `elevatedBox/elevated_box.dart`, `expandable/*`, `info_item/*`, `nomo_elevation/*`, `notification/*`, `outline_container/*`, `snackbar/*`, `data/nodata/no_data.dart` | `NomoCard`, `NomoDialog`, `NomoDivider`, `ElevatedBox`, `Expandable`, `NomoInfoItem`, `NomoElevation`, `NomoNotification`, `NomoOutlineContainer`, `NomoSnackbar`, `NoData` |
| **Menus/overlays** | `components/context_menu/context_menu.dart`, `dropdown_button/*`, `dropdownmenu/*` (+ `drop_down_item.dart`), `modal_sheet/modal_sheet.dart`, `vertical_menu/*` | `ContextMenu`, `NomoDropdownButton`, `NomoDropdownMenu`, `ModalSheet`, `NomoVerticalMenu`, `NomoVerticalTile` |
| **Input** | `components/input/textInput/nomo_input.dart` (+ `text_layout.dart`), `input/form/nomo_form.dart`, `input/cupertino_text_input.dart` | `NomoInput`, `NomoForm`, Cupertino text-input port |
| **Switch/loading/text** | `components/switch/*`, `loading/*` (incl. `shimmer/*`, `fade_in.dart`, `loading_container.dart`), `text/nomo_text.dart` | `NomoSwitch`, (Cupertino switch port), `Loading`, `Shimmer`, `FadeIn`, `NomoText` |
| **Layout** | `components/layout/dynamic_row/dynamic_row.dart` | `DynamicRow` |
| **Theme** | `theme/nomo_theme.dart`, `theme/theme_extension.dart`, `theme/theme_provider.dart`, `theme/sub/*` (color/sizing/typography/constants + `.g.dart`) | `NomoTheme`, color/sizing/typography themes, context extensions |
| **Icons** | `icons/nomo_icons.dart`, `icons/nomo_icons.g.dart`, `icons/icon_data.dart` | `NomoIcons` (2,716 consts), `allIcons`, `IconDataBrands/Solid/Regular/Light/Duotone/Thin` |
| **Entities** | `entities/nomo_decoration.dart`, `entities/menu_item.dart` | `NomoDecoration`, `NomoMenuItem` + 4 subclasses |
| **Utils** | `utils/extensions.dart`, `utils/layout_extensions.dart`, `utils/multi_wrapper.dart`, `utils/tweens.dart`, `utils/platform_info/*` (5 files) | see §2–§5 |
| **Animations** | `animations/implicit/animated_nomo_default_textstyle.dart` | `AnimatedNomoDefaultTextStyle` |
| **Generated theme data** | 22 `*.theme_data.g.dart` files next to their components | `<Component>ThemeData`, `...ThemeDataNullable`, `...ThemeOverride` per component |

Every component's *generated* theme classes are public too — the generated surface is roughly as
large as the hand-written one.

---

## 2. Extension methods

### 2.1 `lib/utils/extensions.dart` (3 extensions)

| Extension | Receiver | Member | What it does |
|---|---|---|---|
| `NotifierUtil<T>` | `ValueNotifier<T>` | `update(T Function(T) updater)` | Functional in-place update: `value = updater(value)`. |
| `ColorExtension` | `Color` | `toHexColor()` → `String` | Returns `'0x'`-prefixed 8-digit ARGB hex via `toARGB32()` (Flutter ≥3.27 API — pins the min Flutter version). |
| `NomoThemeExtension` | `NomoColors` | `materialTheme` → `ThemeData` | Bridges the Nomo color theme into a Material `ThemeData`/`ColorScheme` (used to theme embedded Material widgets). Maps `foreground1` → both `onSurface` and `onError`. |

### 2.2 `lib/utils/layout_extensions.dart` (5 extensions)

| Extension | Receiver | Member | What it does |
|---|---|---|---|
| `LayoutExtensionWidget` | `Widget` | `wrapIf(bool, Widget Function(Widget))` | Conditionally wraps the widget; returns `this` otherwise. |
| | | `wrapIfElse(bool, wrapper, {required elseWrapper})` | Wraps with one of two wrappers depending on the condition. |
| `LayoutExtensionSizing` | `num` | `spacing` → `SizedBox` | Square `SizedBox(width: n, height: n)`. |
| | | `vSpacing` → `SizedBox` | `SizedBox(height: n)` — used pervasively, e.g. `16.vSpacing`. |
| | | `hSpacing` → `SizedBox` | `SizedBox(width: n)`. |
| `DynamicArgumentExtension<T>` | any `T` | `when(bool)` → `T?` | Returns `this` if condition true, else `null`. Handy for optional named args. |
| | | `whenElse(bool, T elseValue)` → `T` | Ternary-as-extension. |
| `RowToColumn` | `Row` | `toColumn(BuildContext)` → `Flex` | If `MediaQuery` width > **hard-coded 1200**, rebuilds a `Row` from `children`; else a `Column(crossAxisAlignment: start)`. Misnamed (it also builds Rows) and drops all other Row properties (alignment, mainAxisSize...). |
| `FlexUtil` | `List<Widget>` | `spacingH(double)` | Interleaves `SizedBox(width: s)` between items. |
| | | `spacingV(double)` | Interleaves `SizedBox(height: s)` between items. |
| | | `spacing(double)` | Interleaves square `SizedBox(width: s, height: s)`. |

**Quirks / hotspots:**
- The three `FlexUtil` methods use `indexOf(w) != length - 1` to skip the trailing spacer —
  **O(n²)** and **wrong with duplicate widget instances** (e.g. two `const SizedBox.shrink()`
  entries: `indexOf` finds the first occurrence, so a spacer is emitted after the true last
  element, or omitted mid-list). A rewrite should index-iterate (or use Flutter 3.27+
  `Row(spacing:)` and delete these entirely).
- `DynamicArgumentExtension` is declared `on T` for *any* type — it pollutes every object's
  namespace (`anything.when(...)` autocompletes everywhere).
- `CLAUDE.md`'s examples (`const SizedBox(height: 16).vSpacing`, `items.spacingV(12)`) show
  `.vSpacing` applied to a `SizedBox`, which doesn't compile — the receiver is `num`. The docs are
  stale relative to the code.
- Note: `spacing`/`vSpacing`/`hSpacing` live in `layout_extensions.dart`, not `extensions.dart`.

---

## 3. `MultiWrapper` (`lib/utils/multi_wrapper.dart`)

```dart
typedef Wrapper = Widget Function(Widget child);

class MultiWrapper extends StatelessWidget {
  final List<Wrapper> wrappers;
  final Widget child;
  // build: wrappers.fold(child, (child, wrapper) => wrapper(child));
}
```

A 18-line stateless widget that folds a list of wrap functions over `child`. Order: `wrappers[0]`
is applied first (innermost), the last wrapper ends up outermost. Used by `NomoApp`
(`lib/app/nomo_app.dart` imports it) to compose app-level wrappers. Trivial to carry over or
inline in a rewrite.

---

## 4. Custom tweens (`lib/utils/tweens.dart`)

Exactly one tween:

| Class | Extends | Notes |
|---|---|---|
| `BoxDecorationTween` | `Tween<BoxDecoration>` | `lerp` delegates to `BoxDecoration.lerp(begin, end, t)!` (non-null assert — throws if both ends null). Extras beyond Flutter's own `DecorationTween`: `copyWith({begin, end})` and `add(BoxDecoration newEnd)` which shifts `begin := end, end := newEnd` — used to chain decoration animations (button hover/press states). |

**Quirk:** Flutter already ships `DecorationTween`; this exists to be typed to `BoxDecoration`
and to support the `add()` re-targeting pattern used by `NomoButton`
(`lib/components/buttons/base/nomo_button.dart`). Name-collides with nothing in Flutter but is an
easy source of import confusion.

---

## 5. `PlatformInfo` conditional-import architecture (`lib/utils/platform_info/`, 5 files)

Classic Dart conditional-import trick to detect platform without importing `dart:io` on web:

1. **`platform_info_base.dart`** — `abstract class BasePlatformInfo` holding 10 final bools
   (`isDesktop, isCupertino, isMaterial, isWeb, isLinux, isAndroid, isIOS, isMacOS, isWindows,
   isMobile`), all defaulting `false` except required `isWeb`.
2. **`platform_info_io.dart`** — `getInstance() => PlatformInfoIO()`; fills flags from `dart:io`
   `Platform`: `isCupertino = iOS || macOS`, `isDesktop = Linux || Windows || macOS`,
   `isMaterial = !(iOS || macOS)`, `isMobile = Android || iOS`.
3. **`platform_info_web.dart`** — `getInstance() => const PlatformInfoWeb()`; **only**
   `isWeb: true`, everything else false.
4. **`platform_info_unsupported.dart`** — `getInstance()` throws `UnsupportedError` (fallback
   stub when neither `dart:io` nor JS libs exist).
5. **`platform_info.dart`** — the facade:

```dart
import '...platform_info_unsupported.dart'
    if (dart.library.io) 'platform_info_io.dart'
    if (dart.library.js_interop) 'platform_info_web.dart'
    if (dart.library.html) 'platform_info_web.dart'
    if (dart.library.js) 'platform_info_web.dart';

abstract class PlatformInfo {
  static final _instance = getInstance();
  static bool get isDesktop => _instance.isDesktop;
  // ... one static getter per flag (10 total)
}
```

**Quirks / hotspots:**
- On web, **every flag except `isWeb` is false** — including `isMaterial` and `isDesktop`. Code
  branching on `isCupertino`/`isMaterial` silently gets "neither" on web; there is no
  browser-OS sniffing. Any rewrite should decide explicitly what web reports.
- `dart.library.io` is checked *first*, so under Wasm/JS the io branch never wins, but ordering
  matters and the triple JS condition (`js_interop`/`html`/`js`) is legacy cruft from pre-Wasm
  Flutter; with modern Flutter, `dart.library.js_interop` (or `kIsWeb`) suffices.
- This whole abstraction is largely replaceable by `defaultTargetPlatform` + `kIsWeb` from
  `flutter/foundation.dart` (theme-aware and testable via `debugDefaultTargetPlatformOverride`);
  `PlatformInfo` reads the *host* OS, not the target-platform override, so it breaks
  platform-override testing/golden tests.

---

## 6. Icon system (end-to-end)

### 6.1 Font families & assets

Copied from `font_awesome_flutter` (comment in `lib/icons/nomo_icons.dart`:
"Copied from https://github.com/fluttercommunity/font_awesome_flutter" — Font Awesome **6.4.2**).
Fonts are bundled in-package and registered in `pubspec.yaml` (lines 37–49) with
`fontPackage: 'nomo_ui_kit'`:

| Family | Asset | Weight | Size on disk |
|---|---|---|---|
| `FontAwesomeBrands` | `lib/icons/fonts/fa-brands-400.ttf` | 400 | 189,684 B (~185 KB) |
| `FontAwesomeRegular` | `lib/icons/fonts/fa-regular-400.ttf` | 400 | 63,348 B (~62 KB) |
| `FontAwesomeSolid` | `lib/icons/fonts/fa-solid-900.ttf` | 900 | 394,668 B (~385 KB) |
| **Total** | | | **647,700 B (~632 KB)** shipped with every app |

### 6.2 `lib/icons/icon_data.dart` — codepoint wrappers

Six `IconData` subclasses, each a `const` ctor taking a codepoint and hard-wiring
`fontFamily` + `fontPackage: 'nomo_ui_kit'`:
`IconDataBrands`, `IconDataSolid`, `IconDataRegular`, and — **dead code** —
`IconDataLight`, `IconDataDuotone` (with a `secondary: IconData?` field for the second glyph,
kept as `IconData` "due to tree-shaking restraints"), `IconDataThin`. The Light/Duotone/Thin
families are Font Awesome **Pro** and their fonts are *not* bundled, and no `NomoIcons` const
uses them — remove in the rewrite.

### 6.3 `lib/icons/nomo_icons.dart` — the catalog

- 14,530 lines / **515,338 bytes** of hand-copied constants.
- `class NomoIcons` annotated `@staticIconProvider` (Flutter's tree-shaking hint) and
  `@StaticFieldsList()` (custom annotation from `nomo_ui_generator` that triggers the
  reflection builder).
- **2,716 `static const IconData` fields**, of which **691 are `@Deprecated` aliases** pointing at
  a canonical const (e.g. `innosoft = fortyTwoGroup`), i.e. ~2,025 distinct icons.
  Each icon carries a doc comment with the fontawesome.com URL and search keywords.

### 6.4 `lib/icons/nomo_icons.g.dart` — reflection output

- Generated by the **ReflectionGenerator** (from the sibling `nomo_ui_generator` package) via the
  `@StaticFieldsList()` annotation; emitted as a `part of 'nomo_icons.dart'`.
- Contains a single top-level `const allIcons = {'zero': NomoIcons.zero, ...}` —
  **2,716 entries** (name-string → `IconData`), 2,730 lines / **106,023 bytes**. Deprecated
  aliases are included (file-level `ignore: deprecated_member_use_from_same_package`).
- `build.yaml` at repo root only excludes `example/**` and `test/**` from generation sources.

### 6.5 Usage & implications

- The only in-repo consumer of `allIcons` is the example gallery
  (`example/lib/sections/icon_section.dart:10`: `final icons = allIcons.entries.toList()`).
- **Tree-shaking hazard:** `@staticIconProvider` lets Flutter shake unused glyphs from the fonts,
  but `allIcons` **references every single const by name**, so any app that imports
  `nomo_icons.dart` (which the barrel does, and the `part` is unconditional) keeps all 2,716
  `IconData` objects live in the compiled code, and icon-font tree-shaking of glyphs referenced
  through the map is defeated (`--no-tree-shake-icons` territory). Memory cost of the const map
  is modest, but binary/code-size cost and the ~632 KB of TTFs are paid by every consumer.
- **Rewrite recommendation:** drop the copied FA catalog entirely (depend on
  `font_awesome_flutter` or a trimmed custom subset), and if a name→icon map is needed for a
  gallery, generate it *in the example app only*, not inside the library.

---

## 7. Entities (`lib/entities/`)

### 7.1 `NomoDecoration` (`nomo_decoration.dart`)

`class NomoDecoration extends BoxDecoration` — a `BoxDecoration` that computes its `boxShadow`
from elevation-style parameters instead of taking a shadow list:

- Extra fields: `elevation` (default 0), `elevationOffset` (`Offset.zero`),
  `blurRadiusK` (default 2), `spreadRadiusK` (default 0), `shadowColor` (`Colors.black12`).
- `static getBoxShadow(...)` returns `[BoxShadow(spreadRadius: spreadRadiusK * elevation,
  blurRadius: blurRadiusK * elevation, offset: offset)]` when `elevation > 0`, else an
  empty list (despite the `List<BoxShadow>?` return type it never returns null).
- **Quirks:** non-const ctor (super ctor computes shadow at construction), so it can't be used in
  const contexts like `BoxDecoration` can. `copyWith`/`lerp` inherited from `BoxDecoration`
  return plain `BoxDecoration`s, silently losing the elevation semantics — lerping two
  `NomoDecoration`s (e.g. via `BoxDecorationTween`, §4) degrades to shadow-list interpolation
  and any `copyWith` drops the `elevation` knobs. A rewrite should model elevation in the theme
  layer, not by subclassing `BoxDecoration`.

### 7.2 `NomoMenuItem` (`menu_item.dart`)

`@immutable sealed class NomoMenuItem<T>` with fields `title` (String), `key` (`T`, the
selection value — *not* a widget `Key`), `subtitle?`, **`trailling?`** (Widget — note the
**misspelling**, it's part of the public API), `leading?` (Widget), and `children?`
(`List<NomoMenuItem<T>>?` for nested/expandable menus). Equality/hashCode use only
`title` + `key` (children/widgets ignored).

Four final subclasses:

| Class | Extra fields | Purpose |
|---|---|---|
| `NomoMenuWidgetItem<T>` | `Widget child` | Arbitrary widget item |
| `NomoMenuTextItem<T>` | — | Text-only (notably does **not** forward `children` — text items can't nest) |
| `NomoMenuIconItem<T>` | `IconData icon` | Icon + text |
| `NomoMenuImageItem<T>` | `String imagePath`, `double? size` | Image asset + text |

Consumed by `NomoBottomBar`, `NomoSider`/`NomoVerticalMenu`, dropdowns
(`lib/components/app/bottom_bar/nomo_bottom_bar.dart`,
`lib/components/vertical_menu/nomo_vertical_menu.dart`, etc.).
**Rewrite notes:** fix `trailling` → `trailing`; reconsider `key` naming (clashes conceptually
with `Widget.key`); equality ignoring `children` means structural menu changes with same
title/key won't be detected by ==.

---

## 8. Animations (`lib/animations/`)

Single file: `implicit/animated_nomo_default_textstyle.dart` (62 lines) —
`AnimatedNomoDefaultTextStyle extends ImplicitlyAnimatedWidget`, animating a `TextStyle` and
providing it to descendant `NomoText`s (a `NomoDefaultTextStyle` analog of Flutter's
`AnimatedDefaultTextStyle`). Covered in depth in the text/typography chapter; listed here only
for completeness of the `lib/` inventory.

---

## 9. Stragglers / full-inventory notes

All 102 `lib/**/*.dart` files are accounted for by the table in §1. Files easy to miss:

- `lib/components/card/card_const.dart` — card constants split out of `nomo_card.dart`.
- `lib/components/app/app.dart` — an app-components aggregate under `components/app/`.
- `lib/components/app/scaffold/nomo_scaffold_layout.dart`,
  `lib/components/app/app_bar/layout/appbar_layout_delegate.dart`,
  `appbar_layout_renderbox.dart` — custom layout plumbing that is public only by accident.
- `lib/components/input/cupertino_text_input.dart` and
  `lib/components/switch/cupertino_switch.dart` — forked Cupertino widgets (maintenance
  liability: they drift from upstream Flutter).
- `lib/components/loading/fade_in.dart`, `loading/shimmer/loading_container.dart` — small helper
  widgets with no theme file.
- `lib/theme/sub/nomo_constants.dart` — theme constants.
- 22 `*.theme_data.g.dart` + `nomo_color_theme.g.dart`, `nomo_sizing_theme.g.dart`,
  `nomo_icons.g.dart` + generated parts = 29 generated files checked into the repo.

## 10. Complexity hotspots for the rewrite (summary)

1. **No `src/` layer; 2-line barrel** — the de-facto API is all 102 files; generated theme
   classes double the surface. Curate exports first.
2. **Icon catalog is a vendored fork** of font_awesome_flutter 6.4.2: 515 KB source file,
   2,716 consts (691 deprecated), 106 KB generated `allIcons` map that defeats icon
   tree-shaking, ~632 KB of TTFs, plus dead Pro-tier `IconData` classes.
3. **`PlatformInfo`** reads host OS, returns all-false flags on web, ignores
   `defaultTargetPlatform` overrides; replace with `kIsWeb` + `defaultTargetPlatform`.
4. **`FlexUtil.spacing*`** `indexOf`-based interleaving is O(n²) and duplicate-unsafe; Flutter's
   native `Row/Column(spacing:)` obsoletes it.
5. **`NomoDecoration`** loses its elevation semantics through inherited `copyWith`/`lerp`.
6. **`trailling` typo** baked into the `NomoMenuItem` public API.
7. **CLAUDE.md drift**: wrong repo layout, and spacing-extension examples that don't compile
   against the actual receivers.
