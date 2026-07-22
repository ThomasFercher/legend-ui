import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child, {Map<Type, Object> components = const {}}) {
  return LegendTheme(
    data: LegendThemeData(tokens: LegendTokens.light, components: components),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        // Backspace-to-delete needs the standard editing shortcuts that
        // WidgetsApp would otherwise install.
        child: DefaultTextEditingShortcuts(child: Center(child: child)),
      ),
    ),
  );
}

Finder _editable() => find.byType(EditableText);

String _text(WidgetTester tester) =>
    tester.widget<EditableText>(_editable()).controller.text;

List<LegendSurface> _cells(WidgetTester tester) =>
    tester.widgetList<LegendSurface>(find.byType(LegendSurface)).toList();

Color? _cellBorderColor(LegendSurface cell) =>
    (cell.border! as Border).top.color;

void main() {
  group('LegendPinField — typing and deleting', () {
    testWidgets('renders length cells; typing fills them left to right', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendPinField(length: 4)));
      expect(_cells(tester), hasLength(4));

      await tester.enterText(_editable(), '12');
      await tester.pump();
      expect(_text(tester), '12');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('input is filtered to digits by default', (tester) async {
      await tester.pumpWidget(_wrap(const LegendPinField()));
      await tester.enterText(_editable(), 'ab-!');
      expect(_text(tester), '');
      await tester.enterText(_editable(), '1a2b');
      expect(_text(tester), '12');
    });

    testWidgets('inputFormatters overrides the digit filter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          LegendPinField(
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[a-z0-9]')),
            ],
          ),
        ),
      );
      await tester.enterText(_editable(), 'a1b2');
      expect(_text(tester), 'a1b2');
    });

    testWidgets('never accepts more than length characters', (tester) async {
      await tester.pumpWidget(_wrap(const LegendPinField(length: 4)));
      await tester.enterText(_editable(), '123456');
      expect(_text(tester), '1234');
    });

    testWidgets('backspace clears backwards', (tester) async {
      await tester.pumpWidget(_wrap(const LegendPinField()));
      await tester.enterText(_editable(), '123');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(_text(tester), '12');
      expect(find.text('3'), findsNothing);
    });

    testWidgets('shrinking length drops the characters past the new cells', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendPinField()));
      await tester.enterText(_editable(), '123456');
      await tester.pumpWidget(_wrap(const LegendPinField(length: 4)));
      expect(_text(tester), '1234');
      expect(_cells(tester), hasLength(4));
    });
  });

  group('LegendPinField — completion', () {
    testWidgets('onCompleted fires with the full code, and only then', (
      tester,
    ) async {
      final changes = <String>[];
      final completions = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendPinField(
            length: 4,
            onChanged: changes.add,
            onCompleted: completions.add,
          ),
        ),
      );
      await tester.enterText(_editable(), '123');
      expect(changes, ['123']);
      expect(completions, isEmpty);

      await tester.enterText(_editable(), '1234');
      expect(completions, ['1234']);
    });

    testWidgets('pasting a full code fills all cells and completes', (
      tester,
    ) async {
      final completions = <String>[];
      await tester.pumpWidget(
        _wrap(LegendPinField(onCompleted: completions.add)),
      );
      // A paste arrives as one editing delta with the whole code.
      await tester.enterText(_editable(), '987654');
      await tester.pump();
      expect(completions, ['987654']);
      for (final char in '987654'.split('')) {
        expect(find.text(char), findsOneWidget);
      }
    });
  });

  group('LegendPinField — obscure mode', () {
    testWidgets('obscure renders dots instead of the characters', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendPinField(obscure: true)));
      await tester.enterText(_editable(), '12');
      await tester.pump();
      // The hidden core carries the real text; nothing readable is painted.
      expect(_text(tester), '12');
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });
  });

  group('LegendPinField — disabled', () {
    testWidgets('disabled: core is read-only and taps do not focus', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(
        _wrap(LegendPinField(enabled: false, focusNode: focusNode)),
      );
      expect(tester.widget<EditableText>(_editable()).readOnly, isTrue);

      await tester.tap(find.byType(LegendPinField));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);
    });
  });

  group('LegendPinField — focus and active cell', () {
    testWidgets('tapping the cells focuses the single hidden field', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(_wrap(LegendPinField(focusNode: focusNode)));
      await tester.tap(find.byType(LegendPinField));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
    });

    testWidgets('the cell the next character lands in is highlighted', (
      tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(_wrap(LegendPinField(focusNode: focusNode)));
      final primary = LegendTokens.light.colors.primary;
      final idle = LegendTokens.light.colors.background3;

      // Unfocused: no highlight anywhere.
      expect(_cells(tester).map(_cellBorderColor), everyElement(idle));

      focusNode.requestFocus();
      // The focus change applies in a microtask; the highlight lands on
      // the following frame.
      await tester.pump();
      await tester.pump();
      expect(_cellBorderColor(_cells(tester)[0]), primary);

      await tester.enterText(_editable(), '12');
      await tester.pump();
      final borders = _cells(tester).map(_cellBorderColor).toList();
      expect(borders[2], primary);
      expect(borders.where((c) => c == primary), hasLength(1));

      // A full code keeps the last cell active.
      await tester.enterText(_editable(), '123456');
      await tester.pump();
      expect(_cellBorderColor(_cells(tester)[5]), primary);
    });
  });

  group('LegendPinField — error state', () {
    testWidgets('errorText shows inline below and recolors every border', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const LegendPinField(errorText: 'Wrong code')),
      );
      expect(find.text('Wrong code'), findsOneWidget);
      final error = LegendTokens.light.colors.error;
      expect(_cells(tester).map(_cellBorderColor), everyElement(error));

      await tester.pumpWidget(_wrap(const LegendPinField()));
      expect(find.text('Wrong code'), findsNothing);
    });
  });

  group('LegendPinField — semantics', () {
    testWidgets('one text-field node counts the entered digits; no per-cell '
        'nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const LegendPinField()));
      expect(
        find.bySemanticsLabel('PIN, 0 of 6 digits entered'),
        findsOneWidget,
      );

      await tester.enterText(_editable(), '123');
      await tester.pump();
      expect(
        find.bySemanticsLabel('PIN, 3 of 6 digits entered'),
        findsOneWidget,
      );
      // The painted cells are excluded from semantics.
      expect(find.bySemanticsLabel('1'), findsNothing);

      // The state (and its '123') survives the rebuild — the label tracks
      // the new name and length around the kept text.
      await tester.pumpWidget(
        _wrap(const LegendPinField(length: 8, semanticLabel: 'Code')),
      );
      expect(
        find.bySemanticsLabel('Code, 3 of 8 digits entered'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('LegendPinField — theming ladder', () {
    testWidgets('registry override restyles the cells; a constructor param '
        'wins', (tester) async {
      const navy = Color(0xFF001F54);
      await tester.pumpWidget(
        _wrap(
          const LegendPinField(),
          components: {
            LegendPinField: const LegendPinFieldThemeNullable(
              cellBackground: navy,
            ),
          },
        ),
      );
      expect(_cells(tester).map((c) => c.color), everyElement(navy));

      const crimson = Color(0xFFDC143C);
      await tester.pumpWidget(
        _wrap(
          const LegendPinField(cellBackground: crimson),
          components: {
            LegendPinField: const LegendPinFieldThemeNullable(
              cellBackground: navy,
            ),
          },
        ),
      );
      expect(_cells(tester).map((c) => c.color), everyElement(crimson));
    });

    testWidgets('subtree override sits between registry and constructor', (
      tester,
    ) async {
      const navy = Color(0xFF001F54);
      const teal = Color(0xFF008080);
      await tester.pumpWidget(
        _wrap(
          const LegendPinFieldThemeOverride(
            data: LegendPinFieldThemeNullable(cellBackground: teal),
            child: LegendPinField(),
          ),
          components: {
            LegendPinField: const LegendPinFieldThemeNullable(
              cellBackground: navy,
            ),
          },
        ),
      );
      expect(_cells(tester).map((c) => c.color), everyElement(teal));
    });

    testWidgets('token-derived defaults size the cells and spacing', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(const LegendPinField(length: 2)));
      final sizes = LegendTokens.light.sizes;
      // The surface adds its border around the cellSize content box.
      final cellBox = tester.getSize(find.byType(LegendSurface).first);
      expect(cellBox.width, sizes.xl + sizes.sm + 2 * sizes.borderWidth);
      expect(cellBox.height, sizes.xxl + 2 * sizes.borderWidth);

      final first = tester.getTopRight(find.byType(LegendSurface).first);
      final second = tester.getTopLeft(find.byType(LegendSurface).last);
      expect(second.dx - first.dx, sizes.sm);
    });
  });
}
