import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_selection_control.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/interactive_colors.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_sizes.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_radio.theme.g.dart';

/// The exclusive one-of-N scope for a set of [LegendRadio]s: carries the
/// group's [value] and [onChanged] down to every descendant radio of the
/// same type argument, so the radios themselves stay declarative leaves.
///
/// Paints nothing — it is an inherited scope plus the group's keyboard
/// behavior: arrow keys move selection between the group's radios (roving
/// focus, wrapping at the ends, skipping disabled radios; left/right are
/// visual directions under RTL), and with a selection made only the
/// selected radio takes part in tab traversal, so Tab crosses the group in
/// one stop. Radios can also be used standalone with explicit
/// [LegendRadio.groupValue]/[LegendRadio.onChanged] — no group required.
class LegendRadioGroup<T> extends StatefulWidget {
  const LegendRadioGroup({
    required this.value,
    required this.onChanged,
    required this.child,
    super.key,
    this.enabled = true,
  });

  /// The currently selected radio's value, or null when nothing is
  /// selected yet.
  final T? value;

  /// Called with the newly selected value. Null disables every radio in
  /// the group.
  final ValueChanged<T>? onChanged;

  /// Whether the group accepts input at all. False makes every descendant
  /// radio fully inert, regardless of its own `enabled`.
  final bool enabled;

  /// The subtree containing the group's [LegendRadio]s.
  final Widget child;

  /// The nearest enclosing group state of the same type argument, or null
  /// when the radio is standalone. Registers a dependency, so a radio
  /// rebuilds when the group's value/handler/enabled change.
  static _LegendRadioGroupState<T>? _maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RadioScope<T>>()?.state;

  @override
  State<LegendRadioGroup<T>> createState() => _LegendRadioGroupState<T>();
}

class _LegendRadioGroupState<T> extends State<LegendRadioGroup<T>> {
  /// The group's radios in build (= visual) order — the roving targets of
  /// the arrow-key movement.
  final _radios = <_LegendRadioState<T>>[];

  void _register(_LegendRadioState<T> radio) {
    if (!_radios.contains(radio)) _radios.add(radio);
  }

  void _unregister(_LegendRadioState<T> radio) {
    _radios.remove(radio);
  }

  /// Moves focus *and* selection [delta] radios over from the currently
  /// focused one, wrapping at the ends and skipping radios that cannot be
  /// selected — the WAI-ARIA radio-group pattern.
  void _move(int delta) {
    final count = _radios.length;
    final current = _radios.indexWhere((radio) => radio._focusNode.hasFocus);
    if (current < 0) return;
    for (var step = 1; step < count; step++) {
      final next = _radios[(current + delta * step) % count];
      if (!next._selectable) continue;
      next._focusNode.requestFocus();
      next._select();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RadioScope<T>(
      state: this,
      value: widget.value,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      child: widget.child,
    );
  }
}

/// The inherited hand-off from a [LegendRadioGroup] to its radios; notifies
/// when the group's value, handler, or enabled flag change.
class _RadioScope<T> extends InheritedWidget {
  const _RadioScope({
    required this.state,
    required this.value,
    required this.onChanged,
    required this.enabled,
    required super.child,
  });

  final _LegendRadioGroupState<T> state;
  final T? value;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  bool updateShouldNotify(_RadioScope<T> oldWidget) =>
      value != oldWidget.value ||
      onChanged != oldWidget.onChanged ||
      enabled != oldWidget.enabled;
}

/// A radio — one option within a mutually exclusive one-of-N choice.
///
/// Composes [LegendSelectionControl] (tap/keyboard activation, real radio
/// semantics: checked state in a mutually exclusive group) +
/// [LegendSurface] (the circle itself); the selected dot is a dedicated
/// painter, no Material. Tapping the selected radio never deselects — an
/// exclusive control has no off gesture.
///
/// Inside a [LegendRadioGroup] of the same type argument the group's
/// value/handler drive selection (and [groupValue]/[onChanged] are
/// ignored); standalone, wire [groupValue] and [onChanged] explicitly.
///
/// An optional inline [label] renders after the circle and is part of the
/// tap target, so tapping the text selects the radio too.
@LegendThemeable()
class LegendRadio<T> extends StatefulWidget {
  const LegendRadio({
    required this.value,
    super.key,
    this.groupValue,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.semanticLabel,
    this.fill,
    this.dotColor,
    this.borderColor,
    this.focusedBorderColor,
    this.size,
    this.borderWidth,
  });

  /// The value this radio stands for — selected while it equals the
  /// group's value.
  final T value;

  /// The currently selected value, for standalone use. Inside a
  /// [LegendRadioGroup] the group's value wins and this is ignored.
  final T? groupValue;

  /// Called with [value] when this radio is selected (tap, Enter/Space, or
  /// an arrow key moving selection here), for standalone use. Null
  /// disables a standalone radio. Inside a [LegendRadioGroup] the group's
  /// handler wins and this is ignored.
  final ValueChanged<T>? onChanged;

  /// Whether this radio accepts input at all. False makes it fully inert
  /// (and arrow-key movement skips it).
  final bool enabled;

  /// Inline label after the circle — part of the tap target, and the
  /// semantic label when [semanticLabel] is unset.
  final String? label;

  /// What this radio chooses (e.g. 'Monthly billing') — the selected state
  /// itself is announced via radio semantics, never as a hard-coded label.
  /// Falls back to [label].
  final String? semanticLabel;

  /// Fill of the circle while selected, per interaction state —
  /// hover/press blend the dot color over the fill (8%/16%), disabled
  /// swaps to the token disabled fill.
  @Style<InteractiveColors>.resolve(_fill, lerp: true)
  final InteractiveColors? fill;

  /// Color of the selected inner dot.
  @Style<Color>.resolve(ColorRef.onPrimary, lerp: true)
  final Color? dotColor;

  /// Border color of the unselected circle.
  @Style<Color>.resolve(ColorRef.background3, lerp: true)
  final Color? borderColor;

  /// Border color while the unselected circle holds keyboard focus (a
  /// selected radio shows focus through the [fill] focused fill instead).
  @Style<Color>.resolve(ColorRef.primary, lerp: true)
  final Color? focusedBorderColor;

  /// Diameter of the circle.
  @Style<double>.resolve(SizeRef.iconMd)
  final double? size;

  /// Stroke width of the unselected border.
  @Style<double>(1.5)
  final double? borderWidth;

  @override
  State<LegendRadio<T>> createState() => _LegendRadioState<T>();
}

class _LegendRadioState<T> extends State<LegendRadio<T>> {
  final _focusNode = FocusNode(debugLabel: 'LegendRadio');

  /// The enclosing group of the same type argument, or null standalone.
  _LegendRadioGroupState<T>? _group;

  /// The effective one-of-N value this radio compares against.
  T? get _groupValue =>
      _group == null ? widget.groupValue : _group!.widget.value;

  /// The effective selection handler — the group's inside a group, the
  /// radio's own standalone.
  ValueChanged<T>? get _onChanged =>
      _group == null ? widget.onChanged : _group!.widget.onChanged;

  bool get _selected => _groupValue == widget.value;

  /// Whether arrow-key movement may land selection here.
  bool get _selectable =>
      widget.enabled && (_group?.widget.enabled ?? true) && _onChanged != null;

  void _select() => _onChanged?.call(widget.value);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = LegendRadioGroup._maybeOf<T>(context);
    if (!identical(group, _group)) {
      _group?._unregister(this);
      _group = group?.._register(this);
    }
  }

  @override
  void dispose() {
    _group?._unregister(this);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final group = _group;
    final selected = _selected;

    // Roving tab stop: once the group has a selection, only the selected
    // radio takes part in tab traversal — arrows move within the group.
    _focusNode.skipTraversal =
        group != null && group.widget.value != null && !selected;

    final control = LegendSelectionControl(
      selected: selected,
      role: LegendSelectionRole.radio,
      enabled: widget.enabled && (group?.widget.enabled ?? true),
      semanticLabel: widget.semanticLabel ?? widget.label,
      focusNode: _focusNode,
      onChanged: _onChanged == null
          ? null
          : (next) {
              // Exclusive: activating the selected radio reports next ==
              // false — ignored, the choice never deselects.
              if (next ?? false) _select();
            },
      builder: (context, state) {
        final borderColor = state.disabled
            ? tokens.colors.disabled
            : state.focused
            ? theme.focusedBorderColor
            : theme.borderColor;
        final circle = LegendSurface(
          color: selected
              ? theme.fill.resolve(state.effective, tokens.states)
              : null,
          borderRadius: BorderRadius.circular(theme.size),
          border: selected
              ? null
              : Border.all(color: borderColor, width: theme.borderWidth),
          duration: const Duration(milliseconds: 120),
          child: SizedBox.square(
            dimension: theme.size,
            child: AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: CustomPaint(
                painter: _DotPainter(
                  color: state.disabled
                      ? tokens.colors.onDisabled
                      : theme.dotColor,
                ),
              ),
            ),
          ),
        );
        final label = widget.label;
        if (label == null) return circle;
        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: tokens.sizes.sm,
          children: [
            circle,
            Flexible(
              // The control's Semantics node already carries the label —
              // without this the text would announce twice.
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: tokens.typography.b2.copyWith(
                    color: state.disabled
                        ? tokens.colors.onDisabled
                        : tokens.colors.foreground1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    if (group == null) return control;

    // The group's arrow-key movement, mounted on each radio so arrows are
    // only captured while a radio holds focus — never from unrelated
    // focusables elsewhere under the group's subtree.
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.arrowUp): _MoveSelectionIntent(-1),
        SingleActivator(LogicalKeyboardKey.arrowDown): _MoveSelectionIntent(1),
        SingleActivator(LogicalKeyboardKey.arrowLeft): _MoveSelectionIntent(
          -1,
          horizontal: true,
        ),
        SingleActivator(LogicalKeyboardKey.arrowRight): _MoveSelectionIntent(
          1,
          horizontal: true,
        ),
      },
      child: Actions(
        actions: {
          _MoveSelectionIntent: CallbackAction<_MoveSelectionIntent>(
            onInvoke: (intent) {
              // Left/right are visual directions: under RTL the index
              // steps the other way (vertical arrows are unaffected).
              final rtl = Directionality.of(context) == TextDirection.rtl;
              group._move(
                intent.horizontal && rtl ? -intent.delta : intent.delta,
              );
              return null;
            },
          ),
        },
        child: control,
      ),
    );
  }
}

/// Moves group selection by [delta] radios ([horizontal] deltas flip under
/// RTL) — the radio owns the arrow-key mapping so movement works without a
/// `WidgetsApp` ancestor.
class _MoveSelectionIntent extends Intent {
  const _MoveSelectionIntent(this.delta, {this.horizontal = false});

  final int delta;
  final bool horizontal;
}

/// Paints the selected inner dot as a filled circle proportional to the
/// radio size.
class _DotPainter extends CustomPainter {
  const _DotPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      size.shortestSide * 0.22,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_DotPainter oldDelegate) => color != oldDelegate.color;
}

InteractiveColors _fill(LegendTokens t) => InteractiveColors(
  normal: t.colors.primary,
  hovered: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.08),
    t.colors.primary,
  ),
  pressed: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.16),
    t.colors.primary,
  ),
  focused: Color.alphaBlend(
    t.colors.onPrimary.withValues(alpha: 0.08),
    t.colors.primary,
  ),
  disabled: t.colors.disabled,
);
