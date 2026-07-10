import 'dart:ui';

import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_state_overlays.dart';

part 'interactive_colors.style.g.dart';

/// The kit's predefined per-state color bundle for hover-bearing widgets —
/// an ordinary `@Style()` value class (RFC-002 R6 amendment 7), the
/// one-to-one replacement of the former `LegendStates<Color>` container.
///
/// Every member is a named, individually overridable variable at every
/// resolution level: merging is member-wise sparse, lerping member-wise
/// (both generated into `interactive_colors.style.g.dart` — the same
/// mechanism consumer-defined style classes get, zero special-casing).
///
/// Selection and derivation are hand-written extensions beside the class:
/// [InteractiveColorsPick.pick] falls back to [normal];
/// [InteractiveColorsResolve.resolve] derives unset members from [normal]
/// through [LegendStateOverlays]. A named member always wins.
@Style()
class InteractiveColors with _$InteractiveColors {
  /// Const so themes can share sparse per-state overrides as literals.
  const InteractiveColors({
    this.normal,
    this.hovered,
    this.pressed,
    this.focused,
    this.disabled,
  });

  /// Fill at rest (and the base unset members fall back to).
  final Color? normal;

  /// Fill while a pointer hovers the widget.
  final Color? hovered;

  /// Fill while the widget is actively pressed.
  final Color? pressed;

  /// Fill while the widget holds keyboard focus.
  final Color? focused;

  /// Fill while the widget is disabled.
  final Color? disabled;

  /// Member-wise lerp (generated, RFC-002 R6 amendment 7).
  static InteractiveColors? lerp(
    InteractiveColors? a,
    InteractiveColors? b,
    double t,
  ) => _$InteractiveColorsLerp(a, b, t);
}

/// Selection with fallback-to-normal — hand-written beside the class
/// (RFC-002 R6 amendment 7: the generator owns only the mechanical
/// members; behavior belongs to the author).
extension InteractiveColorsPick on InteractiveColors {
  /// The member for [state], else [InteractiveColors.normal] (else null).
  Color? pick(LegendWidgetState state) {
    return switch (state) {
      LegendStateNormal() => normal,
      LegendStateHovered() => hovered ?? normal,
      LegendStatePressed() => pressed ?? normal,
      LegendStateFocused() => focused ?? normal,
      LegendStateDisabled() => disabled ?? normal,
    };
  }
}

/// Overlay derivation for unset members — hand-written beside the class.
extension InteractiveColorsResolve on InteractiveColors {
  /// The color for [state]: the named member if set, else the [overlays]
  /// derivation applied to [InteractiveColors.normal] (focus derives as
  /// the normal color itself — focus is drawn as a ring, not a fill
  /// shift), else null when `normal` is unset too.
  Color? resolve(LegendWidgetState state, LegendStateOverlays overlays) {
    return switch (state) {
      LegendStateNormal() => normal,
      LegendStateHovered() => hovered ?? _derived(overlays.hovered),
      LegendStatePressed() => pressed ?? _derived(overlays.pressed),
      LegendStateFocused() => focused ?? normal,
      LegendStateDisabled() => disabled ?? _derived(overlays.disabled),
    };
  }

  Color? _derived(Color Function(Color base) overlay) {
    final base = normal;
    return base == null ? null : overlay(base);
  }
}
