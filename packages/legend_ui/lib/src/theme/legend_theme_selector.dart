import 'package:flutter/foundation.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';

/// A distinct-until-changed [ValueListenable] selector over a theme source
/// (RFC-002 R12.4): listens to [source] (any [Listenable] whose
/// notifications mean "the theme may have changed" — typically the app's
/// theme controller), re-reads [data], applies [select], and notifies
/// **only when the selected value actually changes**.
///
/// This is the element-free change stream for animation and imperative
/// consumers (painters, controllers) that want per-field theme changes
/// without any widget rebuild. It lives against the theme's source of
/// truth, not the element tree, so it has a well-defined lifetime: call
/// [dispose] when done (it detaches from [source]).
///
/// Generated `XThemeListenables.<field>(source, data)` helpers construct
/// these with the field's resolver (registry + token defaults) as
/// [select]; hand-rolling one over any getter works the same way.
class LegendThemeSelector<T> extends ChangeNotifier
    implements ValueListenable<T> {
  /// Creates the selector and computes the initial [value]; attaches to
  /// [source] immediately.
  LegendThemeSelector(this.source, this.data, this.select)
    : _value = select(data()) {
    source.addListener(_recompute);
  }

  /// The notifier this selector subscribes to.
  final Listenable source;

  /// Reads the current theme data whenever [source] notifies.
  final LegendThemeData Function() data;

  /// Selects the observed value; compared with `!=` for distinctness.
  final T Function(LegendThemeData data) select;

  T _value;

  @override
  T get value => _value;

  void _recompute() {
    final next = select(data());
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    source.removeListener(_recompute);
    super.dispose();
  }
}
