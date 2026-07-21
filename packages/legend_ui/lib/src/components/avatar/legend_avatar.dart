import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_avatar.theme.g.dart';

/// A mark for a person or entity — token logos, account identicons, dApp
/// icons, user avatars — a circular clipped fill with a fallback ladder:
/// [image], then [initials], then [placeholder], then a generic silhouette
/// glyph.
///
/// Composes [LegendSurface] (the clipped, bordered circle).
///
/// The ladder degrades per instance: a failed [image] load falls back to
/// the same [initials]/[placeholder] rung it would have used without the
/// image, so a broken URL never leaves a blank hole. [initials] scale with
/// [size] (fitted into the circle), so [foreground] themes their color,
/// weight and family while the diameter alone decides how large they draw.
///
/// [seed] gives an entity a stable identity color without any asset: the
/// same string always picks the same background/foreground pair from a
/// token-derived palette ([seedColors]), across runs and platforms. While
/// a seed is set it supplies the fill, so [background] is unused.
///
/// A [badge] (typically a sibling status widget — the wallet's
/// network-badge-on-token-icon case) renders over the avatar at
/// [badgeAlignment]; it is caller-owned and intentionally untouched by
/// this widget's theme.
@LegendThemeable()
class LegendAvatar extends StatelessWidget {
  const LegendAvatar({
    super.key,
    this.image,
    this.initials,
    this.placeholder,
    this.seed,
    this.badge,
    this.badgeAlignment = AlignmentDirectional.bottomEnd,
    this.semanticLabel,
    this.size,
    this.background,
    this.foreground,
    this.borderRadius,
    this.border,
  });

  /// The picture to show — the top rung of the fallback ladder. A load or
  /// decode error falls back to [initials]/[placeholder] instead of an
  /// error box.
  final ImageProvider<Object>? image;

  /// Short label drawn when no [image] renders — typically one or two
  /// characters ("TF"). Scales with [size].
  final String? initials;

  /// Generic glyph slot drawn when neither [image] nor [initials] is
  /// given — usually a consumer icon. Without one, a minimal person
  /// silhouette in the [foreground] color is painted.
  final Widget? placeholder;

  /// Deterministic identity: hashes to a background/foreground pair from
  /// the token-derived [seedColors] palette. While set, the fill comes
  /// from the seed and [background] is unused.
  final String? seed;

  /// Overlaid at [badgeAlignment] — a status dot or network badge.
  /// Caller-owned; not themed or sized by the avatar.
  final Widget? badge;

  /// Where [badge] sits over the avatar.
  final AlignmentGeometry badgeAlignment;

  /// Announced by assistive technology; without it the avatar is treated
  /// as decorative.
  final String? semanticLabel;

  /// Diameter of the avatar.
  @Style<double>.resolve(SizeRef.xl)
  final double? size;

  /// Fill behind [initials] and the placeholder rungs ([seed] wins while
  /// set).
  @Style<Color>.resolve(ColorRef.background2)
  final Color? background;

  /// Text style of the [initials]; its color also tints the default
  /// silhouette glyph.
  @Style<TextStyle>.resolve(_foreground)
  final TextStyle? foreground;

  /// Corner rounding of the avatar — a full circle by default.
  @Style<BorderRadius>(BorderRadius.all(Radius.circular(9999)))
  final BorderRadius? borderRadius;

  /// Outline drawn around the avatar; none by default.
  @Style<BoxBorder>.value(null)
  final BoxBorder? border;

  /// The deterministic seed palette: hashes [seed] to one of the token
  /// color pairs (each a WCAG-checked `on*` pairing). The hash is a plain
  /// 31-multiplier fold over code units — stable across runs and
  /// platforms, unlike `String.hashCode`.
  static ({Color background, Color foreground}) seedColors(
    String seed,
    LegendColors colors,
  ) {
    final palette = [
      (background: colors.primary, foreground: colors.onPrimary),
      (background: colors.secondary, foreground: colors.onSecondary),
      (
        background: colors.primaryContainer,
        foreground: colors.onPrimaryContainer,
      ),
      (background: colors.background3, foreground: colors.foreground1),
    ];
    var hash = 0;
    for (final unit in seed.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return palette[hash % palette.length];
  }

  /// The rung below [image]: initials, then the placeholder slot, then the
  /// generic silhouette.
  Widget _fallback(BuildContext context, double size, TextStyle foreground) {
    final initials = this.initials;
    if (initials != null) {
      return Padding(
        padding: EdgeInsets.all(size * 0.22),
        child: FittedBox(child: Text(initials, style: foreground)),
      );
    }
    final placeholder = this.placeholder;
    if (placeholder != null) return Center(child: placeholder);
    return CustomPaint(
      size: Size.square(size),
      painter: _SilhouettePainter(
        color:
            foreground.color ??
            LegendTheme.of(context).tokens.colors.foreground1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final size = theme.size;

    final seed = this.seed;
    final seeded = seed == null
        ? null
        : seedColors(seed, LegendTheme.of(context).tokens.colors);
    final foreground = seeded == null
        ? theme.foreground
        : theme.foreground.copyWith(color: seeded.foreground);

    final image = this.image;
    final content = image == null
        ? _fallback(context, size, foreground)
        : Image(
            image: image,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _fallback(context, size, foreground),
          );

    Widget avatar = SizedBox.square(
      dimension: size,
      child: LegendSurface(
        color: seeded?.background ?? theme.background,
        borderRadius: theme.borderRadius,
        border: theme.border,
        clip: true,
        child: content,
      ),
    );

    final semanticLabel = this.semanticLabel;
    if (semanticLabel != null) {
      // The label replaces the content semantics (initials would otherwise
      // announce twice); a [badge] keeps its own semantics below.
      avatar = Semantics(
        label: semanticLabel,
        image: true,
        excludeSemantics: true,
        child: avatar,
      );
    }

    final badge = this.badge;
    if (badge != null) {
      avatar = SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            avatar,
            Positioned.fill(
              child: Align(alignment: badgeAlignment, child: badge),
            ),
          ],
        ),
      );
    }
    return avatar;
  }
}

/// Paints the generic person silhouette — the bottom rung of the ladder.
/// The torso deliberately overflows the bottom edge; the avatar's clip
/// crops it into the familiar bust shape.
class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    canvas
      ..drawCircle(
        Offset(size.width / 2, size.height * 0.38),
        size.width * 0.18,
        paint,
      )
      ..drawOval(
        Rect.fromCenter(
          center: Offset(size.width / 2, size.height * 0.92),
          width: size.width * 0.62,
          height: size.height * 0.55,
        ),
        paint,
      );
  }

  @override
  bool shouldRepaint(_SilhouettePainter oldDelegate) =>
      color != oldDelegate.color;
}

TextStyle _foreground(LegendTokens t) => t.typography.b2.copyWith(
  fontWeight: FontWeight.w600,
  color: t.colors.foreground1,
);
