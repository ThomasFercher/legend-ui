import 'package:example/theme/color_field.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// Type-appropriate editor for one manifest entry (RFC-002 R9): the
/// explorer dispatches on the entry's *declared type string*, so every
/// variable the generator ever emits gets an editor (or a safe read-only
/// row) with no per-variable code.
///
/// Supported: `Color` (swatch row + hex), `double` (stepper), `Duration`
/// (preset dropdown), `EdgeInsetsGeometry` (numeric fields), `BorderRadius`
/// (numeric field), `TextStyle` (size + weight). Anything else renders
/// read-only with its default — never a crash.
class EntryEditor extends StatelessWidget {
  const EntryEditor({
    required this.entry,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The manifest entry being edited.
  final LegendDocEntry entry;

  /// The current override value, or null when the theme default applies.
  final Object? value;

  /// Writes the override; null means "back to the theme default".
  final ValueChanged<Object?> onChanged;

  /// The declared type with the trailing `?` stripped.
  String get baseType => entry.type.endsWith('?')
      ? entry.type.substring(0, entry.type.length - 1)
      : entry.type;

  @override
  Widget build(BuildContext context) {
    return switch (baseType) {
      'Color' => ColorField(
        label: entry.name,
        value: value as Color?,
        onChanged: onChanged,
      ),
      'double' => NumberStepper(
        label: entry.name,
        value: value as double?,
        fallback: double.tryParse(entry.defaultDescription) ?? 8,
        onChanged: onChanged,
      ),
      'Duration' => _DurationEditor(
        label: entry.name,
        value: value as Duration?,
        onChanged: onChanged,
      ),
      'EdgeInsetsGeometry' || 'EdgeInsets' => _EdgeInsetsEditor(
        label: entry.name,
        value: value as EdgeInsets?,
        onChanged: onChanged,
      ),
      'BorderRadius' => NumberStepper(
        label: entry.name,
        value: (value as BorderRadius?)?.topLeft.x,
        fallback: 8,
        onChanged: (radius) =>
            onChanged(radius == null ? null : BorderRadius.circular(radius)),
      ),
      'TextStyle' => _TextStyleEditor(
        label: entry.name,
        value: value as TextStyle?,
        onChanged: onChanged,
      ),
      _ => _ReadOnlyRow(entry: entry),
    };
  }
}

/// A labelled −/+ stepper over a nullable double; null shows the theme
/// default and a Reset appears once a value is set.
class NumberStepper extends StatelessWidget {
  const NumberStepper({
    required this.label,
    required this.value,
    required this.fallback,
    required this.onChanged,
    super.key,
    this.step = 1,
    this.min = 0,
  });

  final String label;
  final double? value;

  /// Starting point for the first −/+ tap when no override is set.
  final double fallback;
  final ValueChanged<double?> onChanged;
  final double step;
  final double min;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final current = value ?? fallback;
    String show(double n) =>
        n == n.roundToDouble() ? '${n.round()}' : n.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        LegendText(label, variant: LegendTextVariant.b3),
        Row(
          spacing: tokens.sizes.xs,
          children: [
            Semantics(
              label: '$label decrease',
              child: SecondaryLegendButton(
                text: '−',
                onPressed: current - step < min
                    ? null
                    : () => onChanged(current - step),
              ),
            ),
            LegendText(
              value == null ? '${show(current)} (default)' : show(current),
              variant: LegendTextVariant.b3,
            ),
            Semantics(
              label: '$label increase',
              child: SecondaryLegendButton(
                text: '+',
                onPressed: () => onChanged(current + step),
              ),
            ),
            if (value != null)
              LegendTextButton(text: 'Reset', onPressed: () => onChanged(null)),
          ],
        ),
      ],
    );
  }
}

/// A preset dropdown over a nullable [Duration].
class _DurationEditor extends StatelessWidget {
  const _DurationEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Duration? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        LegendText(label, variant: LegendTextVariant.b3),
        Row(
          spacing: tokens.sizes.xs,
          children: [
            Expanded(
              child: LegendDropdown<Duration>(
                value: value,
                placeholder: 'Theme default',
                items: const [
                  LegendDropdownItem(
                    value: Duration.zero,
                    label: 'Instant (0 ms)',
                  ),
                  LegendDropdownItem(
                    value: Duration(milliseconds: 150),
                    label: 'Snappy (150 ms)',
                  ),
                  LegendDropdownItem(
                    value: Duration(milliseconds: 500),
                    label: 'Standard (500 ms)',
                  ),
                  LegendDropdownItem(
                    value: Duration(milliseconds: 1200),
                    label: 'Patient (1200 ms)',
                  ),
                ],
                onChanged: onChanged,
              ),
            ),
            if (value != null)
              LegendTextButton(text: 'Reset', onPressed: () => onChanged(null)),
          ],
        ),
      ],
    );
  }
}

/// Numeric horizontal/vertical fields composing `EdgeInsets.symmetric`.
class _EdgeInsetsEditor extends StatelessWidget {
  const _EdgeInsetsEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final EdgeInsets? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final horizontal = value?.left;
    final vertical = value?.top;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        NumberStepper(
          label: '$label.horizontal',
          value: horizontal,
          fallback: 12,
          onChanged: (h) => onChanged(
            h == null && vertical == null
                ? null
                : EdgeInsets.symmetric(
                    horizontal: h ?? horizontal ?? 12,
                    vertical: vertical ?? 8,
                  ),
          ),
        ),
        NumberStepper(
          label: '$label.vertical',
          value: vertical,
          fallback: 8,
          onChanged: (v) => onChanged(
            v == null && horizontal == null
                ? null
                : EdgeInsets.symmetric(
                    horizontal: horizontal ?? 12,
                    vertical: v ?? vertical ?? 8,
                  ),
          ),
        ),
        if (value != null)
          LegendTextButton(text: 'Reset', onPressed: () => onChanged(null)),
      ],
    );
  }
}

/// Font size stepper + weight picker composing a sparse `TextStyle`.
class _TextStyleEditor extends StatelessWidget {
  const _TextStyleEditor({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TextStyle? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final size = value?.fontSize;
    final weight = value?.fontWeight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        NumberStepper(
          label: '$label.fontSize',
          value: size,
          fallback: 14,
          min: 6,
          onChanged: (s) => onChanged(
            s == null && weight == null
                ? null
                : TextStyle(fontSize: s ?? size ?? 14, fontWeight: weight),
          ),
        ),
        LegendText('$label.fontWeight', variant: LegendTextVariant.b3),
        LegendDropdown<FontWeight>(
          value: weight,
          placeholder: 'Theme default',
          items: const [
            LegendDropdownItem(value: FontWeight.w400, label: 'Regular (400)'),
            LegendDropdownItem(value: FontWeight.w500, label: 'Medium (500)'),
            LegendDropdownItem(value: FontWeight.w600, label: 'Semibold (600)'),
            LegendDropdownItem(value: FontWeight.w700, label: 'Bold (700)'),
          ],
          onChanged: (w) =>
              onChanged(TextStyle(fontSize: size ?? 14, fontWeight: w)),
        ),
        if (value != null)
          LegendTextButton(text: 'Reset', onPressed: () => onChanged(null)),
      ],
    );
  }
}

/// Fallback for types without an editor: name, type and default stay
/// visible and documented; the value resolves through the theme untouched.
class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({required this.entry});

  final LegendDocEntry entry;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendText(
      '${entry.name}: no editor for ${entry.type} yet — resolves to '
      '${entry.defaultDescription}.',
      variant: LegendTextVariant.b3,
      color: tokens.colors.foreground3,
    );
  }
}
