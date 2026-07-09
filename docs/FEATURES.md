# Legend UI — Feature Report

> Status as of **2026-07-09** · `legend_ui 1.0.0-dev.4` · `legend_gen 0.1.0-dev.0` · branch `rewrite`
>
> Legend UI is the full rewrite of the legacy Nomo UI Kit: a Material-free Flutter component kit built on design tokens, decorator-declared component themes, and a published codegen CLI. Everything below is implemented, tested, and analyzer-clean; the single supported import is `package:legend_ui/legend_ui.dart`.

---

## 1. Design tokens — the one global theme

`LegendTokens` is a single immutable object holding every design primitive. Handwritten `copyWith`/`lerp`; const `LegendTokens.light` and `LegendTokens.dark` presets ship with the kit.

| Group | Contents |
|---|---|
| `LegendColors` | 17 semantic colors: `primary`/`onPrimary`/`primaryContainer`, `secondary`/`onSecondary`, `background1–3`, `surface`/`onSurface`, `error`/`onError`, `disabled`/`onDisabled`, `foreground1–3` |
| `LegendSizes` | spacing scale `xs–xxl`, radii `radiusSm/Md/Lg`, `borderWidth`, icon sizes `iconSm/Md/Lg` |
| `LegendTypography` | six styles: `h1–h3`, `b1–b3` |
| `LegendShadows` | one elevation system: `none`, `low`, `medium`, `high` |

A theme switch lerps **this one object once** — not one lerp per component class like legacy (~48 of them).

## 2. Theming system

**Decorator contract.** A widget declares its themable surface inline:

```dart
@LegendThemeable()
class LegendCard extends StatelessWidget {
  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;
  ...
}
```

Defaults are expressions over the tokens (`t`), so a token change propagates to every component default without touching component code. The generator **enforces** the contract at parse time with `file:line` errors: themed fields must be nullable, constructor params must default to null (the legacy "unreachable theme values" bug is impossible), and `lerp: true` is only accepted on interpolatable types (`double`, `Color`, `EdgeInsets(Geometry)`, `BorderRadius`, `TextStyle`).

**Generated per component** (committed, CI-verified fresh): `XTheme` (resolved, non-null) · `XThemeNullable` (sparse overrides) · `XThemeOverride` (subtree inherited widget) · `defaults(tokens)` / `merge` / `copyWith` / `lerp` / `XTheme.of(context, local)`.

**Four-level resolution, nearest wins** (DESIGN §9.9):

1. Constructor parameter
2. Subtree override — `XThemeOverride(data: ..., child: ...)`
3. App theme — `LegendThemeData.components[XThemeNullable]`
4. Token-derived annotation defaults (these *are* the kit defaults)

**Open, Type-keyed registry.** `LegendThemeData { tokens, Map<Type, Object> components }`. Consumers annotate **their own widgets**, run `legend_gen`, and register the result in the same map as kit components — identical declaration, artifacts, and resolution, zero kit changes. Proven by an in-repo consumer rehearsal (`test/consumer/balance_card.dart`) that uses only the public barrel.

**Runtime pieces.** `LegendTheme` (inherited widget + `of`/`maybeOf`), generic `LegendThemeOverride<T>`, and `AnimatedLegendTheme` — an implicitly animated widget that tweens the token object on theme change (250 ms default, curve configurable). `LegendThemeData` has value equality, so rebuilding an identical theme never invalidates dependents. The `components` map intentionally snaps rather than animates (documented; DESIGN §9.10).

## 3. Responsiveness (≠ theming)

`LegendTier { compact, medium, expanded }` via `LegendBreakpointScope` — `compact < 600 ≤ medium < 1080 ≤ expanded`, both thresholds configurable. Shell chrome flips by tier; theme switches never masquerade as responsiveness.

## 4. Primitives — the five cores plus a caret

Every component composes these; none touch Material (`Scaffold`, `InkWell`, `showDialog` are not dependencies anywhere).

| Primitive | What it provides |
|---|---|
| `LegendSurface` | animated decorated box: color, border, radius, shadows, padding, optional clipping |
| `LegendInteractive` | the one tap/hover/focus/pressed/disabled handler. Disabled means **inert** (legacy regression closed). Built-in Enter/Space/numpad-Enter activation that works with or without a `WidgetsApp` ancestor; `toggled` parameter for switch/checkbox semantics; no stuck-pressed state when disabled mid-press |
| `LegendButtonCore` | shared button chassis (states → surface → content row); consumers can build their own variants on it |
| `LegendAnchoredOverlay` | anchored overlays on `OverlayPortal` + `CompositedTransformFollower` + `TapRegion` (dropdowns, context menus) |
| `LegendModalRoute` / `showLegendModal` | Material-free `PopupRoute`: centered modals fade+scale, edge-aligned sheets slide; barrier dismiss, translatable `barrierLabel`, safe-area |
| `LegendCaret` | shared rotating chevron (dropdown, expandable) |

## 5. App shell

- **`LegendApp`** — `WidgetsApp`-based root wiring theme animation + breakpoints + default text style. Router-agnostic: `home` or any `RouterConfig`. Locale / `localizationsDelegates` / `supportedLocales` / `onGenerateTitle` passthrough; asserts against conflicting `navigatorKey` + `routerConfig`.
- **`LegendScaffold`** — app bar + navigation + body; below the compact breakpoint navigation renders as `LegendBottomBar`, above it as `LegendSider`.
- **`LegendAppBar`** (plain Row, no custom RenderBox), **`LegendSider`**, **`LegendBottomBar`** (upward shadow, safe-area aware) — all driven by one `LegendNavItem` model.

## 6. Components

| Component | Highlights |
|---|---|
| `PrimaryLegendButton` / `SecondaryLegendButton` / `LegendTextButton` | one shared chassis, no duplicated layout arms; themed padding actually applies (legacy bug closed); text buttons stay transparent when disabled |
| `LegendText` | token typography via `LegendTextVariant { h1–h3, b1–b3 }` |
| `LegendTextField` | built on `EditableText` (replaces the 1,535-line CupertinoTextField fork): placeholder, title, error text, focus border, disabled state, form integration |
| `LegendDropdown<T>` | one dropdown, one item model (`LegendDropdownItem<T>`); themed `menuMaxHeight` (320) with scrolling menu |
| `LegendSwitch` | no Cupertino fork; announces as a toggle with caller-supplied `semanticLabel`; RTL-correct thumb |
| `LegendCard` | surface + one shadow system, reachable theme defaults |
| `LegendDialog` / `showLegendDialog` | on the kit's own modal engine |
| `LegendDivider` | horizontal/vertical, themed thickness and spacing |
| `LegendExpandable` | controlled or uncontrolled expand/collapse |
| `LegendInfoItem` | label/value row with leading/trailing slots |
| `LegendContextMenu` | long-press and secondary-click, anchored overlay, outside-tap dismiss |

## 7. Forms

- **`LegendForm` + `LegendFormController`** — fields register on mount and **unregister on dispose** (legacy leak closed); `isValid` updates live; `values` by field name; `reset()` restores initial values and clears errors.
- **`LegendFormField<T>`** — generic handle so *consumer-built* inputs participate identically to kit fields (validator-less fields count as valid — legacy bug closed).
- **`LegendValidator`** — `required`, `email`, `minLength`/`maxLength`, and `compose`; all return translatable message strings, custom `LegendValidatorFn`s plug in anywhere.
- `LegendTextField` integrates via `formField` / `validator`.

## 8. Feedback

- **`showLegendToast`** — queued toasts on the overlay engine (no `ScaffoldMessenger`, the last Material service dependency is gone); optional action button; auto-dismiss.
- **`LegendLoading`** — animated arc spinner at themed size.
- **`LegendShimmer`** — loading placeholder shimmer.

## 9. Codegen — the `legend_gen` CLI

Standalone pure-Dart CLI (decided over build_runner), published for consumers, pure AST parsing, strictly **one file in → one file out**.

| Command | Purpose |
|---|---|
| `legend_gen themes [paths]` | generate `*.theme.g.dart` next to each annotated source |
| `legend_gen themes --check` | CI freshness gate — fails on stale/missing output |
| `legend_gen themes --watch` | regenerate on save (rename/atomic-save-race proof) |
| `legend_gen create <ClassName>` | scaffold a contract-correct annotated component + its theme file in one step |
| `legend_gen doctor [paths]` | report missing, stale, or orphaned generated files and contract violations |

Guarantees: every contract violation is a `file:line` diagnostic (never silently broken output); generated files import their own source (types declared next to the widget just work); output is version-stamped; the emitter is golden-tested (`UPDATE_GOLDENS=1` flow).

Measured: ~28 generated LOC per themed property (legacy ~35) with zero naming conventions or manual registration; the generator is 541 LOC vs legacy's ~1,050.

## 10. Accessibility & input

- Full keyboard activation on every interactive component (Enter / Space / numpad Enter), focus highlights via `FocusableActionDetector`.
- Honest semantics: buttons announce as buttons, switches as toggles with state; disabled means disabled; no hard-coded English labels anywhere (all labels/barrier text caller-supplied).
- RTL-correct layout (directional alignment in the switch and shell).

## 11. Quality & guarantees

- **86 tests** across the workspace (kit 65, generator 20, example 1), including regression tests for every closed legacy bug: disabled-but-tappable buttons, unreachable theme defaults, ignored themed padding, never-unregistered form fields, validator-less fields pinning forms invalid, whole-theme lerp.
- `very_good_analysis`, zero analyzer issues; `dart format` enforced.
- CI on every push: format → analyze → all test suites → `legend_gen themes --check` freshness gate → example web build.
- Near-zero runtime dependencies; icon-agnostic core (verified: web icon-font tree-shaking 1.6 MB → 8 KB).
- Example gallery app (`example/`) shows every shipped component with no stubs and doubles as the consumer-workflow reference.

## Not yet available

Tracked in [ROADMAP.md](../ROADMAP.md): the showcase/playground with live theme configurator (next milestone, Phase 2.5), vertical menu and `LegendBody` ports (sliver/scroll design pass), text-field selection toolbar/handles, `legend_icons` package + `legend_gen icons`, screenshot goldens (deferred by decision), member API docs / publishing (deferred), and the DESIGN §9.10–9.11 deferrals (component-map animation, dropdown trigger theming / flip-above / keyboard nav, tap-to-position cursor).
