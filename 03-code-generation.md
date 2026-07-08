# Nomo UI Kit — Code Generation Architecture

> Documentation of the build_runner-based generation pipeline used by `nomo_ui_kit` (`/Users/thomas/src/legend-ui`). Companion document: `02-theme-system.md`.

## 1. The generator package

`pubspec.yaml` declares a **path dependency**:

```yaml
nomo_ui_generator:
  path: ../nomo-ui-kit-generator
```

That directory does **not exist on this machine** (`/Users/thomas/src/nomo-ui-kit-generator` is missing, so `pub get` would currently fail). However the same package is published and cached at
`/Users/thomas/.pub-cache/hosted/pub.dev/nomo_ui_generator-0.0.3/`, and this documentation is based on that source. Package contents:

| File | LOC | Role |
|---|---|---|
| `lib/annotations.dart` | 33 | All annotation classes (pure markers). |
| `lib/builder.dart` | ~10 | Entry point: `themeDataBuilder` → `PartBuilder([ComponentThemeDataGenerator()], '.theme_data.g.dart')`. |
| `lib/util_builder.dart` | ~12 | Entry points: `themeUtilsBuilder` → `SharedPartBuilder([ThemeUtilGenerator()], 'theme_utils')`; `reflectionBuilder` → `SharedPartBuilder([ReflectionGenerator()], 'reflection')`. |
| `lib/src/theme_data_generator.dart` | 704 | Per-component theme data classes + resolver (the big one). |
| `lib/src/theme_util_generator.dart` | 127 | Aggregate `NomoComponentColors` / `NomoComponentSizes` registries. |
| `lib/src/reflection_generator.dart` | 33 | Static-field reflection map (icons). |
| `lib/src/model_visitor.dart` | 150 | Element visitor that extracts annotated fields **by string-parsing annotation source**. |

Total generator implementation: **~1,050 LOC** producing **9,586 LOC** of generated Dart in the kit.

### 1.1 `build.yaml` of the generator package

```yaml
builders:
  theme_data_builder:
    builder_factories: ["themeDataBuilder"]
    build_extensions: {".dart": ["theme_data.g.dart"]}
    auto_apply: dependents
    build_to: source                      # generated files are CHECKED IN
    runs_before: ["theme_utils_builder"]  # ordering: data before aggregates
  theme_utils_builder:
    builder_factories: ["themeUtilsBuilder"]
    build_extensions: {".dart": ["theme_utils.g.part"]}
    auto_apply: dependents
    build_to: cache                       # merged into *.g.dart by source_gen combining_builder
    required_inputs: ["theme_data.g.dart"]
  reflection_builder:
    builder_factories: ["reflectionBuilder"]
    build_extensions: {".dart": ["reflection.g.part"]}
    auto_apply: dependents
    build_to: cache
```

The kit's own `/Users/thomas/src/legend-ui/build.yaml` only excludes inputs:

```yaml
targets:
  $default:
    sources:
      exclude: ["example/**", "test/**"]
```

Because `auto_apply: dependents`, any package depending on `nomo_ui_generator` (i.e. `nomo_ui_kit`) gets all three builders automatically. `theme_data_builder` writes real `*.theme_data.g.dart` files to source (they are committed); the other two emit `.g.part` fragments that source_gen's `combining_builder` merges into a single `<file>.g.dart` (e.g. `nomo_color_theme.g.dart`, `nomo_icons.g.dart`).

## 2. Annotation contract (`nomo_ui_generator/lib/annotations.dart`)

| Annotation | Target | Fields | Meaning |
|---|---|---|---|
| `@NomoComponentThemeData(String themeName)` | widget class | `themeName` e.g. `'primaryButton'` | Triggers `ComponentThemeDataGenerator`. `themeName` is the *lookup key prefix* on the aggregate theme: resolver reads `componentColors.<themeName>Color`, `componentSizes.<themeName>Sizing`, `constants.<themeName>Theme`. |
| `@NomoColorField<T>(T value, {bool lerp = true})` | widget field | default value + lerp flag | Field belongs to the component's **ColorData** (switched with color mode, lerped during transitions unless `lerp: false`). |
| `@NomoSizingField<T>(T value, {bool lerp = true})` | widget field | same | Field belongs to **SizingData** (switched with responsive sizing mode). |
| `@NomoConstant<T extends Object>(T value)` | widget field | default value | Field belongs to **Constants** (never lerped, one global value). |
| `@NomoThemeUtils(String name)` | a `const _ = [TypeA, TypeB, …]` top-level list | aggregate class name | Triggers `ThemeUtilGenerator` to build the aggregate registry (`NomoComponentColors` / `NomoComponentSizes`). |
| `@StaticFieldsList()` | class with static const fields | — | Triggers `ReflectionGenerator` (name → value map). Used with `@staticIconProvider` (Flutter SDK annotation for icon tree-shaking) on `NomoIcons`. |

Usage counts in `lib/` (this repo): `@NomoColorField` ×101, `@NomoSizingField` ×63, `@NomoComponentThemeData` ×26, `@NomoConstant` ×11, `@NomoThemeUtils` ×2, `@StaticFieldsList`/`@staticIconProvider` ×1 each.

### 2.1 Authoring pattern on a widget

```dart
// lib/components/buttons/primary/nomo_primary_button.dart
part 'nomo_primary_button.theme_data.g.dart';

@NomoComponentThemeData('primaryButton')
class PrimaryNomoButton extends StatelessWidget with NomoButtonMixin {
  @NomoColorField(primaryColor)                    // default from a const in nomo_theme.dart
  final Color? backgroundColor;
  @NomoColorField(Colors.white)
  final Color? foregroundColor;
  @NomoColorField(1.0)
  final double? elevation;                         // "color" field despite being a double
  @NomoSizingField<EdgeInsetsGeometry>(EdgeInsets.all(16))
  final EdgeInsetsGeometry? padding;
  @NomoColorField<BorderRadiusGeometry>(BorderRadius.all(Radius.circular(8)))
  final BorderRadiusGeometry? borderRadius;
  @NomoColorField<Color?>(null)                    // explicit-null default => stays nullable
  final Color? splashColor;
  // …
  @override
  Widget build(BuildContext context) {
    final theme = getFromContext(context, this);   // generated resolver
    …
  }
}
```

Contract rules (enforced only by convention / generator behavior):

- Annotated fields must be declared **nullable** on the widget (`Color?`) so "not passed" is detectable; the generated resolved type is non-nullable **unless the annotation default is the literal `null`** (`ModelVisitor.getNullablePostfix`: type gets `?` iff the default's source text is `null`/`Null`).
- Default values must be **const expressions valid inside the part file's scope** — they are copied *verbatim as source text* into generated constructors (so `primaryColor` works only because `nomo_theme.dart` exports it and the widget file imports it).
- Generic argument selects the generated field type; without it the annotation value's static type is used, with two hardcoded rewrites (`ModelVisitor.typeOverride`): `EdgeInsets → EdgeInsetsGeometry`, `MaterialColor → Color`.
- `lerp: false` (and always for `bool`, `BoxShape`, `Widget` types) makes transition lerping snap at `t < 0.5`; `double` uses `lerpDouble`; every other type `T` must expose `static T lerp(a, b, t)`.
- `@NomoConstant` fields also appear as widget params and participate in the same resolution, but come from the handwritten `NomoComponentConstants` registry (see 02 doc §6).

### 2.2 How the visitor extracts values — a fragility hotspot

`ModelVisitor` (`model_visitor.dart`) does **not** use resolved constants for the default value. It takes `annotation.toSource()` (the literal source text), strips the annotation name, slices off the generic `<…>` by `indexOf('>')`, strips outer parens, and if the text `contains('lerp')` cuts at the **last comma**. Consequences:

- A default value whose source contains the substring `lerp` or relies on commas in unexpected places can be silently mis-parsed.
- Bug in the `@NomoConstant` branch: it does `replaceAll(sizingField, '')` (wrong constant name — harmless today only because `@NomoSizingField` never appears inside a `@NomoConstant` source string).
- Type names are extracted from `annotation.element.toString()` by angle-bracket slicing — nested generics would break.

## 3. Builder 1: `theme_data_builder` → `*.theme_data.g.dart`

Generator: `ComponentThemeDataGenerator extends GeneratorForAnnotation<NomoComponentThemeData>` (`theme_data_generator.dart`). For each annotated widget `X` with themeName `n`, it emits — in this order — **10 declarations**:

| # | Generated item | Contents |
|---|---|---|
| 1 | `class XColorDataNullable` | one nullable field per `@NomoColorField`; const ctor, all optional. |
| 2 | `class XColorData implements XColorDataNullable` | non-nullable fields (nullable iff default is `null`); const ctor with **annotation defaults**; `static XColorData lerp(a,b,t)`; `static XColorData overrideWith(base, [nullable])` (field-wise `override?.f ?? base.f`). |
| 3 | `class XSizingDataNullable` | same shape for `@NomoSizingField`s. |
| 4 | `class XSizingData implements XSizingDataNullable` | ctor defaults + `lerp` + `overrideWith`. |
| 5 | `class XConstantsNullable` | for `@NomoConstant`s (often empty). |
| 6 | `class XConstants implements XConstantsNullable` | ctor defaults; **no lerp/overrideWith**. |
| 7 | `class XThemeData implements XColorData, XSizingData, XConstants` | union of all fields; ctor with all defaults; `factory XThemeData.from(colors, sizing, constants)`; `XThemeData copyWith([XThemeDataNullable? override])`. |
| 8 | `class XThemeDataNullable implements <all three nullable>` | all-nullable union; the type users pass to overrides. |
| 9 | `class XThemeOverride extends InheritedWidget` | carries `XThemeDataNullable data`; `of` / `maybeOf`; `updateShouldNotify: oldWidget.data != data` (identity compare — the Nullable class has no `==`). |
| 10 | **top-level** `XThemeData getFromContext(BuildContext, X widget)` | full resolution: global (`NomoTheme.maybeOf` → `componentColors.nColor` / `componentSizes.nSizing` / `constants.nTheme`, each `?? const XxxData()`) → `.from(...)` → `.copyWith(themeOverride)` → per-field `widget.f ?? themeData.f`. If a section has no fields it uses `const` locals and skips the theme lookup. |

Concrete examples in-repo: `lib/components/buttons/primary/nomo_primary_button.theme_data.g.dart` (281 LOC from 9 annotated fields), `lib/components/app/scaffold/nomo_scaffold.theme_data.g.dart` (196 LOC from 4 fields; note `showSider`/`showBottomBar` bools snap in lerp), `lib/components/input/textInput/nomo_input.theme_data.g.dart` (361 LOC from 14 fields incl. 3 constants; constants resolved from `NomoTheme.maybeOf(context)?.constants.inputTheme`).

**Namespace hazard:** `getFromContext` is a *top-level function with the same name in every generated file*. Barrel files must `hide` it (`lib/components/app/app.dart`: `export './scaffold/nomo_scaffold.dart' hide getFromContext;` ×5), and two component files can't be imported together without hiding.

## 4. Builder 2: `theme_utils_builder` → aggregate registries

Generator: `ThemeUtilGenerator extends GeneratorForAnnotation<NomoThemeUtils>` (`theme_util_generator.dart`). Input is a top-level annotated const list of *generated* `*ColorData`/`*SizingData` types (hence `runs_before`/`required_inputs` ordering):

```dart
// lib/theme/sub/nomo_color_theme.dart
@NomoThemeUtils('NomoComponentColors')
const _ = [ NomoOutlineContainerColorData, NomoAppBarColorData, …, NomoSwitchColorData ]; // 25 types
```

Field names are derived mechanically: `typeName.replaceAll('Nomo','').replaceAll('Data','')`, lowerCamelCased → `NomoAppBarColorData` becomes `appBarColor`, `PrimaryNomoButtonSizingData` becomes `primaryButtonSizing`. (This derivation must line up with the `themeName` used in `@NomoComponentThemeData` — `'appBar'` + `Color`/`Sizing` suffix — another convention-only coupling.)

Emits into `nomo_color_theme.g.dart` / `nomo_sizing_theme.g.dart` (332 + 307 = 639 LOC):

1. `NomoComponentColors lerpNomoComponentColors(a, b, t)` — delegates to each type's `lerp`.
2. `class NomoComponentColorsNullable` — all fields `XColorDataNullable?`.
3. `class NomoComponentColors implements …Nullable` — all fields non-null, each defaulting to `const XColorData()` (i.e. annotation defaults).
4. `extension NomoComponentColorsOverride` — `overrideWith(nullable)` delegating to each type's `overrideWith`.

These are exactly the types the theme system composes in `NomoThemeDelegate._createColorThemes` (see 02 doc §2.1).

## 5. Builder 3: `reflection_builder` → `nomo_icons.g.dart`

Generator: `ReflectionGenerator extends GeneratorForAnnotation<StaticFieldsList>` (33 LOC). Input: `lib/icons/nomo_icons.dart` (14,530 LOC — Font Awesome 6.4.2 code points copied from `font_awesome_flutter`, ~2,700 `static const IconData` fields on `class NomoIcons`, typed via `IconDataSolid/Regular/Brands` from `lib/icons/icon_data.dart` which bind the three bundled FA font families declared in `pubspec.yaml`).

Output: `lib/icons/nomo_icons.g.dart` (2,730 LOC), a single string→IconData map:

```dart
const allIcons = { 'zero': NomoIcons.zero, 'one': NomoIcons.one, … };
```

Purpose: runtime lookup of icons by name (e.g. icon pickers / server-driven UI in the Nomo app). Note `@staticIconProvider` keeps Flutter's icon tree-shaker working despite the map.

## 6. Developer workflow

Adding/altering a themed component (from repo `CLAUDE.md` + observed structure):

1. Create/edit the widget; annotate class with `@NomoComponentThemeData('name')` and fields with `@NomoColorField/@NomoSizingField/@NomoConstant`; add `part '<file>.theme_data.g.dart';`; call `getFromContext(context, this)` in `build()`.
2. **Manually register** the new `XColorData` / `XSizingData` types in the two `@NomoThemeUtils` lists (`lib/theme/sub/nomo_color_theme.dart` and `nomo_sizing_theme.dart`); optionally add defaults to `predefinedComponentColors/Sizes`; if it has constants, **manually add a field** to `NomoComponentConstants` in `lib/theme/sub/nomo_constants.dart` named `<themeName>Theme`.
3. Run `flutter pub run build_runner build --delete-conflicting-outputs` from the kit root (watch mode available). Rerun whenever annotated fields, defaults, the `@NomoThemeUtils` lists, or `NomoIcons` change. `--delete-conflicting-outputs` is routinely needed because outputs are committed (`build_to: source`).
4. Export hygiene: add `hide getFromContext` when re-exporting the component from barrels.
5. Example app has its own build_runner pass (route generation via `nomo_router`, unrelated to theming).

Failure modes requiring regeneration are silent until compile: stale `.theme_data.g.dart` files still compile against old fields; the aggregate `.g.dart` can compile against stale component data classes.

## 7. Volume / complexity accounting (real counts, this repo)

| Category | Files | LOC |
|---|---|---|
| Generated per-component theme data (`*.theme_data.g.dart`) | 26 | **6,217** |
| Generated aggregates (`nomo_color_theme.g.dart` + `nomo_sizing_theme.g.dart`) | 2 | **639** |
| Generated icon reflection (`nomo_icons.g.dart`) | 1 | **2,730** |
| **All generated code in `lib/`** | 29 | **9,586** |
| Handwritten `lib/` code (non-`.g.dart`) | — | **26,985** |
| …of which icon codepoint tables (`lib/icons/`, themselves copied/mechanical) | — | 14,607 |
| Handwritten excluding `lib/icons/` | — | **12,378** |
| The 26 annotated widget sources | 26 | 4,845 |
| Generator implementation (external package) | 7 | ~1,050 |

Ratios worth quoting:

- Generated code is **26% of all Dart in `lib/`**; against *meaningful* handwritten code (excluding the copied icon tables) it is **9,586 vs 12,378 ≈ 0.77 : 1** — nearly one generated line per handwritten line.
- The 175 annotated theme fields (101 color + 63 sizing + 11 constant) expand to 6,217 LOC ≈ **35 generated LOC per themed property**, or ~239 LOC per component (min ~120, max 446 for `nomo_vertical_menu`).
- Each themed property's name is repeated **~18–20 times** across the generated classes (field decls ×6 classes, ctors ×6, lerp, overrideWith ×2, `.from`, `copyWith`, resolver ×2).

## 8. Pain points / complexity costs (rewrite input)

1. **String-parsed annotation values (highest risk).** Defaults and types are extracted by slicing `toSource()` text (`model_visitor.dart`): angle-bracket index math, "cut at last comma if the text contains `lerp`", a `replaceAll` on the wrong constant in the `@NomoConstant` branch, hardcoded `EdgeInsets→EdgeInsetsGeometry`/`MaterialColor→Color` rewrites, and nullability decided by whether the default's literal text is `null`. Any unusual-but-valid const expression can silently generate wrong code.
2. **Four hand-maintained convention couplings** with no static checks until the build breaks (or worse, doesn't): (a) `themeName` ↔ aggregate field derivation (`'primaryButton'` ↔ `PrimaryNomoButtonColorData`→`primaryButtonColor`); (b) new components must be hand-added to both `@NomoThemeUtils` lists; (c) constants must be hand-added to `NomoComponentConstants` as `<themeName>Theme`; (d) widget fields must be nullable and mirrored in the constructor by hand.
3. **Per-component boilerplate explosion**: 10 generated declarations per component (~35 LOC per property, names repeated ~20×), all committed to source (`build_to: source`) with attendant merge conflicts and staleness risk; plus the top-level `getFromContext` name collision forcing `hide getFromContext` in every barrel export.
4. **Whole-theme lerp animation**: theme switches tween the *entire* `NomoThemeData` (25 color + 23 sizing component classes) every frame for 400 ms, invalidating every `NomoTheme` dependent each frame.
5. **Semantic drift of the color/sizing split**: `elevation`, `borderRadius`, `margin` live in "color" data; booleans like `showSider` live in "sizing" data — the split really encodes *which mode axis switches the value*, not what it is.
6. **Two-phase build ordering** (`theme_data_builder` runs_before `theme_utils_builder` with `required_inputs`) plus a path dependency on a generator repo that isn't present on disk (`../nomo-ui-kit-generator`; only the pub.dev 0.0.3 snapshot exists in the pub cache) makes the build environment fragile to reproduce.

A rewrite could collapse most of this: Dart 3 patterns (or macros-era codegen, or simple generics like `ThemeExtension<T>`-style resolution with one generic `resolve<T>(widgetValue, override, global, default)` helper) can express the entire precedence chain in O(1) handwritten lines per property instead of ~35 generated ones, and a single registry object can replace the three parallel aggregates.
