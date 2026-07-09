# Roadmap

Phases per [docs/DESIGN.md](docs/DESIGN.md) §8. Check items off as they land; add regression-test references when closing legacy bugs (DESIGN §1 / legacy-docs 01 §4.2).

> **2026-07-09 — direction set**: the kit is rebranded **Legend UI** (`legend_ui`/`legend_gen`, `Legend*` symbols). Next milestone: the **showcase/playground** (below). Distribution decision deferred; screenshot goldens deferred until visual regressions bite.

## Phase 0 — validate the theory (current)

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
- [ ] Remaining legacy inventory (decided 2026-07-09: **port both, improved**): vertical menu and `LegendBody` (single-mode route body) — both need a design pass around slivers/scrolling rather than a straight port
- [ ] Deferred (tracked in DESIGN §9.10–9.11): component-map animation, dropdown trigger theming / flip-above / keyboard nav, tap-to-position cursor, import-prefixed annotations

## Phase 2.5 — showcase playground (next milestone, decided 2026-07-09)

Evolve `example/` from a static gallery into a **showcase/playground**:

- [ ] Live theme configurator panel: edit token colors/sizes, toggle light/dark, see every component update through `AnimatedLegendTheme`
- [ ] Per-component override editor — demonstrates the level-3 `components` map exactly as a consumer would use it
- [ ] Sensible preset themes to start from (light/dark plus at least one brand variant)
- [ ] Keep it the consumer-workflow reference: playground code uses only the public barrel

## Phase 3 — icons & polish

- [ ] `packages/legend_icons` (optional, tree-shakeable, no reflection map) + `legend_gen icons`
- [x] Example/gallery app — every shipped component, no empty stubs; web build verified (icon tree-shaking works: Material glyph font 1.6 MB → 8 KB, validating the icon-agnostic core)
- [ ] `packages/legend_gen_builder` (optional thin build_runner wrapper) if demand exists
- [ ] Publishing decision (pub.dev vs submodule); re-enable `public_member_api_docs` and write member docs before publishing

## Open questions

Tracked in [docs/DESIGN.md](docs/DESIGN.md) §9 — resolve each with a dated note in that section.
