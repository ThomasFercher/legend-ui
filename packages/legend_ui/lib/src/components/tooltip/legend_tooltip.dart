import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/popover/legend_popover.dart';
import 'package:legend_ui/src/components/text/legend_text.dart';
import 'package:legend_ui/src/primitives/legend_interactive.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';
import 'package:legend_ui/src/tokens/legend_typography.dart';

part 'legend_tooltip.theme.g.dart';

/// A transient hint anchored to its trigger — shows on hover (after
/// [showDelay]), on keyboard focus, and on long-press for touch; plain
/// text goes through [message], arbitrary content (a citation preview, a
/// formatted wallet address) through [richMessage].
///
/// Composes [LegendPopover] in [LegendPopoverTrigger.manual] mode — the
/// popover supplies the anchored themed panel and outside-tap dismissal;
/// this widget owns only the triggering. Hover uses a raw `MouseRegion`
/// (not [LegendInteractive]: that would wrap the trigger in button
/// semantics, focus handling and a click cursor, and a tooltip trigger
/// must stay semantically transparent — the child is frequently a button
/// itself). Focus is observed through a non-focusable `Focus` ancestor,
/// so the tooltip shows when the child gains keyboard focus without
/// adding a traversal stop of its own; Escape hides it while the trigger
/// keeps focus. A long-press shows the hint on touch; it stays up until
/// a tap anywhere else dismisses it.
///
/// Panel surface styling (background, radius, shadow, padding) resolves
/// through [LegendPopover]'s own theme, so restyling popovers restyles
/// tooltips with them; only tooltip-specific knobs are themed here. The
/// hint is announced to assistive tech via `SemanticsProperties.tooltip`
/// ([message], or [semanticLabel] when using [richMessage]).
@LegendThemeable()
class LegendTooltip extends StatefulWidget {
  const LegendTooltip({
    required this.child,
    super.key,
    this.message,
    this.richMessage,
    this.placement = LegendPopoverPlacement.top,
    this.enabled = true,
    this.semanticLabel,
    this.textStyle,
    this.maxWidth,
    this.showDelay,
    this.hideDelay,
  }) : assert(
         (message == null) != (richMessage == null),
         'Provide exactly one of message or richMessage.',
       );

  /// The trigger the hint anchors to — rendered as-is, semantics and
  /// gestures untouched apart from the long-press recognizer.
  final Widget child;

  /// Plain hint text, rendered in [textStyle] via [LegendText] and
  /// announced as the semantic tooltip.
  final String? message;

  /// Arbitrary hint content replacing [message] — pass [semanticLabel]
  /// alongside so assistive tech still gets an announcement.
  final Widget? richMessage;

  /// Which side of the trigger the hint appears on.
  final LegendPopoverPlacement placement;

  /// When false no trigger — hover, focus, or long-press — shows the
  /// hint, and an already-visible one hides.
  final bool enabled;

  /// Announced as the semantic tooltip; defaults to [message], so it is
  /// only needed with [richMessage].
  final String? semanticLabel;

  /// Style of the plain [message] text — compact by default.
  @Style<TextStyle>.resolve(TextRef.b3)
  final TextStyle? textStyle;

  /// Upper width bound of the hint panel; longer messages wrap.
  @Style<double>(320)
  final double? maxWidth;

  /// How long a pointer must hover before the hint shows.
  @Style<Duration>(Duration(milliseconds: 500))
  final Duration? showDelay;

  /// Grace period after the pointer leaves before the hint hides —
  /// re-entering within it keeps the hint up.
  @Style<Duration>(Duration(milliseconds: 100))
  final Duration? hideDelay;

  @override
  State<LegendTooltip> createState() => _LegendTooltipState();
}

class _LegendTooltipState extends State<LegendTooltip> {
  final LegendPopoverController _controller = LegendPopoverController();
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  void didUpdateWidget(LegendTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && oldWidget.enabled) {
      _cancelTimers();
      _controller.hide();
    }
  }

  @override
  void dispose() {
    _cancelTimers();
    _controller.dispose();
    super.dispose();
  }

  void _cancelTimers() {
    _showTimer?.cancel();
    _showTimer = null;
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  /// Hover enter: any pending hide is void; the hint shows after [delay]
  /// unless it is already up (re-entering within the grace period keeps
  /// it showing without a second wait).
  void _scheduleShow(Duration delay) {
    _hideTimer?.cancel();
    _hideTimer = null;
    if (_controller.isOpen || _showTimer != null) return;
    _showTimer = Timer(delay, () {
      _showTimer = null;
      _controller.show();
    });
  }

  /// Hover exit: a pending show is cancelled; a visible hint hides after
  /// [delay].
  void _scheduleHide(Duration delay) {
    _showTimer?.cancel();
    _showTimer = null;
    if (!_controller.isOpen) return;
    _hideTimer?.cancel();
    _hideTimer = Timer(delay, () {
      _hideTimer = null;
      _controller.hide();
    });
  }

  /// Keyboard users get the hint immediately on focus — a wait would just
  /// hide it from the people who cannot hover — and lose it on blur.
  void _handleFocusChange({required bool focused}) {
    _cancelTimers();
    if (focused) {
      _controller.show();
    } else {
      _controller.hide();
    }
  }

  /// Touch trigger: show immediately; the popover's outside-tap dismissal
  /// takes it down.
  void _handleLongPress() {
    _cancelTimers();
    _controller.show();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // The hint must not swallow Escape the trigger didn't cause.
    if (!_controller.isOpen) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.escape) {
      return KeyEventResult.ignored;
    }
    _cancelTimers();
    _controller.hide();
    return KeyEventResult.handled;
  }

  /// Raw translation opening a token-sized gap between trigger and hint,
  /// away from the anchor edge (start/end resolve against [direction]).
  Offset _gap(double size, TextDirection direction) {
    final ltr = direction == TextDirection.ltr;
    return switch (widget.placement) {
      LegendPopoverPlacement.top => Offset(0, -size),
      LegendPopoverPlacement.bottom => Offset(0, size),
      LegendPopoverPlacement.start when ltr => Offset(-size, 0),
      LegendPopoverPlacement.start => Offset(size, 0),
      LegendPopoverPlacement.end when ltr => Offset(size, 0),
      LegendPopoverPlacement.end => Offset(-size, 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    // R13 auto-extension: `theme` is the generated State getter.
    final theme = this.theme;
    final tokens = LegendTheme.of(context).tokens;
    final label = widget.semanticLabel ?? widget.message;
    final enabled = widget.enabled;

    Widget trigger = MouseRegion(
      onEnter: enabled ? (_) => _scheduleShow(theme.showDelay) : null,
      onExit: enabled ? (_) => _scheduleHide(theme.hideDelay) : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onLongPress: enabled ? _handleLongPress : null,
        child: widget.child,
      ),
    );

    trigger = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: enabled
          ? (focused) => _handleFocusChange(focused: focused)
          : null,
      onKeyEvent: enabled ? _handleKeyEvent : null,
      child: trigger,
    );

    if (label != null) {
      trigger = Semantics(tooltip: label, child: trigger);
    }

    return LegendPopover(
      controller: _controller,
      trigger: LegendPopoverTrigger.manual,
      placement: widget.placement,
      offset: _gap(tokens.sizes.xs, Directionality.of(context)),
      // A hover hint must never steal focus from what the user is doing.
      autofocus: false,
      overlay: (context) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: theme.maxWidth),
        child:
            widget.richMessage ??
            LegendText(widget.message!, style: theme.textStyle),
      ),
      child: trigger,
    );
  }
}
