import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/dialog/nomo_dialog.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_modal.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// A modal dialog surface. Show it with [showNomoDialog] — the kit's own
/// modal engine, no Material `showDialog` (legacy-docs 06).
@NomoThemeable()
class NomoDialog extends StatelessWidget {
  const NomoDialog({
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
    final theme = NomoDialogTheme.of(
      context,
      NomoDialogThemeNullable(
        background: background,
        borderRadius: borderRadius,
        padding: padding,
        maxWidth: maxWidth,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: theme.maxWidth),
      child: NomoSurface(
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

/// Shows a [NomoDialog] (or any widget) as a centered modal.
Future<T?> showNomoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool dismissible = true,
}) {
  return showNomoModal<T>(
    context: context,
    builder: builder,
    dismissible: dismissible,
  );
}
