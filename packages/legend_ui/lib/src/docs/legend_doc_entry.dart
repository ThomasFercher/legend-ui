import 'package:meta/meta.dart';

/// One documented theme variable, extracted from source by
/// `legend_gen docs` (RFC-002 R9).
///
/// The widget file is the single source of truth for behavior, theme AND
/// documentation: `legend_gen docs` turns each `@Style` field's dartdoc
/// into a `*.docs.g.dart` manifest of these entries, which the docs site
/// and playground render. Editing the doc comment where the variable is
/// declared is editing the docs; `legend_gen docs --check` keeps the
/// manifest fresh in CI.
@immutable
class LegendDocEntry {
  /// Const so manifests are `const List<LegendDocEntry>` literals.
  const LegendDocEntry({
    required this.owner,
    required this.name,
    required this.type,
    required this.doc,
    required this.defaultDescription,
    required this.group,
  });

  /// Declaring class, e.g. `LegendCard`.
  final String owner;

  /// Variable name, e.g. `background` — or a named state member of a
  /// style-value-class field, e.g. `background.hovered`.
  final String name;

  /// Declared type source, e.g. `Color?`.
  final String type;

  /// The variable's dartdoc text, `///` markers stripped.
  final String doc;

  /// Source text of the default: the `@Style` const value, or the body of
  /// its `.resolve` tear-off (an expression over `t`, a `LegendTokens`).
  final String defaultDescription;

  /// Manifest group, e.g. `component`.
  final String group;
}
