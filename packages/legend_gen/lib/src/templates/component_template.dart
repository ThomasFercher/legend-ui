/// Scaffolding templates for `legend_gen create` (RFC-002 R11.3).
///
/// **Decision (2026-07-09): structured template module, not a bundled
/// mason brick.** R11.3 prefers Dart Frog's model — `create` templates
/// compiled into the CLI as a `MasonBundle` so they version in lock-step —
/// with an explicit fallback: *"If bundling proves disproportionate, a
/// clearly-structured template module is an acceptable fallback."* It is
/// disproportionate here: the scaffold is a single file with two derived
/// variables, while `package:mason` would add its full runtime
/// (archive/http/yaml/mustache and the brick-bundling toolchain) to every
/// consumer's dev graph — exactly the dependency creep DESIGN.md §5.2
/// sells `legend_gen` as not having. This module keeps the brick *shape* —
/// a named template, typed variables, one render function — so migrating
/// to a real `MasonBundle` stays mechanical if the template set ever grows
/// beyond a couple of files.
///
/// The template still versions in lock-step with the CLI (it is compiled
/// in), needs no network, and cannot drift — the three properties R11.3
/// actually asks for.
library;

/// The typed variable set of the component template — the equivalent of a
/// brick's `vars`.
class ComponentTemplateVars {
  /// Derives both variables from the validated UpperCamelCase [className].
  const ComponentTemplateVars({required this.className, required this.snake});

  /// The widget class name, e.g. `LegendBadge`.
  final String className;

  /// The snake_case source basename (no extension), e.g. `legend_badge`.
  final String snake;
}

/// Renders the annotated-component scaffold (unformatted — the caller runs
/// the formatter): a `@LegendThemeable` StatelessWidget with example
/// `@Style` fields (one `.resolve` tear-off per field), the `part`
/// directive for its generated theme, and a `build` that resolves with one
/// generated `_theme(context)` call — the default wiring form, with
/// comments pointing at the R13 alternatives (State `theme` getter /
/// `_\$XThemeState` mixin for stateful widgets, the opt-in `_\$XBase`
/// two-argument build). Mirrors the structure of the kit's own components
/// (see `legend_ui/lib/src/components/card/legend_card.dart`).
String renderComponentTemplate(ComponentTemplateVars vars) =>
    '''
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

part '${vars.snake}.theme.g.dart';

/// A themed [${vars.className}] — scaffolded by `legend_gen create`. Replace the
/// example `@Style` fields with the component's real theme surface and
/// rerun `legend_gen themes` (and `legend_gen docs`).
@LegendThemeable()
class ${vars.className} extends StatelessWidget {
  const ${vars.className}({
    required this.child,
    super.key,
    this.background,
    this.padding,
  });

  final Widget child;

  /// Fill behind [child].
  @Style<Color>.resolve(_background, lerp: true)
  final Color? background;
  static Color _background(LegendTokens t) => t.colors.surface;

  /// Inner padding around [child].
  @Style<EdgeInsetsGeometry>.resolve(_padding)
  final EdgeInsetsGeometry? padding;
  static EdgeInsetsGeometry _padding(LegendTokens t) =>
      EdgeInsets.all(t.sizes.md);

  @override
  Widget build(BuildContext context) {
    // The generated hook (RFC-002 R13): one call resolves all four theme
    // levels and registers the per-field rebuild aspects (R12).
    //
    // Alternatives, all emitted into ${vars.snake}.theme.g.dart:
    //  - stateful: read `theme` directly in the State's build — the
    //    getter extension is generated when the State class lives in this
    //    file; or mix in `_\$${vars.className}ThemeState` explicitly;
    //  - two-argument build: `extends _\$${vars.className}Base` and write
    //    `Widget build(BuildContext context, ${vars.className}Theme theme)`
    //    (stateless only — the opt-in base form).
    final theme = _theme(context);
    return Container(
      color: theme.background,
      padding: theme.padding,
      child: child,
    );
  }
}
''';
