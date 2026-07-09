import 'dart:async';

import 'package:legend_gen/src/emitter.dart';
import 'package:legend_gen/src/generate_runner.dart';
import 'package:legend_gen/src/parser.dart';

/// Runs `legend_gen docs` (RFC-002 R9): scans [paths] for
/// `@LegendThemeable` widgets and writes a `<source>.docs.g.dart` manifest
/// — a `const List<LegendDocEntry>` per widget, one entry per `@Style`
/// variable (plus one per named state member of a `LegendStates` field)
/// with its dartdoc text and default source — next to each source file.
/// Strictly one-file-in/one-file-out, like `themes`.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate.
///
/// Returns the process exit code.
Future<int> runDocs(List<String> paths, {bool check = false}) {
  return runGeneration(
    paths,
    suffix: '.docs.g.dart',
    label: 'docs',
    command: 'docs',
    parse: parseThemableWidgets,
    emit: emitDocsFile,
    check: check,
  );
}
