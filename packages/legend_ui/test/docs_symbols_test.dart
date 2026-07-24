@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the *living* docs against symbol drift.
///
/// The docs are the first thing a contributor — human or agent — reads, and a
/// documented symbol that does not exist is worse than no documentation: it
/// gets reproduced verbatim and fails to compile. Two real instances this
/// pins down:
///
///  * `LegendValidators` (plural) was documented in README/ROADMAP/CHANGELOG;
///    the real class is `LegendValidator`.
///  * `FEATURES.md` §2 showed `@Themed(defaultsTo: 't.colors.surface')` long
///    after RFC-002 R10 replaced it with the typed `@Style<T>` contract.
///
/// Only the docs that describe *current state* are checked. `ROADMAP.md` and
/// `docs/RFC-*.md` are dated historical records — they deliberately contain
/// design-time names, and `docs/DESIGN.md` §0 maps those to what shipped.
void main() {
  /// Symbols the docs mention on purpose that are not (yet) in the source.
  /// Removing something from here should mean it shipped.
  const deliberatelyAbsent = {
    // RFC-004's one unbuilt widget — parked pending a QR-encode dependency.
    'LegendQrCode',
    // Open audit follow-up: widgets-layer SelectableRegion.
    'LegendSelectionArea',
    // Prose globs, not claims: `LegendSliver*`, `showLegend…`.
    'LegendSliver',
    'showLegend',
  };

  /// Docs that must describe the code as it is today.
  const livingDocs = ['README.md', 'CLAUDE.md', 'docs/FEATURES.md'];

  final repoRoot = Directory.current.path.endsWith('packages/legend_ui')
      ? Directory('../..')
      : Directory('.');

  late final Set<String> declared;

  setUpAll(() {
    final symbol = RegExp(r'\b(?:Legend|showLegend)[A-Za-z0-9_]*\b');
    declared = {
      for (final pkg in ['legend_ui', 'legend_gen'])
        ...Directory('${repoRoot.path}/packages/$pkg/lib')
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .expand((f) => symbol.allMatches(f.readAsStringSync()))
            .map((m) => m[0]!),
    };
  });

  test('every Legend* symbol in the source scan resolves', () {
    // Sanity check on the scan itself — if this trips, the glob is wrong and
    // the assertions below would pass vacuously.
    expect(declared, contains('LegendValidator'));
    expect(declared, contains('LegendCard'));
    expect(declared.length, greaterThan(200));
  });

  for (final doc in livingDocs) {
    test('$doc mentions no symbol that does not exist', () {
      final file = File('${repoRoot.path}/$doc');
      expect(file.existsSync(), isTrue, reason: '$doc is missing');

      // Only backticked identifiers — prose like "Legend UI" is not a claim.
      final backticked = RegExp(
        '`((?:Legend|showLegend)[A-Za-z0-9_]*)',
      ).allMatches(file.readAsStringSync());

      final unknown = {
        for (final m in backticked)
          if (!declared.contains(m[1]) && !deliberatelyAbsent.contains(m[1]))
            m[1]!,
      };

      expect(
        unknown,
        isEmpty,
        reason:
            'These symbols are documented in $doc but do not exist in '
            'packages/*/lib. Either the docs are stale, or the symbol was '
            'renamed — fix the doc, or add it to `deliberatelyAbsent` with a '
            'reason if it is intentionally unshipped.',
      );
    });
  }

  test('the retired @Themed annotation is not documented anywhere', () {
    // RFC-002 R10 replaced the string-expression form with typed @Style<T>.
    for (final doc in livingDocs) {
      final text = File('${repoRoot.path}/$doc').readAsStringSync();
      expect(
        text,
        isNot(contains('@Themed')),
        reason:
            '$doc still shows the retired @Themed contract; '
            'the current form is @Style<T>(…) / @Style<T>.resolve(…).',
      );
    }
  });
}
