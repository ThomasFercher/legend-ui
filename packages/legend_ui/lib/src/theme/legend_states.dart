import 'dart:ui';

import 'package:legend_ui/src/theme/legend_widget_state.dart';
import 'package:legend_ui/src/tokens/legend_state_overlays.dart';
import 'package:meta/meta.dart';

/// The ONE minimal generic per-state container (RFC-002 R6): a pure-data
/// record of a value for each [LegendWidgetState], all members optional.
///
/// One class serves every value type — `LegendStates<Color>`,
/// `LegendStates<double>`, `LegendStates<TextStyle>` — Dart's generics carry
/// the type safety; there is no per-type wrapper zoo and no function-valued
/// members (themes stay pure data). Every member is a named, individually
/// overridable variable at every resolution level: merging is member-wise
/// sparse ([merge]), lerping is member-wise with a type-appropriate lerper
/// ([lerpWith]), equality is member-wise.
///
/// Type-specific behavior attaches by extension where it type-checks:
/// [LegendStatesPick.pick] selects for any `T`, [LegendStatesColorResolve]
/// adds overlay derivation for colors only, and [ColorStates.states] lifts
/// a raw [Color] so the common case stays nearly unwrapped.
@immutable
class LegendStates<T> {
  /// Const so themes can share sparse per-state overrides as literals.
  const LegendStates({
    this.normal,
    this.hovered,
    this.pressed,
    this.focused,
    this.disabled,
  });

  /// Value in the resting state (and the base other members derive from).
  final T? normal;

  /// Value while a pointer hovers the widget.
  final T? hovered;

  /// Value while the widget is actively pressed.
  final T? pressed;

  /// Value while the widget holds keyboard focus.
  final T? focused;

  /// Value while the widget is disabled.
  final T? disabled;

  /// Member-wise sparse merge: [b]'s set members win over [a]'s, unset
  /// members inherit — so a level that names only `pressed` never clobbers
  /// a lower level's `hovered`. Null containers pass the other through.
  static LegendStates<T>? merge<T>(LegendStates<T>? a, LegendStates<T>? b) {
    if (a == null) return b;
    if (b == null) return a;
    return LegendStates(
      normal: b.normal ?? a.normal,
      hovered: b.hovered ?? a.hovered,
      pressed: b.pressed ?? a.pressed,
      focused: b.focused ?? a.focused,
      disabled: b.disabled ?? a.disabled,
    );
  }

  /// Member-wise lerp with the type-appropriate [lerper] for `T` (e.g.
  /// `Color.lerp` for `LegendStates<Color>`).
  static LegendStates<T> lerpWith<T>(
    LegendStates<T> a,
    LegendStates<T> b,
    double t,
    T? Function(T? a, T? b, double t) lerper,
  ) {
    return LegendStates(
      normal: lerper(a.normal, b.normal, t),
      hovered: lerper(a.hovered, b.hovered, t),
      pressed: lerper(a.pressed, b.pressed, t),
      focused: lerper(a.focused, b.focused, t),
      disabled: lerper(a.disabled, b.disabled, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendStates<T> &&
          other.normal == normal &&
          other.hovered == hovered &&
          other.pressed == pressed &&
          other.focused == focused &&
          other.disabled == disabled;

  @override
  int get hashCode => Object.hash(normal, hovered, pressed, focused, disabled);
}

/// Selection for any `T` — fallback-to-normal built in.
extension LegendStatesPick<T> on LegendStates<T> {
  /// The member for [state], else [LegendStates.normal] (else null).
  T? pick(LegendWidgetState state) {
    return switch (state) {
      LegendStateNormal() => normal,
      LegendStateHovered() => hovered ?? normal,
      LegendStatePressed() => pressed ?? normal,
      LegendStateFocused() => focused ?? normal,
      LegendStateDisabled() => disabled ?? normal,
    };
  }
}

/// Overlay derivation — exists ONLY where it makes sense, bound to
/// `LegendStates<Color>` (RFC-002 R6).
extension LegendStatesColorResolve on LegendStates<Color> {
  /// The color for [state]: the named member if set, else the [overlays]
  /// derivation applied to [LegendStates.normal] (focus derives as the
  /// normal color itself — focus is drawn as a ring, not a fill shift),
  /// else null when `normal` is unset too.
  Color? resolve(LegendWidgetState state, LegendStateOverlays overlays) {
    return switch (state) {
      LegendStateNormal() => normal,
      LegendStateHovered() => hovered ?? _derived(overlays.hovered),
      LegendStatePressed() => pressed ?? _derived(overlays.pressed),
      LegendStateFocused() => focused ?? normal,
      LegendStateDisabled() => disabled ?? _derived(overlays.disabled),
    };
  }

  /// This container with every unset member filled from [LegendStates.normal]
  /// via [overlays] — what generated `XTheme.of` applies post-merge, so one
  /// brand color yields consistent hover/press everywhere and re-derives
  /// from any level's override. Named members always win; when `normal` is
  /// unset there is nothing to derive from and `this` returns unchanged.
  LegendStates<Color> withDerived(LegendStateOverlays overlays) {
    final base = normal;
    if (base == null) return this;
    return LegendStates(
      normal: base,
      hovered: hovered ?? overlays.hovered(base),
      pressed: pressed ?? overlays.pressed(base),
      focused: focused ?? base,
      disabled: disabled ?? overlays.disabled(base),
    );
  }

  Color? _derived(Color Function(Color base) overlay) {
    final base = normal;
    return base == null ? null : overlay(base);
  }
}

/// Lifts a raw value — the common case stays nearly unwrapped:
/// `PrimaryLegendButton(background: brand.states)`.
extension ColorStates on Color {
  /// A [LegendStates] with this color as its `normal` member (the other
  /// members derive through [LegendStateOverlays] at resolution time).
  LegendStates<Color> get states => LegendStates(normal: this);
}
