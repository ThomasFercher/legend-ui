# 09 — Rewrite Proposal: The Slim Approach

> Status: **accepted** (2026-07-09) — the architecture for the full rewrite.
> Grounded in the problem inventory of [01 — Overview](01-overview.md) §4 and the detailed chapters.
> **Decisions locked**: annotation-driven codegen stays (§2); consumer widgets get identical theming support via the open Type-keyed registry (§2.3); the generator is a **published standalone CLI, `nomo_gen`** — chosen over build_runner (§5.3); repo becomes a Dart workspace (§6).
> Implementation happens on the `rewrite` branch; this document is copied there as `docs/DESIGN.md` and evolves with the code.

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
4. **Consumer widgets are first-class citizens**: dependents of the kit don't just consume the shipped components — they can author their own widgets and give them **identical theming support**: the same decorator declaration, the same generated artifacts, the same five-level resolution, plugged into the same `NomoThemeData`. A consumer defining their widget's theme must look exactly like the kit defining `PrimaryNomoButton`'s theme. This makes the generator a **published, consumer-facing product**, not an internal maintainer tool — with major consequences for tooling choice (§5) and theme architecture (§2.3).
5. **Self-contained repo**: `git clone && flutter pub get && flutter test` must work with no sibling checkouts. The generator is developed *inside this repo* (and published from it).
6. **Keep the good ideas**: delegate-driven color×sizing modes, responsive shell, near-zero runtime deps (see 01 §5).
7. **Honest API surface**: `lib/src/` + curated barrel, semver, no typos, tested, CI that runs.

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

The multi-level resolution semantics are **identical at every level of the stack**: an app can restyle one button subtree (level 2), reskin all buttons per theme mode (level 3), ship kit-wide defaults (level 4), or accept token-derived defaults (level 5) — and a plain constructor argument still always wins (level 1).

**No aggregate registry — the theme is an open, Type-keyed registry.** This is the load-bearing decision that makes consumer widgets (§1 goal 4) possible. Legacy wired every component into `NomoThemeData` through a generated aggregate file plus manual `@NomoThemeUtils` lists — a *closed* set only the kit could extend. Instead, `NomoThemeData` holds component themes the way Flutter holds `ThemeExtension`s:

```dart
class NomoThemeData {
  final NomoTokens tokens;
  final Map<Type, NomoComponentTheme> components;   // open — anyone can add entries
}
```

Each generated `XTheme.of(context)` resolves level 3 via `theme.components[XTheme]` and falls back to its own token-derived defaults. Consequences:

- **Consumer symmetry for free**: a dependent annotates their own widget, runs the generator, and registers `BalanceCardTheme` in the same map next to the kit's entries — same declaration, same artifacts, same resolution, zero kit changes:

  ```dart
  // in the consumer's app — identical workflow to the kit's own components
  @NomoThemeable()
  class BalanceCard extends StatelessWidget {
    @Themed(defaultsTo: 't.colors.surface')
    final Color? background;
    ...
  }
  // generator emits balance_card.theme.g.dart → BalanceCardTheme(+Nullable, Override, .of)

  NomoThemeData(
    tokens: myTokens,
    components: { ...nomoDefaults, BalanceCardTheme: BalanceCardThemeNullable(...) },
  )
  ```

- **Every generated file depends only on its own widget file.** No cross-file, cross-package, or whole-project analysis step exists anywhere — generation is embarrassingly parallel, trivially incremental, and works identically whether the tool is a CLI or a build_runner builder (§5).
- The legacy aggregate-registry artifact and both manual registration lists disappear outright.

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

## 5. The generator: a consumer-facing tool — standalone CLI vs build_runner

### 5.1 The requirement that reframes everything

Goal 4 (§1) makes the generator part of the **product**: dependents annotate *their own* widgets and generate the same theming plumbing the kit's components get. That kills the earlier framing of "maintainers are the only codegen users — keep it in `tool/`". The generator must now be:

- **published** (consumers `dart pub add --dev nomo_gen` or globally activate it),
- runnable against **arbitrary consumer packages**, not just this repo,
- excellent at **diagnostics**, because its users didn't write it and will hold its errors against the kit,
- stable in output format, because consumer `.g.dart` files are committed in *their* repos.

Note what §2.3's open Type-keyed registry already bought us: **no generation step needs whole-project or cross-package analysis** — each annotated widget file maps to exactly one output file. Both candidate tools can do that job; the choice is about ergonomics, dependency mechanics, and what else the tool can do.

### 5.2 Head-to-head under the consumer-facing constraint

| Criterion | Standalone CLI (`nomo_gen`) | build_runner Builder |
|---|---|---|
| **Familiarity** | new tool to learn (one command) | the ecosystem standard — consumers already run it for freezed / json_serializable / riverpod_generator |
| **Workflow integration** | second watch process next to an existing `build_runner watch` | folds into the watch process most Flutter apps already have |
| **Dependency mechanics** | as a dev dep: only `analyzer` (+ `args`) enters the consumer's dev graph — no `build`/`build_runner`/`source_gen` chain; globally activated: **zero** footprint, fully isolated resolution | must co-resolve `analyzer`/`build`/`source_gen` with every other generator the consumer uses — the classic lock-step pain; a kit should not be the package that blocks a consumer's freezed upgrade |
| **Speed** | analyze only annotated files, no build-graph hashing; cold runs in seconds, warm watch near-instant | full build-graph initialization every cold run (tens of seconds in real apps), even for one changed widget |
| **Debuggability** | plain `main()`, run under a debugger, readable stack traces | builder failures surface through build_runner's log plumbing |
| **Diagnostics UX** | owns its output: `file:line` errors, colored output, `--fix` suggestions, exit codes | constrained to build_runner's error reporting |
| **Staleness protection** | output can go stale → mitigated by `nomo_gen --check` in CI (and a version stamp in file headers) | `build_runner watch` keeps outputs fresh automatically; per-build check |
| **IDE story** | committed `.g.dart` = full navigation; no plugin needed | same (also committed), plus some IDEs auto-trigger builds |
| **Beyond codegen** | scaffolding (`nomo_gen create component`), migration codemods for kit upgrades, `nomo_gen doctor` (validate a consumer's theme setup), icon table generation (§4) — one tool, many subcommands | codegen only; everything else needs a separate CLI anyway |
| **Versioning** | dev dep pins per-project (reproducible); global activation risks team version drift → prefer dev dep, stamp generator version into output, `--check` verifies | pinned per-project like any dev dep |

### 5.3 Verdict: **standalone CLI, published, CLI-first; build_runner as a thin optional wrapper** *(DECIDED 2026-07-09)*

The consumer-facing requirement *strengthens* the CLI case rather than weakening it, for three reasons:

1. **Dependency hygiene is now a product feature.** The moment `nomo_gen` is in every consumer's dev graph, a build_runner-based generator makes the kit a permanent participant in the ecosystem's `analyzer`/`build` version lock-step. A lean CLI (`analyzer` only, wide constraints) — or global activation with zero footprint — keeps the kit from ever being the reason a consumer's unrelated codegen breaks. Legacy already demonstrated where generator coupling pain leads (03; 01 §4.1.1).
2. **The kit needs a CLI anyway.** Scaffolding new themed components, a `doctor` for mis-registered themes, migration codemods between kit versions, icon regeneration — these are consumer-facing needs no Builder can serve. Once `nomo_gen` exists for those, theme generation is one more subcommand, and shipping *two* mandatory tools would be worse than one.
3. **The architecture removed build_runner's trump card.** Incremental build-graph tracking pays off for expensive, interdependent generation. §2.3 made generation one-file-in/one-file-out with no cross-file analysis — a workload where build_runner's machinery is pure overhead and a watch loop over annotated files is trivial to implement correctly.

The honest cost: consumers who live in `build_runner watch` get a second process to run (or forget to run). That is real friction, and it is exactly the group a **thin optional `nomo_gen_builder` package** serves: a ~50-line Builder wrapping the same emission core, published separately so only the people who opt in inherit the version lock-step. The parsing/emission core stays packaging-agnostic; the CLI is the reference frontend and the only *required* one. CI freshness (`nomo_gen --check`) is documented as the standard consumer setup either way.

Requirements for the rebuilt core, each fixing a documented legacy failure (03):

| Requirement | Legacy failure it fixes |
|---|---|
| Parse via `package:analyzer` **AST**, never `toSource()` string-slicing | index-math default extraction, "cut at last comma if contains 'lerp'", the `@NomoConstant` `replaceAll` bug |
| Validate and **diagnose** with `file:line` errors: type/category mismatches, non-null annotated params, missing token references, unregistered themes | size fields silently landing in the color bucket and being color-lerped |
| **Zero naming conventions**: discovery by annotation scan only | themeName↔field derivation, `@NomoThemeUtils` manual lists, `<themeName>Theme` constant matching |
| Namespaced emission (static `.of()`, no top-level free functions) | 26 colliding `getFromContext` symbols, `hide` in every barrel |
| Deterministic, formatted, version-stamped, committed output | opaque regeneration diffs, undetectable staleness |
| One-file-in/one-file-out, no cross-file analysis (guaranteed by §2.3) | aggregate builders, whole-kit regeneration |

Dart macros — which would have made annotations expand with zero tooling — were discontinued by the Dart team in early 2025, so an explicit generator remains the right call; the CLI keeps it as small and ownable as possible.

## 6. Package & repo structure

A **Dart workspace** (stable since Dart 3.6) inside this single repo — the generator is a real published package now (§5.1), but the legacy sibling-repo mistake is not repeated:

```
packages/
  nomo_ui_kit/              # the kit
    lib/
      nomo_ui_kit.dart      # THE barrel — the only supported import
      src/
        annotations/        # @NomoThemeable, @Themed — the decorator contract (re-exported; consumers need it)
        tokens/             # NomoTokens, colors, sizes, typography, shadows, responsive values
        theme/              # NomoTheme widget, NomoThemeData (open Type-keyed registry), delegate
        primitives/         # surface, interactive, overlay engine, text core, field core
        components/         # public components + their committed *.g.dart theme files
        shell/              # NomoApp, NomoScaffold, app bar, sider, bottom bar, body
  nomo_gen/                 # the CLI: themes + icons + create + doctor + codemods — PUBLISHED for consumers
  nomo_gen_builder/         # optional thin build_runner wrapper around nomo_gen's core (§5.3)
  nomo_icons/               # optional FontAwesome package (§4)
example/                    # gallery app — every component, no empty stubs; doubles as the consumer-workflow fixture
test/                       # per package; incl. generator golden tests
```

- **`lib/src/` + single barrel** ends the deep-import free-for-all; everything exported is deliberate API (fixes 01 §4.1.5). Generated theme classes and the annotations are re-exported through the barrel deliberately.
- Nothing outside this repo is needed to build; the old generator repo is archived. Same-repo workspace = generator and kit evolve in lock-step and are tested against each other in every PR — the annotation contract can never drift from the tool again.
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

1. **Phase 0 — validate the theory**: build `tokens/`, the annotation contract, the open `NomoThemeData` registry, and a **minimal `nomo_gen themes`** (parse one fixture widget, emit the §2.3 artifact set); port **one** hard component (PrimaryNomoButton) + one overlay (dropdown) end-to-end on it — **and run the full consumer workflow once**: annotate a widget in `example/` (as if it were a third-party app), generate, register it in the theme map, override it at all five levels. Measure: handwritten LOC per component, generated LOC per property (target: well under legacy's ~35), resolution ergonomics, consumer-workflow friction, theme-switch performance. Revisit §2/§5 if targets are missed.
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
7. `nomo_gen` distribution default for consumers: dev dependency (per-project pinning, `analyzer` enters their dev graph with wide constraints) vs `dart pub global activate` (zero dependency footprint, but team version drift — mitigated by the version stamp + `--check`). Leaning dev-dependency as the documented default with global activation as the escape hatch; confirm with real consumer feedback in Phase 1.
8. Does the level-3 map key on the theme class (`components[BalanceCardTheme]`) suffice, or do consumers need *variant* registration (one widget, several named themes, e.g. `BalanceCard.compact`)? If yes, key by `(Type, name)` — decide before the map's API ships.
