# 09 — Rewrite Proposal: The Slim Approach

> Status: **theory / RFC** — this chapter proposes the architecture for the full rewrite.
> It is grounded in the problem inventory of [01 — Overview](01-overview.md) §4 and the detailed chapters. Nothing here is implemented yet.

## 1. Goals and non-goals

**Goals**

1. **Slim**: an order of magnitude less machinery per component. Target ≤ ~40 handwritten lines of theming code per component instead of ~239 generated ones.
2. **No `nomo_ui_generator`**: the custom build_runner generator is retired entirely (explicit project goal). Whatever code generation survives must be trivial, in-repo, and optional to the build.
3. **Self-contained repo**: `git clone && flutter pub get && flutter test` must work with no sibling checkouts.
4. **Keep the good ideas**: resolution precedence (param → local override → global theme → default), delegate-driven color×sizing modes, responsive shell, near-zero runtime deps (see 01 §5).
5. **Honest API surface**: `lib/src/` + curated barrel, semver, no typos, tested, CI that runs.

**Non-goals**

- Visual redesign — the design language stays; this is an architecture rewrite.
- Backwards compatibility with legacy deep imports. The Nomo App migrates deliberately, component by component.
- Supporting Material's theming system. We interoperate with Material widgets where practical but do not mirror `ThemeData`.

## 2. The core idea: design away the need for codegen

The legacy generator exists to produce, per component: a data class, nullable variant, `lerp`, `copyWith`, override InheritedWidget, and a 3-layer `getFromContext` resolver — ~10 artifacts × 26 components. The rewrite replaces all of that with **one generic mechanism plus one small handwritten style class per component**.

### 2.1 Design tokens (the only global theme)

A single immutable `NomoTokens` object holds the primitives — nothing component-specific:

```dart
class NomoTokens {
  final NomoColors colors;       // the 17 semantic colors (audited, possibly trimmed)
  final NomoSizes sizes;         // spacing scale, radii, border widths, icon sizes
  final NomoTypography type;     // b1–b3, h1–h3 (+ label/mono if needed)
  final NomoShadows shadows;     // ONE elevation system (replaces ElevatedBox vs NomoElevation split)
}
```

Handwritten, with handwritten `copyWith`/`lerp` — this is written **once**, not per component, so the boilerplate argument for codegen disappears.

### 2.2 Component styles are plain classes with a resolve hook

Each component gets exactly one small style class deriving its defaults *from tokens*:

```dart
class NomoButtonStyle {
  final Color? background;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? radius;
  // ...

  const NomoButtonStyle({this.background, this.padding, this.radius});

  /// Fill unset fields from tokens — replaces generated defaults + constants.
  NomoButtonStyle withDefaults(NomoTokens t) => NomoButtonStyle(
        background: background ?? t.colors.primary,
        padding: padding ?? EdgeInsets.all(t.sizes.md),
        radius: radius ?? t.sizes.radiusMd,
      );

  NomoButtonStyle merge(NomoButtonStyle? other) => /* other-wins, ~5 lines */;
}
```

Key differences from legacy:

- **All fields nullable, all constructor defaults null.** This fixes the systemic legacy bug where non-null constructor defaults made theme values unreachable (01 §4.2).
- Defaults come from tokens *at resolve time*, so a token change propagates without touching component code.
- `copyWith`/`lerp` are only written where actually needed (styles that animate). Most don't need `lerp` at all — see §2.4.

### 2.3 One generic resolution primitive

The legacy precedence chain is kept but implemented once:

```dart
class NomoStyle<S> extends InheritedTheme { final S style; ... }

extension StyleResolve on BuildContext {
  S resolveStyle<S>(S Function(NomoTokens) fromTheme, {S? local}) { ... }
}
```

Resolution order (identical semantics to legacy, one implementation instead of 26 generated ones):

1. widget constructor params (merged last, they win)
2. nearest `NomoStyle<NomoButtonStyle>` ancestor (replaces every generated `…ThemeOverride`)
3. the app theme's style registry (`NomoThemeData.buttonStyle`, plain fields — no naming-convention magic, no `@NomoThemeUtils` aggregate lists)
4. `withDefaults(tokens)`

A component's total theming cost: the style class (§2.2, ~25–40 lines) + one `context.resolveStyle` call. **No generated files, no `hide getFromContext`, no registration conventions.**

### 2.4 Decouple responsiveness and animation from theming

Two legacy design decisions multiply each other's cost: breakpoints are theme swaps, and theme swaps lerp *all* ~48 component classes at 60 fps (01 §4.1.3). The rewrite separates the three concerns:

- **Responsiveness**: a lightweight `NomoBreakpoints` InheritedModel exposing the current tier (`compact / medium / expanded`) and the raw width. Widgets and the shell read the tier directly; the *theme does not change* when the window resizes. Sizing values that genuinely vary per tier are expressed as `NomoResponsive<T>` values (`T resolve(tier)`) inside tokens.
- **Theme switching** (light/dark/brand): swaps the `NomoTokens` object. Animation happens at the *consumer* via implicit animations on resolved values (`AnimatedContainer`, `AnimatedDefaultTextStyle`, or a tiny `AnimatedTokens` widget that lerps only the token object — one lerp, not 48). Component styles are re-derived, not tweened.
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

Public components then become thin compositions (`PrimaryNomoButton` = `NomoInteractive` + `NomoSurface` + slot layout). Consolidations while porting:

- **One dropdown** (menu + button unified, one item model), **one switch** (no Cupertino fork — build on `NomoInteractive`), **one modal sheet** (actually implemented this time).
- **`NomoRouteBody` → `NomoBody`** with a single sliver-based mode; convenience constructors cover the legacy use cases instead of six exclusive flag-modes.
- Forms get a real lifecycle: field registration/unregistration, a working validity model, and an actual `NomoValidator` set (the API CLAUDE.md always claimed existed).
- All vendored third-party code (FadeIn, InAppNotification, switch/textfield forks) is dropped or rebuilt on the primitives (~3,500 LOC deleted).

## 4. Icons: unbundle

Legacy ships a 14.5k-line FontAwesome fork, ~632 KB of TTFs, and a reflection map that defeats icon tree-shaking for every consumer (07). The rewrite:

1. **Core kit ships no icon font.** Components accept `Widget`/`IconData` — the kit is icon-agnostic.
2. FontAwesome moves to an **optional sibling package** (`nomo_icons`), regenerated from upstream metadata, marked `@staticIconProvider`, with **no `allIcons` reflection map** in the library. Apps that need name→icon lookup (the icon-gallery use case) opt in via a separate deferred import or generate the map into their own app.
3. Result: consumers pay only for the glyphs they use; the kit loses ~17k LOC and 632 KB of assets.

## 5. Replacing the generator: build_runner vs CLI vs none

The explicit goal is retiring `nomo_ui_generator`. Three options were considered:

| | A — No codegen | B — build_runner generator | C — standalone CLI |
|---|---|---|---|
| Boilerplate per component | ~25–40 LOC handwritten | ~0 handwritten, ~200+ generated | ~0 handwritten, generated on demand |
| Build integration | none needed | hooks every `pub run build_runner` build; slow; version-locks `analyzer`/`build` across consumers | run manually / in CI; no build-graph coupling |
| Failure modes | none (it's just code) | the exact fragility we're escaping (source-string parsing, stale outputs, `--delete-conflicting-outputs` rituals) | stale output possible → needs a CI freshness check |
| IDE experience | perfect (plain Dart, jump-to-def) | generated parts, weaker navigation | same as A for committed output |
| Dependency footprint | zero | `build_runner` + `source_gen` + `analyzer` in every consumer's dev deps | dev-only `tool/` dir or separate package; consumers never see it |

**Recommendation: A as the architecture, C as the escape hatch.**

- §2 deliberately reduces per-component theming to an amount of code (one small style class) where generating it costs more than writing it. *The best generator is an architecture that doesn't need one.* Dart macros — the language feature that would have made B attractive — were discontinued by the Dart team in early 2025, so betting on annotation-driven generation again means betting on build_runner indefinitely.
- Where mechanical generation genuinely pays off — the **icon codepoint tables** (§4) and possibly a `styles.g.dart` aggregating token presets — a **small in-repo CLI** (`dart run tool/nomo_gen.dart icons`, plain `package:analyzer`-free string templating from upstream JSON metadata) is the right tool: run on demand by maintainers, output committed, freshness enforced by a CI step that reruns it and fails on diff. This matches the user-stated preference for a CLI over build_runner and keeps consumers completely codegen-free.
- build_runner (B) is rejected: it recreates the legacy failure mode (external generator package, version lock-step, opaque builds) for a benefit §2 already eliminated.

## 6. Package & repo structure

```
lib/
  nomo_ui_kit.dart          # THE barrel — the only supported import
  src/
    tokens/                 # NomoTokens, colors, sizes, typography, shadows, responsive values
    theme/                  # NomoTheme widget, NomoStyle<S>, resolveStyle
    primitives/             # surface, interactive, overlay engine, text core, field core
    components/             # thin public components composed from primitives
    shell/                  # NomoApp, NomoScaffold, app bar, sider, bottom bar, body
tool/
  nomo_gen.dart             # optional CLI (icons etc.), dev-only
example/                    # gallery app — every component, no empty stubs
test/                       # required from day one
```

- **`lib/src/` + single barrel** ends the deep-import free-for-all; everything exported is deliberate API (fixes 01 §4.1.5).
- The generator repo is archived; nothing outside this repo is needed to build.
- Router stays decoupled: the kit takes a `RouterConfig` like legacy `NomoApp`, but `NomoBody` loses its router-coupled `copyWith` (04).

## 7. Quality gates (day-one, not retrofit)

| Gate | Legacy status | Rewrite policy |
|---|---|---|
| Tests | zero | every primitive gets widget tests; components get golden tests; theme resolution gets unit tests |
| CI | two dead configs | one GitHub workflow on `main` + PRs: analyze, format, test, `tool/nomo_gen.dart --check`, example build |
| Lints | very_good_analysis (kept) | kept, no ignores without justification |
| Versioning | patch-only, no tags | semver + tags + CHANGELOG discipline; publishable structure even if `publish_to: none` initially |
| API hygiene | typos baked in | spell-checked public API; `dart doc` builds clean |

## 8. Migration & sequencing

1. **Phase 0 — validate the theory**: build `tokens/`, `NomoStyle`/`resolveStyle`, `NomoSurface`, `NomoInteractive`, and port **one** hard component (PrimaryNomoButton) + one overlay (dropdown) end-to-end. Measure: LOC per component, resolution ergonomics, theme-switch performance. Revisit §2 if targets are missed.
2. **Phase 1 — primitives complete**: overlay engine, text core, field core; golden-test infrastructure.
3. **Phase 2 — component ports** in dependency order (buttons → surfaces → menus/selection → input/form → shell), consolidating duplicates per §3. Each port closes out the corresponding legacy bugs from 01 §4.2 with a regression test.
4. **Phase 3 — icons unbundling** + example-app rebuild (no stubs) + docs.
5. Nomo App migrates per component behind its own abstraction; legacy `main` stays frozen as reference (this docs branch is the map).

## 9. Open questions

1. Trim the 17 semantic colors? Several exist only for single components — audit during Phase 0.
2. Does anything real depend on `NomoText` auto-fit (deleted upstream but API still public)? If yes, `NomoFittedText`; if no, drop.
3. One `NomoResponsive<T>` mechanism vs. per-tier token sets — decide with Phase 0 measurements.
4. Does the Nomo App need the name→IconData lookup at runtime, or only the example gallery? Determines how aggressive §4.2 can be.
5. Snackbar: keep ScaffoldMessenger interop, or move fully onto the overlay engine and drop the last Material service dependency?
