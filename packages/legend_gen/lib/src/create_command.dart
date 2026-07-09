import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:legend_gen/src/themes_command.dart';
import 'package:path/path.dart' as p;

/// Runs `legend_gen create <ClassName>`: scaffolds an annotated component
/// stub and immediately generates its `.theme.g.dart`, so the stub's
/// generated-file import resolves from the first second (DESIGN.md §5.3
/// "the kit needs a CLI anyway").
///
/// The stub mirrors the structure of the kit's own components (see
/// `legend_ui/lib/src/components/card/legend_card.dart`): a
/// `@LegendThemeable` StatelessWidget with example `@Themed` fields whose
/// `build` resolves `<X>Theme.of(context, <X>ThemeNullable(...))`.
///
/// [dir] defaults to `lib/src/components/<name>/` where `<name>` is the
/// snake_case class name without its `Legend` prefix (LegendBadge → `badge`).
///
/// Returns the process exit code: 64 for an invalid class name, 65 when
/// the target file already exists, otherwise the theme generation's code.
Future<int> runCreate(String className, {String? dir}) async {
  if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(className)) {
    stderr.writeln(
      'ERROR: "$className" is not an UpperCamelCase class name '
      '(e.g. LegendBadge).',
    );
    return 64;
  }

  final snake = _snakeCase(className);
  final targetDir = dir ?? defaultCreateDir(className);
  final targetPath = p.join(targetDir, '$snake.dart');
  final target = File(targetPath);
  if (target.existsSync()) {
    stderr.writeln(
      'ERROR: $targetPath already exists — refusing to overwrite. '
      'Pick another name or --dir.',
    );
    return 65;
  }

  target
    ..createSync(recursive: true)
    ..writeAsStringSync(
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(_stub(className, snake)),
    );
  stdout.writeln('created $targetPath');
  return runThemes([targetPath]);
}

/// The directory `create` targets when `--dir` is omitted:
/// `lib/src/components/<name>/` (LegendBadge → `lib/src/components/badge`).
String defaultCreateDir(String className) =>
    p.join('lib', 'src', 'components', _componentDirName(className));

/// Default component directory name: the class name without its `Legend`
/// prefix, in snake_case (LegendBadge → `badge`, Chip → `chip`).
String _componentDirName(String className) {
  const prefix = 'Legend';
  final stripped =
      className.startsWith(prefix) && className.length > prefix.length
      ? className.substring(prefix.length)
      : className;
  return _snakeCase(stripped);
}

/// UpperCamelCase → snake_case, keeping acronyms together
/// (LegendBadge → legend_badge, LegendUIBox → legend_ui_box).
String _snakeCase(String input) => input
    .replaceAllMapped(
      RegExp('(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
      (_) => '_',
    )
    .toLowerCase();

String _stub(String className, String snake) =>
    '''
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

import '$snake.theme.g.dart';

/// A themed [$className] — scaffolded by `legend_gen create`. Replace the
/// example `@Themed` fields with the component's real theme surface and
/// rerun `legend_gen themes`.
@LegendThemeable()
class $className extends StatelessWidget {
  const $className({
    required this.child,
    super.key,
    this.background,
    this.padding,
  });

  final Widget child;

  @Themed(defaultsTo: 't.colors.surface', lerp: true)
  final Color? background;

  @Themed(defaultsTo: 'EdgeInsets.all(t.sizes.md)')
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = ${className}Theme.of(
      context,
      ${className}ThemeNullable(background: background, padding: padding),
    );
    return Container(
      color: theme.background,
      padding: theme.padding,
      child: child,
    );
  }
}
''';
