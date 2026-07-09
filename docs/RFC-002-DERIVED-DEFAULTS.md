# RFC-002 — Derived defaults, generated ceremony, sealed-state styling

> Status: **accepted** (2026-07-09, directed by maintainer) — implementation in progress; each landed step gets a dated note in §5. Companion to [DESIGN.md](DESIGN.md) (RFC-001) — this RFC does **not** relitigate its settled decisions; every proposal below strengthens them. Grounded in a comparative study of Ant Design v5, MUI v5–v7/Base UI, the headless school (TanStack, Radix, Zag/Ark, shadcn/ui), Fluent 2 / Fluent UI React v9, and Airbnb's DLS, plus a line-level audit of this repo.

## 1. Motivation

Legend UI's raw ideas are right and stay: **layered configurability** (four-level nearest-wins resolution), **good defaults** (token-derived annotation defaults ARE the kit defaults), **consumer symmetry** (open Type-keyed registry + published generator). The audit shows where the implementation under-delivers on "minimize boilerplate by building on good defaults":

| Friction | Evidence |
|---|---|
| Every themed field is hand-written **3×** (constructor param, `@Themed` field, resolve-block argument) | the "mirror block" appears in all 19 themed widgets; ~47% of `LegendCard`'s 64 hand lines are ceremony |
| Token classes are hand-maintained mechanical code | ~230 of 390 LOC in `tokens/` is `copyWith`/`lerp`; adding one color touches 4 places |
| A from-scratch theme costs **17 hand-picked colors** | `LegendColors` has zero derivation; light *and* dark are fully hand-authored |
| App-wide restyle = nested `copyWith` chains | `theme_controller.dart:85–98`, two levels deep for 3 colors |
| Interaction states are outside the theme system | hover/pressed/disabled colors ad-hoc in every `LegendInteractive.builder` |
| Variant duplication | 3 button theme classes; `defaultsTo` strings duplicated verbatim (strings can't share constants) |
| Registry-key footgun | keying `components` by widget type instead of `XThemeNullable` is a **silent no-op** |
| Generated `XThemeNullable` has no `==` | any rebuild reconstructing a non-const override invalidates every dependent |
| Field core missing | `LegendTextField` (286 LOC, largest component) is both primitive and component |
| Conventions without tooling | playground rung + doc-comment rules are manual process; docs drift from code |

## 2. What the field study established — and Legend's synthesis

One-line verdicts; full reports in the session research (2026-07-09).

- **AntD v5** — ~27 *seed* tokens expand into ~180 map/alias tokens via **pure, composable derivation algorithms**; one brand color expands to a 10-stop ramp (`@ant-design/colors`' `generate()`) whose stops become bg/hover/border/active variants; dark mode re-runs generation blended against a dark background. Hand-authoring derived values (their v4, 1000+ variables) grows unboundedly.
- **MUI** — consumers write **deltas over a complete default theme**; `light`/`dark`/`contrastText` derive from one `main` color; `ownerState` makes theme overrides prop-aware. Anti-lesson: precedence via CSS injection order, type-augmentation ceremony.
- **Headless (TanStack/Radix/Zag/shadcn)** — behavior is the expensive reusable part; state exposed *as data* to the styling layer (`data-state`); every headless ecosystem re-grew a styled defaults layer. shadcn: **surface/foreground pairs**, one radius derives a scale.
- **Fluent v9** — brand ramp in, full light+dark themes out; raw ramps hidden from the public theme; removed v8's per-component style callbacks (slow, unpredictable); escape hatches form an explicit cost ladder ending in recomposition.
- **Airbnb DLS** — zero technical escape hatch caused a 30-prop Button and mass bypass; the rebuild landed on **unstyled base + styled variants**.

### Legend's opinionated synthesis

What we take, and what is ours alone:

1. **From AntD**: the ramp algorithm and seed→derived split — but *behind* the theme surface (Fluent's rule), never as a 180-token public namespace.
2. **From MUI/shadcn**: deltas-over-defaults and legibility pairs — expressed as typed Dart, not string paths.
3. **From the headless school**: state-as-data flowing into the styling layer — but typed and **sealed**, not stringly `data-state` attributes.
4. **From Fluent/Airbnb**: themes stay declarative and inspectable; recomposition from primitives is the last rung of the ladder.
5. **Ours: the sealed-state ladder (§R6)** — Dart 3 sealed classes make widget interaction state an *exhaustively-switchable, single-valued* type instead of Material's `Set<WidgetState>` guess-the-precedence model. One minimal generic container (`LegendStates<T>`) + type-bound extensions carry per-state values for any type; generic annotations (legacy's good idea, AST-parsed) type the contract; every member is a named, individually overridable variable.
6. **Ours: the widget file is the single source of truth for behavior, theme AND documentation (§R9)** — dartdoc comments on tokens and `@Themed` fields are extracted by the generator into a docs manifest; the docs site and playground render every variable from it. Documentation cannot drift from code because it *is* the code.

### Legacy inspection findings (2026-07-09, `main` generated artifacts + `NomoTheme` core)

Read: `nomo_primary_button.theme_data.g.dart`, `nomo_theme.dart`, `nomo_color_theme.dart`. The legacy resolution chain was: **widget param ≻ subtree `…ThemeOverride` ≻ per-mode `components` overrides ≻ app-delegate `defaultComponentsColor` ≻ kit `predefinedComponentColors(colors)` ≻ frozen annotation consts.** Four findings feed this RFC:

1. **Legacy generated the widget-param resolver** — `getFromContext(BuildContext, PrimaryNomoButton widget)` did the `widget.background ?? themeData.background` mapping *in generated code*. The rewrite regressed this into the hand-written mirror block; **R1 is a restoration** of the legacy behavior, namespaced (extension `resolveTheme`) instead of 26 colliding free functions.
2. **Legacy already had named state-color variables** per component — `hoverColor`, `focusColor`, `highlightColor`, `splashColor` — with kit defaults derived by alpha overlays (`colors.primary.withValues(alpha: .06)`), duplicated verbatim across every interactive component in `predefinedComponentColors`. This is direct precedent for R6: named per-state variables with overlay-derived defaults — minus the copy-paste, which `LegendStates<T>` + `LegendStateOverlays` absorb.
3. **`predefinedComponentColors(NomoColors)` was the kit's token-relation layer** — a central, closed, hand-written widget-type→defaults function. R10's `.resolve` tear-offs decentralize exactly this onto each widget's own file: same capability, no central registry to maintain, automatically open to consumer widgets.
4. The delegate offered two app-level layers (base component defaults + per-mode overrides); Legend's single `components` map per `LegendThemeData` (one instance per mode, built by the consumer's controller) covers the same power with one concept.

## 3. Proposals

All preserve the settled rules: one-file-in/one-file-out generation, open Type-keyed registry, four-level resolution, responsiveness ≠ theming.

### R1 — Generate the mirror block away; hide the resolution *(amended 2026-07-09: part-of emission + private in-library resolver, directed)*

The full developer experience is: **declare one var + one annotation, run the CLI (or leave `--watch` running) — done.** The widget is a plain `StatelessWidget`/`StatefulWidget` (no custom base classes, fully compatible with ordinary Flutter widgets); the resolved values arrive through one generated, in-library call:

```dart
part 'legend_switch.theme.g.dart';          // scaffolded by `legend_gen create`

@LegendThemeable()
class LegendSwitch extends StatelessWidget {
  /// Track color while the switch is on.
  @Style<Color>.resolve(_activeTrack)
  final Color? activeTrack;
  static Color _activeTrack(LegendTokens t) => t.colors.primary;
  ...
  Widget build(BuildContext context) {
    final theme = _theme(context);          // ← the whole visible resolution step
    ...
  }
}
```

The generated part file contains a **private extension** on the widget (`extension _$LegendSwitchThemeResolve on LegendSwitch { LegendSwitchTheme _theme(BuildContext) => LegendSwitchTheme.of(context, LegendSwitchThemeNullable(activeTrack: activeTrack, ...)); }`) — it re-lists the fields so the author never does, and being `part of` the same library it needs no import, pollutes no public API, and can call the private tear-offs. (`widget._theme(context)` from a `State`.) Legacy precedent: generated `getFromContext(context, widget)` did exactly this — restored here namespaced and private. **Generation switches from import-own-source to `part of`** (amending post-review fix C1; the part directive is the stronger version of the same source↔artifact coupling, and R10's private tear-offs require it). Themed fields are written **once**; ~15–40 hand lines removed per component across 19 widgets.

### R2 — Generate `==`/`hashCode` (+ `debugFillProperties`) on `XThemeNullable`

Identity-compared override data means any ancestor rebuild reconstructing a non-const override invalidates all dependents. Value equality makes generated classes as honest as the hand-written `LegendThemeData` already is.

### R3 — Key the registry by the **widget type**

`components: {LegendSwitch: LegendSwitchThemeNullable(...)}` instead of keying by the Nullable class. The widget type is what consumers naturally reach for (the current mistake mode is a *silent no-op*). Value type stays the Nullable class; `legend_gen doctor` checks key/value mismatches, plus a debug assert in `LegendThemeData`. Amends the §9.2 Phase-0 note.

### R4 — Seed-derived tokens: `LegendTokens.fromSeed` with an AntD-adapted ramp

A small **`LegendSeed`** — brand color, optional neutral tint, radius, density/size unit, font family, brightness — and a pure derivation producing full `LegendTokens`:

```dart
final tokens = LegendTokens.fromSeed(LegendSeed(brand: Color(0xFF0059FF)));
final dark   = LegendTokens.fromSeed(LegendSeed(brand: ..., brightness: Brightness.dark));
```

- **`LegendRamp`** adapts AntD's `generate()`: from one color, a 10-stop ramp via HSV rotation/saturation/value stepping (stops 1–4 light surfaces, 5 hover, 6 base, 7 active, 8–10 dark accents). **Dark mode is the same seed re-generated blended against the dark background** — one algorithm, not a second hand-authored palette.
- The ramp is **internal** (Fluent's rule): public `LegendColors` exposes semantic **surface/foreground pairs** (`primary`/`onPrimary`, `primaryContainer`/`onPrimaryContainer`, `surface`/`onSurface`, …) mapped from ramp stops, with contrast-checked `on*` colors (MUI's `contrastThreshold` idea). Resolves DESIGN §9.1: the 17 flat colors restructure into pairs.
- Size scale from one unit, radius scale from one radius, type scale from one base size (shadcn's one-knob-derives-the-scale).
- `LegendTokens.light`/`.dark` become the kit seeds run through the derivation, golden-tested so defaults can't drift.
- Hand-authoring stays possible: `fromSeed` returns a normal `LegendTokens`; `copyWith` applies on top. Derivation is a *constructor*, not a new resolution level — rule 6 (lerp tokens once) untouched.
- Consumer cost of a coherent theme: **17 colors → 1–4 seed values.**

### R5 — Generate the token classes *(mechanical members only — see R10 scope)*

`tokens/` data classes get their `copyWith`/`lerp`/`==` generated into `*.tokens.g.dart` via a separate lightweight marker (NOT `@LegendThemeable` — tokens are the base theme, not component themes, and never get Override widgets or registry entries). Removes ~230 hand LOC, makes "add a token" a one-line diff, and dogfoods the generator on the kit's own core.

### R6 — Sealed widget states; ~~ONE minimal generic container~~ → custom style classes *(re-settled 2026-07-10 ×7, directed: `LegendStates<T>` is removed — any `@Style`-annotated class is a themed value type)*

> **Amendment 7 (2026-07-10, directed — supersedes the container design below; the sealed `LegendWidgetState` + overlays + ladder stay).** The kit-special generic container is gone. Instead, **users define custom style classes** and the CLI generates their type-safe resolution plumbing:
>
> ```dart
> @Style()                       // class form: "this is a style value class"
> class InteractiveColors {
>   const InteractiveColors({this.normal, this.hovered, this.pressed, this.focused, this.disabled});
>   /// Fill at rest.
>   final Color? normal;
>   /// Fill while hovered.
>   final Color? hovered;
>   ...
> }
> // legend_gen emits into the class's part: member-wise sparse merge,
> // member-wise type-appropriate lerp, value ==/hashCode, docs-manifest entries.
> ```
>
> A widget field typed with any `@Style`-annotated class gets **member-wise** treatment in the generated theme artifacts (detected from the field type's resolved element — output stays strictly one-file-in/one-file-out). The class may carry any shape — the record idea, fully user-extensible — and any methods the author likes (`pick(LegendWidgetState)`, derivations); the generator only owns the mechanical members. **The kit predefines the common cases as ordinary predefined style classes** (e.g. `InteractiveColors` for hover-bearing widgets, replacing every former `LegendStates<Color>` use one-to-one) — same mechanism as user classes, zero special-casing. The generator's `LegendStates` category, the `withDerived` post-merge hook, and the generic container itself are deleted.

*(Historical — superseded by amendment 7 above:)*

Interaction state becomes a **sealed type** with a single effective value, resolved by a fixed priority ladder (disabled ≻ pressed ≻ hovered ≻ focused ≻ normal):

```dart
sealed class LegendWidgetState { const LegendWidgetState(); }
final class LegendStateNormal   extends LegendWidgetState { const ... }
final class LegendStateHovered  extends LegendWidgetState { const ... }
final class LegendStatePressed  extends LegendWidgetState { const ... }
final class LegendStateFocused  extends LegendWidgetState { const ... }
final class LegendStateDisabled extends LegendWidgetState { const ... }
```

**One minimal generic object, not per-type wrappers.** State-bearing values use **`LegendStates<T>`** — the single, tiny, pure-data generic container (five `T?` members: `normal`, `hovered`, `pressed`, `focused`, `disabled`). One class serves every value type — `LegendStates<Color>`, `LegendStates<double>`, `LegendStates<TextStyle>` — Dart's generics carry the type safety; no per-type wrapper zoo, no functions:

```dart
@Style<LegendStates<Color>>.resolve(_background)   // typed contract — see R10
final LegendStates<Color>? background;
static LegendStates<Color> _background(LegendTokens t) => LegendStates(normal: t.colors.primary);
```

Every member is a named variable at every resolution level (member-wise sparse merge, member-wise lerp with the type-appropriate lerper, member-wise `==`; the manifest lists `background.hovered` etc.):

```dart
// override exactly one state variant, any level:
PrimaryLegendButtonThemeNullable(background: LegendStates(pressed: navy))
```

**Generic annotations (the legacy pattern, done right).** The field annotation takes a type argument like legacy's `@NomoColorField<T>` — parsed from the AST (never `toSource()` slicing), validated against the field's declared type, and used by the generator to pick the merge/lerp strategy for `T` (including through `LegendStates<T>`). The full typed contract is R10.

**Extensions carry the type-specific behavior and the ergonomics.** The generic container stays dumb; capabilities attach by extension exactly where they type-check:

```dart
// lift a raw value — the common case stays nearly unwrapped:
PrimaryLegendButton(background: brand.states)          // extension on Color
// selection, any T — fallback-to-normal built in:
extension LegendStatesPick<T> on LegendStates<T> { T? pick(LegendWidgetState state); }
// overlay derivation exists ONLY where it makes sense, via a Color-bound extension:
extension LegendStatesColorResolve on LegendStates<Color> {
  Color? resolve(LegendWidgetState state, LegendStateOverlays overlays); // member ?? overlays(normal)
}
```

**Derivation fills what you didn't set** — tokens gain `LegendStateOverlays` (hover/press deltas, disabled opacity); for `LegendStates<Color>` an unset member resolves as overlays applied to the *resolved* `normal`, so one brand color yields consistent hover/press everywhere and re-derives from any level's override; a named member always wins.

**Flat named variables remain the fallback**: an author who wants a variant as its own constructor param (or a nonstandard state axis like `selected`) declares it as an ordinary separate `@Themed` field — plain types, no container, full four-level resolution. Nothing forces the container. `LegendInteractive` maps its `LegendInteractionStates` snapshot onto the ladder via `states.effective`.

### R7 — Shared defaults + variant consolidation

1. ~~`defaultsTo` may reference static consts/functions~~ — superseded by R10: typed defaults are ordinary Dart symbols (consts and tear-offs), so sharing them across the three buttons is plain code reuse; the string-duplication problem ceases to exist.
2. Shared button surface (padding, radius, minHeight) moves into `LegendButtonCore`'s own themed declaration; variant classes declare only what differs (colors). Airbnb's base+variant, applied to theme declarations. §9.8 (named variant registration) stays deferred.

### R8 — Consumer & process ergonomics

- **`LegendThemeController`** ships in the kit (mode + seed + component overrides); the docs app becomes its reference consumer.
- Flat restyle helpers (`tokens.withColors(primary: …)`) generated with R5.
- **`legend_gen create`** scaffolds widget + test + playground rung + docs stub; **`legend_gen doctor`** checks registry keys, missing rungs, stale `.g.dart`.
- Extract **`LegendFieldCore`** from `LegendTextField`; widen `LegendInteractive`'s vocabulary (secondary-tap, focus-tap) so the two audited `GestureDetector` bypasses become compositions again.
- Document the **escape-hatch ladder** on the Theming page: tokens → app map → subtree override → constructor → recomposition from primitives.

### R9 — The theme docs CMS: doc comments are the content *(added 2026-07-09)*

Every token field and every `@Themed` field already carries (or per CLAUDE.md must carry) a dartdoc intent comment. The generator turns those comments into the documentation system:

- **`legend_gen docs`** — for each annotated file (token class or themed widget), emit a `*.docs.g.dart` manifest next to the theme artifacts: a const list of `LegendDocEntry {owner, name, type, dartdoc, defaultExpression, group}` records extracted from the AST. Strictly one-file-in/one-file-out; the docs app aggregates by importing the manifests it cares about (open, like the components registry — consumers' own widgets get manifests too).
- **The playground becomes manifest-driven**: instead of hand-built knob rungs, the configurator renders **every variable** — all token fields grouped (colors/sizes/typography/shadows/state overlays) and every component's themed fields — each with its name, extracted doc comment, default expression, current resolved value, and an editor appropriate to its type (color swatch/hex, number stepper, state-style editor). Hand-curated presets stay; exhaustive coverage comes from the manifest, so a new `@Themed` field appears in the playground on regeneration with **zero playground code**.
- The docs site gains a **Theme reference** page rendered from the same manifests — the "CMS" is the source tree; editing content means editing the doc comment where the variable is declared, and `legend_gen --check` keeps it fresh in CI.

### R10 — Typed annotation contract: `@Style<T>` *(added 2026-07-09, directed)*

**The annotation exists for exactly one thing: generating the theme boilerplate** (the legacy model, with the CLI in place of build_runner). The field stays a plain declaration; the annotation is generic and its default is **typed Dart, not a string**:

```dart
/// Fill behind the label.
@Style<Color>(Color(0xFF2563EB))          // const default — the value "without theme"
final Color? background;

/// Text color, related to the static theme values by the author:
@Style<Color>.resolve(_foreground)         // typed tear-off: Color Function(LegendTokens)
final Color? foreground;
static Color _foreground(LegendTokens t) => t.colors.onPrimary;
```

- **`@Style<T>(value)`** — the positional const value is the default used when no theme provides anything (level 4). It is overridden by any theme override at any level: constructor ≻ subtree override ≻ components map ≻ this default. Untouched four-level semantics.
- **`@Style<T>.resolve(tearOff)`** — the value is optional; omitting it means the developer defines the relation to the static theme values instead, as a **const tear-off** `T Function(LegendTokens)`. This replaces the `defaultsTo` string expressions wholesale and closes DESIGN §9.2 with the *typed* answer it hoped for: the default is compile-checked in the widget file itself, IDE-navigable, rename-safe, and shareable across widgets as an ordinary symbol — no analyzer-after-generation gap, no duplicated strings.
- **Neither given** → the default is null (legacy's `@NomoColorField<Color?>(null)` case): the component treats the value as genuinely optional.
- `lerp:` stays as the opt-in flag. The generator reads value/tear-off from the AST (structured expression spans, never index math), validates `T` against the field type, and emits `XTheme.defaults(LegendTokens t)` calling the tear-offs / inlining the consts. Tear-offs may be **private** statics — the generated artifact is `part of` the widget's library (R1), so private symbols resolve.
- `@LegendThemeable()` remains the class marker; `@Style<T>` replaces `@Themed`. Migration of the 72 existing fields is mechanical (each `defaultsTo` string becomes either a const value or a private static tear-off in the same file).

**Scope: component themes only** *(clarified 2026-07-09, directed)*. `@Style`/`@LegendThemeable` and the generated artifact set apply to **components** — never to the base theme. `LegendTokens` (the base colors/sizes/typography/shadows) is its own layer, exactly as in the legacy split:

- The **kit defines the base defaults** (`LegendTokens.light`/`.dark`, and `fromSeed` once R4 lands); consumers override them **wholesale at their levels** — app-wide via `LegendThemeData(tokens: …)`, per-subtree via a nested `LegendTheme` — without any codegen involvement.
- Component defaults *relate* to the base through `.resolve` tear-offs (`(t) => t.colors.primary`), so a base-color override cascades into every component default that references it, while any component-level override (constructor / subtree / components map) still wins for that component.
- **Consumer symmetry is CLI-delivered** (DESIGN goal 4, unchanged): a package user runs `legend_gen` on their own annotated widget and gets the identical feature set — generated theme classes, four-level resolution, registry entry, docs manifest — with zero kit changes.
- R5 (generated token classes) is accordingly *mechanical only*: a separate lightweight marker generates `copyWith`/`lerp`/`==` for the token data classes — it must never grow Override widgets, registry entries, or any of the component-theme machinery.

**Amendment — the token Ref catalog** *(added 2026-07-10, directed)*. The common one-hop default (`static double _spacing(LegendTokens t) => t.sizes.md;`) should live entirely inside the annotation, but Dart forbids inline closures in annotations (they are not const). The kit therefore generates a **const tear-off catalog** from the token classes: `@LegendTokenData` gains `mountedAt` (an explicit declaration of the class's `LegendTokens` getter — `'colors'`, `'sizes'`, …; never a naming convention; `''` is the root sentinel for `LegendTokens` itself), and `legend_gen tokens` emits `abstract final class <ClassName>Ref` into the same `.tokens.g.dart` part — one plain static per token field (`static double md(LegendTokens t) => t.sizes.md;`, dartdoc copied from the field), covering every field type with no filtering, so the annotation reads `@Style<double>.resolve(LegendSizesRef.md)` with no adjacent hand-written tear-off. Hand-written tear-offs remain the form for **composite** defaults (`EdgeInsets.symmetric(…)`, `LegendStates(…)`, blend math) — written as private **top-level functions** of the widget's file (the parser accepts top-level functions alongside class statics; both are const-tear-off-able where instance methods and local functions are not). Migration: 38 one-hop fields moved to the catalog form, 33 composite tear-offs kept (now top-level); docs-manifest `defaultDescription`s for catalog fields read as the member itself (`LegendSizesRef.md`) — clearer than the raw expression.

### R11 — CLI quality bar: the Serverpod / Dart Frog standard *(added 2026-07-09, from CLI field study)*

`legend_gen` is consumer-facing product surface (DESIGN §5.1); it adopts the proven stack of the two best Dart CLIs:

1. **Foundation**: `package:args` `CommandRunner` + `package:mason_logger` — `-v/--verbose` → `logger.detail`, `-q/--quiet`, `progress()` spinners, `ExitCode` semantics with a distinct exit code for `--check` dirty (CI-friendly).
2. **Watch loop = Dart Frog's shape**: `package:watcher` + debounce; regenerate only the changed file (fits one-file-in/one-file-out exactly); *never exit on a source error* — print `file:line`, keep the last good output, rebuild on next save (snapshot/rollback).
3. **Scaffolding via bundled mason bricks**: `create` templates compiled into the CLI so they version in lock-step — no network, no drift (Dart Frog's model).
4. **`update` command on `package:pub_updater`** + post-run "new version available" nudge; `doctor` warns when the activated CLI version ≠ the project's `legend_ui` version (Serverpod's pin policy — generated output must match runtime API); version stamp in generated headers stays.
5. **Shell completion** via `package:cli_completion` (drop-in `CompletionCommandRunner`).
6. **Error taxonomy**: recoverable annotation/analyzer errors (keep watching) vs internal generator faults (exit `software`); messages *name the fix* ("param `size` has a non-null default; make it nullable").

Skipped deliberately: a `dev`-style VM-service server (the consumer's `flutter run` already hot-reloads the emitted source), an LSP/`daemon` command (until an editor extension exists), and default-on analytics (trust cost, no benefit here).

### R12 — Granular rebuilds: per-field listening, opt-out, and ValueListenables *(added 2026-07-10, directed)*

Today `_theme(context)` depends on `LegendTheme` as a whole — any theme change rebuilds every themed widget. R12 makes the dependency **per resolved field**:

1. **`LegendTheme` (and the subtree override) become `InheritedModel`s** with aspect objects. The generated `_theme(context)` registers one aspect per listened field; `updateShouldNotifyDependent` re-resolves just the dependent's fields against old vs new data and notifies only on actual value change. Constructor params (level 1) are local and never a rebuild source.
2. **`@Style(..., listen: false)`** — opt a field out of automatic rebuilds: it is still resolved (fresh value on every build) but registers no aspect, so changes to it alone never schedule a rebuild. For values consumed by imperative code (painters, controllers) or deliberately latched.
3. **Generated per-field accessors** — alongside `_theme(context)`, each field gets `_<fieldName>(context)` resolving that single field with only its own aspect, for widgets consuming one property.
4. **`ValueListenable<T>` per field** — generated controller-backed selectors (`XThemeListenables.background(LegendThemeController)`), distinct-until-changed, for animation/imperative consumers that want change streams without any widget rebuild. Lives against the controller (the theme's source of truth), not the element tree, so it has a well-defined lifetime.

Themes remain pure data; this changes only *who gets notified*, never how values resolve.

### R13 — The themed build signature: `build(context, theme)` *(added 2026-07-10, directed)*

The resolution step disappears from author code entirely: the theme arrives **alongside the context**, riverpod-`ConsumerWidget`-style. Dart forbids overloading, so a plain `StatelessWidget` can't add a two-arg `build` — the kit owns a tiny custom-element hierarchy once (`LegendStatelessWidget<T>` / `LegendStatefulWidget` + `LegendState<T>`; the element calls `widget.build(context, widget.resolveThemeOf(context))`), and the generated part emits a per-widget base that hides every trace of it:

```dart
class LegendDivider extends _$LegendDividerBase {          // generated base in the part file
  @override
  Widget build(BuildContext context, LegendDividerTheme theme) { ... }
}
```

`_$LegendDividerBase` extends `LegendStatelessWidget<LegendDividerTheme>`, declares abstract getters for the themed fields (satisfied by the widget's finals), and implements `resolveThemeOf` — which is also where R12's per-field aspects register, so granular rebuilds and `listen: false` compose unchanged. These are ordinary `Widget`s, fully interoperable with default Flutter widgets. The freezed-style bootstrap (base doesn't exist before the first CLI run) is covered by `legend_gen create` and `--watch`. The private `_theme(context)` extension keeps being emitted as the escape hatch for widgets that must extend another supertype.

## 4. What is deliberately NOT adopted

- **No function-valued theme content; exactly one generic container** *(amendments 4–6)* — the `resolveWith` function form was dropped, and per-type wrappers (`LegendStateColor`) were replaced by the single generic `LegendStates<T>` with type-bound extensions. Themes are pure data; computed values are produced at theme-build time. Nothing in a theme receives a BuildContext or a callback.
- **No headless/unstyled pivot** — annotation defaults remain the styled layer; primitives remain the recomposition hatch.
- **No closed variant registry, no naming conventions, no cross-file generation** — RFC-001 rules hold.
- **No `sx`-style ad-hoc instance styling** — typed constructor params are the instance hatch.
- **No public token namespace explosion** — the ramp is internal; the public surface is semantic pairs.

## 5. Sequencing & measurements

| Step | Contents | Status |
|---|---|---|
| **A — generator sprint** | R1 + R2 + R3 + R10 `@Style<T>` typed contract + `LegendStates<T>` category + `legend_gen docs`; migrate all 72 fields; regenerate all + goldens | **landed** (2026-07-09): typed `@Style<T>` (value/resolve/null), part-of emission with the private `_theme(context)` resolver extension, `XThemeNullable` value `==`, both-keys registry lookup (widget type wins), sealed `LegendWidgetState` + `LegendStates<T>` + `LegendStateOverlays` on the tokens, `legend_gen docs` manifests (`LegendDocEntry`). Migrated 82 fields across 19 widgets + the consumer fixture (73 `.resolve` tear-offs, 9 const values); all 20 mirror blocks deleted (−317 hand LOC, +257 for the typed tear-off statics); 20 theme parts + 20 docs manifests regenerated and committed; generator goldens ×3 (theme ×2, docs ×1) |
| **B — token sprint** | R5 then R4 (`LegendRamp`, `LegendSeed`, pairs restructure, `LegendStateOverlays`); goldens pin light/dark | **landed** (2026-07-09): `legend_gen tokens` + `@LegendTokenData` marker (mechanical members only per R10 scope — `copyWith` + value `==`/`hashCode` as a generated mixin, member-wise lerp behind the class's one-line static redirect); all six token classes migrated (−217 hand LOC, 472 generated); internal `LegendRamp` (AntD-adapted 10-stop, dark = same seed blended against `#141414`), `LegendSeed` (brand/neutral/radius/sizeUnit/fontFamily/brightness), `LegendTokens.fromSeed` with the pure-pole ≥ 4.5:1 pair guarantee. Pairs audit: `onPrimaryContainer` added additively; the full pair-restructure deferred to a deliberate breaking pass (DESIGN §9.1 note) — `light`/`dark` stay hand-authored, zero visual drift |
| **A2 — CLI polish (R11)** | mason_logger foundation, exit codes, never-crash watch, update/doctor-pin, completion, create template | **landed** (2026-07-09): CommandRunner + mason_logger with `-v/-q`, exit-code table (65 = `--check` dirty for CI, 66 = recoverable contract diagnostics, 70 = internal), watcher-based `--watch` on themes/docs/tokens (150 ms debounce, changed-paths-only, last-good-output structural guarantee), every diagnostic names the fix, `update` (pub_updater) + CI-aware nudge, doctor version-pin check, cli_completion; `create` kept as a structured template module instead of bundling mason (DESIGN §5.2 hygiene). legend_gen suite 46 → 87 |
| **C — component adoption** | `_theme()` everywhere (done in A); interactive components move to `LegendStates<Color>`; R7.2; doc-comment pass; `LegendText.rich` | **landed** (2026-07-09): buttons' background/foreground + menu/sider/expandable surfaces converted to `LegendStates<Color>` with fully-named members reproducing the pre-R6 blends exactly (25 per-state pins written first, green unchanged); public constructor params stay `Color?` and lift via `.states` (cost: 7 ctors lose `const`); `LegendButtonCore` gains the shared `padding`/`borderRadius` theme (variant ≻ core layering); standardized doc comments across the barrel — zero empty `doc:` entries in all 21 manifests; `LegendText.rich` (widgets-only, selection-participating). Kit suite 110 → 144. **Design note**: generated `of()` applies `withDerived` unconditionally post-merge, so a fully-named default makes overlay derivation dormant for that field; if cascade-on-override is wanted later, the generator needs a per-field derive mode |
| **D — playground & docs CMS** | manifest-driven configurator over every variable; Theme reference page; `LegendThemeController` in kit | in progress (2026-07-09) |

Measurements to record (extending the Phase-0 table): hand LOC per component before/after R1 (target: ceremony share < 15%), seed-values-to-coherent-theme (target ≤ 4), generated-vs-hand ratio in `tokens/`, playground variables covered / total manifest entries (target: 100%).

Open questions resolved (dated notes to DESIGN §9): §9.1 (colors → derived pairs, R4), §9.2 amendment (shared default expressions, R7), §9.8 (variants stay deferred), new entries for the registry-key change (R3) and sealed-state styling (R6).
