import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part 'fancy_box.theme.g.dart';

/// Golden-test fixture: covers every `@Style` default shape — a Ref
/// catalog member (`LegendColorsRef.surface`, qualified tear-off from the
/// tokens library), a class-static tear-off, a top-level private function
/// tear-off, a typed const default (double, lerp), and a genuinely
/// optional `@Style<T>(null)` field.
@LegendThemeable()
class FancyBox extends StatelessWidget {
  const FancyBox({
    super.key,
    this.background,
    this.gap,
    this.padding,
    this.stripeWidth,
    this.outline,
  });

  /// Fill behind the child.
  @Style<Color>.resolve(LegendColorsRef.surface, lerp: true)
  final Color? background;

  /// Space between children.
  @Style<double>(8.0, lerp: true)
  final double? gap;

  /// Inner padding.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  /// Width of the decorative stripe.
  @Style<double>.resolve(_stripeWidth)
  final double? stripeWidth;

  /// Optional outline color; nothing is drawn when unset at every level.
  @Style<Color>(null, lerp: true)
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    return Container(color: theme.background, padding: theme.padding);
  }
}

/// Composite default as a top-level private function — the house style
/// for anything that is not a single token field read.
double _stripeWidth(LegendTokens t) => t.sizes.borderWidth * 2;
