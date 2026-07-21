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

part 'legend_list_item.theme.g.dart';

/// The tappable row every list is made of — a [title] with an optional
/// [subtitle] stacked beneath it, between free-form [leading] and
/// [trailing] slots (an avatar, a value, a checkbox — the slot doesn't
/// care what it holds).
///
/// Composes [LegendSurface] (row fill and rounding) over one of two
/// interaction primitives, picked by [selected]: while [selected] is null
/// the row is a plain activation target on [LegendInteractive] (a
/// semantic button); once [selected] is set the row participates in a
/// selection model and composes [LegendSelectionControl] with
/// [LegendSelectionRole.selectable] instead, so assistive tech announces
/// the row's selected state rather than a plain button. With neither
/// [onTap] nor [selected] the row renders static.
///
/// The tappable generalization of `LegendInfoItem`, which stays the
/// static label/value row (RFC-004, resolved 2026-07-10: both exist).
@LegendThemeable()
class LegendListItem extends StatelessWidget {
  const LegendListItem({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected,
    this.enabled = true,
    this.semanticLabel,
    this.colors,
    this.selectedBackground,
    this.selectedColor,
    this.titleStyle,
    this.subtitleStyle,
    this.padding,
    this.borderRadius,
  });

  /// The row's primary line.
  final String title;

  /// Optional secondary line under the [title], in a muted style.
  final String? subtitle;

  /// Shown before the text stack (avatar, icon, checkbox — free-form).
  final Widget? leading;

  /// Shown after the text stack (a value, a chevron, an action).
  final Widget? trailing;

  /// Activation — tap, and (when focused) Enter/Space. Null together with
  /// a null [selected] renders the row static.
  final VoidCallback? onTap;

  /// Non-null opts the row into a selection model: it announces selected
  /// state ([LegendSelectionRole.selectable]) and fills with
  /// [selectedBackground] while true. The parent owns the model — [onTap]
  /// still fires on activation. Null keeps the row a plain button.
  final bool? selected;

  /// Whether the row accepts input at all. False makes it fully inert.
  final bool enabled;

  /// What this row activates or selects — defaults to [title].
  final String? semanticLabel;

  /// Fill of the row per interaction state — `normal` is the resting row,
  /// `hovered`/`pressed`/`focused` tint the row under the pointer (a
  /// selected row uses [selectedBackground] instead).
  @Style<InteractiveColors>.resolve(_colors)
  final InteractiveColors? colors;

  /// Fill behind the row while [selected] is true.
  @Style<Color>.resolve(ColorRef.primaryContainer, lerp: true)
  final Color? selectedBackground;

  /// [title] color while [selected] is true.
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? selectedColor;

  /// Text style of the [title].
  @Style<TextStyle>.resolve(_titleStyle)
  final TextStyle? titleStyle;

  /// Text style of the [subtitle] (muted, smaller than the title).
  @Style<TextStyle>.resolve(_subtitleStyle)
  final TextStyle? subtitleStyle;

  /// Inner padding of the row.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Corner rounding of the row surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final selected = this.selected;
    final onTap = this.onTap;

    // Selection model: LegendSelectionControl announces the selected state
    // that LegendInteractive's button/toggle vocabulary cannot express.
    if (selected != null) {
      return LegendSelectionControl(
        selected: selected,
        onChanged: onTap == null ? null : (_) => onTap(),
        role: LegendSelectionRole.selectable,
        enabled: enabled,
        semanticLabel: semanticLabel ?? title,
        builder: (context, state) =>
            _row(theme, tokens, state.effective, selected: state.selected),
      );
    }

    // No interaction at all: a static row, like LegendInfoItem.
    if (onTap == null) {
      return _row(theme, tokens, const LegendStateNormal(), selected: false);
    }

    // Plain activation: a semantic button on LegendInteractive.
    return LegendInteractive(
      onTap: onTap,
      enabled: enabled,
      semanticLabel: semanticLabel ?? title,
      builder: (context, states) =>
          _row(theme, tokens, states.effective, selected: false),
    );
  }

  Widget _row(
    LegendListItemTheme theme,
    LegendTokens tokens,
    LegendWidgetState state, {
    required bool selected,
  }) {
    final titleStyle = selected
        ? theme.titleStyle.copyWith(color: theme.selectedColor)
        : theme.titleStyle;
    return LegendSurface(
      color: selected
          ? theme.selectedBackground
          : theme.colors.resolve(state, tokens.states),
      borderRadius: theme.borderRadius,
      padding: theme.padding,
      duration: const Duration(milliseconds: 120),
      child: Row(
        spacing: tokens.sizes.sm,
        children: [
          ?leading,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: titleStyle, overflow: TextOverflow.ellipsis),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.subtitleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

InteractiveColors _colors(LegendTokens t) => InteractiveColors(
  normal: t.colors.surface,
  hovered: t.colors.background2,
  pressed: t.colors.background2,
  focused: t.colors.background2,
);

TextStyle _titleStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground1);

TextStyle _subtitleStyle(LegendTokens t) =>
    t.typography.b3.copyWith(color: t.colors.foreground2);

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;
