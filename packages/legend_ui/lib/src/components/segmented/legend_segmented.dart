import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_selection_control.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_segmented.theme.g.dart';

/// One segment of [LegendSegmented]. One item model, mirroring
/// `LegendDropdownItem` — never a parallel per-surface type.
class LegendSegment<T> {
  const LegendSegment({
    required this.value,
    required this.label,
    this.icon,
    this.iconBuilder,
  }) : assert(
         icon == null || iconBuilder == null,
         'Provide icon or iconBuilder, not both.',
       );

  final T value;
  final String label;

  /// Icon glyph; the kit bundles no icon font (DESIGN.md §4), so this is
  /// whatever font the app ships.
  final IconData? icon;

  /// Fully custom icon widget; receives the resolved foreground color.
  final Widget Function(Color color)? iconBuilder;

  Widget? buildIcon(Color color, double size) {
    if (iconBuilder != null) return iconBuilder!(color);
    if (icon != null) return Icon(icon, color: color, size: size);
    return null;
  }
}

/// An exclusive one-of-N choice rendered as joined equal-width segments
/// with a sliding thumb behind the selected one.
///
/// Composes [LegendSelectionControl] (per-segment activation, selected
/// semantics, focus) and [LegendSurface] (track and thumb). Arrow keys
/// move focus between segments (wrapping, direction-aware under RTL);
/// Enter/Space select the focused segment. Tapping the already selected
/// segment is a no-op — an exclusive control never deselects.
@LegendThemeable()
class LegendSegmented<T> extends StatefulWidget {
  /// The [thumb] color lifts into the `normal` member of the per-state
  /// theme field (RFC-002 R6).
  LegendSegmented({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.background,
    Color? thumb,
    this.labelStyle,
    this.selectedLabelStyle,
    this.borderRadius,
    this.padding,
    this.segmentPadding,
  }) : assert(segments.isNotEmpty, 'segments must not be empty.'),
       thumb = thumb == null ? null : InteractiveColors(normal: thumb);

  /// The choices, in visual order.
  final List<LegendSegment<T>> segments;

  /// The currently selected segment's value. A value not present in
  /// [segments] renders with no thumb.
  final T value;

  /// Called with the activated segment's value. Null disables the control.
  final ValueChanged<T>? onChanged;

  /// Whether the control accepts input at all. False makes it fully inert.
  final bool enabled;

  /// Fill of the recessed track behind all segments.
  @Style<Color>.resolve(ColorRef.background2)
  final Color? background;

  /// Fill of the thumb behind the selected segment, per interaction state —
  /// `normal` is the resting thumb, `hovered`/`pressed` tint it under the
  /// pointer, `disabled` paints the inert thumb.
  @Style<InteractiveColors>.resolve(_thumb)
  final InteractiveColors? thumb;

  /// Text style of unselected segment labels.
  @Style<TextStyle>.resolve(_labelStyle)
  final TextStyle? labelStyle;

  /// Text style of the selected segment's label.
  @Style<TextStyle>.resolve(_selectedLabelStyle)
  final TextStyle? selectedLabelStyle;

  /// Corner rounding of the track (the thumb derives its own by deflating
  /// this through [padding]).
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inset between the track edge and the thumb.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Inner padding of each segment, around its icon and label.
  @Style<EdgeInsetsGeometry>.resolve(_segmentPadding)
  final EdgeInsetsGeometry? segmentPadding;

  @override
  State<LegendSegmented<T>> createState() => _LegendSegmentedState<T>();
}

class _LegendSegmentedState<T> extends State<LegendSegmented<T>> {
  /// One focus node per segment, index-aligned with [LegendSegmented.segments]
  /// — the roving target of the arrow-key movement.
  final _nodes = <FocusNode>[];

  /// Index of the segment under the pointer (for the thumb's hover tint),
  /// or null.
  int? _hovered;

  @override
  void initState() {
    super.initState();
    _syncNodes();
  }

  @override
  void didUpdateWidget(LegendSegmented<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncNodes() {
    while (_nodes.length < widget.segments.length) {
      _nodes.add(FocusNode(debugLabel: 'LegendSegmented segment'));
    }
    while (_nodes.length > widget.segments.length) {
      _nodes.removeLast().dispose();
    }
  }

  /// Moves focus [delta] segments over, wrapping at the ends. Left/right
  /// are visual directions: under RTL the index steps the other way.
  void _move(int delta) {
    final step = Directionality.of(context) == TextDirection.rtl
        ? -delta
        : delta;
    final current = _nodes.indexWhere((node) => node.hasFocus);
    if (current < 0) return;
    _nodes[(current + step) % _nodes.length].requestFocus();
  }

  void _setHovered(int index, {required bool hovering}) {
    final next = hovering ? index : (_hovered == index ? null : _hovered);
    if (next == _hovered) return;
    setState(() => _hovered = next);
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final enabled = widget.enabled && widget.onChanged != null;
    final segments = widget.segments;
    final count = segments.length;
    final selectedIndex = segments.indexWhere(
      (segment) => segment.value == widget.value,
    );
    final thumbRadius = _deflateRadius(
      theme.borderRadius,
      theme.padding.resolve(Directionality.of(context)),
    );

    // The thumb tint follows the selected segment's pointer state; press
    // is skipped deliberately — pressing the selected segment activates
    // nothing (exclusive controls never deselect).
    final thumbState = !enabled
        ? const LegendStateDisabled()
        : _hovered == selectedIndex
        ? const LegendStateHovered()
        : const LegendStateNormal();

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveFocusIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveFocusIntent(1),
      },
      child: Actions(
        actions: {
          _MoveFocusIntent: CallbackAction<_MoveFocusIntent>(
            onInvoke: (intent) {
              _move(intent.delta);
              return null;
            },
          ),
        },
        child: LegendSurface(
          color: enabled ? theme.background : tokens.colors.disabled,
          borderRadius: theme.borderRadius,
          padding: theme.padding,
          duration: const Duration(milliseconds: 120),
          child: IntrinsicWidth(
            child: Stack(
              children: [
                if (selectedIndex >= 0)
                  Positioned.fill(
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      alignment: AlignmentDirectional(
                        count <= 1 ? 0 : -1 + 2 * selectedIndex / (count - 1),
                        0,
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 1 / count,
                        heightFactor: 1,
                        child: LegendSurface(
                          color: theme.thumb.resolve(thumbState, tokens.states),
                          borderRadius: thumbRadius,
                          shadows: tokens.shadows.low,
                          duration: const Duration(milliseconds: 120),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (final (index, segment) in segments.indexed)
                      Expanded(
                        child: _segment(
                          index,
                          segment,
                          tokens,
                          thumbRadius,
                          selected: index == selectedIndex,
                          enabled: enabled,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _segment(
    int index,
    LegendSegment<T> segment,
    LegendTokens tokens,
    BorderRadius thumbRadius, {
    required bool selected,
    required bool enabled,
  }) {
    final theme = this.theme;
    final onChanged = widget.onChanged;
    return LegendSelectionControl(
      selected: selected,
      role: LegendSelectionRole.selectable,
      enabled: enabled,
      semanticLabel: segment.label,
      focusNode: _nodes[index],
      onHoverChange: (hovering) => _setHovered(index, hovering: hovering),
      onChanged: onChanged == null
          ? null
          : (next) {
              // Exclusive: activating the selected segment reports next ==
              // false — ignored, the choice never deselects.
              if (next ?? false) onChanged(segment.value);
            },
      builder: (context, state) {
        var style = state.selected
            ? theme.selectedLabelStyle
            : theme.labelStyle;
        if (state.disabled) {
          style = style.copyWith(color: tokens.colors.onDisabled);
        } else if (!state.selected && (state.hovered || state.pressed)) {
          style = style.copyWith(color: tokens.colors.foreground1);
        }
        final foreground = style.color ?? tokens.colors.foreground1;
        return LegendSurface(
          // Focus draws as a ring, not a fill shift (RFC-002 R6); the
          // transparent resting border keeps the label from jumping.
          border: Border.all(
            color: state.focused && !state.disabled
                ? tokens.colors.primary
                : const Color(0x00000000),
            width: tokens.sizes.borderWidth,
          ),
          borderRadius: thumbRadius,
          padding: theme.segmentPadding,
          duration: const Duration(milliseconds: 120),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: tokens.sizes.xs,
            children: [
              ?segment.buildIcon(foreground, tokens.sizes.iconSm),
              Flexible(
                child: Text(
                  segment.label,
                  style: style,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Moves segment focus by [delta] (visual direction; RTL flips the index
/// step) — the widget owns the arrow-key mapping so movement works without
/// a `WidgetsApp` ancestor.
class _MoveFocusIntent extends Intent {
  const _MoveFocusIntent(this.delta);

  final int delta;
}

/// The thumb's rounding: the track radius deflated by the track padding,
/// so the inner curve stays concentric with the outer one.
BorderRadius _deflateRadius(BorderRadius outer, EdgeInsets inset) {
  Radius shrink(Radius radius, double dx, double dy) =>
      Radius.elliptical(math.max(0, radius.x - dx), math.max(0, radius.y - dy));
  return BorderRadius.only(
    topLeft: shrink(outer.topLeft, inset.left, inset.top),
    topRight: shrink(outer.topRight, inset.right, inset.top),
    bottomLeft: shrink(outer.bottomLeft, inset.left, inset.bottom),
    bottomRight: shrink(outer.bottomRight, inset.right, inset.bottom),
  );
}

InteractiveColors _thumb(LegendTokens t) =>
    InteractiveColors(normal: t.colors.surface);

TextStyle _labelStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

TextStyle _selectedLabelStyle(LegendTokens t) => t.typography.b3.copyWith(
  color: t.colors.foreground1,
  fontWeight: FontWeight.w600,
);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.xs);

EdgeInsetsGeometry _segmentPadding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.sm, vertical: t.sizes.xs);
