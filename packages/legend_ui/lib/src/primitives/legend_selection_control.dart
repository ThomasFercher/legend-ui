import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';

/// The accessibility role a [LegendSelectionControl] announces.
///
/// The primitive never hard-codes a role — each leaf passes the one that
/// matches the control it paints, so a checkbox reports as a checkbox and a
/// radio as a radio to assistive tech (rather than every selection control
/// masquerading as the same widget).
enum LegendSelectionRole {
  /// An independent on/off choice — announced with checked state (and a
  /// mixed state for a tristate indeterminate value).
  checkbox,

  /// One option within a mutually exclusive set — announced checked and
  /// in-mutually-exclusive-group.
  radio,

  /// An on/off switch — announced with toggled state.
  toggle,

  /// A selectable surface (list tile, menu item, segment) — announced with
  /// selected state.
  selectable,
}

/// Snapshot of a selection control's state, passed to
/// [LegendSelectionControl.builder] so the leaf can paint its own visual.
///
/// Bundles the selection value ([selected]/[indeterminate]) with the same
/// input states `LegendInteractionStates` carries, so a leaf resolves both
/// its checked visual and its hover/press tint from one object.
class LegendSelectionState {
  const LegendSelectionState({
    required this.selected,
    required this.indeterminate,
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.disabled,
  });

  /// Whether the control currently reads as selected (`false` while
  /// [indeterminate]).
  final bool selected;

  /// The tristate middle value — neither selected nor unselected (only ever
  /// true when [LegendSelectionControl.tristate] is set).
  final bool indeterminate;

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool disabled;

  /// The single effective input [LegendWidgetState] this snapshot maps to,
  /// by the fixed priority ladder disabled ≻ pressed ≻ hovered ≻ focused ≻
  /// normal (RFC-002 R6) — feed it to `InteractiveColors.pick`/`resolve`.
  /// The selection value is orthogonal ([selected]/[indeterminate]).
  LegendWidgetState get effective {
    if (disabled) return const LegendStateDisabled();
    if (pressed) return const LegendStatePressed();
    if (hovered) return const LegendStateHovered();
    if (focused) return const LegendStateFocused();
    return const LegendStateNormal();
  }
}

/// The shared selection-state primitive (DESIGN.md §3) behind every
/// checked/selected control — Checkbox, Radio, Toggle, Segmented, and
/// selectable list/menu items compose this instead of each re-implementing
/// activation, focus, and selection semantics.
///
/// Mirrors `LegendInteractive`'s interaction scaffolding (tap + Enter/Space
/// activation, hover/press/focus tracking, disabled = genuinely inert),
/// but owns the selection *value* and emits selection-role semantics
/// ([LegendSelectionRole]) that `LegendInteractive`'s plain button/toggle
/// vocabulary cannot express. It paints nothing itself — the [builder]
/// renders the leaf's visual from a [LegendSelectionState]. It is to
/// selection controls what `LegendButtonCore` is to buttons.
///
/// A disabled control is genuinely inert: no hit-testing callbacks, no
/// keyboard activation, no focus traversal, semantics marked disabled —
/// preserving the fix for legacy's "disabled buttons stay tappable" bug.
class LegendSelectionControl extends StatefulWidget {
  const LegendSelectionControl({
    required this.selected,
    required this.onChanged,
    required this.role,
    required this.builder,
    super.key,
    this.enabled = true,
    this.tristate = false,
    this.semanticLabel,
    this.onHoverChange,
    this.focusNode,
  }) : assert(
         tristate || selected != null,
         'selected may only be null when tristate is true.',
       );

  /// Current selection value — true/false, or null for the tristate
  /// indeterminate middle (only valid while [tristate]).
  final bool? selected;

  /// Called with the next value when the control is activated (tap or
  /// Enter/Space). Null disables the control. Non-tristate controls always
  /// receive a non-null value; tristate ones cycle false → true → null.
  final ValueChanged<bool?>? onChanged;

  /// The accessibility role this control announces — set by the leaf, never
  /// hard-coded here.
  final LegendSelectionRole role;

  /// Renders the leaf's visual from the current [LegendSelectionState].
  final Widget Function(BuildContext context, LegendSelectionState state)
  builder;

  /// Whether the control accepts input at all. False makes it fully inert.
  final bool enabled;

  /// Enables the third indeterminate value: the activation cycle becomes
  /// false → true → null → false and [selected] may be null.
  final bool tristate;

  /// What this control selects (e.g. 'Wi-Fi') — the checked/selected state
  /// itself is announced via role semantics, never as a hard-coded label.
  final String? semanticLabel;

  /// Raw pointer enter (true) / exit (false) — independent of the styled
  /// [LegendSelectionState.hovered] flag, for leaves (selectable tiles)
  /// that react to hover imperatively. Never fires while disabled.
  final ValueChanged<bool>? onHoverChange;

  final FocusNode? focusNode;

  @override
  State<LegendSelectionControl> createState() => _LegendSelectionControlState();
}

class _LegendSelectionControlState extends State<LegendSelectionControl> {
  var _hovered = false;
  var _pressed = false;
  var _focused = false;

  /// The activation path: enabled and wired to a change handler.
  bool get _enabled => widget.enabled && widget.onChanged != null;

  /// Whether the control reacts to a pointer at all (activation or a raw
  /// hover callback) — gates the hover/focus detector.
  bool get _interactive =>
      widget.enabled &&
      (widget.onChanged != null || widget.onHoverChange != null);

  @override
  void didUpdateWidget(LegendSelectionControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling mid-press nulls the release callbacks, so without this reset
    // the control re-enables stuck pressed (mirrors LegendInteractive).
    if (!_enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    // Recognizer disposal can fire onTapCancel synchronously during this
    // very rebuild (disable mid-press) — only setState on a real change.
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  /// The next value in the activation cycle: a plain toggle, or the
  /// tristate false → true → null → false ladder.
  bool? _nextValue() {
    if (!widget.tristate) return !(widget.selected ?? false);
    return switch (widget.selected) {
      false => true,
      true => null,
      null => false,
    };
  }

  void _activate() => widget.onChanged?.call(_nextValue());

  @override
  Widget build(BuildContext context) {
    final value = widget.selected;
    final state = LegendSelectionState(
      selected: value ?? false,
      indeterminate: value == null,
      // Hover is valid whenever enabled; press/focus stay activation-only.
      hovered: _hovered && widget.enabled,
      pressed: _pressed && _enabled,
      focused: _focused && _enabled,
      disabled: !_enabled,
    );

    // Role-specific semantics — the flags a screen reader reads to name the
    // control.
    final bool? checked;
    final bool? mixed;
    final bool? toggled;
    final bool? selectedFlag;
    switch (widget.role) {
      case LegendSelectionRole.checkbox:
        checked = value;
        mixed = value == null ? true : null;
        toggled = null;
        selectedFlag = null;
      case LegendSelectionRole.radio:
        checked = value ?? false;
        mixed = null;
        toggled = null;
        selectedFlag = null;
      case LegendSelectionRole.toggle:
        checked = null;
        mixed = null;
        toggled = value ?? false;
        selectedFlag = null;
      case LegendSelectionRole.selectable:
        checked = null;
        mixed = null;
        toggled = null;
        selectedFlag = value ?? false;
    }

    return Semantics(
      enabled: _enabled,
      checked: checked,
      mixed: mixed,
      toggled: toggled,
      selected: selectedFlag,
      inMutuallyExclusiveGroup: widget.role == LegendSelectionRole.radio,
      label: widget.semanticLabel,
      // The labeled node must carry the action itself — assistive tech (and
      // semantics-driven tooling) activates the node it announces.
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        // Enabled for any interaction so hover/focus track even without an
        // activation handler; a fully inert control stays out of traversal.
        enabled: _interactive,
        focusNode: widget.focusNode,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        // Own the shortcuts so Enter/Space activate even without a
        // WidgetsApp ancestor (and regardless of platform default mappings).
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
          // WidgetsApp's defaults map Enter to this variant on desktop.
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => _setPressed(true) : null,
          onTapUp: _enabled ? (_) => _setPressed(false) : null,
          onTapCancel: _enabled ? () => _setPressed(false) : null,
          onTap: _enabled ? _activate : null,
          // A dedicated hover region for onHoverChange: a raw enter/exit
          // signal independent of the styled hover highlight (which the
          // focus system gates by highlight mode). Inert while disabled.
          child: widget.onHoverChange == null
              ? widget.builder(context, state)
              : MouseRegion(
                  onEnter: (_) {
                    if (widget.enabled) widget.onHoverChange!(true);
                  },
                  onExit: (_) {
                    if (widget.enabled) widget.onHoverChange!(false);
                  },
                  child: widget.builder(context, state),
                ),
        ),
      ),
    );
  }
}
