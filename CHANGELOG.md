# Changelog

## 1.0.0-dev.2 (unreleased) — Phases 1–2 core

- Theme animation (`AnimatedNomoTheme`: one token lerp per switch), `NomoBreakpoints` responsive tiers, `NomoApp` root (WidgetsApp-based, optional `RouterConfig`).
- Modal engine (`NomoModalRoute`/`showNomoModal`) + `NomoDialog`/`showNomoDialog` — no Material dialogs.
- `NomoText` (token typography) and `NomoTextField` on `EditableText` — the CupertinoTextField fork is gone.
- `NomoButtonCore` chassis; `SecondaryNomoButton`, `NomoTextButton`; `NomoCard`; `NomoSwitch`.
- Responsive shell: `NomoScaffold`, `NomoAppBar`, `NomoSider`, `NomoBottomBar`, one `NomoNavItem` model — chrome flips by breakpoint tier, not theme swaps.
- `nomo_gen themes --watch`; CI runs the `--check` freshness gate.
- Example gallery app (workspace member, web-buildable, no stubs) doubling as the consumer reference.

## 1.0.0-dev.1 (unreleased) — Phase 0

- `NomoTokens` (colors/sizes/typography/shadows) with single-object `lerp`.
- `@NomoThemeable`/`@Themed` decorator contract; `NomoThemeData` with the open Type-keyed component registry; generic `NomoThemeOverride`.
- `nomo_gen themes`: AST-based generation of the full per-component artifact set, contract diagnostics (`file:line`), `--check` freshness gate, golden-tested. Runs as a normal dev dependency (`dart run nomo_gen themes lib`).
- Primitives: `NomoSurface`, `NomoInteractive`, `NomoAnchoredOverlay`.
- Components: `PrimaryNomoButton` (five-level resolution verified; disabled buttons are genuinely inert — fixes a legacy bug), unified `NomoDropdown`.
- Consumer-workflow rehearsal: an out-of-tree widget themed with the identical decorator/generator/registry workflow (tested).

## 1.0.0-dev.0 (unreleased)

- Workspace scaffold for the full rewrite: `packages/nomo_ui_kit` + `packages/nomo_gen` (standalone CLI, decided over build_runner).
- Accepted design RFC checked in as `docs/DESIGN.md`; phased plan in `ROADMAP.md`.
- Legacy kit (v0.0.36) frozen on `main`; complete legacy documentation on the `legacy-docs` branch.
