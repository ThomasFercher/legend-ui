# Roadmap

Phases per [docs/DESIGN.md](docs/DESIGN.md) §8. Check items off as they land; add regression-test references when closing legacy bugs (DESIGN §1 / legacy-docs 01 §4.2).

## Phase 0 — validate the theory (current)

Goal: prove the token model, the decorator contract, and the CLI end-to-end on one hard component — including the consumer workflow. Go/no-go review at the end; revisit DESIGN §2/§5 if targets are missed.

- [ ] `NomoTokens` (colors, sizes, typography, shadows) with handwritten `copyWith`/`lerp`
- [ ] Annotation contract: `@NomoThemeable` / `@Themed` (decide string token-expressions vs typed `TokenRef` — DESIGN §9.2)
- [ ] `NomoThemeData` open Type-keyed registry + `NomoTheme` widget + delegate skeleton
- [ ] `nomo_gen themes` MVP: analyzer-AST parse of a fixture widget → emit the full artifact set (Theme, ThemeNullable, merge/copyWith/lerp, Override widget, `.of(context)`)
- [ ] Generator golden test: annotated fixture in → expected `.g.dart` out
- [ ] Minimal primitives: `NomoSurface`, `NomoInteractive`
- [ ] Port `PrimaryNomoButton` on the primitives + generated theme
- [ ] Minimal `NomoOverlayEngine` + port one dropdown
- [ ] Consumer-workflow rehearsal: annotate a widget in the (future) example app as if third-party, generate, register in the theme map, override at all five levels
- [ ] Measurements: handwritten LOC/component, generated LOC/property (target: well under legacy's ~35), theme-switch performance
- [ ] Go/no-go review

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
