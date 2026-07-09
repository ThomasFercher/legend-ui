import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_switch.theme.g.dart';

/// A toggle switch built on [LegendInteractive] — no CupertinoSwitch fork
/// (legacy vendored one just to change its size, complete with an
/// `Opacity(opacity: 42)` crash).
@LegendThemeable()
class LegendSwitch extends StatelessWidget {
  const LegendSwitch({
    required this.value,
    required this.onChanged,
    super.key,
    this.enabled = true,
    this.semanticLabel,
    this.activeTrack,
    this.inactiveTrack,
    this.thumb,
    this.width,
    this.height,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  /// What this switch controls (e.g. 'Dark mode') — the on/off state itself
  /// is announced via toggle semantics, never as a hard-coded English label.
  final String? semanticLabel;

  @Style<Color>.resolve(_activeTrack, lerp: true)
  final Color? activeTrack;
  static Color _activeTrack(LegendTokens t) => t.colors.primary;

  @Style<Color>.resolve(_inactiveTrack, lerp: true)
  final Color? inactiveTrack;
  static Color _inactiveTrack(LegendTokens t) => t.colors.background3;

  @Style<Color>.resolve(_thumb)
  final Color? thumb;
  static Color _thumb(LegendTokens t) => t.colors.surface;

  @Style<double>(44)
  final double? width;

  @Style<double>(24)
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final onChanged = this.onChanged;

    return LegendInteractive(
      enabled: enabled && onChanged != null,
      onTap: onChanged == null ? null : () => onChanged(!value),
      semanticLabel: semanticLabel,
      toggled: value,
      builder: (context, states) {
        final track = states.disabled
            ? tokens.colors.disabled
            : value
            ? theme.activeTrack
            : theme.inactiveTrack;
        final inset = theme.height * 0.1;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          width: theme.width,
          height: theme.height,
          padding: EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(theme.height / 2),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            alignment: value
                ? AlignmentDirectional.centerEnd
                : AlignmentDirectional.centerStart,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: states.disabled ? tokens.colors.onDisabled : theme.thumb,
                shape: BoxShape.circle,
                boxShadow: tokens.shadows.low,
              ),
              child: SizedBox.square(dimension: theme.height - inset * 2),
            ),
          ),
        );
      },
    );
  }
}
