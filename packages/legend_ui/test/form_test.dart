import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

Widget _wrap(Widget child) {
  return LegendTheme(
    data: const LegendThemeData(tokens: LegendTokens.light),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  group('LegendValidator', () {
    test('required rejects null, empty and whitespace', () {
      expect(LegendValidator.required(null), isNotNull);
      expect(LegendValidator.required(''), isNotNull);
      expect(LegendValidator.required('   '), isNotNull);
      expect(LegendValidator.required('x'), isNull);
    });

    test('email validates format but passes empty', () {
      expect(LegendValidator.email(null), isNull);
      expect(LegendValidator.email(''), isNull);
      expect(LegendValidator.email('nope'), isNotNull);
      expect(LegendValidator.email('a@b'), isNotNull);
      expect(LegendValidator.email('a b@c.d'), isNotNull);
      expect(LegendValidator.email('a@b.co'), isNull);
    });

    test('minLength / maxLength bound non-empty values', () {
      final min3 = LegendValidator.minLength(3);
      expect(min3(''), isNull); // compose with required instead
      expect(min3('ab'), isNotNull);
      expect(min3('abc'), isNull);

      final max3 = LegendValidator.maxLength(3, message: 'too long');
      expect(max3(null), isNull);
      expect(max3('abc'), isNull);
      expect(max3('abcd'), 'too long');
    });

    test('compose returns first failure, null when all pass', () {
      final v = LegendValidator.compose([
        LegendValidator.required,
        LegendValidator.minLength(3, message: 'short'),
      ]);
      expect(v(null), LegendValidator.required(null));
      expect(v('ab'), 'short');
      expect(v('abc'), isNull);
    });
  });

  group('LegendFormController lifecycle', () {
    testWidgets('fields register on mount and unregister on dispose '
        '(legacy bug regression)', (tester) async {
      final controller = LegendFormController();
      var showSecond = true;
      late StateSetter rebuild;

      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return Column(
                  children: [
                    const LegendTextField(formField: 'first'),
                    if (showSecond)
                      const LegendTextField(
                        formField: 'second',
                        validator: LegendValidator.required,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump(); // flush the deferred validity recompute

      expect(controller.values.keys, containsAll(['first', 'second']));
      // 'second' is required and empty — the live model is invalid.
      expect(controller.isValid.value, isFalse);

      // Dispose the invalid field: it must leave values AND stop pinning
      // the form invalid (legacy: fields never unregistered).
      rebuild(() => showSecond = false);
      await tester.pump();
      await tester.pump();

      expect(controller.values.keys, ['first']);
      expect(controller.isValid.value, isTrue);
    });

    testWidgets('validator-less fields count as always valid '
        '(legacy bug regression)', (tester) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: const Column(
              children: [
                LegendTextField(formField: 'a'),
                LegendTextField(formField: 'b'),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // Legacy pinned the form invalid forever when a field had no
      // validator; here it is valid live and through validate().
      expect(controller.isValid.value, isTrue);
      expect(controller.validate(), isTrue);
    });

    testWidgets('values reflects current field text by name', (tester) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: const LegendTextField(formField: 'name'),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Ada');
      expect(controller.values, {'name': 'Ada'});
    });

    testWidgets('isValid updates live as the user types', (tester) async {
      final controller = LegendFormController();
      final seen = <bool>[];
      controller.isValid.addListener(() => seen.add(controller.isValid.value));

      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: LegendTextField(
              formField: 'email',
              validator: LegendValidator.compose([
                LegendValidator.required,
                LegendValidator.email,
              ]),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.isValid.value, isFalse);

      await tester.enterText(find.byType(EditableText), 'ada@lovelace.dev');
      expect(controller.isValid.value, isTrue);

      await tester.enterText(find.byType(EditableText), 'ada@');
      expect(controller.isValid.value, isFalse);
      expect(seen, [false, true, false]);

      // Live validity never displayed an error — only validate() does.
      expect(find.text('Enter a valid email address.'), findsNothing);
    });

    testWidgets('reset restores initial values and clears errors', (
      tester,
    ) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: Column(
              children: [
                const LegendTextField(
                  formField: 'name',
                  validator: LegendValidator.required,
                ),
                LegendFormField<int>(
                  name: 'count',
                  initialValue: 3,
                  builder: (context, field) => Text('${field.value}'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'x');
      await tester.enterText(find.byType(EditableText), '');
      controller.validate();
      await tester.pump();
      expect(find.text('This field is required.'), findsOneWidget);

      controller.reset();
      await tester.pump();
      expect(find.text('This field is required.'), findsNothing);
      expect(controller.values, {'name': '', 'count': 3});

      // reset() also rearms "errors only after validate": typing again
      // shows no error until the next validate().
      await tester.enterText(find.byType(EditableText), 'y');
      await tester.enterText(find.byType(EditableText), '');
      await tester.pump();
      expect(find.text('This field is required.'), findsNothing);
    });
  });

  group('LegendTextField in a LegendForm', () {
    testWidgets('validate-on-submit, revalidate-on-change error display', (
      tester,
    ) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: LegendTextField(
              formField: 'email',
              validator: LegendValidator.compose([
                LegendValidator.required,
                LegendValidator.email,
              ]),
            ),
          ),
        ),
      );

      // Before the first validate(): typing invalid input shows no error.
      await tester.enterText(find.byType(EditableText), 'not-an-email');
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsNothing);

      // First submit attempt: error appears, validate() reports false.
      expect(controller.validate(), isFalse);
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsOneWidget);

      // After the first validate(), errors track every change.
      await tester.enterText(find.byType(EditableText), 'ada@lovelace.dev');
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsNothing);

      await tester.enterText(find.byType(EditableText), 'broken@');
      await tester.pump();
      expect(find.text('Enter a valid email address.'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'ada@lovelace.dev');
      expect(controller.validate(), isTrue);
    });

    testWidgets('explicit errorText wins over the form error', (tester) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: const LegendTextField(
              formField: 'name',
              errorText: 'Explicit error',
              validator: LegendValidator.required,
            ),
          ),
        ),
      );
      controller.validate();
      await tester.pump();
      expect(find.text('Explicit error'), findsOneWidget);
      expect(find.text('This field is required.'), findsNothing);
    });

    testWidgets('field without formField name is form-inert', (tester) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: const LegendTextField(validator: LegendValidator.required),
          ),
        ),
      );
      await tester.pump();
      expect(controller.values, isEmpty);
      expect(controller.validate(), isTrue);
    });

    testWidgets('works standalone outside any LegendForm', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const LegendTextField(
            formField: 'lonely',
            validator: LegendValidator.required,
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'hi');
      await tester.pump();
      expect(find.text('hi'), findsOneWidget);
    });
  });

  group('LegendFormField<T> consumer symmetry', () {
    testWidgets('consumer input registers, validates, resets and '
        'unregisters like a kit field', (tester) async {
      final controller = LegendFormController();
      var showField = true;
      late StateSetter rebuild;

      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                if (!showField) return const SizedBox.shrink();
                return LegendFormField<bool>(
                  name: 'terms',
                  initialValue: false,
                  validator: (v) =>
                      (v ?? false) ? null : 'Please accept the terms.',
                  builder: (context, field) => Column(
                    children: [
                      LegendSwitch(
                        value: field.value ?? false,
                        onChanged: field.didChange,
                      ),
                      if (field.error != null) Text(field.error!),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Registered with its initial value; live validity sees it fail.
      expect(controller.values, {'terms': false});
      expect(controller.isValid.value, isFalse);

      // Submit → error displays through the consumer's own builder.
      expect(controller.validate(), isFalse);
      await tester.pump();
      expect(find.text('Please accept the terms.'), findsOneWidget);

      // didChange reports the value and revalidates on change.
      await tester.tap(find.byType(LegendSwitch));
      await tester.pumpAndSettle();
      expect(controller.values, {'terms': true});
      expect(controller.isValid.value, isTrue);
      expect(find.text('Please accept the terms.'), findsNothing);

      // reset() returns the consumer field to its initialValue.
      controller.reset();
      await tester.pump();
      expect(controller.values, {'terms': false});

      // Dispose → unregistered, form no longer sees it.
      rebuild(() => showField = false);
      await tester.pump();
      await tester.pump();
      expect(controller.values, isEmpty);
      expect(controller.isValid.value, isTrue);
    });

    testWidgets('validator-less consumer field is always valid', (
      tester,
    ) async {
      final controller = LegendFormController();
      await tester.pumpWidget(
        _wrap(
          LegendForm(
            controller: controller,
            child: LegendFormField<int>(
              name: 'plain',
              initialValue: 1,
              builder: (context, field) => Text('${field.value}'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(controller.isValid.value, isTrue);
      expect(controller.validate(), isTrue);
      expect(controller.values, {'plain': 1});
    });
  });
}
