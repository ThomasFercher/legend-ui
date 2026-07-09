import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// A color editor built from kit pieces: preset swatches plus a hex field.
/// Passing null to [onChanged] means "back to the theme default".
class ColorField extends StatefulWidget {
  const ColorField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
    this.swatches = defaultSwatches,
  });

  final String label;

  /// The current override, or null when the theme default applies.
  final Color? value;
  final ValueChanged<Color?> onChanged;
  final List<Color> swatches;

  static const defaultSwatches = [
    Color(0xFF2563EB),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDC2626),
    Color(0xFF8B5CF6),
    Color(0xFF0D9488),
  ];

  @override
  State<ColorField> createState() => _ColorFieldState();
}

class _ColorFieldState extends State<ColorField> {
  late final _hex = TextEditingController(text: _format(widget.value));

  static String _format(Color? color) => color == null
      ? ''
      : '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static Color? _parse(String input) {
    final cleaned = input.replaceFirst('#', '').trim();
    if (cleaned.length != 6) return null;
    final value = int.tryParse(cleaned, radix: 16);
    return value == null ? null : Color(0xFF000000 | value);
  }

  @override
  void didUpdateWidget(ColorField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) _hex.text = _format(widget.value);
  }

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        LegendText(widget.label, variant: LegendTextVariant.b3),
        Wrap(
          spacing: tokens.sizes.xs,
          runSpacing: tokens.sizes.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final swatch in widget.swatches)
              LegendInteractive(
                semanticLabel: '${widget.label} ${_format(swatch)}',
                onTap: () => widget.onChanged(swatch),
                builder: (context, states) => LegendSurface(
                  color: swatch,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: widget.value == swatch || states.hovered
                        ? tokens.colors.foreground1
                        : tokens.colors.background3,
                    width: widget.value == swatch ? 2 : 1,
                  ),
                  child: const SizedBox.square(dimension: 22),
                ),
              ),
            SizedBox(
              width: 110,
              child: LegendTextField(
                controller: _hex,
                placeholder: '#RRGGBB',
                onChanged: (text) {
                  final parsed = _parse(text);
                  if (parsed != null) widget.onChanged(parsed);
                },
              ),
            ),
            if (widget.value != null)
              LegendTextButton(
                text: 'Reset',
                onPressed: () => widget.onChanged(null),
              ),
          ],
        ),
      ],
    );
  }
}
