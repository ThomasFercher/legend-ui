import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(
  Widget child, {
  LegendThemeData data = const LegendThemeData(tokens: LegendTokens.light),
}) {
  return LegendTheme(
    data: data,
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

/// An [ImageProvider] whose load always fails — drives the avatar's
/// image → fallback rung.
class _FailingImage extends ImageProvider<_FailingImage> {
  const _FailingImage();

  @override
  Future<_FailingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<_FailingImage>(this);

  @override
  ImageStreamCompleter loadImage(
    _FailingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(Exception('no image')),
  );
}

LegendSurface _surfaceOf(WidgetTester tester) => tester.widget<LegendSurface>(
  find.descendant(
    of: find.byType(LegendAvatar),
    matching: find.byType(LegendSurface),
  ),
);

void main() {
  group('fallback ladder', () {
    testWidgets('initials render when no image is given', (tester) async {
      await tester.pumpWidget(_wrap(const LegendAvatar(initials: 'TF')));
      expect(find.text('TF'), findsOneWidget);
    });

    testWidgets('placeholder renders when no initials are given', (
      tester,
    ) async {
      const key = Key('placeholder');
      await tester.pumpWidget(
        _wrap(const LegendAvatar(placeholder: SizedBox(key: key))),
      );
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('the generic silhouette renders when nothing is given', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendAvatar()));
      expect(
        find.descendant(
          of: find.byType(LegendAvatar),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('an image outranks initials', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendAvatar(image: _FailingImage(), initials: 'TF')),
      );
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('TF'), findsNothing);
    });

    testWidgets('a failed image load falls back to initials', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendAvatar(image: _FailingImage(), initials: 'TF')),
      );
      // Let the failing load future complete and the errorBuilder swap in.
      await tester.pump();
      expect(find.text('TF'), findsOneWidget);
    });

    testWidgets(
      'a failed image load falls back to the silhouette without initials',
      (tester) async {
        await tester.pumpWidget(
          _wrap(const LegendAvatar(image: _FailingImage())),
        );
        await tester.pump();
        expect(
          find.descendant(
            of: find.byType(LegendAvatar),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('seed colors', () {
    const colors = LegendColors.light;

    test('the same seed always picks the same pair', () {
      final a = LegendAvatar.seedColors('0xAbC123', colors);
      final b = LegendAvatar.seedColors('0xAbC123', colors);
      expect(a.background, b.background);
      expect(a.foreground, b.foreground);
    });

    test('different seeds spread across the palette', () {
      final backgrounds = {
        for (final seed in ['alice', 'bob', 'carol', 'dave', 'erin'])
          LegendAvatar.seedColors(seed, colors).background,
      };
      expect(backgrounds.length, greaterThan(1));
    });

    testWidgets('a seeded avatar fills with its deterministic pair', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendAvatar(seed: 'legend', initials: 'L')),
      );
      final expected = LegendAvatar.seedColors('legend', colors);
      expect(_surfaceOf(tester).color, expected.background);
      final text = tester.widget<Text>(find.text('L'));
      expect(text.style?.color, expected.foreground);
    });

    testWidgets('the seed outranks the themed background', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendAvatar(seed: 'legend'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendAvatar: LegendAvatarThemeNullable(
                background: Color(0xFF123456),
              ),
            },
          ),
        ),
      );
      final expected = LegendAvatar.seedColors('legend', colors);
      expect(_surfaceOf(tester).color, expected.background);
    });
  });

  group('theming', () {
    testWidgets('defaults come from the tokens', (tester) async {
      await tester.pumpWidget(_wrap(const LegendAvatar(initials: 'TF')));
      expect(
        tester.getSize(find.byType(LegendAvatar)),
        const Size.square(32), // LegendSizes.xl
      );
      expect(_surfaceOf(tester).color, LegendColors.light.background2);
    });

    testWidgets('the registry restyles size and border (level 3)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendAvatar(initials: 'TF'),
          data: LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendAvatar: LegendAvatarThemeNullable(
                size: 64,
                border: Border.all(color: const Color(0xFF123456), width: 2),
              ),
            },
          ),
        ),
      );
      expect(tester.getSize(find.byType(LegendAvatar)), const Size.square(64));
      expect(_surfaceOf(tester).border, isNotNull);
    });

    testWidgets('a constructor param outranks the registry (level 1)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendAvatar(initials: 'TF', size: 40),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {LegendAvatar: LegendAvatarThemeNullable(size: 64)},
          ),
        ),
      );
      expect(tester.getSize(find.byType(LegendAvatar)), const Size.square(40));
    });
  });

  group('badge', () {
    testWidgets('sits at the bottom end by default', (tester) async {
      const key = Key('badge');
      await tester.pumpWidget(
        _wrap(
          const LegendAvatar(
            initials: 'TF',
            size: 48,
            badge: SizedBox(key: key, width: 12, height: 12),
          ),
        ),
      );
      final avatar = tester.getRect(find.byType(LegendAvatar));
      final badge = tester.getRect(find.byKey(key));
      expect(badge.bottomRight, avatar.bottomRight);
    });

    testWidgets('honors a custom alignment', (tester) async {
      const key = Key('badge');
      await tester.pumpWidget(
        _wrap(
          const LegendAvatar(
            initials: 'TF',
            size: 48,
            badge: SizedBox(key: key, width: 12, height: 12),
            badgeAlignment: AlignmentDirectional.topStart,
          ),
        ),
      );
      final avatar = tester.getRect(find.byType(LegendAvatar));
      final badge = tester.getRect(find.byKey(key));
      expect(badge.topLeft, avatar.topLeft);
    });
  });

  group('semantics', () {
    testWidgets('announces the semantic label as an image', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LegendAvatar(initials: 'TF', semanticLabel: 'Tom')),
      );
      final node = tester.getSemantics(find.byType(LegendAvatar));
      expect(node.label, 'Tom');
      expect(node.flagsCollection.isImage, isTrue);
      handle.dispose();
    });
  });
}
