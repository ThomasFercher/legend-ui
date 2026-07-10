import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(data: const MediaQueryData(), child: child),
);

void main() {
  group('LegendFieldCore — the editing primitive', () {
    testWidgets('wraps EditableText and edits the caller-owned controller', (
      tester,
    ) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      final changes = <String>[];
      await tester.pumpWidget(
        _wrap(
          LegendFieldCore(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 14),
            cursorColor: const Color(0xFF2563EB),
            backgroundCursorColor: const Color(0xFF888888),
            onChanged: changes.add,
          ),
        ),
      );

      expect(find.byType(EditableText), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'hello');
      expect(controller.text, 'hello');
      expect(changes.last, 'hello');
    });

    testWidgets('carries the resolved style and cursor colors through to '
        'EditableText (no chrome, no theme reads)', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        _wrap(
          LegendFieldCore(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(fontSize: 21),
            cursorColor: const Color(0xFF112233),
            backgroundCursorColor: const Color(0xFF445566),
            selectionColor: const Color(0x33112233),
            readOnly: true,
          ),
        ),
      );

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, 21);
      expect(editable.cursorColor, const Color(0xFF112233));
      expect(editable.backgroundCursorColor, const Color(0xFF445566));
      expect(editable.selectionColor, const Color(0x33112233));
      expect(editable.readOnly, isTrue);
    });
  });
}
