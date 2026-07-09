/// The sealed interaction-state vocabulary (RFC-002 R6).
///
/// A widget is always in exactly **one** effective state, picked by the
/// fixed priority ladder disabled ≻ pressed ≻ hovered ≻ focused ≻ normal
/// (see `LegendInteractionStates.effective`). Because the type is sealed
/// over five values, a `switch` over it is exhaustively checked by the
/// compiler — unlike Material's `Set<WidgetState>` guess-the-precedence
/// model.
sealed class LegendWidgetState {
  const LegendWidgetState();
}

/// Resting state — no pointer, focus, or press interaction.
final class LegendStateNormal extends LegendWidgetState {
  /// Const so switch arms and samplers can share one instance.
  const LegendStateNormal();
}

/// A pointer is hovering the widget.
final class LegendStateHovered extends LegendWidgetState {
  /// Const so switch arms and samplers can share one instance.
  const LegendStateHovered();
}

/// The widget is actively pressed (pointer down or keyboard activation).
final class LegendStatePressed extends LegendWidgetState {
  /// Const so switch arms and samplers can share one instance.
  const LegendStatePressed();
}

/// The widget holds keyboard focus.
final class LegendStateFocused extends LegendWidgetState {
  /// Const so switch arms and samplers can share one instance.
  const LegendStateFocused();
}

/// The widget is disabled and inert.
final class LegendStateDisabled extends LegendWidgetState {
  /// Const so switch arms and samplers can share one instance.
  const LegendStateDisabled();
}

/// Every [LegendWidgetState] once, for callers that enumerate the domain
/// (state editors, previews, tests).
const List<LegendWidgetState> kLegendWidgetStates = [
  LegendStateNormal(),
  LegendStateHovered(),
  LegendStatePressed(),
  LegendStateFocused(),
  LegendStateDisabled(),
];
