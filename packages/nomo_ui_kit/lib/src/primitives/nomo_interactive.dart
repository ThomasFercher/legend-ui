import 'package:flutter/widgets.dart';

/// Snapshot of an interactive widget's input state, passed to
/// [NomoInteractive.builder].
class NomoInteractionStates {
  const NomoInteractionStates({
    required this.hovered,
    required this.pressed,
    required this.focused,
    required this.disabled,
  });

  final bool hovered;
  final bool pressed;
  final bool focused;
  final bool disabled;
}

/// The one tap/hover/focus/disabled primitive (DESIGN.md §3) — every
/// interactive component composes this instead of re-implementing input
/// handling (and instead of Material's InkWell).
///
/// A disabled [NomoInteractive] is genuinely inert: no hit-testing
/// callbacks, no keyboard activation, semantics marked disabled — fixing
/// the legacy bug where "disabled" buttons stayed tappable.
class NomoInteractive extends StatefulWidget {
  const NomoInteractive({
    required this.builder,
    super.key,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.focusNode,
  });

  final Widget Function(BuildContext context, NomoInteractionStates states)
  builder;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;
  final FocusNode? focusNode;

  @override
  State<NomoInteractive> createState() => _NomoInteractiveState();
}

class _NomoInteractiveState extends State<NomoInteractive> {
  var _hovered = false;
  var _pressed = false;
  var _focused = false;

  bool get _enabled => widget.enabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final states = NomoInteractionStates(
      hovered: _hovered && _enabled,
      pressed: _pressed && _enabled,
      focused: _focused && _enabled,
      disabled: !_enabled,
    );
    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: widget.focusNode,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onTap : null,
          child: widget.builder(context, states),
        ),
      ),
    );
  }
}
