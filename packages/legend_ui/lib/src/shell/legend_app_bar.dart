import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_app_bar.theme.g.dart';

/// Top bar: leading / title / actions in a plain Row — no custom
/// RenderBox (legacy's slotted app-bar render object had broken
/// intrinsics and no RTL support).
@LegendThemeable()
class LegendAppBar extends StatelessWidget {
  const LegendAppBar({
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

  @Style<Color>.resolve(_background)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  @Style<double>(56)
  final double? height;

  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.symmetric(horizontal: t.sizes.md);

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
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

    return LegendSurface(
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
