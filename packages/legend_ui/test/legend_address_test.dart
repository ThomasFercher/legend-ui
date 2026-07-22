import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

const _dai = '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063';

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('LegendAddress — truncation', () {
    testWidgets('middle-truncates to prefix + separator + suffix', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendAddress(_dai)));
      expect(find.text('0x8f3C…A063'), findsOneWidget);
    });

    testWidgets('prefixChars and suffixChars are honored', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendAddress(_dai, prefixChars: 10, suffixChars: 6)),
      );
      expect(find.text('0x8f3Cf7ad…c6A063'), findsOneWidget);
    });

    testWidgets('an address eliding would not shorten renders whole', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendAddress('0x123456789', copyable: false)),
      );
      // 11 chars = prefix 6 + suffix 4 + a 1-char separator: nothing won.
      expect(find.text('0x123456789'), findsOneWidget);
      // No elision, no tooltip to reveal what is already visible.
      expect(find.byType(LegendTooltip), findsNothing);
    });

    testWidgets('the tooltip carries the full address in the mono style', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendAddress(_dai)));
      final tooltip = tester.widget<LegendTooltip>(find.byType(LegendTooltip));
      expect(tooltip.message, _dai);
      expect(tooltip.textStyle?.fontFamily, 'monospace');
    });

    testWidgets('assistive tech reads the full address, not the ellipsis', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(const LegendAddress(_dai, copyable: false)),
      );
      expect(find.bySemanticsLabel(_dai), findsOneWidget);
      expect(find.bySemanticsLabel('0x8f3C…A063'), findsNothing);
      semantics.dispose();
    });
  });

  group('LegendAddress — copy affordance', () {
    testWidgets('copies the FULL address, never the elided form', (
      tester,
    ) async {
      final written = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            final args = call.arguments as Map<Object?, Object?>;
            written.add(args['text']! as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      var copied = 0;
      await tester.pumpWidget(
        _wrap(LegendAddress(_dai, onCopied: () => copied++)),
      );
      await tester.tap(find.byType(LegendCopyButton));
      await tester.pump();

      expect(written, [_dai]);
      expect(copied, 1);
      await tester.pump(const Duration(milliseconds: 1600));
    });

    testWidgets('copyable: false renders no copy button', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendAddress(_dai, copyable: false)),
      );
      expect(find.byType(LegendCopyButton), findsNothing);
    });
  });

  group('LegendAddress — theming', () {
    testWidgets('renders the mono token style by default', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendAddress(_dai, copyable: false)),
      );
      final text = tester.widget<Text>(find.text('0x8f3C…A063'));
      expect(text.style?.fontFamily, 'monospace');
      expect(text.style?.fontSize, LegendTokens.light.typography.b2.fontSize);
    });

    testWidgets('separator resolves registry → constructor param', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendAddress(_dai),
          components: {
            LegendAddress: const LegendAddressThemeNullable(separator: '⋯'),
          },
        ),
      );
      expect(find.text('0x8f3C⋯A063'), findsOneWidget);

      await tester.pumpWidget(
        _wrap(
          const LegendAddress(_dai, separator: '[..]'),
          components: {
            LegendAddress: const LegendAddressThemeNullable(separator: '⋯'),
          },
        ),
      );
      expect(find.text('0x8f3C[..]A063'), findsOneWidget);
    });

    testWidgets('a textStyle param replaces the mono default whole', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendAddress(
            _dai,
            copyable: false,
            textStyle: TextStyle(color: navy),
          ),
        ),
      );
      final text = tester.widget<Text>(find.text('0x8f3C…A063'));
      expect(text.style?.color, navy);
      // Whole-field resolution (RFC-002): the param is the style, it does
      // not merge with the annotation default's mono family.
      expect(text.style?.fontFamily, isNull);
    });
  });
}
