import 'package:flutter/widgets.dart';

/// One navigation destination, shared by `NomoSider` and `NomoBottomBar`
/// — a single model instead of legacy's per-surface item types (and no
/// `trailling` typos).
class NomoNavItem {
  const NomoNavItem({required this.label, this.icon, this.iconBuilder})
    : assert(
        icon == null || iconBuilder == null,
        'Provide icon or iconBuilder, not both.',
      );

  final String label;

  /// Icon glyph; the kit bundles no icon font (DESIGN.md §4), so this is
  /// whatever font the app ships.
  final IconData? icon;

  /// Fully custom icon widget; receives the resolved foreground color.
  final Widget Function(Color color)? iconBuilder;

  Widget? buildIcon(Color color, double size) {
    if (iconBuilder != null) return iconBuilder!(color);
    if (icon != null) return Icon(icon, color: color, size: size);
    return null;
  }
}
