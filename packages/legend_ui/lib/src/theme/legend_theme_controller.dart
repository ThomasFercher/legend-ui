import 'package:flutter/foundation.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_seed.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

/// The consumer-side theme state (RFC-002 R8): a [ChangeNotifier] that holds
/// a token source — a [LegendSeed] or explicit [baseTokens] — a [dark] flag,
/// and the per-widget-type override map, and assembles them into the
/// [LegendThemeData] an app hands to `LegendApp`/[LegendTheme].
///
/// Every real app grows exactly this object; shipping it removes the
/// boilerplate without adding policy:
///
/// - **Token source**: [baseTokens] wins when set; else [seed] runs through
///   [LegendTokens.fromSeed]; else the kit presets [LegendTokens.light] /
///   [LegendTokens.dark]. The controller's [dark] flag is the single
///   brightness switch — it overrides [LegendSeed.brightness], so one seed
///   serves both modes.
/// - **Component overrides** (level 3): [setOverride] registers a sparse
///   generated `XThemeNullable` under its **widget type** in the open
///   `components` registry (RFC-002 R3) — the same map consumers' own
///   generated themes plug into.
/// - Every typed mutator calls [notifyListeners] (and no-ops on equal
///   values, so wiring it to an `AnimatedLegendTheme` never re-lerps for
///   nothing).
///
/// Subclasses may override [tokens] to derive the base tokens differently
/// (presets, `copyWith` adjustments); [data] and the override map keep
/// working unchanged. The docs app's `ThemeController` is the reference
/// consumer.
class LegendThemeController extends ChangeNotifier {
  /// Creates the controller; all sources are optional — the default is the
  /// kit's light preset with no overrides.
  LegendThemeController({
    LegendSeed? seed,
    LegendTokens? tokens,
    bool dark = false,
    Map<Type, Object>? components,
  }) : _seed = seed,
       _baseTokens = tokens,
       _dark = dark,
       _components = {...?components};

  LegendSeed? _seed;
  LegendTokens? _baseTokens;
  bool _dark;
  final Map<Type, Object> _components;

  /// The seed the base tokens derive from, unless [baseTokens] overrides
  /// it wholesale. Null means "use the kit preset tokens".
  LegendSeed? get seed => _seed;

  /// Swaps the seed (null returns to the kit presets) and regenerates
  /// [tokens] via [LegendTokens.fromSeed].
  void setSeed(LegendSeed? value) {
    if (_seed == value) return;
    _seed = value;
    notifyListeners();
  }

  /// Explicit base tokens; when set they win over [seed] and [dark].
  LegendTokens? get baseTokens => _baseTokens;

  /// Sets (or with null, clears) the explicit base tokens.
  void setTokens(LegendTokens? value) {
    if (identical(_baseTokens, value)) return;
    _baseTokens = value;
    notifyListeners();
  }

  /// Whether the derived theme is dark. The flag re-runs the seed
  /// derivation (or swaps the kit preset) — one seed, both modes.
  bool get dark => _dark;

  /// Flips [dark].
  void setDark({required bool value}) {
    if (_dark == value) return;
    _dark = value;
    notifyListeners();
  }

  /// Read-only view of the registered component overrides, keyed by widget
  /// type (RFC-002 R3).
  Map<Type, Object> get components => Map.unmodifiable(_components);

  /// Registers [theme] — a generated sparse `XThemeNullable` — for [widget]
  /// in the level-3 `components` registry; null removes the entry (same as
  /// [clearOverride]).
  ///
  /// Generated `XThemeNullable` classes are value-compared (RFC-002 R2), so
  /// re-setting an equal override is a no-op and notifies nobody.
  void setOverride(Type widget, Object? theme) {
    if (_components[widget] == theme) return;
    if (theme == null) {
      if (!_components.containsKey(widget)) return;
      _components.remove(widget);
    } else {
      _components[widget] = theme;
    }
    notifyListeners();
  }

  /// Removes the override registered for [widget]; unset properties resume
  /// resolving through the lower levels (token-derived defaults).
  void clearOverride(Type widget) => setOverride(widget, null);

  /// Drops every registered component override.
  void clearOverrides() {
    if (_components.isEmpty) return;
    _components.clear();
    notifyListeners();
  }

  /// Back to square one: no seed, no explicit tokens, light, no overrides.
  void reset() {
    final untouched =
        _seed == null && _baseTokens == null && !_dark && _components.isEmpty;
    if (untouched) return;
    _seed = null;
    _baseTokens = null;
    _dark = false;
    _components.clear();
    notifyListeners();
  }

  /// The base tokens the controller currently derives — the one overridable
  /// hook: [baseTokens] wholesale, else [seed] through
  /// [LegendTokens.fromSeed] with [dark] deciding the brightness, else the
  /// kit presets.
  LegendTokens get tokens {
    final explicit = _baseTokens;
    if (explicit != null) return explicit;
    final seed = _seed;
    if (seed == null) return _dark ? LegendTokens.dark : LegendTokens.light;
    return LegendTokens.fromSeed(
      LegendSeed(
        brand: seed.brand,
        neutral: seed.neutral,
        radius: seed.radius,
        sizeUnit: seed.sizeUnit,
        fontFamily: seed.fontFamily,
        brightness: _dark ? Brightness.dark : Brightness.light,
      ),
    );
  }

  /// The assembled [LegendThemeData] the app runs on: [tokens] plus a copy
  /// of the override registry.
  LegendThemeData get data =>
      LegendThemeData(tokens: tokens, components: Map.of(_components));
}
