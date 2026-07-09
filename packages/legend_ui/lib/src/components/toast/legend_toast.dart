import 'dart:async';
import 'dart:collection';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/primitives/legend_surface.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_colors.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_toast.theme.g.dart';

/// Severity of a [LegendToast] — maps to a leading token-color accent
/// (`primary` = info, `secondary` = success, `error` = error).
enum LegendToastSeverity { info, success, error }

/// A transient feedback surface, shown via [showLegendToast].
///
/// Composes [LegendSurface]; rendered through the kit's own overlay
/// engine (a root-`Overlay` entry) — no Material `ScaffoldMessenger`.
///
/// Overlapping [showLegendToast] calls queue FIFO and show one at a time,
/// in order (legacy showed exactly one toast with no queue).
@LegendThemeable()
class LegendToast extends StatelessWidget {
  const LegendToast({
    required this.message,
    super.key,
    this.severity = LegendToastSeverity.info,
    this.action,
    this.background,
    this.borderRadius,
    this.padding,
    this.infoAccent,
    this.successAccent,
    this.errorAccent,
  });

  final String message;
  final LegendToastSeverity severity;

  /// Optional trailing widget (e.g. an undo button).
  final Widget? action;

  /// Fill color of the toast surface.
  @Style<Color>.resolve(LegendColorsRef.surface)
  final Color? background;

  /// Corner rounding of the toast surface.
  @Style<BorderRadius>.resolve(_borderRadius)
  final BorderRadius? borderRadius;

  /// Inner padding around the accent bar, message and action.
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;

  /// Leading accent color for [LegendToastSeverity.info].
  @Style<Color>.resolve(LegendColorsRef.primary)
  final Color? infoAccent;

  /// Leading accent color for [LegendToastSeverity.success].
  @Style<Color>.resolve(LegendColorsRef.secondary)
  final Color? successAccent;

  /// Leading accent color for [LegendToastSeverity.error].
  @Style<Color>.resolve(LegendColorsRef.error)
  final Color? errorAccent;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final tokens = LegendTheme.of(context).tokens;
    final accent = switch (severity) {
      LegendToastSeverity.info => theme.infoAccent,
      LegendToastSeverity.success => theme.successAccent,
      LegendToastSeverity.error => theme.errorAccent,
    };

    return LegendSurface(
      color: theme.background,
      borderRadius: theme.borderRadius,
      shadows: tokens.shadows.medium,
      padding: theme.padding,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: tokens.sizes.sm,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const SizedBox(width: 4),
            ),
            Flexible(
              child: Center(
                widthFactor: 1,
                child: Text(
                  message,
                  style: tokens.typography.b2.copyWith(
                    color: tokens.colors.foreground1,
                  ),
                ),
              ),
            ),
            if (action != null) Center(widthFactor: 1, child: action),
          ],
        ),
      ),
    );
  }
}

/// Shows [message] as a [LegendToast] in the root [Overlay].
///
/// The toast slides+fades in from the bottom, auto-dismisses after
/// [duration], and queues FIFO behind any toast currently showing.
void showLegendToast(
  BuildContext context,
  String message, {
  LegendToastSeverity severity = LegendToastSeverity.info,
  Duration duration = const Duration(seconds: 3),
  Widget? action,
}) {
  _LegendToastQueue.instance.enqueue(
    _LegendToastRequest(
      overlay: Overlay.of(context, rootOverlay: true),
      toast: LegendToast(message: message, severity: severity, action: action),
      duration: duration,
    ),
  );
}

class _LegendToastRequest {
  const _LegendToastRequest({
    required this.overlay,
    required this.toast,
    required this.duration,
  });

  final OverlayState overlay;
  final LegendToast toast;
  final Duration duration;
}

/// One toast at a time, strictly in call order.
class _LegendToastQueue {
  _LegendToastQueue._();

  static final _LegendToastQueue instance = _LegendToastQueue._();

  final Queue<_LegendToastRequest> _pending = Queue<_LegendToastRequest>();
  bool _showing = false;

  void enqueue(_LegendToastRequest request) {
    _pending.add(request);
    _showNext();
  }

  void _showNext() {
    while (!_showing && _pending.isNotEmpty) {
      final request = _pending.removeFirst();
      // The overlay may be gone by the time this request's turn comes
      // (navigation teardown, test teardown) — drop it and move on.
      if (!request.overlay.mounted) continue;
      _showing = true;
      late final OverlayEntry entry;
      entry = OverlayEntry(
        builder: (context) => _LegendToastHost(
          request: request,
          onFinished: () {
            entry
              ..remove()
              ..dispose();
            _showing = false;
            _showNext();
          },
          // The tree was torn down mid-toast; the entry died with its
          // overlay. Just unblock the queue.
          onTeardown: () => _showing = false,
        ),
      );
      request.overlay.insert(entry);
    }
  }
}

/// Animates one toast in, holds it for its duration, animates it out.
class _LegendToastHost extends StatefulWidget {
  const _LegendToastHost({
    required this.request,
    required this.onFinished,
    required this.onTeardown,
  });

  final _LegendToastRequest request;
  final VoidCallback onFinished;
  final VoidCallback onTeardown;

  @override
  State<_LegendToastHost> createState() => _LegendToastHostState();
}

class _LegendToastHostState extends State<_LegendToastHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.request.duration, _dismiss);
  }

  void _dismiss() {
    _controller.reverse().whenCompleteOrCancel(() {
      if (_done) return;
      _done = true;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    final finished = _done;
    // Guard: disposing the controller cancels an in-flight reverse, which
    // fires the whenCompleteOrCancel callback above — it must not call
    // onFinished during teardown.
    _done = true;
    _curve.dispose();
    _controller.dispose();
    if (!finished) widget.onTeardown();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(tokens.sizes.md),
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(_curve),
            child: FadeTransition(opacity: _curve, child: widget.request.toast),
          ),
        ),
      ),
    );
  }
}

BorderRadius _borderRadius(LegendTokens t) => t.sizes.borderRadiusMd;

EdgeInsetsGeometry _padding(LegendTokens t) =>
    EdgeInsets.symmetric(horizontal: t.sizes.md, vertical: t.sizes.sm);
