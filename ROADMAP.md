# Roadmap

Phases per [docs/DESIGN.md](docs/DESIGN.md) §8. Check items off as they land; add regression-test references when closing legacy bugs (DESIGN §1 / legacy-docs 01 §4.2).

> **2026-07-09 — direction set**: the kit is rebranded **Legend UI** (`legend_ui`/`legend_gen`, `Legend*` symbols). Next milestone: the **showcase/playground** (below). Distribution decision deferred; screenshot goldens deferred until visual regressions bite.

## Phase 0 — validate the theory

Goal: prove the token model, the decorator contract, and the CLI end-to-end on one hard component — including the consumer workflow. Go/no-go review at the end; revisit DESIGN §2/§5 if targets are missed.

- [x] `LegendTokens` (colors, sizes, typography, shadows) with handwritten `copyWith`/`lerp`
- [x] Annotation contract: `@LegendThemeable` / `@Themed` (MVP uses string token-expressions, validated by the analyzer on emitted code — dated note in DESIGN §9.2; typed `TokenRef` still open)
- [x] `LegendThemeData` open Type-keyed registry + `LegendTheme` widget (delegate skeleton deferred to Phase 1 alongside `LegendBreakpoints`)
- [x] `legend_gen themes` MVP: analyzer-AST parse → full artifact set; contract diagnostics with file:line (nullable fields, null constructor defaults, adjacent strings)
- [x] Generator golden test (`UPDATE_GOLDENS=1` flow) + contract-violation tests
- [x] Minimal primitives: `LegendSurface`, `LegendInteractive`
- [x] Port `PrimaryLegendButton` — layered resolution proven by widget tests (four levels — DESIGN §9.9); **closes legacy "disabled buttons stay tappable"** with a regression test
- [x] `LegendAnchoredOverlay` primitive + unified `LegendDropdown` (one item model)
- [x] Consumer-workflow rehearsal: `test/consumer/balance_card.dart` uses only the public barrel + `dart run legend_gen themes test/consumer`; registers in the same components map as kit widgets (tested)
- [x] Measurements (2026-07-09):
  - Generated LOC/property: button 150/6 = **25**, dropdown 135/5 = **27**, consumer card 102/3 = 34 (fixed overhead dominates small counts) → avg **~28 vs legacy ~35**, with zero naming conventions, no symbol collisions, no manual registration.
  - Handwritten: button 144 LOC incl. themed declarations; entire runtime core (tokens+theme+annotations+3 primitives) 1,137 LOC.
  - Generator: 541 LOC total vs legacy's ~1,050 — and it's in-repo, AST-based, tested.
  - Theme-switch performance: micro-benchmark deferred to Phase 1 (needs `AnimatedTokens`); architecture already lerps 1 token object instead of 48 classes.
- [x] Go/no-go review — **GO** (2026-07-09): architecture validated through Phase 2; continued under the Legend rebrand

## Phase 1 — primitives complete

- [x] Overlay engine: anchored (`LegendAnchoredOverlay`) + modal (`LegendModalRoute`/`showLegendModal` — fade/scale centered, slide for edges, barrier dismiss, safe-area)
- [x] Text core: `LegendText` on token typography — legacy's dead `fit:` API intentionally not ported (DESIGN §9.4 stays open for an explicit `LegendFittedText` if a real need appears)
- [x] Field core: `LegendTextField` on `EditableText` (placeholder/title/error/focus border/disabled) — replaces the 1,535-line CupertinoTextField fork; selection toolbar/handles still TODO
- [x] Theme animation: `AnimatedLegendTheme` lerps the token object once per switch (tested mid-animation); `LegendBreakpoints`/`LegendBreakpointScope` for responsive tiers; `LegendApp` root (WidgetsApp, optional RouterConfig)
- [~] Golden-test infrastructure — **deferred by decision (2026-07-09)**: behavior-level widget tests suffice; revisit when a visual regression actually bites
- [x] `legend_gen` hardened: file:line diagnostics, `--check` (in CI), `--watch`, version stamping; `create` (annotated-widget scaffold) and `doctor` (workspace sanity) subcommands
- [ ] Decide `legend_gen` consumer distribution default (DESIGN §9.7) — needs a real external consumer

## Phase 2 — component ports

Consolidations per DESIGN §3; every port closes its legacy bugs.

- [x] Buttons: Primary / Secondary / Text on the shared `LegendButtonCore` chassis (no duplicated layout arms; themed padding actually applies — legacy bug; disabled = inert — legacy bug, regression-tested)
- [x] Surfaces: `LegendCard` on `LegendSurface` (one shadow system; reachable theme defaults)
- [x] Menus/selection: one `LegendDropdown` (one item model), `LegendSwitch` (no Cupertino fork)
- [x] Shell: `LegendScaffold` + `LegendAppBar` (plain Row, no custom RenderBox) + `LegendSider` + `LegendBottomBar`, chrome driven by breakpoint tier not theme swaps; one `LegendNavItem` model
- [x] Dialog: `LegendDialog` + `showLegendDialog` on the kit's own modal engine (no Material `showDialog`)
- [x] Form system: `LegendForm`/`LegendFormController` + `LegendFormField<T>` + `LegendValidators` — **closes legacy "fields never unregistered" and "validator-less fields pin forms invalid"** with regression tests; `LegendTextField` integrates via `formField`/`validator`
- [x] Feedback: queued `LegendToast` (overlay engine, no ScaffoldMessenger — resolves DESIGN §9.6 toward the overlay engine), `LegendLoading`, `LegendShimmer`
- [x] Small components: `LegendDivider`, `LegendExpandable`, `LegendInfoItem`, `LegendContextMenu` (+ shared `LegendCaret` primitive)
- [x] Post-review hardening (2026-07-09): generated files import their own source (C1); `LegendInteractive` keyboard activation without WidgetsApp, toggle semantics, no stuck-pressed after mid-press disable (I1/I3); transparent disabled text buttons (I2); dropdown `menuMaxHeight` + scrollable menu (I4); `LegendApp` locale passthrough + navigatorKey/routerConfig assert (I5); `LegendThemeData` value equality (I7); RTL switch thumb (M1); `lerp:` type validation in legend_gen (M4); crash-proof `--watch` (M5); upward bottom-bar shadow + translatable modal `barrierLabel` (M6)
- [ ] Remaining legacy inventory (decided 2026-07-09: **port both, improved**): vertical menu and `LegendBody` (single-mode route body) — the sliver/scrolling design pass is done: [RFC-003](docs/RFC-003-LEGEND-BODY.md) (proposed 2026-07-10) specs `LegendBody` + the `LegendSliver*` helpers; both ports are queued as Phase 2.6 step F
- [ ] Deferred (tracked in DESIGN §9.10–9.11): component-map animation, dropdown trigger theming / flip-above / keyboard nav, tap-to-position cursor, import-prefixed annotations

## Phase 2.5 — docs site + showcase playground (landed 2026-07-09)

Evolve `example/` from a static gallery into a **documentation site with a live playground** (decided 2026-07-09: docs are part of the playground app):

- [x] Docs pages per component group: description, live demos, code snippets, themed-property tables (11 pages)
- [x] Getting-started and theming-concepts pages (tokens, four-level resolution, consumer-widget workflow)
- [x] Live theme configurator panel: presets (Light/Dark/Emerald/Violet), brand colors (swatches + hex), corner radius, density — animates through `AnimatedLegendTheme`; site-wide side panel on wide tiers
- [x] Per-component override editor — registers a sparse `PrimaryLegendButtonThemeNullable` in the level-3 `components` map, tested
- [x] Sensible preset themes to start from (light/dark plus two brand variants)
- [x] Keep it the consumer-workflow reference: playground code uses only the public barrel (tested: preset/brand/override restyling)

## Phase 2.6 — RFC-002 refactor: derived defaults & generated ceremony (current)

The accepted [RFC-002](docs/RFC-002-DERIVED-DEFAULTS.md) drives this phase; its §5 table carries the dated landed notes and measurements. Checklist mirror:

- [x] **A — generator sprint** (2026-07-09): typed `@Style<T>` contract, part-of emission with the hidden `_theme(context)` resolver, widget-type registry keys, `legend_gen docs` manifests; 82 fields migrated, all 20 hand-written mirror blocks deleted
- [x] **B — token sprint** (2026-07-09): `@LegendTokenData` generated token members (−217 hand LOC); `LegendSeed`/`LegendRamp`/`LegendTokens.fromSeed` (AntD-adapted ramp, ≥ 4.5:1 pair guarantee)
- [x] **A2 — CLI polish** (2026-07-09): `legend_gen` rebuilt to the Serverpod/Dart Frog bar — mason_logger, exit-code table, never-crash `--watch`, `update`/`doctor`/completion; suite 46 → 87
- [x] **C — component adoption** (2026-07-09): state-styled interactive surfaces, shared `LegendButtonCore` chassis theme, standardized doc comments (21/21 manifests non-empty), `LegendText.rich`; kit suite 110 → 144
- [x] **C2 — Ref catalogs** (2026-07-10): token defaults live fully inside `@Style.resolve` via generated const tear-off catalogs (`LegendColorsRef` …); composites as private top-level functions
- [ ] **D — playground & docs CMS** (in flight): `LegendThemeController` in the kit, manifest-driven configurator over every themed variable, Theme reference page, seed section
- [ ] **E — custom style classes, granular rebuilds, wiring** (in flight): custom `@Style` classes replace `LegendStates<T>` (R6 final, `InteractiveColors` predefined), per-field `listen:` opt-out + `_field` accessors + `ValueListenable`s (R12), extensions-first wiring with the opt-in `_$XBase` (R13), terse Ref renames (`ColorRef` et al.)
- [ ] **F — remaining ports & primitives** (queued): implement [RFC-003 `LegendBody`](docs/RFC-003-LEGEND-BODY.md) + `LegendSliver*` helpers and migrate the docs site onto them, extract `LegendFieldCore` from `LegendTextField`, widen the `LegendInteractive` vocabulary (secondary-tap, focus-tap), port the vertical menu; regression tests for every legacy bug closed on the way

### Audit follow-ups (2026-07-10 — LegendApp/rebuild audit, measured on Flutter 3.38.6)

Verdict: `LegendApp` is **current** — zero window-singleton usage, no deprecated WidgetsApp params, multi-window (experimental in 3.38) needs no structural change. The R12-relevant findings (type-scoped registry notification + lerp identity fast-paths) are folded into RFC-002 R12 and Phase E. Remaining maintenance items:

- [x] `LegendBreakpoints`: switch `MediaQuery.sizeOf(context).width` to `MediaQuery.widthOf` (3.35+) and split tier vs width dependencies (aspects or `tierOf`/`widthOf` statics) — measured: same-tier drag-resize rebuilds every tier consumer *(landed 2026-07-10: `InheritedModel` with `tierOf`/`widthOf`, kit + docs-site call sites migrated, regression tests in `breakpoints_test.dart`)*
- [ ] `LegendSelectionArea`: widgets-layer `SelectableRegion` + kit-styled `contextMenuBuilder` — drops the `MaterialLocalizations` delegate requirement from consumers and the docs site's last Material import; evaluate 3.38 `OverlayPortal.overlayChildLayoutBuilder` for the anchored-overlay engine in the same pass
- [x] `LegendApp` passthroughs: `restorationScopeId`, `shortcuts`/`actions`, `debugShowCheckedModeBanner`; document the Android predictive-back gap for custom routes *(landed 2026-07-10, forwarding test in `shell_test.dart`)*
- [x] Consumer rebuild guidance (docs site as reference): controller above `LegendApp`, stable home child, token reads in the narrowest `Builder` — measured: inline children under a root `ListenableBuilder` rebuild the whole tree 17× per theme toggle vs dependents-only with a stable child; document the (semantically necessary) `DefaultTextStyle` cascade during color animation *(landed 2026-07-10: docs app restructured — stable `_home` + self-listening dark switch; cascade + stable-child guidance on the `LegendApp` doc comment)*

## Phase 3 — icons & polish

- [ ] `packages/legend_icons` (optional, tree-shakeable, no reflection map) + `legend_gen icons`
- [x] Example/gallery app — every shipped component, no empty stubs; web build verified (icon tree-shaking works: Material glyph font 1.6 MB → 8 KB, validating the icon-agnostic core)
- [ ] `packages/legend_gen_builder` (optional thin build_runner wrapper) if demand exists
- [ ] Publishing decision (pub.dev vs submodule); re-enable `public_member_api_docs` and write member docs before publishing

## Open questions

Tracked in [docs/DESIGN.md](docs/DESIGN.md) §9 — resolve each with a dated note in that section.
