import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_empty.theme.g.dart';

/// A zero-state placeholder — the centered "nothing here yet" block a list,
/// panel or page shows instead of content ("No transactions yet", "No
/// sources").
///
/// Composes [LegendSurface] for the padded block and token-styled text for
/// the [title] and [description]; purely presentational — it has no
/// gestures of its own.
///
/// The [icon] slot is free-form (icons come from the consumer — the kit
/// ships none): an `Icon` inherits [iconColor] and [iconSize] through an
/// `IconTheme`, while a custom illustration keeps its own size and simply
/// centers. The [action] slot takes the way out of the zero state,
/// typically a button (e.g. `PrimaryLegendButton(text: 'Add source')`).
///
/// Content is capped at [maxContentWidth] so a long [description] wraps
/// into a readable centered column instead of spanning the panel.
@LegendThemeable()
class LegendEmpty extends StatelessWidget {
  const LegendEmpty({
    required this.title,
    super.key,
    this.description,
    this.icon,
    this.action,
    this.iconColor,
    this.iconSize,
    this.titleStyle,
    this.descriptionStyle,
    this.spacing,
    this.padding,
    this.maxContentWidth,
  });

  /// The one-line headline naming what is absent.
  final String title;

  /// Optional supporting copy under the [title] — why it is empty or what
  /// filling it takes.
  final String? description;

  /// Optional icon/illustration slot above the [title].
  final Widget? icon;

  /// Optional call-to-action slot under the texts (caller passes a button).
  final Widget? action;

  /// Color an `Icon` in the [icon] slot inherits (muted).
  @Style<Color>.resolve(ColorRef.foreground3)
  final Color? iconColor;

  /// Size an `Icon` in the [icon] slot inherits.
  @Style<double>.resolve(_iconSize)
  final double? iconSize;

  /// Text style of the [title] (muted — the whole zero state recedes).
  @Style<TextStyle>.resolve(_titleStyle)
  final TextStyle? titleStyle;

  /// Text style of the [description] (more muted than the title).
  @Style<TextStyle>.resolve(_descriptionStyle)
  final TextStyle? descriptionStyle;

  /// Vertical gap between icon, title, description and action.
  @Style<double>.resolve(SizeRef.sm)
  final double? spacing;

  /// Outer padding around the centered block.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Widest the centered content column may grow — long descriptions wrap
  /// instead of spanning the panel.
  @Style<double>(360)
  final double? maxContentWidth;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return LegendSurface(
      padding: theme.padding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: theme.maxContentWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: theme.spacing,
            children: [
              if (icon != null)
                IconTheme.merge(
                  data: IconThemeData(
                    color: theme.iconColor,
                    size: theme.iconSize,
                  ),
                  child: icon!,
                ),
              Text(title, style: theme.titleStyle, textAlign: TextAlign.center),
              if (description != null)
                Text(
                  description!,
                  style: theme.descriptionStyle,
                  textAlign: TextAlign.center,
                ),
              ?action,
            ],
          ),
        ),
      ),
    );
  }
}

/// The zero-state glyph is display-sized: double the large inline icon.
double _iconSize(LegendTokens t) => t.sizes.iconLg * 2;

TextStyle _titleStyle(LegendTokens t) => t.typography.b1.copyWith(
  fontWeight: FontWeight.w600,
  color: t.colors.foreground2,
);

TextStyle _descriptionStyle(LegendTokens t) =>
    t.typography.b2.copyWith(color: t.colors.foreground3);

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.xl);
