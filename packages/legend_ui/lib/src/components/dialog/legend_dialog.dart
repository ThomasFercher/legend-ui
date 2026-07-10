import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_modal.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_dialog.theme.g.dart';

/// A modal dialog surface with an optional title, content and action row.
///
/// Composes [LegendSurface]; [showLegendDialog] presents it through
/// [LegendModalRoute], the kit's own modal engine.
///
/// Replaces the legacy dialog's dependency on Material `showDialog`
/// (legacy-docs 06).
@LegendThemeable()
class LegendDialog extends StatelessWidget {
  const LegendDialog({
    super.key,
    this.title,
    this.content,
    this.actions = const [],
    this.background,
    this.borderRadius,
    this.padding,
    this.maxWidth,
  });

  final String? title;
  final Widget? content;
  final List<Widget> actions;

  /// Fill color of the dialog surface.
  @Style<Color>.resolve(ColorRef.surface)
  final Color? background;

  /// Corner rounding of the dialog surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding around title, content and actions.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Widest the dialog grows before its content wraps.
  @Style<double>(420)
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: theme.maxWidth),
      child: LegendSurface(
        color: theme.background,
        borderRadius: theme.borderRadius,
        shadows: tokens.shadows.high,
        padding: theme.padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.sizes.md,
          children: [
            if (title != null)
              Text(
                title!,
                style: tokens.typography.h3.copyWith(
                  color: tokens.colors.foreground1,
                ),
              ),
            if (content != null)
              DefaultTextStyle(
                style: tokens.typography.b2.copyWith(
                  color: tokens.colors.foreground2,
                ),
                child: content!,
              ),
            if (actions.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: tokens.sizes.sm,
                children: actions,
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows a [LegendDialog] (or any widget) as a centered modal.
Future<T?> showLegendDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showLegendModal<T>(
    context: context,
    builder: builder,
    dismissible: dismissible,
  );
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusLg;

EdgeInsetsGeometry _padding(LegendTokens t) => EdgeInsets.all(t.sizes.lg);
