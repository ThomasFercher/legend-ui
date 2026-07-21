import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/primitives/legend_selection_control.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_chip.theme.g.dart';

/// A compact labeled token — a tag, filter, or citation pill.
///
/// Composes [LegendSurface] (the pill) with, depending on mode,
/// [LegendSelectionControl] (`role: selectable` — a toggling filter chip
/// announced with selected state) or [LegendInteractive] (a tappable
/// action chip, and the trailing remove affordance of a dismissible one).
///
/// The mode follows the callbacks: [onSelected] makes the chip a
/// selectable filter, [onTap] a plain action (mutually exclusive with
/// [onSelected]), [onDismissed] adds a trailing remove control to either —
/// or to a static label chip when no other callback is set. A disabled
/// chip is genuinely inert in every mode, remove affordance included.
///
/// A number-only label (a citation chip like '3') works without special
/// casing — the padding scale keeps the pill compact.
@LegendThemeable()
class LegendChip extends StatelessWidget {
  const LegendChip({
    required this.label,
    super.key,
    this.leading,
    this.selected = false,
    this.onSelected,
    this.onTap,
    this.onDismissed,
    this.enabled = true,
    this.semanticLabel,
    this.dismissLabel,
    this.background,
    this.selectedBackground,
    this.foreground,
    this.selectedForeground,
    this.borderRadius,
    this.padding,
    this.textStyle,
  }) : assert(
         onSelected == null || onTap == null,
         'A chip is selectable (onSelected) or an action (onTap), not both.',
       );

  /// The text on the pill.
  final String label;

  /// Optional slot before the label — an icon, avatar, or status dot
  /// (sized by the consumer; the chip only spaces it).
  final Widget? leading;

  /// Whether the chip currently reads as selected (drawn with the
  /// selected colors; announced only in selectable mode).
  final bool selected;

  /// Called with the next value when the chip toggles — makes it a
  /// selectable filter chip.
  final ValueChanged<bool>? onSelected;

  /// Primary activation — makes the chip a plain action (e.g. a citation
  /// or suggested-question chip).
  final VoidCallback? onTap;

  /// Called when the trailing remove affordance is activated — its
  /// presence adds the affordance.
  final VoidCallback? onDismissed;

  /// Whether the chip accepts input at all. False makes it fully inert,
  /// the remove affordance included.
  final bool enabled;

  /// What this chip represents to assistive tech; defaults to [label].
  final String? semanticLabel;

  /// What the remove affordance announces (e.g. 'Remove Ethereum') — never
  /// a hard-coded English default.
  final String? dismissLabel;

  /// Fill of the unselected pill, per interaction state (hover/press
  /// derive from `normal` through the state overlays when unset).
  @Style<InteractiveColors>.resolve(_background, lerp: true)
  final InteractiveColors? background;

  /// Fill of the selected pill, per interaction state.
  @Style<InteractiveColors>.resolve(_selectedBackground, lerp: true)
  final InteractiveColors? selectedBackground;

  /// Color of the label, leading slot, and remove glyph while unselected.
  @Style<Color>.resolve(ColorRef.foreground1, lerp: true)
  final Color? foreground;

  /// Color of the label, leading slot, and remove glyph while selected.
  @Style<Color>.resolve(ColorRef.onPrimaryContainer, lerp: true)
  final Color? selectedForeground;

  /// Corner rounding of the pill (a full pill by default).
  @Style<BorderRadius>(BorderRadius.all(Radius.circular(999)))
  final BorderRadius? borderRadius;

  /// Inner padding around the chip content.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Text style of [label] (its color comes from [foreground] /
  /// [selectedForeground]).
  @Style<TextStyle>.resolve(TextRef.b3)
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final semanticLabel = this.semanticLabel ?? label;

    final onSelected = this.onSelected;
    if (onSelected != null) {
      return LegendSelectionControl(
        selected: selected,
        onChanged: (value) => onSelected(value ?? false),
        role: LegendSelectionRole.selectable,
        enabled: enabled,
        semanticLabel: semanticLabel,
        builder: (context, state) =>
            _pill(theme, tokens, state: state.effective),
      );
    }

    if (onTap != null) {
      return LegendInteractive(
        onTap: onTap,
        enabled: enabled,
        semanticLabel: semanticLabel,
        builder: (context, states) =>
            _pill(theme, tokens, state: states.effective),
      );
    }

    // Static (optionally dismissible) chip — no activation surface of its
    // own, so no interaction primitive around the pill.
    return _pill(
      theme,
      tokens,
      state: enabled ? const LegendStateNormal() : const LegendStateDisabled(),
    );
  }

  Widget _pill(
    LegendChipTheme theme,
    LegendTokens tokens, {
    required LegendWidgetState state,
  }) {
    final colors = selected ? theme.selectedBackground : theme.background;
    final disabled = state is LegendStateDisabled;
    final foreground = disabled
        ? tokens.colors.onDisabled
        : selected
        ? theme.selectedForeground
        : theme.foreground;

    return LegendSurface(
      color: colors.resolve(state, tokens.states),
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      duration: const Duration(milliseconds: 120),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: tokens.sizes.xs,
        children: [
          ?leading,
          Text(label, style: theme.textStyle.copyWith(color: foreground)),
          if (onDismissed != null)
            _RemoveAffordance(
              onDismissed: onDismissed!,
              enabled: enabled,
              color: foreground,
              semanticLabel: dismissLabel,
            ),
        ],
      ),
    );
  }
}

/// The trailing remove control of a dismissible [LegendChip] — its own
/// [LegendInteractive] so it presses, focuses, and announces separately
/// from the chip body (and wins the gesture arena over it).
class _RemoveAffordance extends StatelessWidget {
  const _RemoveAffordance({
    required this.onDismissed,
    required this.enabled,
    required this.color,
    required this.semanticLabel,
  });

  final VoidCallback onDismissed;
  final bool enabled;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LegendInteractive(
      onTap: onDismissed,
      enabled: enabled,
      semanticLabel: semanticLabel,
      builder: (context, states) => AnimatedOpacity(
        // Rests dimmed, sharpens under the pointer — the affordance
        // signal without a second fill inside the pill.
        opacity: states.hovered || states.pressed || states.focused ? 1.0 : 0.6,
        duration: const Duration(milliseconds: 120),
        child: CustomPaint(
          size: const Size.square(8),
          painter: _RemovePainter(color),
        ),
      ),
    );
  }
}

/// Paints the small ✕ glyph (stroke style matching `LegendCaret`).
class _RemovePainter extends CustomPainter {
  const _RemovePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(Offset.zero, Offset(size.width, size.height), paint)
      ..drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_RemovePainter oldDelegate) => color != oldDelegate.color;
}

InteractiveColors _background(LegendTokens t) => InteractiveColors(
  normal: t.colors.background2,
  disabled: t.colors.disabled,
);

InteractiveColors _selectedBackground(LegendTokens t) => InteractiveColors(
  normal: t.colors.primaryContainer,
  disabled: t.colors.disabled,
);

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.sm, vertical: t.sizes.xs);
