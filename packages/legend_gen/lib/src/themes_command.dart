import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/generate_runner.dart';
import 'package:legend_gen/src/model.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:mason_logger/mason_logger.dart';

/// Runs `legend_gen themes` in two passes over [paths]:
///
/// 1. **styles** — `@Style()` value classes (RFC-002 R6 amendment 7) get
///    `<source>.style.g.dart` (member-wise merge/lerp, value `==`), and
/// 2. **themes** — `@LegendThemeable` widgets get `<source>.theme.g.dart`,
///
/// both emitted as a `part` of the declaring library (RFC-002 R1), next to
/// each source file, strictly one-file-in/one-file-out.
///
/// Widget fields typed with a style value class get member-wise treatment;
/// the class is *detected* through the run's style-class index — built
/// from [indexPaths] (defaults to [paths]; watch mode passes the full
/// configured path set so single-file regeneration still sees every style
/// class) plus the kit's compiled-in [builtinStyleClasses].
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns a `LegendGenExit` process exit code (see `runGeneration`); the
/// worse pass wins.
Future<int> runThemes(
  List<String> paths, {
  bool check = false,
  Logger? logger,
  List<String>? indexPaths,
}) async {
  final index = buildStyleClassIndex(indexPaths ?? paths, logger: logger);
  final styles = await runGeneration(
    paths,
    suffix: '.style.g.dart',
    label: 'style',
    command: 'themes',
    parse: parseStyleClasses,
    emit: (classes) => emitStyleFile(classes, styleClasses: index),
    check: check,
    logger: logger,
  );
  final themes = await runGeneration(
    paths,
    suffix: '.theme.g.dart',
    label: 'theme',
    command: 'themes',
    parse: (path, content) =>
        parseThemableWidgets(path, content, styleClasses: index),
    emit: emitThemeFile,
    check: check,
    logger: logger,
  );
  return worseExit(styles, themes);
}
