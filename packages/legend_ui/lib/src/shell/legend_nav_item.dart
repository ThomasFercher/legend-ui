import 'package:flutter/widgets.dart';

/// One navigation destination, shared by `LegendSider`, `LegendBottomBar`
/// and `LegendVerticalMenu` — a single model instead of legacy's
/// per-surface item types (and no `trailling` typos).
///
/// An item with [children] is an expandable section (used by
/// `LegendVerticalMenu`); flat surfaces simply ignore it.
class LegendNavItem {
  const LegendNavItem({
    required this.label,
    this.icon,
    this.iconBuilder,
    this.children,
  }) : assert(
         icon == null || iconBuilder == null,
         'Provide icon or iconBuilder, not both.',
       );

  final String label;

  /// Icon glyph; the kit bundles no icon font (DESIGN.md §4), so this is
  /// whatever font the app ships.
  final IconData? icon;

  /// Fully custom icon widget; receives the resolved foreground color.
  final Widget Function(Color color)? iconBuilder;

  /// Nested destinations under this item; non-null makes it an expandable
  /// section in `LegendVerticalMenu`. Flat surfaces ignore it.
  final List<LegendNavItem>? children;

  Widget? buildIcon(Color color, double size) {
    if (iconBuilder != null) return iconBuilder!(color);
    if (icon != null) return Icon(icon, color: color, size: size);
    return null;
  }
}
