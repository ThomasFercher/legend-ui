import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/generate_runner.dart';
import 'package:legend_gen/src/parser.dart';
import 'package:mason_logger/mason_logger.dart';

/// Runs `legend_gen docs` (RFC-002 R9): scans [paths] for
/// `@LegendThemeable` widgets and `@Style()` value classes and writes a
/// `<source>.docs.g.dart` manifest — a `const List<LegendDocEntry>` per
/// declaration: one entry per `@Style` variable (plus a dot-path entry per
/// member of a style-value-class field), and one `group: 'style'` entry
/// per style-class member — with dartdoc text and default source, next to
/// each source file. Strictly one-file-in/one-file-out, like `themes`.
///
/// [indexPaths] feeds the style-class index exactly as in `runThemes`.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate.
///
/// Returns a `LegendGenExit` process exit code (see `runGeneration`).
Future<int> runDocs(
  List<String> paths, {
  bool check = false,
  Logger? logger,
  List<String>? indexPaths,
}) {
  final index = buildStyleClassIndex(indexPaths ?? paths, logger: logger);
  return runGeneration(
    paths,
    suffix: '.docs.g.dart',
    label: 'docs',
    command: 'docs',
    parse: (path, content) =>
        parseDocsDeclarations(path, content, styleClasses: index),
    emit: emitDocsFile,
    check: check,
    logger: logger,
  );
}
