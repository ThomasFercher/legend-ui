import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/shell/nomo_app_bar.theme.g.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// Top bar: leading / title / actions in a plain Row — no custom
/// RenderBox (legacy's slotted app-bar render object had broken
/// intrinsics and no RTL support).
@NomoThemeable()
class NomoAppBar extends StatelessWidget {
  const NomoAppBar({
    super.key,
    this.leading,
    this.title,
    this.titleWidget,
    this.actions = const [],
    this.background,
    this.height,
    this.padding,
  });

  final Widget? leading;
  final String? title;

  /// Replaces [title] when set.
  final Widget? titleWidget;

  final List<Widget> actions;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;

  @Themed(defaultsTo: '56.0')
  final double? height;

  @Themed(defaultsTo: 'EdgeInsets.symmetric(horizontal: t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = NomoAppBarTheme.of(
      context,
      NomoAppBarThemeNullable(
        background: background,
        height: height,
        padding: padding,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    final titleChild =
        titleWidget ??
        (title == null
            ? null
            : Text(
                title!,
                style: tokens.typography.h3.copyWith(
                  color: tokens.colors.foreground1,
                ),
                overflow: TextOverflow.ellipsis,
              ));

    return NomoSurface(
      color: theme.background,
      padding: theme.padding,
      duration: const Duration(milliseconds: 120),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: theme.height,
          child: Row(
            spacing: tokens.sizes.sm,
            children: [
              if (leading != null) leading!,
              if (titleChild != null)
                Expanded(child: titleChild)
              else
                const Spacer(),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}
