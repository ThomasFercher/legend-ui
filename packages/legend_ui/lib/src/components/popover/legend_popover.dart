import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/context_menu/legend_context_menu.dart';
import 'package:legend_ui/src/components/dropdown/legend_dropdown.dart';
import 'package:legend_ui/src/primitives/legend_anchored_overlay.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_shadows.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_popover.theme.g.dart';

/// Which side of its trigger a [LegendPopover] panel attaches to.
///
/// [start] and [end] resolve against the ambient [Directionality]
/// (start = left in LTR, right in RTL) so popovers read correctly in both.
enum LegendPopoverPlacement { top, bottom, start, end }

/// How a [LegendPopover] opens.
enum LegendPopoverTrigger {
  /// Tapping the trigger child toggles the panel.
  tap,

  /// Only a [LegendPopoverController] opens and closes the panel; the
  /// trigger child gets no gesture of its own. The seam hover-driven
  /// wrappers (tooltip, hover card) build on.
  manual,
}

/// Imperative open/close handle for a [LegendPopover].
///
/// A [ChangeNotifier] so wrapping widgets (tooltip, action menu, combobox)
/// can both drive the panel — [show]/[hide]/[toggle] — and observe [isOpen],
/// which stays in sync when the panel dismisses itself on an outside tap or
/// Escape. Pass one to [LegendPopover.controller]; without one the popover
/// owns a private instance.
class LegendPopoverController extends ChangeNotifier {
  final OverlayPortalController _portal = OverlayPortalController();

  bool _isOpen = false;

  /// Whether the panel is currently shown.
  bool get isOpen => _isOpen;

  /// Shows the panel; a no-op when already open.
  void show() {
    if (_isOpen) return;
    _isOpen = true;
    _portal.show();
    notifyListeners();
  }

  /// Hides the panel; a no-op when already closed.
  void hide() {
    if (!_isOpen) return;
    _isOpen = false;
    _portal.hide();
    notifyListeners();
  }

  /// Toggles between [show] and [hide].
  void toggle() => _isOpen ? hide() : show();
}

/// A floating themed surface anchored to a trigger — the reusable
/// positioned-panel foundation tooltips, action menus, hover cards and
/// combobox panels compose instead of re-implementing overlay wiring.
///
/// Composes [LegendAnchoredOverlay] (positioning + outside-tap dismissal),
/// [LegendSurface] (the panel) and [LegendInteractive] (the tap trigger).
///
/// Generalizes the per-widget overlay plumbing [LegendContextMenu] and
/// [LegendDropdown] carry into one themeable component — legacy shipped
/// three unrelated overlay systems and handed callers raw `OverlayEntry`s
/// to manage by hand (legacy-docs 06).
///
/// The panel dismisses on an outside tap and, while it holds focus
/// ([autofocus]), on Escape. Content is caller-provided through [overlay]
/// and deliberately unopinionated — text for a tooltip, a list for a menu,
/// a field plus list for a combobox.
@LegendThemeable()
class LegendPopover extends StatefulWidget {
  const LegendPopover({
    required this.child,
    required this.overlay,
    super.key,
    this.controller,
    this.placement = LegendPopoverPlacement.bottom,
    this.trigger = LegendPopoverTrigger.tap,
    this.offset = Offset.zero,
    this.enabled = true,
    this.autofocus = true,
    this.showArrow = false,
    this.semanticLabel,
    this.background,
    this.borderRadius,
    this.shadows,
    this.padding,
  });

  /// The trigger the panel anchors to. Wrapped in a [LegendInteractive]
  /// under [LegendPopoverTrigger.tap]; rendered as-is under `manual`.
  final Widget child;

  /// Builds the panel content inside the themed surface — caller-owned and
  /// unopinionated.
  final WidgetBuilder overlay;

  /// Opens and closes the panel imperatively. Null lets the popover own a
  /// private controller; required in practice for
  /// [LegendPopoverTrigger.manual], where nothing else opens the panel.
  final LegendPopoverController? controller;

  /// Which side of the trigger the panel attaches to.
  final LegendPopoverPlacement placement;

  /// What opens the panel — a tap on [child], or only the [controller].
  final LegendPopoverTrigger trigger;

  /// Extra translation applied after placement — the knob for a gap
  /// between trigger and panel.
  final Offset offset;

  /// When false the tap trigger is inert (the [controller] still works —
  /// callers own their imperative calls).
  final bool enabled;

  /// Whether the panel takes focus when shown so Escape dismisses it. Turn
  /// off when the content manages its own focus (e.g. a combobox field).
  final bool autofocus;

  /// Paints a small arrow on the panel edge pointing at the trigger,
  /// filled with [background].
  final bool showArrow;

  /// Announced for the tap trigger; unused under
  /// [LegendPopoverTrigger.manual].
  final String? semanticLabel;

  /// Fill of the floating panel (and its arrow).
  @Style<Color>.resolve(ColorRef.surface)
  final Color? background;

  /// Corner rounding of the panel.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Drop shadow lifting the panel off the page.
  @Style<List<BoxShadow>>.resolve(ShadowRef.medium)
  final List<BoxShadow>? shadows;

  /// Inner padding around the panel content.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  @override
  State<LegendPopover> createState() => _LegendPopoverState();
}

class _LegendPopoverState extends State<LegendPopover> {
  /// Created lazily when the caller passes no controller; only an owned
  /// controller is disposed here.
  LegendPopoverController? _internal;

  LegendPopoverController get _controller =>
      widget.controller ?? (_internal ??= LegendPopoverController());

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!widget.enabled) return;
    _controller.toggle();
  }

  /// Maps [LegendPopover.placement] to the engine's anchor/follower
  /// alignment pair, resolving start/end against [direction].
  ({Alignment anchor, Alignment follower}) _alignments(
    TextDirection direction,
  ) {
    final ltr = direction == TextDirection.ltr;
    return switch (widget.placement) {
      LegendPopoverPlacement.bottom => (
        anchor: Alignment.bottomCenter,
        follower: Alignment.topCenter,
      ),
      LegendPopoverPlacement.top => (
        anchor: Alignment.topCenter,
        follower: Alignment.bottomCenter,
      ),
      LegendPopoverPlacement.start when ltr => (
        anchor: Alignment.centerLeft,
        follower: Alignment.centerRight,
      ),
      LegendPopoverPlacement.start => (
        anchor: Alignment.centerRight,
        follower: Alignment.centerLeft,
      ),
      LegendPopoverPlacement.end when ltr => (
        anchor: Alignment.centerRight,
        follower: Alignment.centerLeft,
      ),
      LegendPopoverPlacement.end => (
        anchor: Alignment.centerLeft,
        follower: Alignment.centerRight,
      ),
    };
  }

  Widget _panel(BuildContext context, LegendPopoverTheme theme) {
    Widget panel = LegendSurface(
      color: theme.background,
      borderRadius: theme.borderRadius,
      shadows: theme.shadows,
      padding: theme.padding,
      clip: true,
      child: widget.overlay(context),
    );

    if (widget.showArrow) {
      // The arrow sits between anchor and panel inside the positioned
      // subtree, so the alignment math needs no correction. It is a filled
      // wedge in the panel color — LegendCaret is a stroked disclosure
      // chevron and deliberately not reused here.
      final length = LegendTheme.of(context).tokens.sizes.sm;
      final direction = Directionality.of(context);
      final towardAnchor = switch (widget.placement) {
        LegendPopoverPlacement.bottom => AxisDirection.up,
        LegendPopoverPlacement.top => AxisDirection.down,
        LegendPopoverPlacement.start =>
          direction == TextDirection.ltr
              ? AxisDirection.right
              : AxisDirection.left,
        LegendPopoverPlacement.end =>
          direction == TextDirection.ltr
              ? AxisDirection.left
              : AxisDirection.right,
      };
      final arrow = CustomPaint(
        size: switch (towardAnchor) {
          AxisDirection.up || AxisDirection.down => Size(length * 2, length),
          AxisDirection.left || AxisDirection.right => Size(length, length * 2),
        },
        painter: _ArrowPainter(color: theme.background, toward: towardAnchor),
      );
      panel = switch (towardAnchor) {
        AxisDirection.up => Column(
          mainAxisSize: MainAxisSize.min,
          children: [arrow, panel],
        ),
        AxisDirection.down => Column(
          mainAxisSize: MainAxisSize.min,
          children: [panel, arrow],
        ),
        AxisDirection.left => Row(
          mainAxisSize: MainAxisSize.min,
          children: [arrow, panel],
        ),
        AxisDirection.right => Row(
          mainAxisSize: MainAxisSize.min,
          children: [panel, arrow],
        ),
      };
    }

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _controller.hide,
      },
      child: Focus(autofocus: widget.autofocus, child: panel),
    );
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final placement = _alignments(Directionality.of(context));

    return LegendAnchoredOverlay(
      controller: _controller._portal,
      anchorAlignment: placement.anchor,
      overlayAlignment: placement.follower,
      offset: widget.offset,
      onDismiss: _controller.hide,
      overlay: (context) => _panel(context, theme),
      child: switch (widget.trigger) {
        LegendPopoverTrigger.tap => LegendInteractive(
          enabled: widget.enabled,
          semanticLabel: widget.semanticLabel,
          onTap: _toggle,
          builder: (context, states) => widget.child,
        ),
        LegendPopoverTrigger.manual => widget.child,
      },
    );
  }
}

/// Paints the popover arrow: a filled isosceles wedge whose tip points
/// [toward] the anchor.
class _ArrowPainter extends CustomPainter {
  const _ArrowPainter({required this.color, required this.toward});

  final Color color;
  final AxisDirection toward;

  @override
  void paint(Canvas canvas, Size size) {
    final path = switch (toward) {
      AxisDirection.up =>
        Path()
          ..moveTo(0, size.height)
          ..lineTo(size.width / 2, 0)
          ..lineTo(size.width, size.height),
      AxisDirection.down =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width / 2, size.height)
          ..lineTo(size.width, 0),
      AxisDirection.left =>
        Path()
          ..moveTo(size.width, 0)
          ..lineTo(0, size.height / 2)
          ..lineTo(size.width, size.height),
      AxisDirection.right =>
        Path()
          ..moveTo(0, 0)
          ..lineTo(size.width, size.height / 2)
          ..lineTo(0, size.height),
    }..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) =>
      color != oldDelegate.color || toward != oldDelegate.toward;
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.md);
