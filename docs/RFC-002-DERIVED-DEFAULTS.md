# RFC-002 — Derived defaults, generated ceremony: the boilerplate refactor

> Status: **proposed** (2026-07-09). Companion to [DESIGN.md](DESIGN.md) (RFC-001, accepted) — this RFC does **not** relitigate its settled decisions; every proposal below strengthens them. Grounded in a comparative study of Ant Design v5, MUI v5–v7/Base UI, the headless school (TanStack, Radix, Zag/Ark, shadcn/ui), Fluent 2 / Fluent UI React v9, and Airbnb's DLS, plus a line-level audit of this repo.

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
| Generated `XThemeNullable` has no `==` | any rebuild reconstructing a non-const override invalidates every dependent (`LegendThemeData` implements equality precisely to avoid this — the generated classes don't) |
| Field core missing | `LegendTextField` (286 LOC, largest component) is both primitive and component; a second field has nothing to reuse |
| Conventions without tooling | playground rung + doc-comment rules are manual process; `legend_gen create` scaffolds neither |

## 2. What the field study established

One-line verdicts; full reports in the session research (2026-07-09).

- **AntD v5** — ~27 *seed* tokens expand into ~180 map/alias tokens via **pure, composable derivation algorithms** (dark and compact are algorithms, not hand-authored forks). One seed change stays self-consistent system-wide. Component tokens default to alias tokens; per-component overrides are sparse. Their v4 (1000+ hand-maintained variables) is the cautionary tale — hand-authoring derived values grows unboundedly.
- **MUI** — consumers write **deltas over a complete default theme** (partial deep-merge); a coherent brand theme is 10–20 lines because `light`/`dark`/`contrastText` derive from one `main` color. The `defaultProps` / `styleOverrides` / `variants` triad names three distinct customization intents. Anti-lesson: precedence via CSS injection order, and type-augmentation ceremony as the extension mechanism.
- **Headless (TanStack/Radix/Zag/shadcn)** — behavior is the expensive reusable part; state exposed *as data* to the styling layer (`data-state` ≈ our builder `states`); controlled+uncontrolled on every stateful prop. Every headless ecosystem had to bolt a styled layer back on (Radix→Themes, Ark→Park UI) — shipping good defaults first-class was the right call. shadcn's token vocabulary: **surface/foreground pairs** (ink guaranteed legible on its surface) and **one radius from which a scale derives**.
- **Fluent v9** — brand ramp in, `createLightTheme`/`createDarkTheme` out. Deliberately **removed per-component style callbacks from the theme** (v8's model): runtime merges were slow and unpredictable. Component themes must stay **data**. Escape hatches form an explicit cost ladder ending in recomposition from the behavior hooks (≈ our five primitives). Raw ramps are hidden from the public theme so nobody hardcodes a theme-invariant value.
- **Airbnb DLS** — zero technical escape hatch ("petition for a prop") caused a 30-prop, 33 KB Button and mass bypass; the rebuild landed on **unstyled base + styled variants**. Constraint must live in the architecture, not in an approval queue.

Convergent conclusion: **the systems that minimize boilerplate all do it the same way — a small seed surface plus pure derivation for defaults, sparse diffs for customization, and generated/uniform plumbing per component.** Legend UI already has the resolution model and the generator; what's missing is derivation (tokens) and absorption of the remaining ceremony (generator).

## 3. Proposals

Ordered by leverage ÷ risk. R1–R3 are mechanical generator work; R4–R6 are design work; R7–R8 are quality-of-life. All preserve the settled rules: one-file-in/one-file-out generation, open Type-keyed registry, themes as data, four-level resolution, responsiveness ≠ theming.

### R1 — Generate the mirror block away *(biggest per-component win)*

The generator already parses the widget file and knows every `@Themed` field; emit a resolver **extension on the widget class** into the existing `.theme.g.dart`:

```dart
// generated
extension LegendSwitchThemeResolve on LegendSwitch {
  LegendSwitchTheme resolveTheme(BuildContext context) =>
      LegendSwitchTheme.of(context, LegendSwitchThemeNullable(
        activeTrack: activeTrack, inactiveTrack: inactiveTrack,
        thumb: thumb, width: width, height: height,
      ));
}
```

Component build method drops from a 5–10 line hand-maintained block (that silently drifts when a field is added) to:

```dart
final theme = resolveTheme(context);          // StatelessWidget
final theme = widget.resolveTheme(context);   // State<...>
```

Effect: themed fields are written **2× instead of 3×**; adding a field can no longer be forgotten in the resolve path (the generator regenerates it). ~15–40 hand lines removed per component across 19 widgets. Stays strictly one-file-in/one-file-out.

### R2 — Generate `==`/`hashCode` (+ `debugFillProperties`) on `XThemeNullable`

Fixes the `updateShouldNotify` churn the audit found: identity-compared override data means any ancestor rebuild invalidates all dependents unless consumers remember `const`. Value equality makes the generated classes as honest as the hand-written `LegendThemeData` already is. Pure generator change + regen.

### R3 — Key the registry by the **widget type**

`components: {LegendSwitch: LegendSwitchThemeNullable(...)}` instead of keying by `LegendSwitchThemeNullable`. The widget type is what consumers naturally reach for (the current mistake mode is a *silent no-op*), reads better, and the generator knows the widget type when emitting `.of`. Value type stays the Nullable class; `legend_gen doctor` gains a check for value-type/key mismatches (debug assert in `LegendThemeData` too — value's runtime type must be a `LegendComponentTheme`). Mechanical migration; updates the §9.2 Phase-0 note with a dated amendment.

### R4 — Seed-derived tokens: `LegendTokens.fromSeed` *(biggest consumer-defaults win)*

Adopt the AntD/Fluent/MUI convergence: a small **`LegendSeed`** — brand color, optional neutral tint, radius, density/size unit, font family, brightness — and a **pure derivation function** producing the full `LegendTokens`:

```dart
final tokens = LegendTokens.fromSeed(LegendSeed(brand: Color(0xFF0059FF)));
final dark  = LegendTokens.fromSeed(LegendSeed(brand: ..., brightness: Brightness.dark));
```

- Derivation lives in one audited function (HSL ramp for containers/hover surfaces, contrast-checked foregrounds à la MUI's `contrastThreshold`, size scale from one unit, radius scale from one radius — shadcn's "one knob derives the scale").
- **Dark is the same seed through a dark algorithm**, not a second hand-authored palette. `LegendTokens.light`/`.dark` remain as the kit's canonical seeds run through the derivation (golden-tested so the defaults can't drift silently).
- Hand-authoring stays possible — `fromSeed` returns a normal `LegendTokens`; `copyWith` still applies on top. Derivation is a *constructor*, not a new layer, so rule 6 (lerp tokens once) is untouched.
- Resolves DESIGN §9.1 (the 17-color audit) by restructuring `LegendColors` into **surface/foreground pairs** (`primary`/`onPrimary`, `surface`/`onSurface`…) — the shadcn/Fluent lesson that legibility pairing belongs in the token vocabulary, plus Fluent's "never expose raw ramps" rule: the ramp is internal to derivation.
- Consumer cost of a coherent custom theme: **17 colors → 1–4 seed values.** The playground's preset/brand-color panel becomes a thin UI over `LegendSeed`.

### R5 — Generate the token classes

`tokens/` is 4 data classes whose `copyWith`/`lerp`/ctors are exactly what `legend_gen` exists to write. Annotate them (`@LegendTokenClass` or reuse `@LegendThemeable` with a mode flag) and generate the mechanical members into `*.tokens.g.dart`. Removes ~230 hand LOC, makes "add a token" a one-line diff, and dogfoods the generator on the kit's own core. (Also where R4's `lerp` for any new state-overlay tokens comes from for free.)

### R6 — Interaction states enter the theme system as **data**

Today every component hand-rolls `states.disabled ? tokens.colors.disabled : theme.activeTrack`. Two coordinated pieces, honoring Fluent's "no callbacks in the theme" rule:

1. **`LegendStateColor`** — a lerpable value type `{normal, hovered, pressed, disabled}` usable as a `@Themed` field type. The generator already infers categories from types; this adds one.
2. **Token-level state derivation**: tokens gain a small `LegendStateOverlays` (hover/press deltas, disabled opacity) so `defaultsTo: 't.states.of(t.colors.primary)'` yields a complete, consistent state set — good defaults again; components stop inventing their own hover math, and a brand restyle automatically restyles hover/press everywhere.

`LegendInteractive`'s builder contract is unchanged; components map `states → theme.background.resolve(states)` in one line. This is MUI's `ownerState`-awareness and Radix's `data-state`, expressed as typed data.

### R7 — Shared default expressions + variant consolidation

Two fixes for the duplicated-`defaultsTo`-string problem (partially reopens §9.2, as its Phase-0 note anticipated):

1. `defaultsTo` may reference **static consts/functions on the widget's own file** (still one-file-in/one-file-out) — e.g. `defaultsTo: '_buttonPadding(t)'`. Trivial parser change; kills the verbatim triplication across the three buttons.
2. The three button *theme* classes stay (registry is Type-keyed — settled) but their shared surface moves into `LegendButtonCore`'s own themed declaration where truly common (padding, radius, minHeight), with the variant classes declaring only what genuinely differs (colors). Airbnb's base+variant, applied to theme declarations. §9.8 (named variant registration) stays **deferred** — MUI's `variants` evidence is noted, but no consumer demand yet; the constructor + subtree levels cover today's cases.

### R8 — Consumer & process ergonomics

- **`LegendThemeController`** ships in the kit (mode + seed + per-component overrides + `notifyListeners`); every consumer currently rewrites the example's. The docs app becomes its reference consumer.
- **Flat restyle helpers** where nesting hurts most: `tokens.withColors(primary: …)` sugar over the nested `copyWith` chain (generated with R5).
- **`legend_gen create`** scaffolds the full component contract: widget + annotations + test stub + **playground rung + docs-page section stub**, making CLAUDE.md's conventions tool-enforced instead of process-enforced. **`legend_gen doctor`** checks registry keys (R3), missing playground rungs, and stale `.g.dart`.
- **Extract `LegendFieldCore`** from `LegendTextField` (the RFC-001 §3 primitive that never materialized) and widen `LegendInteractive`'s vocabulary (secondary-tap, focus-tap) so the two audited `GestureDetector` bypasses become compositions again.
- Document the **escape-hatch ladder** (Fluent's cost gradient) on the Theming page: tokens → app map → subtree override → constructor → recomposition from primitives. All five rungs exist today; naming the ladder is what makes people use the cheap rungs first.

## 4. What is deliberately NOT proposed

- **No style callbacks in themes** (Fluent v8's mistake) — `LegendStateColor` is data; derivation runs at theme-build time.
- **No headless/unstyled pivot** — every headless ecosystem re-grew a styled layer; our annotation defaults already are that layer. The primitives remain the recomposition escape hatch.
- **No closed variant registry, no naming conventions, no cross-file generation** — RFC-001 rules 4/5 hold everywhere above.
- **No `sx`-style ad-hoc instance styling** — typed constructor params are the instance hatch; MUI shows how an over-ergonomic escape hatch metastasizes.
- **No token count explosion** — Fluent measured the cost of ~1,200 CSS vars; R4 *restructures* the 17 colors into pairs, it does not multiply them.

## 5. Sequencing & measurements

| Step | Contents | Risk |
|---|---|---|
| **R-a** (generator sprint) | R1 + R2 + R3, regenerate all 19 + consumer fixture, goldens updated | Low — mechanical, fully test-covered |
| **R-b** (token sprint) | R5 then R4 (generated lerp/copyWith make derivation cheap), goldens pin `light`/`dark` == today's palettes | Medium — visual diffs must be zero by construction |
| **R-c** (state sprint) | R6 across the interactive components, closing per-component hover math | Medium |
| **R-d** (ergonomics) | R7 + R8 alongside the two remaining Phase-2 ports | Low, incremental |

Measurements to record (extending the Phase-0 table): hand LOC per component before/after R1 (target: ceremony share < 15%), seed-values-to-coherent-theme (target ≤ 4), generated-vs-hand ratio in `tokens/`, and the playground's preset panel rewritten over `LegendSeed` as the consumer-workflow proof.

Open questions resolved on acceptance (dated notes go into DESIGN §9): §9.1 (colors → derived pairs, R4), §9.2 amendment (shared default expressions, R7), §9.8 (variants stay deferred, dated re-affirmation), plus a new §9 entry for the registry-key change (R3).
