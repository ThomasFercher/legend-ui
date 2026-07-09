import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/generate_runner.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:mason_logger/mason_logger.dart';

/// Runs `legend_gen themes`: scans [paths] for `@LegendThemeable` widgets and
/// writes `<source>.theme.g.dart` — a `part` of the widget's library
/// (RFC-002 R1) — next to each source file.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate (DESIGN.md §5.3).
///
/// Returns a `LegendGenExit` process exit code (see `runGeneration`).
Future<int> runThemes(
  List<String> paths, {
  bool check = false,
  Logger? logger,
}) {
  return runGeneration(
    paths,
    suffix: '.theme.g.dart',
    label: 'theme',
    command: 'themes',
    parse: parseThemableWidgets,
    emit: emitThemeFile,
    check: check,
    logger: logger,
  );
}
