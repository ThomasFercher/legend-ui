import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {LegendThemeData? data}) {
  return LegendTheme(
    data: data ?? const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

TextStyle _textStyle(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!;

void main() {
  const tokens = LegendTokens.light;

  group('LegendEmpty content', () {
    testWidgets('renders title, description, icon and action slots', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendEmpty(
            title: 'No transactions yet',
            description: 'Activity shows up here after your first transfer.',
            icon: Text('?'),
            action: Text('Receive'),
          ),
        ),
      );
      expect(find.text('No transactions yet'), findsOneWidget);
      expect(
        find.text('Activity shows up here after your first transfer.'),
        findsOneWidget,
      );
      expect(find.text('?'), findsOneWidget);
      expect(find.text('Receive'), findsOneWidget);
    });

    testWidgets('title alone renders without the optional slots', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendEmpty(title: 'No sources')));
      expect(find.text('No sources'), findsOneWidget);
      expect(find.byType(IconTheme), findsNothing);
      // Exactly the title — no stray description/action text nodes.
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('is purely presentational — no interaction primitives of '
        'its own', (tester) async {
      await tester.pumpWidget(_wrap(const LegendEmpty(title: 'Empty')));
      expect(find.byType(LegendInteractive), findsNothing);
      expect(find.byType(GestureDetector), findsNothing);
    });
  });

  group('LegendEmpty icon slot', () {
    testWidgets('an Icon inherits the muted color and display size', (
      tester,
    ) async {
      IconThemeData? inherited;
      await tester.pumpWidget(
        _wrap(
          LegendEmpty(
            title: 'Empty',
            icon: Builder(
              builder: (context) {
                inherited = IconTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(inherited!.color, tokens.colors.foreground3);
      // Display-sized: double the large inline icon token.
      expect(inherited!.size, tokens.sizes.iconLg * 2);
    });

    testWidgets('constructor iconColor and iconSize win', (tester) async {
      const navy = Color(0xFF001F54);
      IconThemeData? inherited;
      await tester.pumpWidget(
        _wrap(
          LegendEmpty(
            title: 'Empty',
            iconColor: navy,
            iconSize: 40,
            icon: Builder(
              builder: (context) {
                inherited = IconTheme.of(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(inherited!.color, navy);
      expect(inherited!.size, 40);
    });
  });

  group('LegendEmpty typography defaults', () {
    testWidgets('title is emphasized foreground2, description muted '
        'foreground3', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendEmpty(title: 't', description: 'd')),
      );
      final title = _textStyle(tester, 't');
      expect(title.color, tokens.colors.foreground2);
      expect(title.fontWeight, FontWeight.w600);
      expect(_textStyle(tester, 'd').color, tokens.colors.foreground3);
    });

    testWidgets('texts are centered', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendEmpty(title: 't', description: 'd')),
      );
      expect(tester.widget<Text>(find.text('t')).textAlign, TextAlign.center);
      expect(tester.widget<Text>(find.text('d')).textAlign, TextAlign.center);
    });
  });

  group('LegendEmpty layout', () {
    testWidgets('caps the content column at maxContentWidth', (tester) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 800,
            child: LegendEmpty(title: 'Empty', description: 'x' * 400),
          ),
        ),
      );
      final constrained = tester.widget<ConstrainedBox>(
        find
            .ancestor(
              of: find.byType(Column),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(constrained.constraints.maxWidth, 360);
      expect(tester.getSize(find.byType(Column)).width, 360);
    });

    testWidgets('spacing separates title and description', (tester) async {
      await tester.pumpWidget(
        _wrap(const LegendEmpty(title: 't', description: 'd', spacing: 24)),
      );
      final titleBottom = tester.getBottomLeft(find.text('t')).dy;
      final descriptionTop = tester.getTopLeft(find.text('d')).dy;
      expect(descriptionTop - titleBottom, 24);
    });
  });

  group('LegendEmpty theme resolution', () {
    const navy = Color(0xFF001F54);

    testWidgets('constructor param wins over the annotation default', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendEmpty(
            title: 't',
            titleStyle: TextStyle(color: navy),
          ),
        ),
      );
      expect(_textStyle(tester, 't').color, navy);
    });

    testWidgets('components-map entry (level 3) restyles the block', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const LegendEmpty(title: 't'),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendEmpty: LegendEmptyThemeNullable(
                titleStyle: TextStyle(color: navy),
              ),
            },
          ),
        ),
      );
      expect(_textStyle(tester, 't').color, navy);
    });

    testWidgets('subtree override (level 2) beats the registry', (
      tester,
    ) async {
      const violet = Color(0xFF5B21B6);
      await tester.pumpWidget(
        _wrap(
          const LegendEmptyThemeOverride(
            data: LegendEmptyThemeNullable(
              titleStyle: TextStyle(color: violet),
            ),
            child: LegendEmpty(title: 't'),
          ),
          data: const LegendThemeData(
            tokens: LegendTokens.light,
            components: {
              LegendEmpty: LegendEmptyThemeNullable(
                titleStyle: TextStyle(color: navy),
              ),
            },
          ),
        ),
      );
      expect(_textStyle(tester, 't').color, violet);
    });
  });
}
