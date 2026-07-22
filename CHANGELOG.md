# Changelog

## 1.0.0-dev.6 (unreleased) — widget expansion (RFC-004/005) + full playground

- **RFC-004 widget catalog, Waves 0–3 complete** — 30+ new components, each built by an agent under the committed `legend-widget-author` spec and merged one at a time behind the strict gate:
  - **Foundations**: `LegendSelectionControl` (shared checked/pressed/focus base), `LegendPopover` (positioned surface over the anchored-overlay engine).
  - **Selection**: `LegendCheckbox`, `LegendRadio`/`LegendRadioGroup`, `LegendSegmented`, `LegendChip` — all on `LegendSelectionControl`.
  - **Inputs**: `LegendCombobox` (typeahead), `LegendNumberField` (decimal + stepper), `LegendPinField` (fixed-length code), `LegendSlider`.
  - **Data display & layout**: `LegendList`/`LegendListItem`, `LegendBadge`, `LegendAvatar`, `LegendStat`, `LegendTabs`, `LegendAccordion`, `LegendSplitPane`, `LegendSteps`, `LegendTimeline`, `LegendBreadcrumb`, `LegendPagination`, `LegendEmpty`, `LegendProgress`.
  - **Overlays**: `LegendTooltip`, `LegendMenu` (button-anchored), `LegendDrawer` (edge/bottom sheet with drag-dismiss).
  - **Feedback**: `LegendBanner` (persistent inline alert).
  - **Wallet/workspace utilities**: `LegendCopyButton`, `LegendAddress` (copy + truncation), `LegendCodeBlock`.
  - Parked: `LegendQrCode` — awaits maintainer sign-off on a QR-encode dependency.
- **RFC-005 `LegendMarkdownEditor`** — an in-house editable markdown surface on `LegendFieldCore`: a style-only `buildTextSpan` controller (never mutates source; exact round-trip), an incremental tokenizer, and an **extensible `LegendMarkdownSyntax` registry shared with the `LegendMarkdown` renderer** so domain-specific notations highlight in the editor and render in the reader from one registration. Ships with `LegendMarkdown` (block renderer: lists/tables/headings/code over `LegendText.rich`).
- **Playground expansion (RFC-002 step-D relaunch)** — every shipped widget now has a live, interactive instance in the example app's preview column, and a new manifest-driven **Theme Explorer** configures all 54 components straight from their generated `*.docs.g.dart` manifests (type-dispatched editors → sparse level-3 overrides in the open `components` map). 48 generated theme-surface tables and a custom-syntax editor demo close the docs gaps.
- Suites: kit 690 · generator 115 · example 44 tests, `flutter analyze` clean, all `legend_gen --check` fresh.

## 1.0.0-dev.5 (unreleased) — docs site + playground

- `example/` is now the **Legend UI documentation site**: eleven doc pages (getting started, theming concepts, buttons, typography, inputs & forms, selection, overlays, layout, feedback, shell, playground) with live demos, code snippets, and themed-property tables.
- **Live theme playground**: presets (Light/Dark/Emerald/Violet), brand-color editing (swatches + hex), corner radius and density controls — all through public token `copyWith`, animating site-wide via `AnimatedLegendTheme`. Available as a side panel on wide screens and as the Playground page everywhere.
- **Component override editor**: registers a sparse `PrimaryLegendButtonThemeNullable` in the open `components` map (level 3) and shows the exact code it emits — executable documentation of the consumer workflow (widget-tested).

## 1.0.0-dev.4 (unreleased) — Legend rebrand

- **Full rebrand from Nomo to Legend** (2026-07-09): packages renamed (`nomo_ui_kit` → `legend_ui`, `nomo_gen` → `legend_gen`), every public symbol re-prefixed (`NomoTokens` → `LegendTokens`, `@NomoThemeable` → `@LegendThemeable`, `NomoApp` → `LegendApp`, …), all generated files regenerated, docs updated. "Nomo" now only refers to the frozen legacy kit on `main`. Earlier entries below use Legend names for the same code, pre-rename.
- Roadmap direction set: next milestone is evolving the example gallery into a **showcase/playground with a live theme configurator**; screenshot goldens deferred; vertical menu + `LegendBody` will be ported with a scrolling/sliver design pass.

## 1.0.0-dev.3 (unreleased) — Phase 2 completion + review hardening

- Form system: `LegendForm`/`LegendFormController`, `LegendFormField<T>`, `LegendValidators`; `LegendTextField` plugs in via `formField`/`validator`. Closes legacy bugs: fields now unregister on dispose, validator-less fields no longer pin forms invalid (regression-tested).
- Feedback: queued `LegendToast` on the overlay engine (no ScaffoldMessenger — the last Material service dependency is gone), `LegendLoading`, `LegendShimmer`.
- Small components: `LegendDivider`, `LegendExpandable`, `LegendInfoItem`, `LegendContextMenu`; shared `LegendCaret` primitive.
- `legend_gen create` (scaffold an annotated widget) and `legend_gen doctor` (workspace sanity checks).
- Review hardening:
  - Generated theme files import their own source file — consumer types declared next to the widget now compile (C1).
  - `LegendInteractive`: Enter/Space/numpad-Enter activation works without a `WidgetsApp` ancestor; optional `toggled` for switch/checkbox semantics; disabling mid-press no longer leaves a stuck pressed state (I1/I3, regression-tested).
  - `LegendSwitch` announces as a toggle with a caller-supplied `semanticLabel` (hard-coded English 'On'/'Off' removed); thumb mirrors correctly under RTL (M1).
  - Text buttons stay transparent when disabled instead of growing a grey slab (I2).
  - `LegendDropdown`: themed `menuMaxHeight` (default 320), menu scrolls on long lists (I4).
  - `LegendApp`: `locale`/`localizationsDelegates`/`supportedLocales`/`onGenerateTitle` passthrough; asserts against `navigatorKey` + `routerConfig` together (I5).
  - `LegendThemeData` has value equality — rebuilding an identical theme no longer invalidates every dependent (I7).
  - `LegendBottomBar` casts its shadow upward; `showLegendModal` takes a translatable `barrierLabel` (M6).
  - `legend_gen`: `lerp: true` on a non-interpolatable type is a `file:line` error (M4); `--watch` survives atomic-save races (M5).
- Resolution model documented as four levels — "kit defaults" collapsed into token-derived annotation defaults (DESIGN §9.9).

## 1.0.0-dev.2 (unreleased) — Phases 1–2 core

- Theme animation (`AnimatedLegendTheme`: one token lerp per switch), `LegendBreakpoints` responsive tiers, `LegendApp` root (WidgetsApp-based, optional `RouterConfig`).
- Modal engine (`LegendModalRoute`/`showLegendModal`) + `LegendDialog`/`showLegendDialog` — no Material dialogs.
- `LegendText` (token typography) and `LegendTextField` on `EditableText` — the CupertinoTextField fork is gone.
- `LegendButtonCore` chassis; `SecondaryLegendButton`, `LegendTextButton`; `LegendCard`; `LegendSwitch`.
- Responsive shell: `LegendScaffold`, `LegendAppBar`, `LegendSider`, `LegendBottomBar`, one `LegendNavItem` model — chrome flips by breakpoint tier, not theme swaps.
- `legend_gen themes --watch`; CI runs the `--check` freshness gate.
- Example gallery app (workspace member, web-buildable, no stubs) doubling as the consumer reference.

## 1.0.0-dev.1 (unreleased) — Phase 0

- `LegendTokens` (colors/sizes/typography/shadows) with single-object `lerp`.
- `@LegendThemeable`/`@Themed` decorator contract; `LegendThemeData` with the open Type-keyed component registry; generic `LegendThemeOverride`.
- `legend_gen themes`: AST-based generation of the full per-component artifact set, contract diagnostics (`file:line`), `--check` freshness gate, golden-tested. Runs as a normal dev dependency (`dart run legend_gen themes lib`).
- Primitives: `LegendSurface`, `LegendInteractive`, `LegendAnchoredOverlay`.
- Components: `PrimaryLegendButton` (five-level resolution verified; disabled buttons are genuinely inert — fixes a legacy bug), unified `LegendDropdown`.
- Consumer-workflow rehearsal: an out-of-tree widget themed with the identical decorator/generator/registry workflow (tested).

## 1.0.0-dev.0 (unreleased)

- Workspace scaffold for the full rewrite: `packages/legend_ui` + `packages/legend_gen` (standalone CLI, decided over build_runner).
- Accepted design RFC checked in as `docs/DESIGN.md`; phased plan in `ROADMAP.md`.
- Legacy kit (v0.0.36) frozen on `main`; complete legacy documentation on the `legacy-docs` branch.
