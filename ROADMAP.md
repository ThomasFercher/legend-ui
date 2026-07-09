# Roadmap

Phases per [docs/DESIGN.md](docs/DESIGN.md) §8. Check items off as they land; add regression-test references when closing legacy bugs (DESIGN §1 / legacy-docs 01 §4.2).

## Phase 0 — validate the theory (current)

Goal: prove the token model, the decorator contract, and the CLI end-to-end on one hard component — including the consumer workflow. Go/no-go review at the end; revisit DESIGN §2/§5 if targets are missed.

- [x] `NomoTokens` (colors, sizes, typography, shadows) with handwritten `copyWith`/`lerp`
- [x] Annotation contract: `@NomoThemeable` / `@Themed` (MVP uses string token-expressions, validated by the analyzer on emitted code — dated note in DESIGN §9.2; typed `TokenRef` still open)
- [x] `NomoThemeData` open Type-keyed registry + `NomoTheme` widget (delegate skeleton deferred to Phase 1 alongside `NomoBreakpoints`)
- [x] `nomo_gen themes` MVP: analyzer-AST parse → full artifact set; contract diagnostics with file:line (nullable fields, null constructor defaults, adjacent strings)
- [x] Generator golden test (`UPDATE_GOLDENS=1` flow) + contract-violation tests
- [x] Minimal primitives: `NomoSurface`, `NomoInteractive`
- [x] Port `PrimaryNomoButton` — five-level resolution proven by widget tests; **closes legacy "disabled buttons stay tappable"** with a regression test
- [x] `NomoAnchoredOverlay` primitive + unified `NomoDropdown` (one item model)
- [x] Consumer-workflow rehearsal: `test/consumer/balance_card.dart` uses only the public barrel + `dart run nomo_gen themes test/consumer`; registers in the same components map as kit widgets (tested)
- [x] Measurements (2026-07-09):
  - Generated LOC/property: button 150/6 = **25**, dropdown 135/5 = **27**, consumer card 102/3 = 34 (fixed overhead dominates small counts) → avg **~28 vs legacy ~35**, with zero naming conventions, no symbol collisions, no manual registration.
  - Handwritten: button 144 LOC incl. themed declarations; entire runtime core (tokens+theme+annotations+3 primitives) 1,137 LOC.
  - Generator: 541 LOC total vs legacy's ~1,050 — and it's in-repo, AST-based, tested.
  - Theme-switch performance: micro-benchmark deferred to Phase 1 (needs `AnimatedTokens`); architecture already lerps 1 token object instead of 48 classes.
- [ ] Go/no-go review ← **next: user reviews Phase 0 results**

## Phase 1 — primitives complete

- [x] Overlay engine: anchored (`NomoAnchoredOverlay`) + modal (`NomoModalRoute`/`showNomoModal` — fade/scale centered, slide for edges, barrier dismiss, safe-area)
- [x] Text core: `NomoText` on token typography — legacy's dead `fit:` API intentionally not ported (DESIGN §9.4 stays open for an explicit `NomoFittedText` if a real need appears)
- [x] Field core: `NomoTextField` on `EditableText` (placeholder/title/error/focus border/disabled) — replaces the 1,535-line CupertinoTextField fork; selection toolbar/handles still TODO
- [x] Theme animation: `AnimatedNomoTheme` lerps the token object once per switch (tested mid-animation); `NomoBreakpoints`/`NomoBreakpointScope` for responsive tiers; `NomoApp` root (WidgetsApp, optional RouterConfig)
- [ ] Golden-test infrastructure for components (behavior-level widget tests exist; screenshot goldens TODO)
- [x] `nomo_gen` hardened: file:line diagnostics, `--check` (in CI), `--watch`, version stamping
- [ ] Decide `nomo_gen` consumer distribution default (DESIGN §9.7) — needs a real external consumer

## Phase 2 — component ports

Consolidations per DESIGN §3; every port closes its legacy bugs.

- [x] Buttons: Primary / Secondary / Text on the shared `NomoButtonCore` chassis (no duplicated layout arms; themed padding actually applies — legacy bug; disabled = inert — legacy bug, regression-tested)
- [x] Surfaces: `NomoCard` on `NomoSurface` (one shadow system; reachable theme defaults)
- [x] Menus/selection: one `NomoDropdown` (one item model), `NomoSwitch` (no Cupertino fork)
- [x] Shell: `NomoScaffold` + `NomoAppBar` (plain Row, no custom RenderBox) + `NomoSider` + `NomoBottomBar`, chrome driven by breakpoint tier not theme swaps; one `NomoNavItem` model
- [x] Dialog: `NomoDialog` + `showNomoDialog` on the kit's own modal engine (no Material `showDialog`)
- [ ] Form system (registration/unregistration lifecycle, working validity model, `NomoValidator` set)
- [ ] Remaining legacy inventory: snackbar/toast, context menu, expandable, vertical menu, divider, info item, shimmer/loading, `NomoBody` (single-mode route body)

## Phase 3 — icons & polish

- [ ] `packages/nomo_icons` (optional, tree-shakeable, no reflection map) + `nomo_gen icons`
- [x] Example/gallery app — every shipped component, no empty stubs; web build verified (icon tree-shaking works: Material glyph font 1.6 MB → 8 KB, validating the icon-agnostic core)
- [ ] `packages/nomo_gen_builder` (optional thin build_runner wrapper) if demand exists
- [ ] Publishing decision (pub.dev vs submodule); re-enable `public_member_api_docs` and write member docs before publishing

## Open questions

Tracked in [docs/DESIGN.md](docs/DESIGN.md) §9 — resolve each with a dated note in that section.
