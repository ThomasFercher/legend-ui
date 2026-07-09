import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/dialog/legend_dialog.theme.g.dart';
import 'package:legend_ui/src/primitives/legend_modal.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// A modal dialog surface. Show it with [showLegendDialog] — the kit's own
/// modal engine, no Material `showDialog` (legacy-docs 06).
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

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;

  @Themed(defaultsTo: 't.sizes.borderRadiusLg')
  final BorderRadius? borderRadius;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.lg)')
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: '420.0')
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = LegendDialogTheme.of(
      context,
      LegendDialogThemeNullable(
        background: background,
        borderRadius: borderRadius,
        padding: padding,
        maxWidth: maxWidth,
      ),
    );
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
