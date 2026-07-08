# 09 — Rewrite Proposal: The Slim Approach

> Status: **theory / RFC** — this chapter proposes the architecture for the full rewrite.
> It is grounded in the problem inventory of [01 — Overview](01-overview.md) §4 and the detailed chapters. Nothing here is implemented yet.

## 1. Goals and non-goals

**Goals**

1. **Slim**: an order of magnitude less machinery per component — but *slim in what we write and maintain*, not necessarily in what is generated. Code generation stays: it saves real time and keeps component theming uniform. What must shrink is the fragility and convention-magic around it.
2. **Replace `nomo_ui_generator`, keep the codegen model**: the current generator implementation is retired (broken external path dependency, string-slicing of annotation source, unchecked naming conventions — see [03](03-code-generation.md)). Component themes remain **declared with decorators (annotations) on the widget itself** — the widget is the single source of truth from which theme data is generated.
3. **Configurability and defaults at every level**: the layered resolution model is the product. Every themed property must be settable at each of these levels, nearest wins:
   1. widget constructor parameter
   2. local subtree override (`…ThemeOverride`-style inherited widget)
   3. app-theme component override (per color/sizing mode)
   4. delegate/kit defaults
   5. annotation-declared default on the widget (derived from tokens)
4. **Self-contained repo**: `git clone && flutter pub get && flutter test` must work with no sibling checkouts. The generator lives *inside this repo*.
5. **Keep the good ideas**: delegate-driven color×sizing modes, responsive shell, near-zero runtime deps (see 01 §5).
6. **Honest API surface**: `lib/src/` + curated barrel, semver, no typos, tested, CI that runs.

**Non-goals**

- Visual redesign — the design language stays; this is an architecture rewrite.
- Backwards compatibility with legacy deep imports. The Nomo App migrates deliberately, component by component.
- Supporting Material's theming system. We interoperate with Material widgets where practical but do not mirror `ThemeData`.

## 2. Theming model: decorators on the widget, layers all the way down

The legacy insight worth keeping: **annotating the widget's fields and generating the theme plumbing from them** means a component's themable surface is declared exactly once, next to the code that uses it. The rewrite keeps this and fixes the implementation.

### 2.1 Design tokens (the global base layer)

A single immutable `NomoTokens` object holds the primitives — nothing component-specific:

```dart
class NomoTokens {
  final NomoColors colors;       // the 17 semantic colors (audited, possibly trimmed)
  final NomoSizes sizes;         // spacing scale, radii, border widths, icon sizes
  final NomoTypography type;     // b1–b3, h1–h3 (+ label/mono if needed)
  final NomoShadows shadows;     // ONE elevation system (replaces ElevatedBox vs NomoElevation split)
}
```

Handwritten once, with handwritten `copyWith`/`lerp`. Annotation defaults on components reference tokens, so a token change propagates to every component default without touching component code.

### 2.2 Declaring a component theme (the decorator contract)

The widget declares its themable properties inline — same spirit as legacy `@NomoComponentThemeData`, with a cleaned-up schema:

```dart
@NomoThemeable()
class PrimaryNomoButton extends StatelessWidget {
  /// Defaults are expressions over tokens (t), not baked literals.
  @Themed(defaultsTo: 't.colors.primary')
  final Color? background;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.sizes.radiusMd', lerp: false)
  final BorderRadius? radius;
  ...
}
```

Contract fixes relative to legacy (see 03 for the failure modes being fixed):

- **One annotation kind, typed by the field** — no more `@NomoColorField` vs `@NomoSizingField` bucket mix-ups (the wrong-bucket/color-lerping bug class disappears; the generator infers category from the Dart type and validates it).
- **All annotated constructor params are nullable with null defaults** — the generator *enforces* this, fixing the legacy bug where non-null constructor defaults made theme values unreachable.
- **Defaults are token expressions**, resolved at theme-build time, not frozen constants.
- **No naming conventions**: the generator discovers annotated widgets by scanning the source tree; registration lists (`@NomoThemeUtils`) are generated, never hand-maintained.

### 2.3 What gets generated per component

A leaner artifact set than legacy's ~10 (namespaced, so no colliding top-level `getFromContext` / no `hide` rituals):

| Artifact | Purpose |
|---|---|
| `PrimaryNomoButtonTheme` (style class) | all annotated fields, non-null, resolved |
| `PrimaryNomoButtonThemeNullable` | sparse overrides for levels 1–3 |
| `merge` / `copyWith` / `lerp` | layering + animated theme switches (`lerp` only for fields that opt in) |
| `PrimaryNomoButtonThemeOverride` | the level-2 inherited widget |
| `PrimaryNomoButtonTheme.of(context)` | static resolver walking levels 1→5 (replaces free-function `getFromContext`) |
| aggregate registry (one file, whole kit) | wires every component theme into `NomoThemeData`, generated — no manual lists |

The multi-level resolution semantics are **identical at every level of the stack**: an app can restyle one button subtree (level 2), reskin all buttons per theme mode (level 3), ship kit-wide defaults (level 4), or accept token-derived defaults (level 5) — and a plain constructor argument still always wins (level 1).

### 2.4 Decouple responsiveness and animation from theming

Two legacy design decisions multiply each other's cost: breakpoints are theme swaps, and theme swaps lerp *all* ~48 component classes at 60 fps (01 §4.1.3). The rewrite separates the three concerns:

- **Responsiveness**: a lightweight `NomoBreakpoints` InheritedModel exposing the current tier (`compact / medium / expanded`) and the raw width. Widgets and the shell read the tier directly; the *theme does not change* when the window resizes. Sizing values that genuinely vary per tier are expressed as `NomoResponsive<T>` values (`T resolve(tier)`) inside tokens.
- **Theme switching** (light/dark/brand): swaps `NomoTokens` and re-derives component themes. Animation lerps the token object once (plus the opt-in `lerp: true` component fields), instead of tweening 48 full data classes every frame.
- **Interaction animation** (hover/press/focus): stays inside components, driven by a shared interaction-state primitive (§3.1).

This removes `MetricReactor` + `ThemeAnimator` + the whole-app 400 ms rebuild storm, and fixes the stale-tween jump bug class by construction.

## 3. Component layer: fewer, composed primitives

The ~26 legacy components rebuild on top of **five kit-internal primitives** (all in `lib/src/primitives/`):

| Primitive | Replaces / fixes |
|---|---|
| `NomoSurface` (shape + border + shadow + clip) | Card, OutlineContainer, ElevatedBox **and** NomoElevation (two shadow systems → one) |
| `NomoInteractive` (tap/hover/focus/disabled states, semantics, ripple-free feedback) | Per-button reimplementations; fixes "disabled buttons are tappable"; removes the InkWell/Material dependency |
| `NomoOverlayEngine` (anchored + modal overlays, dismiss, animation, safe-area) | The three separate hand-rolled overlay systems (dropdown, context menu, notification) plus `showDialog` reliance; dialogs, sheets, menus, toasts, snackbars all route through it |
| `NomoTextCore` (styled text; explicit `NomoFittedText` variant if auto-fit returns) | NomoText's dead `fit` API — fit becomes a separate, honest widget instead of 7 dead params |
| `NomoFieldCore` (thin wrapper over Flutter's `EditableText`) | The 1,535-line CupertinoTextField fork and its broken slotted render box — we stop vendoring Flutter internals |

Public components then become thin compositions (`PrimaryNomoButton` = `NomoInteractive` + `NomoSurface` + slot layout), each carrying its `@NomoThemeable` declaration. Consolidations while porting:

- **One dropdown** (menu + button unified, one item model), **one switch** (no Cupertino fork — build on `NomoInteractive`), **one modal sheet** (actually implemented this time).
- **`NomoRouteBody` → `NomoBody`** with a single sliver-based mode; convenience constructors cover the legacy use cases instead of six exclusive flag-modes.
- Forms get a real lifecycle: field registration/unregistration, a working validity model, and an actual `NomoValidator` set (the API CLAUDE.md always claimed existed).
- All vendored third-party code (FadeIn, InAppNotification, switch/textfield forks) is dropped or rebuilt on the primitives (~3,500 LOC deleted).

## 4. Icons: unbundle

Legacy ships a 14.5k-line FontAwesome fork, ~632 KB of TTFs, and a reflection map that defeats icon tree-shaking for every consumer (07). The rewrite:

1. **Core kit ships no icon font.** Components accept `Widget`/`IconData` — the kit is icon-agnostic.
2. FontAwesome moves to an **optional sibling package** (`nomo_icons`), regenerated from upstream metadata, marked `@staticIconProvider`, with **no `allIcons` reflection map** in the library. Apps that need name→icon lookup (the icon-gallery use case) opt in via a separate deferred import or generate the map into their own app.
3. Result: consumers pay only for the glyphs they use; the kit loses ~17k LOC and 632 KB of assets.

## 5. The new generator: CLI-first, build_runner optional

The generator is rebuilt from scratch **inside this repo**. Requirements, each fixing a documented legacy failure (03):

| Requirement | Legacy failure it fixes |
|---|---|
| Parse via `package:analyzer` **AST**, never `toSource()` string-slicing | index-math default extraction, "cut at last comma if contains 'lerp'", the `@NomoConstant` `replaceAll` bug |
| Validate and **diagnose**: type/category mismatches, non-null annotated params, missing token references → hard errors with file:line | size fields silently landing in the color bucket and being color-lerped |
| **Zero naming conventions**: discovery by annotation scan; the aggregate registry is generated output, not hand-maintained input | themeName↔field derivation, `@NomoThemeUtils` manual lists, `<themeName>Theme` constant matching |
| Namespaced emission (static `.of()`, no top-level free functions) | 26 colliding `getFromContext` symbols, `hide` in every barrel |
| Deterministic, formatted, committed output | opaque regeneration diffs |

**Packaging — CLI first (recommended), build_runner as an optional wrapper:**

- **Primary: `dart run nomo_gen`** — an in-repo `tool/` CLI (or a `nomo_gen` package in this repo if we adopt a workspace layout). Run on demand while developing components (`nomo_gen watch` for iteration), output committed, freshness enforced by a CI step that reruns it and fails on diff. Consumers of the kit never install or run any codegen — they receive committed `.g.dart` files. No `build_runner`/`analyzer` version lock-step leaks into consumers' dev dependencies.
- **Optional later: a thin `build_runner` Builder** wrapping the same core library, for contributors who prefer `build_runner watch` integration. The parsing/emission core is packaging-agnostic, so this is additive, not a fork.
- Rationale for CLI-first: kit maintainers are the only codegen users; a CLI is faster to run, trivial to debug (plain `main()`), has no build-graph coupling, and matches how the icon tables (§4) are regenerated anyway — one tool, two subcommands (`nomo_gen themes`, `nomo_gen icons`).

Dart macros — which would have made annotations expand with zero tooling — were discontinued by the Dart team in early 2025, so an explicit generator remains the right call; the CLI keeps it as small and ownable as possible.

## 6. Package & repo structure

```
lib/
  nomo_ui_kit.dart          # THE barrel — the only supported import
  src/
    annotations/            # @NomoThemeable, @Themed — the decorator contract
    tokens/                 # NomoTokens, colors, sizes, typography, shadows, responsive values
    theme/                  # NomoTheme widget, NomoThemeData, delegate
    primitives/             # surface, interactive, overlay engine, text core, field core
    components/             # public components + their committed *.g.dart theme files
    shell/                  # NomoApp, NomoScaffold, app bar, sider, bottom bar, body
tool/
  nomo_gen/                 # the generator CLI (themes + icons), dev-only, in-repo
example/                    # gallery app — every component, no empty stubs
test/                       # required from day one (incl. generator golden tests)
```

- **`lib/src/` + single barrel** ends the deep-import free-for-all; everything exported is deliberate API (fixes 01 §4.1.5). Generated theme classes are re-exported through the barrel deliberately.
- Nothing outside this repo is needed to build; the old generator repo is archived.
- Router stays decoupled: the kit takes a `RouterConfig` like legacy `NomoApp`, but `NomoBody` loses its router-coupled `copyWith` (04).

## 7. Quality gates (day-one, not retrofit)

| Gate | Legacy status | Rewrite policy |
|---|---|---|
| Tests | zero | every primitive gets widget tests; components get golden tests; theme resolution gets unit tests; **the generator gets golden tests** (annotated fixture in → expected .g.dart out) |
| CI | two dead configs | one GitHub workflow on `main` + PRs: analyze, format, test, `dart run nomo_gen --check` (regenerate + fail on diff), example build |
| Lints | very_good_analysis (kept) | kept, no ignores without justification |
| Versioning | patch-only, no tags | semver + tags + CHANGELOG discipline; publishable structure even if `publish_to: none` initially |
| API hygiene | typos baked in | spell-checked public API; `dart doc` builds clean |

## 8. Migration & sequencing

1. **Phase 0 — validate the theory**: build `tokens/`, the annotation contract, and a **minimal `nomo_gen themes`** (parse one fixture widget, emit the §2.3 artifact set); port **one** hard component (PrimaryNomoButton) + one overlay (dropdown) end-to-end on it. Measure: handwritten LOC per component, generated LOC per property (target: well under legacy's ~35), resolution ergonomics at all five levels, theme-switch performance. Revisit §2/§5 if targets are missed.
2. **Phase 1 — primitives complete**: overlay engine, text core, field core; golden-test infrastructure; `nomo_gen` hardened (diagnostics, `--check`, watch mode).
3. **Phase 2 — component ports** in dependency order (buttons → surfaces → menus/selection → input/form → shell), consolidating duplicates per §3. Each port closes out the corresponding legacy bugs from 01 §4.2 with a regression test.
4. **Phase 3 — icons unbundling** (`nomo_gen icons`) + example-app rebuild (no stubs) + docs.
5. Nomo App migrates per component behind its own abstraction; legacy `main` stays frozen as reference (this docs branch is the map).

## 9. Open questions

1. Trim the 17 semantic colors? Several exist only for single components — audit during Phase 0.
2. Annotation schema details: are token-expression defaults as strings (`'t.colors.primary'`) acceptable, or do we want a typed `TokenRef` API for IDE support? Decide in Phase 0 with real usage.
3. How much `lerp` is actually needed once theme switching lerps tokens instead of component classes? Possibly only a handful of opt-in fields.
4. Does anything real depend on `NomoText` auto-fit (deleted upstream but API still public)? If yes, `NomoFittedText`; if no, drop.
5. Does the Nomo App need the name→IconData lookup at runtime, or only the example gallery? Determines how aggressive §4.2 can be.
6. Snackbar: keep ScaffoldMessenger interop, or move fully onto the overlay engine and drop the last Material service dependency?
7. Repo layout for the generator: `tool/` script vs. a proper `nomo_gen` package in a Dart workspace within this repo (workspaces are stable since Dart 3.6) — decide when Phase 0 starts.
