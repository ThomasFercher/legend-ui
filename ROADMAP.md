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

- [ ] Overlay engine (anchored + modal, dismiss, animation, safe-area)
- [ ] Text core (+ decide fate of auto-fit — DESIGN §9.4)
- [ ] Field core (thin `EditableText` wrapper — no more CupertinoTextField fork)
- [ ] Golden-test infrastructure for components
- [ ] `nomo_gen` hardened: diagnostics with file:line, `--check`, `--watch`, version stamping
- [ ] Decide `nomo_gen` consumer distribution default (DESIGN §9.7)

## Phase 2 — component ports

Dependency order: buttons → surfaces → menus/selection → input/form → shell. Consolidations per DESIGN §3 (one dropdown, one switch, one elevation system, `NomoBody` single-mode, real form lifecycle). Every port closes its legacy bugs with a regression test.

## Phase 3 — icons & polish

- [ ] `packages/nomo_icons` (optional, tree-shakeable, no reflection map) + `nomo_gen icons`
- [ ] Example/gallery app rebuilt — every component, no empty stubs
- [ ] `packages/nomo_gen_builder` (optional thin build_runner wrapper) if demand exists
- [ ] Publishing decision (pub.dev vs submodule)

## Open questions

Tracked in [docs/DESIGN.md](docs/DESIGN.md) §9 — resolve each with a dated note in that section.
