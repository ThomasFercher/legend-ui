import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/src/annotations/annotations.dart';
import 'package:nomo_ui_kit/src/components/toast/nomo_toast.theme.g.dart';
import 'package:nomo_ui_kit/src/primitives/nomo_surface.dart';
import 'package:nomo_ui_kit/src/theme/nomo_theme.dart';

/// Severity of a [NomoToast] — maps to a leading token-color accent
/// (`primary` = info, `secondary` = success, `error` = error).
enum NomoToastSeverity { info, success, error }

/// A transient feedback surface, shown via [showNomoToast].
///
/// Rendered through the kit's own overlay engine (a root-`Overlay` entry)
/// — no Material `ScaffoldMessenger`. Overlapping [showNomoToast] calls
/// queue FIFO and show one at a time, in order (legacy showed exactly one
/// toast with no queue).
@NomoThemeable()
class NomoToast extends StatelessWidget {
  const NomoToast({
    required this.message,
    super.key,
    this.severity = NomoToastSeverity.info,
    this.action,
    this.background,
    this.borderRadius,
    this.padding,
    this.infoAccent,
    this.successAccent,
    this.errorAccent,
  });

  final String message;
  final NomoToastSeverity severity;

  /// Optional trailing widget (e.g. an undo button).
  final Widget? action;

  @Themed(defaultsTo: 't.colors.surface')
  final Color? background;

  @Themed(defaultsTo: 't.sizes.borderRadiusMd')
  final BorderRadius? borderRadius;

  @Themed(
    defaultsTo:
        'EdgeInsets.symmetric(horizontal: t.sizes.md, '
        'vertical: t.sizes.sm)',
  )
  final EdgeInsetsGeometry? padding;

  @Themed(defaultsTo: 't.colors.primary')
  final Color? infoAccent;

  @Themed(defaultsTo: 't.colors.secondary')
  final Color? successAccent;

  @Themed(defaultsTo: 't.colors.error')
  final Color? errorAccent;

  @override
  Widget build(BuildContext context) {
    final theme = NomoToastTheme.of(
      context,
      NomoToastThemeNullable(
        background: background,
        borderRadius: borderRadius,
        padding: padding,
        infoAccent: infoAccent,
        successAccent: successAccent,
        errorAccent: errorAccent,
      ),
    );
    final tokens = NomoTheme.of(context).tokens;
    final accent = switch (severity) {
      NomoToastSeverity.info => theme.infoAccent,
      NomoToastSeverity.success => theme.successAccent,
      NomoToastSeverity.error => theme.errorAccent,
    };

    return NomoSurface(
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

/// Shows [message] as a [NomoToast] in the root [Overlay].
///
/// The toast slides+fades in from the bottom, auto-dismisses after
/// [duration], and queues FIFO behind any toast currently showing.
void showNomoToast(
  BuildContext context,
  String message, {
  NomoToastSeverity severity = NomoToastSeverity.info,
  Duration duration = const Duration(seconds: 3),
  Widget? action,
}) {
  _NomoToastQueue.instance.enqueue(
    _NomoToastRequest(
      overlay: Overlay.of(context, rootOverlay: true),
      toast: NomoToast(message: message, severity: severity, action: action),
      duration: duration,
    ),
  );
}

class _NomoToastRequest {
  const _NomoToastRequest({
    required this.overlay,
    required this.toast,
    required this.duration,
  });

  final OverlayState overlay;
  final NomoToast toast;
  final Duration duration;
}

/// One toast at a time, strictly in call order.
class _NomoToastQueue {
  _NomoToastQueue._();

  static final _NomoToastQueue instance = _NomoToastQueue._();

  final Queue<_NomoToastRequest> _pending = Queue<_NomoToastRequest>();
  bool _showing = false;

  void enqueue(_NomoToastRequest request) {
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
        builder: (context) => _NomoToastHost(
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
class _NomoToastHost extends StatefulWidget {
  const _NomoToastHost({
    required this.request,
    required this.onFinished,
    required this.onTeardown,
  });

  final _NomoToastRequest request;
  final VoidCallback onFinished;
  final VoidCallback onTeardown;

  @override
  State<_NomoToastHost> createState() => _NomoToastHostState();
}

class _NomoToastHostState extends State<_NomoToastHost>
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
    final tokens = NomoTheme.of(context).tokens;
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
