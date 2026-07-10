import 'package:flutter/widgets.dart';

/// The opt-in base for the two-argument `build(context, theme)` form
/// (RFC-002 R13, opt-in base).
///
/// Plain-widget forms are the default wiring — the generated
/// `_theme(context)` hook for stateless widgets and the `theme` getter
/// (auto-extension or `_$XThemeState` mixin) for stateful ones. This
/// hierarchy exists solely to serve authors who want the theme as a build
/// *parameter*: the generated part of every themable widget also emits
/// `abstract class _$XBase extends LegendStatelessWidget<XTheme>`
/// (abstract getters over the themed fields + a [resolveThemeOf]
/// implementation that registers the R12 per-field aspects), so opting in
/// is one `extends` swap:
///
/// ```dart
/// @LegendThemeable()
/// class LegendBadge extends _$LegendBadgeBase {
///   const LegendBadge({super.key, this.background});
///
///   @override
///   @Style<Color>.resolve(ColorRef.primary)
///   final Color? background;
///
///   @override
///   Widget build(BuildContext context, LegendBadgeTheme theme) =>
///       ColoredBox(color: theme.background);
/// }
/// ```
///
/// Const-able and hot-reload safe: the element is a plain
/// [ComponentElement] mirroring `StatelessElement` — reassemble marks it
/// dirty like any stateless widget, and [resolveThemeOf] runs inside
/// `build()` so dependencies re-register on every rebuild. There is no
/// stateful two-argument variant (RFC-002 R13 revision 2): stateful
/// widgets use the `theme` getter.
abstract class LegendStatelessWidget<T> extends Widget {
  /// Const so subclasses stay const-able.
  const LegendStatelessWidget({super.key});

  /// Resolves this widget's theme against [context] — the generated
  /// `_$XBase` implements it via `XTheme.of` (full four-level resolution
  /// with the widget's constructor params as level 1, registering the
  /// R12 per-field rebuild aspects).
  @protected
  T resolveThemeOf(BuildContext context);

  /// The two-argument build: [theme] is [resolveThemeOf]'s result for
  /// this frame.
  @protected
  Widget build(BuildContext context, T theme);

  @override
  Element createElement() => _LegendStatelessElement<T>(this);
}

/// Mirrors `StatelessElement`, with the theme resolved as part of the
/// build so dependency registration stays inside the build scope.
class _LegendStatelessElement<T> extends ComponentElement {
  _LegendStatelessElement(LegendStatelessWidget<T> super.widget);

  @override
  Widget build() {
    final widget = this.widget as LegendStatelessWidget<T>;
    return widget.build(this, widget.resolveThemeOf(this));
  }

  @override
  void update(LegendStatelessWidget<T> newWidget) {
    super.update(newWidget);
    rebuild(force: true);
  }
}
