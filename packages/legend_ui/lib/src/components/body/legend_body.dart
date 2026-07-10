import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_body.theme.g.dart';

/// How a [LegendBody] was constructed — each named constructor is one
/// page archetype (RFC-003 §3); invalid combinations are unrepresentable.
enum _LegendBodyMode { list, pinnedFooter, slivers, fixed }

/// The page body: one sliver-based scrolling core behind named-constructor
/// archetypes (RFC-003) — plain page, form with a bottom-pinned footer,
/// raw sliver page, and non-scrolling fill page.
///
/// Internally always a [CustomScrollView] ([LegendBody.fixed] included,
/// with non-scrolling physics), so padding, reading-column max width,
/// safe areas, and the keyboard inset behave identically in every mode.
/// Pipeline, outside-in: optional [RawScrollbar] → [CustomScrollView] →
/// [SliverSafeArea] → cross-axis centering + [SliverConstrainedCrossAxis]
/// → [SliverPadding] → content → optional footer → trailing keyboard
/// inset padding. The state owns and disposes its [ScrollController] and
/// publishes it via [PrimaryScrollController].
///
/// Replaces legacy `NomoRouteBody` and its documented failures (RFC-003
/// §1): six mutually-exclusive content params guarded by an assert become
/// constructors; the per-build never-disposed `ScrollController` leak is
/// closed by construction; the half-split padding scheme becomes one
/// [SliverPadding]; the sliver-mode-ignores-appBar bug loses its field
/// (app bars belong to `LegendScaffold` / `LegendSliverPinnedHeader`).
///
/// The keyboard inset ([MediaQueryData.viewInsets]) is always consumed:
/// scrolling modes append it as trailing scroll padding (so content and a
/// pinned footer can rise above the keyboard), [LegendBody.fixed] shrinks
/// its fill extent by it.
///
/// A reading column is `LegendBody(maxContentWidth: 720)`, not a separate
/// constructor. Pull-to-refresh (`.refresh` + `LegendSliverRefresh`) is
/// deferred (RFC-003 §4).
@LegendThemeable()
class LegendBody extends StatefulWidget {
  /// Plain scrolling page: box [children] in a [SliverList], padded and
  /// centered; an optional [footer] flows after the content (never
  /// pinned here — use [LegendBody.pinnedFooter] for that).
  const LegendBody({
    required List<Widget> children,
    super.key,
    this.footer,
    this.controller,
    this.physics,
    this.safeArea = true,
    this.scrollbar = false,
    this.padding,
    this.maxContentWidth,
    this.scrollbarThickness,
    this.scrollbarRadius,
  }) : _mode = _LegendBodyMode.list,
       _children = children,
       _slivers = null,
       _child = null;

  /// Form archetype: [footer] is pinned to the viewport bottom while the
  /// content is short and flows after the content once it scrolls
  /// (`SliverFillRemaining(hasScrollBody: false)`); it rises above the
  /// keyboard via the trailing inset padding. Footer padding lives inside
  /// the fill-remaining child (flutter#141256).
  const LegendBody.pinnedFooter({
    required List<Widget> children,
    required Widget this.footer,
    super.key,
    this.controller,
    this.physics,
    this.safeArea = true,
    this.scrollbar = false,
    this.padding,
    this.maxContentWidth,
    this.scrollbarThickness,
    this.scrollbarRadius,
  }) : _mode = _LegendBodyMode.pinnedFooter,
       _children = children,
       _slivers = null,
       _child = null;

  /// Raw sliver page (headers, lists, grids): [slivers] must be slivers
  /// (see `LegendSliverX.asSliver`, `LegendSliverSection`,
  /// `LegendSliverPinnedHeader`); an optional [footer] is bottom-pinned
  /// exactly as in [LegendBody.pinnedFooter].
  const LegendBody.slivers({
    required List<Widget> slivers,
    super.key,
    this.footer,
    this.controller,
    this.physics,
    this.safeArea = true,
    this.scrollbar = false,
    this.padding,
    this.maxContentWidth,
    this.scrollbarThickness,
    this.scrollbarRadius,
  }) : _mode = _LegendBodyMode.slivers,
       _children = null,
       _slivers = slivers,
       _child = null;

  /// Non-scrolling page that expands to the viewport (dashboards, split
  /// panes): [child] fills the remaining space with non-scrolling
  /// physics; the keyboard inset shrinks the fill extent instead of
  /// scrolling.
  const LegendBody.fixed({
    required Widget child,
    super.key,
    this.safeArea = true,
    this.padding,
    this.maxContentWidth,
  }) : _mode = _LegendBodyMode.fixed,
       _children = null,
       _slivers = null,
       _child = child,
       footer = null,
       controller = null,
       physics = null,
       scrollbar = false,
       scrollbarThickness = null,
       scrollbarRadius = null;

  final _LegendBodyMode _mode;
  final List<Widget>? _children;
  final List<Widget>? _slivers;
  final Widget? _child;

  /// Widget after the content: flowing in the plain constructor,
  /// bottom-pinned in [LegendBody.pinnedFooter] / [LegendBody.slivers].
  final Widget? footer;

  /// External scroll position owner; null means the state creates (and
  /// disposes) its own — either way it is published via
  /// [PrimaryScrollController].
  final ScrollController? controller;

  /// Scroll physics of the page ([LegendBody.fixed] always uses
  /// [NeverScrollableScrollPhysics]).
  final ScrollPhysics? physics;

  /// Whether the content avoids the display's safe areas
  /// ([SliverSafeArea], so insets scroll away naturally).
  final bool safeArea;

  /// Whether a [RawScrollbar] (themed via [scrollbarThickness] /
  /// [scrollbarRadius]) is shown.
  final bool scrollbar;

  /// Content padding — applied once, by one [SliverPadding] (legacy's
  /// half-split padding scheme removed).
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Centered reading-column width; null means unconstrained.
  @Style<double>.value(null)
  final double? maxContentWidth;

  /// Scrollbar stroke width when [scrollbar] is true.
  @Style<double>(8)
  final double? scrollbarThickness;

  /// Scrollbar corner rounding when [scrollbar] is true.
  @Style<Radius>(Radius.circular(4))
  final Radius? scrollbarRadius;

  @override
  State<LegendBody> createState() => _LegendBodyState();
}

class _LegendBodyState extends State<LegendBody> {
  /// Created lazily when no external controller is given; owned and
  /// disposed here — the legacy leak (a fresh controller per build,
  /// never disposed) is unrepresentable.
  ScrollController? _ownController;

  ScrollController get _controller =>
      widget.controller ?? (_ownController ??= ScrollController());

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  /// Bottom-pinned footer: fills whatever viewport space the content
  /// leaves (footer pinned to the bottom while the page is short) and
  /// collapses to the footer itself once the content scrolls. Its share
  /// of the page padding sits inside the fill-remaining child
  /// (flutter#141256 — outside, the fill extent miscounts it).
  Widget _pinnedFooter(EdgeInsets padding) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          0,
          padding.right,
          padding.bottom,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [widget.footer!],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final padding = theme.padding.resolve(Directionality.of(context));
    final fixed = widget._mode == _LegendBodyMode.fixed;

    // Content region: one SliverPadding around the mode's slivers, plus
    // the footer sliver (whose padding lives inside itself, see above).
    final slivers = switch (widget._mode) {
      _LegendBodyMode.list => [
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(
            children: [...widget._children!, ?widget.footer],
          ),
        ),
      ],
      _LegendBodyMode.pinnedFooter => [
        SliverPadding(
          padding: padding,
          sliver: SliverList.list(children: widget._children!),
        ),
        _pinnedFooter(padding),
      ],
      _LegendBodyMode.slivers => [
        SliverPadding(
          padding: padding,
          sliver: SliverMainAxisGroup(slivers: widget._slivers!),
        ),
        if (widget.footer != null) _pinnedFooter(padding),
      ],
      _LegendBodyMode.fixed => [
        SliverFillRemaining(
          hasScrollBody: false,
          // The keyboard inset shrinks the fill extent — a fixed page
          // cannot scroll content above the keyboard, so it yields the
          // space instead.
          child: Padding(
            padding: padding + EdgeInsets.only(bottom: keyboardInset),
            child: widget._child,
          ),
        ),
      ],
    };

    Widget body = SliverMainAxisGroup(slivers: slivers);

    final maxContentWidth = theme.maxContentWidth;
    if (maxContentWidth != null) {
      body = SliverCrossAxisGroup(
        slivers: [
          const SliverCrossAxisExpanded(
            flex: 1,
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          SliverConstrainedCrossAxis(maxExtent: maxContentWidth, sliver: body),
          const SliverCrossAxisExpanded(
            flex: 1,
            sliver: SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
        ],
      );
    }

    if (widget.safeArea) body = SliverSafeArea(sliver: body);

    Widget result = CustomScrollView(
      controller: _controller,
      physics: fixed ? const NeverScrollableScrollPhysics() : widget.physics,
      slivers: [
        body,
        // The keyboard inset is always consumed (RFC-003 §3): trailing
        // scroll extent lets content — and a pinned footer — rise above
        // the keyboard (EditableText ensureVisible does the scrolling).
        if (!fixed)
          SliverPadding(padding: EdgeInsets.only(bottom: keyboardInset)),
      ],
    );

    if (widget.scrollbar && !fixed) {
      result = RawScrollbar(
        controller: _controller,
        thickness: theme.scrollbarThickness,
        radius: theme.scrollbarRadius,
        child: result,
      );
    }

    return PrimaryScrollController(controller: _controller, child: result);
  }
}

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.lg);
