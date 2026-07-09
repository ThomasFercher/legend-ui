# Changelog

## 1.0.0-dev.3 (unreleased) — Phase 2 completion + review hardening

- Form system: `NomoForm`/`NomoFormController`, `NomoFormField<T>`, `NomoValidators`; `NomoTextField` plugs in via `formField`/`validator`. Closes legacy bugs: fields now unregister on dispose, validator-less fields no longer pin forms invalid (regression-tested).
- Feedback: queued `NomoToast` on the overlay engine (no ScaffoldMessenger — the last Material service dependency is gone), `NomoLoading`, `NomoShimmer`.
- Small components: `NomoDivider`, `NomoExpandable`, `NomoInfoItem`, `NomoContextMenu`; shared `NomoCaret` primitive.
- `nomo_gen create` (scaffold an annotated widget) and `nomo_gen doctor` (workspace sanity checks).
- Review hardening:
  - Generated theme files import their own source file — consumer types declared next to the widget now compile (C1).
  - `NomoInteractive`: Enter/Space/numpad-Enter activation works without a `WidgetsApp` ancestor; optional `toggled` for switch/checkbox semantics; disabling mid-press no longer leaves a stuck pressed state (I1/I3, regression-tested).
  - `NomoSwitch` announces as a toggle with a caller-supplied `semanticLabel` (hard-coded English 'On'/'Off' removed); thumb mirrors correctly under RTL (M1).
  - Text buttons stay transparent when disabled instead of growing a grey slab (I2).
  - `NomoDropdown`: themed `menuMaxHeight` (default 320), menu scrolls on long lists (I4).
  - `NomoApp`: `locale`/`localizationsDelegates`/`supportedLocales`/`onGenerateTitle` passthrough; asserts against `navigatorKey` + `routerConfig` together (I5).
  - `NomoThemeData` has value equality — rebuilding an identical theme no longer invalidates every dependent (I7).
  - `NomoBottomBar` casts its shadow upward; `showNomoModal` takes a translatable `barrierLabel` (M6).
  - `nomo_gen`: `lerp: true` on a non-interpolatable type is a `file:line` error (M4); `--watch` survives atomic-save races (M5).
- Resolution model documented as four levels — "kit defaults" collapsed into token-derived annotation defaults (DESIGN §9.9).

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
