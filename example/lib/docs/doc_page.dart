import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

/// Standard documentation page: title, intro paragraph, sections.
class DocPage extends StatelessWidget {
  const DocPage({
    required this.title,
    required this.intro,
    required this.children,
    super.key,
  });

  final String title;
  final String intro;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.md,
      children: [
        LegendText(title, variant: LegendTextVariant.h2),
        LegendText(intro, variant: LegendTextVariant.b2),
        ...children,
      ],
    );
  }
}

/// A titled documentation section: prose, a live demo, and optionally the
/// code that produces it.
class DocSection extends StatelessWidget {
  const DocSection({
    required this.title,
    super.key,
    this.description,
    this.demo,
    this.code,
  });

  final String title;
  final String? description;
  final Widget? demo;
  final String? code;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: tokens.sizes.md,
        children: [
          LegendText(title, variant: LegendTextVariant.h3),
          if (description != null)
            LegendText(description!, variant: LegendTextVariant.b2),
          ?demo,
          if (code != null) CodeBlock(code!),
        ],
      ),
    );
  }
}

/// A monospace code snippet on a recessed surface.
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendSurface(
      color: tokens.colors.background2,
      borderRadius: tokens.sizes.borderRadiusSm,
      padding: EdgeInsets.all(tokens.sizes.sm),
      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            code.trim(),
            style: tokens.typography.b3.copyWith(
              fontFamily: 'monospace',
              fontFamilyFallback: const ['Menlo', 'Courier'],
              color: tokens.colors.foreground2,
            ),
          ),
        ),
      ),
    );
  }
}

/// One themed property of a component, for [PropsTable].
typedef PropRow = ({String name, String type, String defaultsTo});

/// The component's `@Style` surface: property, type, token default.
/// Every row is overridable at all four resolution levels.
class PropsTable extends StatelessWidget {
  const PropsTable({required this.rows, super.key});

  final List<PropRow> rows;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    final mono = tokens.typography.b3.copyWith(
      fontFamily: 'monospace',
      fontFamilyFallback: const ['Menlo', 'Courier'],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.xs,
      children: [
        const LegendText('Themed properties', variant: LegendTextVariant.b3),
        for (final row in rows)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  row.name,
                  style: mono.copyWith(color: tokens.colors.foreground1),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  row.type,
                  style: mono.copyWith(color: tokens.colors.foreground3),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  row.defaultsTo,
                  style: mono.copyWith(color: tokens.colors.foreground2),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
