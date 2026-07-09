import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class LayoutPage extends StatelessWidget {
  const LayoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Layout',
      intro:
          'Structural pieces: cards, dividers, expandables, and info rows — '
          'all thin compositions over LegendSurface and LegendInteractive.',
      children: [
        DocSection(
          title: 'Card',
          description: 'Give it onTap and it becomes interactive.',
          demo: Column(
            spacing: tokens.sizes.sm,
            children: [
              const LegendCard(
                child: LegendText('A plain card on LegendSurface.'),
              ),
              LegendCard(
                onTap: () {},
                child: const LegendText('A tappable card — hover me.'),
              ),
            ],
          ),
          code: '''
LegendCard(
  onTap: open,
  child: const LegendText('A tappable card'),
)''',
        ),
        const DocSection(
          title: 'Divider',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LegendText('Above'),
              LegendDivider(),
              LegendText('Below'),
              SizedBox(
                height: 40,
                child: Row(
                  children: [
                    LegendText('Left'),
                    LegendDivider(axis: Axis.vertical),
                    LegendText('Right'),
                  ],
                ),
              ),
            ],
          ),
          code: 'const LegendDivider()  //  or axis: Axis.vertical',
        ),
        DocSection(
          title: 'Expandable',
          description:
              'Uncontrolled by default; pass expanded/onToggle to control '
              'it yourself.',
          demo: LegendExpandable(
            title: 'What is Legend UI?',
            child: const LegendText(
              'A Material-free component kit where design tokens are the '
              'only global theme and every component theme is generated '
              'from decorators on the widget.',
              variant: LegendTextVariant.b2,
            ),
          ),
          code: '''
LegendExpandable(
  title: 'What is Legend UI?',
  child: LegendText('A Material-free component kit ...'),
)''',
        ),
        const DocSection(
          title: 'Info item',
          description: 'Label/value rows for detail screens.',
          demo: Column(
            children: [
              LegendInfoItem(label: 'Network', value: 'Ethereum'),
              LegendInfoItem(label: 'Fee', value: '0.0021 ETH'),
              LegendInfoItem(label: 'Status', value: 'Confirmed'),
            ],
          ),
          code: "LegendInfoItem(label: 'Fee', value: '0.0021 ETH')",
        ),
      ],
    );
  }
}
