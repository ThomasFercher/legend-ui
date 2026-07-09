import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:nomo_gen/src/themes_command.dart';
import 'package:path/path.dart' as p;

/// Runs `nomo_gen create <ClassName>`: scaffolds an annotated component
/// stub and immediately generates its `.theme.g.dart`, so the stub's
/// generated-file import resolves from the first second (DESIGN.md §5.3
/// "the kit needs a CLI anyway").
///
/// The stub mirrors the structure of the kit's own components (see
/// `nomo_ui_kit/lib/src/components/card/nomo_card.dart`): a
/// `@NomoThemeable` StatelessWidget with example `@Themed` fields whose
/// `build` resolves `<X>Theme.of(context, <X>ThemeNullable(...))`.
///
/// [dir] defaults to `lib/src/components/<name>/` where `<name>` is the
/// snake_case class name without its `Nomo` prefix (NomoBadge → `badge`).
///
/// Returns the process exit code: 64 for an invalid class name, 65 when
/// the target file already exists, otherwise the theme generation's code.
Future<int> runCreate(String className, {String? dir}) async {
  if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(className)) {
    stderr.writeln(
      'ERROR: "$className" is not an UpperCamelCase class name '
      '(e.g. NomoBadge).',
    );
    return 64;
  }

  final snake = _snakeCase(className);
  final targetDir =
      dir ?? p.join('lib', 'src', 'components', _componentDirName(className));
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

/// Default component directory name: the class name without its `Nomo`
/// prefix, in snake_case (NomoBadge → `badge`, Chip → `chip`).
String _componentDirName(String className) {
  const prefix = 'Nomo';
  final stripped =
      className.startsWith(prefix) && className.length > prefix.length
      ? className.substring(prefix.length)
      : className;
  return _snakeCase(stripped);
}

/// UpperCamelCase → snake_case, keeping acronyms together
/// (NomoBadge → nomo_badge, NomoUIBox → nomo_ui_box).
String _snakeCase(String input) => input
    .replaceAllMapped(
      RegExp('(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])'),
      (_) => '_',
    )
    .toLowerCase();

String _stub(String className, String snake) =>
    '''
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

import '$snake.theme.g.dart';

/// A themed [$className] — scaffolded by `nomo_gen create`. Replace the
/// example `@Themed` fields with the component's real theme surface and
/// rerun `nomo_gen themes`.
@NomoThemeable()
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
