import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/theme/legend_widget_state.dart';

/// Snapshot of an interactive widget's input state, passed to
/// [LegendInteractive.builder].
class LegendInteractionStates {
  const LegendInteractionStates({
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.disabled,
  });

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool disabled;

  /// The single effective [LegendWidgetState] this snapshot maps to, by
  /// the fixed priority ladder disabled ≻ pressed ≻ hovered ≻ focused ≻
  /// normal (RFC-002 R6) — feed it to `InteractiveColors.pick`/`resolve`.
  LegendWidgetState get effective {
    if (disabled) return const LegendStateDisabled();
    if (pressed) return const LegendStatePressed();
    if (hovered) return const LegendStateHovered();
    if (focused) return const LegendStateFocused();
    return const LegendStateNormal();
  }
}

/// The one tap/hover/focus/disabled primitive (DESIGN.md §3) — every
/// interactive component composes this instead of re-implementing input
/// handling (and instead of Material's InkWell).
///
/// A disabled [LegendInteractive] is genuinely inert: no hit-testing
/// callbacks, no keyboard activation, semantics marked disabled — fixing
/// the legacy bug where "disabled" buttons stayed tappable.
class LegendInteractive extends StatefulWidget {
  const LegendInteractive({
    required this.builder,
    super.key,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.toggled,
    this.focusNode,
  });

  final Widget Function(BuildContext context, LegendInteractionStates states)
  builder;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;

  /// Non-null announces this as a toggle (switch/checkbox) with the given
  /// state instead of a plain button.
  final bool? toggled;

  final FocusNode? focusNode;

  @override
  State<LegendInteractive> createState() => _LegendInteractiveState();
}

class _LegendInteractiveState extends State<LegendInteractive> {
  var _hovered = false;
  var _pressed = false;
  var _focused = false;

  bool get _enabled => widget.enabled && widget.onTap != null;

  @override
  void didUpdateWidget(LegendInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Disabling mid-press nulls the tap callbacks, so the release never
    // clears _pressed — reset here or the widget re-enables stuck pressed.
    if (!_enabled) _pressed = false;
  }

  void _setPressed(bool value) {
    // Recognizer disposal fires onTapCancel synchronously while this very
    // widget is rebuilding (disable mid-press) — only setState on a change.
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final states = LegendInteractionStates(
      hovered: _hovered && _enabled,
      pressed: _pressed && _enabled,
      focused: _focused && _enabled,
      disabled: !_enabled,
    );
    return Semantics(
      button: widget.toggled == null,
      toggled: widget.toggled,
      enabled: _enabled,
      label: widget.semanticLabel,
      // The labeled node must carry the tap action itself — assistive tech
      // (and semantics-driven tooling) activates the node it announces.
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        // Own shortcuts so Enter/Space activate even without a WidgetsApp
        // ancestor (and regardless of platform default mappings).
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
          onTap: _enabled ? widget.onTap : null,
          child: widget.builder(context, states),
        ),
      ),
    );
  }
}
