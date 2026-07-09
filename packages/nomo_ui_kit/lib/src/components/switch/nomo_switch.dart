import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/switch/nomo_switch.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_interactive.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// A toggle switch built on [NomoInteractive] — no CupertinoSwitch fork
/// (legacy vendored one just to change its size, complete with an
/// `Opacity(opacity: 42)` crash).
@NomoThemeable()
class NomoSwitch extends StatelessWidget {
  const NomoSwitch({
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

  @Themed(defaultsTo: 't.colors.primary', lerp: true)
  final Color? activeTrack;

  @Themed(defaultsTo: 't.colors.background3', lerp: true)
  final Color? inactiveTrack;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? thumb;

  @Themed(defaultsTo: '44.0')
  final double? width;

  @Themed(defaultsTo: '24.0')
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = NomoSwitchTheme.of(
      context,
      NomoSwitchThemeNullable(
        activeTrack: activeTrack,
        inactiveTrack: inactiveTrack,
        thumb: thumb,
        width: width,
        height: height,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    final onChanged = this.onChanged;

    return NomoInteractive(
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
