import 'dart:async';

import 'package:legend_gen/src/generate_runner.dart';
import 'package:legend_gen/src/tokens_emitter.dart';
import 'package:legend_gen/src/tokens_parser.dart';

/// Runs `legend_gen tokens` (RFC-002 R5): scans [paths] for
/// `@LegendTokenData` classes and writes `<source>.tokens.g.dart` — a
/// `part` of the token library carrying the mechanical members only
/// (`copyWith` + value `==`/`hashCode` as a `_$ClassName` mixin, plus the
/// private member-wise lerp the class's `static lerp` redirects to) —
/// next to each source file. Strictly one-file-in/one-file-out, like
/// `themes`.
///
/// Deliberately separate from `themes` (RFC-002 R10 scope): token classes
/// are the base theme and never get Override widgets, registry entries,
/// or `of()` resolvers.
///
/// With [check], nothing is written; stale or missing output makes the run
/// fail — the CI freshness gate.
///
/// Returns the process exit code.
Future<int> runTokens(List<String> paths, {bool check = false}) {
  return runGeneration(
    paths,
    suffix: '.tokens.g.dart',
    label: 'token',
    command: 'tokens',
    parse: parseTokenClasses,
    emit: emitTokensFile,
    check: check,
  );
}
