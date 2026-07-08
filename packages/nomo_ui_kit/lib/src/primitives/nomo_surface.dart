import 'package:flutter/widgets.dart';

/// The one shape/border/shadow primitive (DESIGN.md §3) — replaces the
/// legacy Card/OutlineContainer/ElevatedBox/NomoElevation split.
///
/// Pass [duration] to animate decoration changes implicitly (theme
/// switches animate at the consumer, not by tweening theme classes —
/// DESIGN.md §2.4).
class NomoSurface extends StatelessWidget {
  const NomoSurface({
    super.key,
    this.color,
    this.borderRadius,
    this.border,
    this.shadows,
    this.padding,
    this.duration,
    this.clip = false,
    this.child,
  });

  final Color? color;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  /// When set, decoration/padding changes animate implicitly.
  final Duration? duration;

  /// Clips [child] to [borderRadius].
  final bool clip;

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    var content = child;
    if (clip && borderRadius != null && content != null) {
      content = ClipRRect(borderRadius: borderRadius!, child: content);
    }
    final decoration = BoxDecoration(
      color: color,
      borderRadius: borderRadius,
      border: border,
      boxShadow: shadows,
    );
    final duration = this.duration;
    if (duration == null) {
      return Container(
        decoration: decoration,
        padding: padding,
        child: content,
      );
    }
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      decoration: decoration,
      padding: padding,
      child: content,
    );
  }
}
