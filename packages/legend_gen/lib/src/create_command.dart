import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:legend_gen/src/docs_command.dart';
import 'package:legend_gen/src/exit_codes.dart';
import 'package:legend_gen/src/templates/component_template.dart';
import 'package:legend_gen/src/themes_command.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

/// Runs `legend_gen create <ClassName>`: scaffolds an annotated component
/// stub and immediately generates its `.theme.g.dart` and `.docs.g.dart`,
/// so the stub's `part` directive resolves from the first second
/// (DESIGN.md §5.3 "the kit needs a CLI anyway").
///
/// The stub comes from the compiled-in template module
/// (`templates/component_template.dart` — the documented R11.3 fallback to
/// bundled mason bricks; the decision note lives there).
///
/// [dir] defaults to `lib/src/components/<name>/` where `<name>` is the
/// snake_case class name without its `Legend` prefix (LegendBadge → `badge`).
///
/// Returns a `LegendGenExit` code: [LegendGenExit.usage] for an invalid
/// class name, [LegendGenExit.cantCreate] when the target file already
/// exists, otherwise the theme/docs generation's code.
Future<int> runCreate(String className, {String? dir, Logger? logger}) async {
  final log = logger ?? Logger();
  if (!RegExp(r'^[A-Z][A-Za-z0-9]*$').hasMatch(className)) {
    log.err(
      '"$className" is not an UpperCamelCase class name — rename it '
      '(e.g. LegendBadge).',
    );
    return LegendGenExit.usage;
  }

  final snake = _snakeCase(className);
  final targetDir = dir ?? defaultCreateDir(className);
  final targetPath = p.join(targetDir, '$snake.dart');
  final target = File(targetPath);
  if (target.existsSync()) {
    log.err(
      '$targetPath already exists — refusing to overwrite. '
      'Pick another name or --dir.',
    );
    return LegendGenExit.cantCreate;
  }

  final progress = log.progress('Scaffolding $className');
  target
    ..createSync(recursive: true)
    ..writeAsStringSync(
      DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(
        renderComponentTemplate(
          ComponentTemplateVars(className: className, snake: snake),
        ),
      ),
    );
  progress.complete('created $targetPath');
  final themesCode = await runThemes([targetPath], logger: log);
  if (themesCode != LegendGenExit.success) return themesCode;
  return runDocs([targetPath], logger: log);
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
