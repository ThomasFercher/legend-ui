# Legend UI — Feature Report

> Status as of **2026-07-25** · `legend_ui 1.0.0-dev.5` · `legend_gen 0.2.0-dev.0` · branch `main`
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
  @Style<Color>.resolve(ColorRef.surface, lerp: true)
  final Color? background;

  @Style<EdgeInsetsGeometry>.resolve(_padding)   // composite: top-level tear-off
  final EdgeInsetsGeometry? padding;
  ...
}
```

Defaults are **typed `@Style<T>`** annotations (RFC-002 R10) in one of three forms: a const value, a `.resolve` tear-off, or `null`. One-hop token defaults come from generated const **Ref catalogs** — `ColorRef`, `SizeRef`, `ShadowRef`, `StateRef`, `TextRef`, `TokenRef` — so a token change propagates to every component default without touching component code; composite defaults (`EdgeInsets.symmetric(…)`, blend math) are private top-level functions in the widget's own file.

The generator **enforces** the contract at parse time with `file:line` errors that name the fix: themed fields must be nullable, constructor params must default to null (the legacy "unreachable theme values" bug is impossible), and `lerp: true` is only accepted on interpolatable types.

**Custom style value classes.** `@Style()` on a value class groups related properties into one themed unit (`InteractiveColors` is the predefined one), emitting a `.style.g.dart` part with member-wise merge/lerp/`==` — so overriding one member cascades correctly instead of replacing the whole object.

**Generated per component** (committed, CI-verified fresh): `XTheme` (resolved, non-null) · `XThemeNullable` (sparse overrides) · `XThemeOverride` (subtree inherited widget) · `defaults(tokens)` / `merge` / `copyWith` / `lerp` / `XTheme.of(context, local)`.

**Four-level resolution, nearest wins** (DESIGN §9.9):

1. Constructor parameter
2. Subtree override — `XThemeOverride(data: ..., child: ...)`
3. App theme — `LegendThemeData.components[XThemeNullable]`
4. Token-derived annotation defaults (these *are* the kit defaults)

**Open, Type-keyed registry.** `LegendThemeData { tokens, Map<Type, Object> components }`. Consumers annotate **their own widgets**, run `legend_gen`, and register the result in the same map as kit components — identical declaration, artifacts, and resolution, zero kit changes. Proven by an in-repo consumer rehearsal (`test/consumer/balance_card.dart`) that uses only the public barrel.

**Runtime pieces.** `LegendTheme` (inherited widget + `of`/`maybeOf`), generic `LegendThemeOverride<T>`, and `AnimatedLegendTheme` — an implicitly animated widget that tweens the token object on theme change (250 ms default, curve configurable). `LegendThemeData` has value equality, so rebuilding an identical theme never invalidates dependents. The `components` map intentionally snaps rather than animates (documented; DESIGN §9.10).

## 3. Responsiveness (≠ theming)

`LegendTier { compact, medium, expanded }` via `LegendBreakpointScope` — `compact < 600 ≤ medium < 1080 ≤ expanded`, both thresholds configurable. `LegendBreakpoints` is an `InheritedModel` exposing tier and raw width as **separate aspects** (`tierOf` / `widthOf`), so a same-tier drag-resize never rebuilds tier consumers. Shell chrome flips by tier; theme switches never masquerade as responsiveness.

## 4. Primitives — the shared cores

Every component composes these; none touch Material (`Scaffold`, `InkWell`, `showDialog` are not dependencies anywhere).

| Primitive | What it provides |
|---|---|
| `LegendSurface` | animated decorated box: color, border, radius, shadows, padding, optional clipping |
| `LegendInteractive` | the one tap/hover/focus/pressed/disabled handler. Disabled means **inert** (legacy regression closed). Built-in Enter/Space/numpad-Enter activation that works with or without a `WidgetsApp` ancestor; `toggled` parameter for switch/checkbox semantics; no stuck-pressed state when disabled mid-press |
| `LegendButtonCore` | shared button chassis (states → surface → content row); consumers can build their own variants on it |
| `LegendAnchoredOverlay` | anchored overlays on `OverlayPortal` + `CompositedTransformFollower` + `TapRegion` (dropdowns, context menus) |
| `LegendModalRoute` / `showLegendModal` | Material-free `PopupRoute`: centered modals fade+scale, edge-aligned sheets slide; barrier dismiss, translatable `barrierLabel`, safe-area |
| `LegendCaret` | shared rotating chevron (dropdown, expandable) |
| `LegendPopover` | controller-synced show/hide over the anchored-overlay engine; RTL placements, optional arrow |
| `LegendSelectionControl` | role-parameterized checkbox / radio / toggle / selectable semantics, tristate, disabled-inert |

## 5. App shell

- **`LegendApp`** — `WidgetsApp`-based root wiring theme animation + breakpoints + default text style. Router-agnostic: `home` or any `RouterConfig`. Locale / `localizationsDelegates` / `supportedLocales` / `onGenerateTitle` passthrough; asserts against conflicting `navigatorKey` + `routerConfig`.
- **`LegendScaffold`** — app bar + navigation + body; below the compact breakpoint navigation renders as `LegendBottomBar`, above it as `LegendSider`.
- **`LegendAppBar`** (plain Row, no custom RenderBox), **`LegendSider`**, **`LegendBottomBar`** (upward shadow, safe-area aware) — all driven by one `LegendNavItem` model.

## 6. Components

52 components carry a full generated theme. Grouped by what they are:

**Buttons & actions** — `PrimaryLegendButton` / `SecondaryLegendButton` / `LegendTextButton` (one shared `LegendButtonCore` chassis, no duplicated layout arms; themed padding actually applies — legacy bug closed; text buttons stay transparent when disabled), `LegendCopyButton` (platform-confirmed copy, live-region feedback), `LegendAddress` (deterministic truncation + copy).

**Text & content** — `LegendText` (token typography via `LegendTextVariant { h1–h3, b1–b3 }`, plus `.rich`), `LegendMarkdown` (AST block renderer with the extensible `LegendMarkdownSyntax` registry, selectable spans), `LegendMarkdownEditor` (in-house; style-only highlighting over unchanged source with exact round-trip, incremental per-line tokenizer, list continuation / Tab indent / Cmd-B-I toggles), `LegendCodeBlock` (monospace panel + copy, highlighter hook).

**Inputs** — `LegendTextField` (on `EditableText`, replacing the 1,535-line CupertinoTextField fork), `LegendNumberField` (decimal formatter, clamp-on-commit, hold-repeat steppers), `LegendPinField` (one hidden field → N painted cells, paste-fill), `LegendDropdown<T>` (one item model, themed `menuMaxHeight` with scrolling), `LegendCombobox` (typeahead over `LegendFieldCore` + overlay), `LegendSlider` (drag + tap-to-position, divisions, slider semantics).

**Selection** — `LegendCheckbox`, `LegendRadio` / `LegendRadioGroup` (roving focus, RTL arrows), `LegendSwitch` (no Cupertino fork, RTL-correct thumb), `LegendSegmented`, `LegendChip` — all over the shared `LegendSelectionControl`.

**Data display** — `LegendCard`, `LegendList` / `LegendListItem`, `LegendInfoItem`, `LegendBadge`, `LegendAvatar`, `LegendStat` (delta arrows, `fromChange`), `LegendProgress`, `LegendEmpty`.

**Layout & disclosure** — `LegendTabs`, `LegendAccordion` (single/multi-open over `LegendExpandable`), `LegendExpandable`, `LegendDivider`, `LegendSplitPane` (draggable divider, min-px bounds, breakpoint collapse), `LegendSteps` / `LegendTimeline`, `LegendBreadcrumb` / `LegendPagination` (windowing, RTL), `LegendBody` + `LegendSliverPinnedHeader` / `LegendSliverSection`.

**Overlays** — `LegendTooltip`, `LegendMenu` (sealed entry model on `LegendPopover`, keyboard highlight), `LegendContextMenu` (long-press + secondary-click), `LegendDialog` / `showLegendDialog`, `LegendDrawer` (start/end/bottom over `LegendModalRoute`, drag-dismiss).

**Navigation** — `LegendVerticalMenu` (expandable sections on the shared `LegendNavItem`).

## 7. Forms

- **`LegendForm` + `LegendFormController`** — fields register on mount and **unregister on dispose** (legacy leak closed); `isValid` updates live; `values` by field name; `reset()` restores initial values and clears errors.
- **`LegendFormField<T>`** — generic handle so *consumer-built* inputs participate identically to kit fields (validator-less fields count as valid — legacy bug closed).
- **`LegendValidator`** — `required`, `email`, `minLength`/`maxLength`, and `compose`; all return translatable message strings, custom `LegendValidatorFn`s plug in anywhere.
- `LegendTextField` integrates via `formField` / `validator`.

## 8. Feedback

- **`showLegendToast`** — queued toasts on the overlay engine (no `ScaffoldMessenger`, the last Material service dependency is gone); optional action button; auto-dismiss.
- **`LegendLoading`** — animated arc spinner at themed size.
- **`LegendShimmer`** — loading placeholder shimmer.
- **`LegendBanner`** — inline alert. *(Flagged: derives amber locally; there is no `warning`/`onWarning` token pair yet.)*

## 9. Codegen — the `legend_gen` CLI

Standalone pure-Dart CLI (decided over build_runner), published for consumers, pure AST parsing, strictly **one file in → one file out**.

| Command | Purpose |
|---|---|
| `legend_gen themes [paths]` | generate `*.theme.g.dart` next to each annotated source |
| `legend_gen themes --check` | CI freshness gate — fails on stale/missing output |
| `legend_gen themes --watch` | regenerate on save (rename/atomic-save-race proof) |
| `legend_gen create <ClassName>` | scaffold a contract-correct annotated component + its theme file in one step |
| `legend_gen docs [paths]` | generate `*.docs.g.dart` manifests — the docs-CMS content, sourced from doc comments |
| `legend_gen tokens [paths]` | generate `*.tokens.g.dart` (`copyWith`, lerp, `==`) plus the `Ref` tear-off catalogs |
| `legend_gen doctor [paths]` | report missing, stale, or orphaned generated files and contract violations |
| `legend_gen update` | update `legend_gen` to the latest version |

All three generation commands share `--check` (CI freshness gate) and `--watch` (never-crash, debounced); shell completion ships too. Combining `--check` with `--watch` is a usage error (exit 64).

Guarantees: every contract violation is a `file:line` diagnostic (never silently broken output); generated files import their own source (types declared next to the widget just work); output is version-stamped; the emitter is golden-tested (`UPDATE_GOLDENS=1` flow).

Measured: ~28 generated LOC per themed property (legacy ~35) with zero naming conventions or manual registration; the generator is 541 LOC vs legacy's ~1,050.

## 10. Accessibility & input

- Full keyboard activation on every interactive component (Enter / Space / numpad Enter), focus highlights via `FocusableActionDetector`.
- Honest semantics: buttons announce as buttons, switches as toggles with state; disabled means disabled; no hard-coded English labels anywhere (all labels/barrier text caller-supplied).
- RTL-correct layout (directional alignment in the switch and shell).

## 11. Quality & guarantees

- **849 tests** across the workspace (kit 690, generator 115, example 44), including regression tests for every closed legacy bug: disabled-but-tappable buttons, unreachable theme defaults, ignored themed padding, never-unregistered form fields, validator-less fields pinning forms invalid, whole-theme lerp.
- `very_good_analysis`, zero analyzer issues; `dart format` enforced.
- CI on every push and PR to `main`: format → analyze → all test suites → `legend_gen --check` freshness gate → example web build.
- Near-zero runtime dependencies; icon-agnostic core (verified: web icon-font tree-shaking 1.6 MB → 8 KB).
- The `example/` app is a documentation site with a live playground: every shipped component has a live instance and at least one editable knob, plus a manifest-driven **Theme Explorer** built from the 54 committed `*.docs.g.dart` manifests (completeness pinned by a filesystem-scan test). It doubles as the consumer-workflow reference — it uses only the public barrel.

## Not yet available

Tracked in [ROADMAP.md](../ROADMAP.md):

- **`LegendQrCode`** — the one RFC-004 widget not built; parked pending sign-off on a QR-encode dependency.
- **`LegendSelectionArea`** — a widgets-layer `SelectableRegion` with a kit-styled context menu, to drop the docs site's last Material import (`MaterialLocalizations`).
- **Token gaps** — no `warning`/`onWarning` pair (`LegendBanner` derives amber locally); token classes have no generated manifests, so the Theme Explorer's token/seed reference stays hand-curated.
- **Flagged dedups** — `LegendCodeBlock` ↔ `LegendCopyButton`, and the Markdown fence path; `LegendDrawer.show` vs the top-level `showLegend…` naming; sibling overlay panels lack `IntrinsicWidth` (only `LegendMenu` pins it).
- **Editor follow-ups** — IME soft-keyboard Enter continuation, scroll-synced preview, fence auto-close.
- **Deferred by decision** — screenshot goldens (revisit when a visual regression bites), member API docs / publishing, `legend_icons` package + `legend_gen icons`, `legend_gen` consumer-distribution default (needs a real external consumer), and the DESIGN §9.10–9.11 deferrals (component-map animation, dropdown trigger theming / flip-above / keyboard nav, tap-to-position cursor).
- **Next milestone** — the two flagship apps (cross-platform crypto wallet, NotebookLM-class AI workspace) that drove the RFC-004 catalog.
