import 'package:flutter/widgets.dart';

/// The modal half of the overlay engine (DESIGN.md §3): a Material-free
/// `PopupRoute` used by dialogs and sheets alike.
///
/// Centered modals fade+scale; edge-aligned ones (sheets) slide from
/// their edge.
class NomoModalRoute<T> extends PopupRoute<T> {
  NomoModalRoute({
    required this.builder,
    this.alignment = Alignment.center,
    this.dismissible = true,
    String barrierLabel = 'Dismiss',
    Color? barrier,
    Duration? duration,
  }) : _barrierLabel = barrierLabel,
       _barrier = barrier ?? const Color(0x8A000000),
       _duration = duration ?? const Duration(milliseconds: 180);

  final WidgetBuilder builder;
  final Alignment alignment;
  final bool dismissible;
  final String _barrierLabel;
  final Color _barrier;
  final Duration _duration;

  @override
  Color get barrierColor => _barrier;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => _barrierLabel;

  @override
  Duration get transitionDuration => _duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SafeArea(
      child: Align(alignment: alignment, child: builder(context)),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    if (alignment.y == 1 || alignment.y == -1) {
      return SlideTransition(
        position: Tween(
          begin: Offset(0, alignment.y == 1 ? 1 : -1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    }
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
        child: child,
      ),
    );
  }
}

/// Shows [builder] as a modal above everything; returns the value passed
/// to `Navigator.pop`.
Future<T?> showNomoModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Alignment alignment = Alignment.center,
  bool dismissible = true,
  String barrierLabel = 'Dismiss',
  Color? barrier,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    NomoModalRoute<T>(
      builder: builder,
      alignment: alignment,
      dismissible: dismissible,
      barrierLabel: barrierLabel,
      barrier: barrier,
    ),
  );
}
