# RFC-003 — LegendBody: one sliver core, named-constructor page archetypes

> Status: **implemented** (2026-07-10) — `.refresh`/`LegendSliverRefresh` deferred. Research-backed design for the last major ROADMAP Phase 2 port. Implements DESIGN.md §3's settled direction ("single sliver-based mode; convenience constructors cover the legacy use cases instead of six exclusive flag-modes"). Sources and full findings: session research 2026-07-10 (legacy `NomoRouteBody` on `main`, legacy-docs 01 §4.2 / 04 §10, sliver_tools/extended_sliver/super_sliver_list, Flutter ≥3.13 sliver groups, fluent_ui `ScaffoldPage`, macos_ui, SliverFillRemaining issues #141256/#62194).

## 1. What the legacy widget got wrong (evidence)

`NomoRouteBody`: six mutually-exclusive content params (`child`/`builder`/`children`/`childrenBuilder`/`slivers`/`sliverBuilder`) guarded only by an assert, forked further by `expands`/`scrollable`/`useScrollBar` bools. Documented failures: sliver mode silently ignores `appBar`; `scrollController ?? ScrollController()` created every build and never disposed; padding split half-half between `SliverPadding` and spacer slivers; a 130-line router-coupled `copyWith` grab-bag (already dropped per DESIGN.md §6); `background` as a **Widget stored in the color theme** (lerped as a color); `floatingFooter` as an unpositioned Stack escape hatch. No pull-to-refresh anywhere.

## 2. Ecosystem conclusions that shape the design

- **Flutter ≥3.13 absorbed most of sliver_tools**: `SliverMainAxisGroup`, `SliverCrossAxisGroup`, `SliverConstrainedCrossAxis` are in the framework — no dependency needed (DESIGN §1 goal 6). The one gap left: child-sized pinned headers without a `SliverPersistentHeaderDelegate` subclass.
- **The footer archetype** (form + submit button: pinned to viewport bottom when content is short, flows after content when long) is canonically `SliverFillRemaining(hasScrollBody: false)` + bottom alignment; footer padding must live *inside* the fill-remaining child (flutter#141256).
- **Keyboard**: Material-free pages must consume `MediaQuery.viewInsets.bottom` themselves (trailing sliver padding); `EditableText` auto-`ensureVisible`s once the page scrolls. **Safe areas** per page via `SliverSafeArea` so insets scroll away naturally.
- **Best precedent**: fluent_ui `ScaffoldPage` — named constructors, not flags.
- **Refresh**: Material's `RefreshIndicator` is Material; the sliver-native model is an overscroll-driven refresh sliver (à la `CupertinoSliverRefreshControl`) — ship our own or defer.

## 3. `LegendBody` API

Internally **always** a `CustomScrollView` (`.fixed` included, with non-scrolling physics) so padding/max-width/safe-area/keyboard behave identically in every mode. Pipeline, outside-in: `RawScrollbar?` (widgets layer) → `CustomScrollView(controller:)` → `SliverSafeArea` → cross-axis centering + `SliverConstrainedCrossAxis(maxContentWidth)` → `SliverPadding(theme.padding)` → content slivers → optional footer sliver → trailing `SliverPadding(bottom: viewInsets.bottom)`. A `StatefulWidget` owning and disposing its `ScrollController` (legacy leak closed), published via `PrimaryScrollController`.

```dart
@LegendThemeable()
class LegendBody extends StatefulWidget {
  /// Plain scrolling page: box children in a SliverList, padded and centered.
  const LegendBody({required List<Widget> children, Key? key,
      Widget? footer,            // flows after content (never pinned here)
      ScrollController? controller, ScrollPhysics? physics,
      bool safeArea = true, bool scrollbar = false,
      EdgeInsetsGeometry? padding, double? maxContentWidth});

  /// Form archetype: footer bottom-pinned when content is short, flows after
  /// content when long (SliverFillRemaining, hasScrollBody: false); rises
  /// above the keyboard via the trailing viewInsets padding.
  const LegendBody.pinnedFooter({required List<Widget> children,
      required Widget footer, /* + shared params */});

  /// Raw sliver page (headers, lists, grids). Children must be slivers.
  const LegendBody.slivers({required List<Widget> slivers,
      Widget? footer /* pinned, as in .pinnedFooter */, /* + shared */});

  /// Non-scrolling page that expands to the viewport (dashboards, split
  /// panes): SliverFillRemaining(hasScrollBody: false) + NeverScrollable
  /// physics; keyboard inset shrinks the fill extent.
  const LegendBody.fixed({required Widget child, /* + shared minus scrollbar */});

  /// Pull-to-refresh list (ships only with LegendSliverRefresh, §4).
  const LegendBody.refresh({required Future<void> Function() onRefresh,
      required List<Widget> children, Widget? refreshIndicator, /* + shared */});

  /// Content padding (one SliverPadding — legacy's half-split scheme removed).
  @Style<EdgeInsetsGeometry>.resolve(_padding)        // t.sizes.lg all around
  final EdgeInsetsGeometry? padding;

  /// Centered reading-column width; null = unconstrained.
  @Style<double?>.resolve(_maxContentWidth, lerp: false)
  final double? maxContentWidth;

  /// RawScrollbar geometry when [scrollbar] is true.
  @Style<double>.resolve(_scrollbarThickness)          // 8.0
  final double? scrollbarThickness;
  @Style<Radius>.resolve(_scrollbarRadius)             // circular(4)
  final Radius? scrollbarRadius;
}
```

Semantics decisions: bottom keyboard inset is always consumed (no opt-out until someone needs it); no `background`/`borderRadius` (`LegendScaffold.background` + `LegendSurface` own those); no builder variants (`Builder` covers it); the reading column is `LegendBody(maxContentWidth: 720)`, not a sixth constructor.

## 4. `LegendSliver*` helpers (in-kit, zero dependencies)

| Helper | Problem removed | Verdict |
|---|---|---|
| `LegendSliverPinnedHeader({required Widget child})` | delegate subclass + hand-fed extents for "just pin this widget"; child-sized, pins at top | **implement** (~150 LOC RenderSliver — the only gap the framework still has) |
| `LegendSliverSection({Widget? header, bool pinHeader = false, required List<Widget> slivers})` | header+content grouping, sticky section headers | **implement as composition** over `SliverMainAxisGroup` (~40 LOC) |
| `extension LegendSliverX on Widget { Widget get asSliver; }` | `SliverToBoxAdapter` noise | ~5 LOC |
| `LegendSliverRefresh({required onRefresh, WidgetBuilder? builder})` | no Material-free pull-to-refresh exists | **implement, may defer** (~250–300 LOC overscroll state machine; `.refresh` waits for it — no Material fallback) |

Not shipping: `SliverStack` (no in-kit consumer), padding/grid wrappers (framework's are fine), `MultiSliver` clone (superseded by `SliverMainAxisGroup`).

## 5. Interop

- `LegendScaffold(body: LegendBody(...))` — scaffold owns chrome + breakpoints; body owns scrolling. Per-tier sizing via `LegendBreakpoints` or tier-aware token defaults.
- Docs-site migration: `SelectionArea(child: LegendBody(maxContentWidth: 860, children: [...]))` deletes the hand-rolled `SingleChildScrollView + ConstrainedBox`, makes 860 themable, keeps selection.
- Playground: LegendBody preview + `maxContentWidth` knob (CLAUDE.md convention 1).

## 6. Reject list (each with the reason it dies)

- Six exclusive content params + assert → named constructors; invalid combos unrepresentable.
- `expands`/`scrollable` bools → `.fixed`; `shrinkWrap` gone entirely (perf trap).
- Router-coupled `copyWith(context, …)` → dropped (DESIGN.md §6); modal chrome belongs to the modal engine.
- `appBar` param → `LegendScaffold` / `LegendSliverPinnedHeader`; removes the "sliver mode ignores appBar" bug by removing the field.
- `background: Widget` in the color theme → widgets don't lerp; scaffold/surface own it.
- `floatingFooter` stack slot → callers use `Stack` or the overlay engine.
- Per-build undisposed `ScrollController` → State-owned + `PrimaryScrollController`.
- `borderRadius` + modal-styling leakage → `LegendSurface`'s job.
- Half-split padding → one `SliverPadding`; footer padding inside the fill-remaining child (flutter#141256).
- Material `Scrollbar` → `RawScrollbar`, themed thickness/radius.
- Builder content variants → redundant; `Builder` if context is needed.
