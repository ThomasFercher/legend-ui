import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class OverlaysSection extends StatefulWidget {
  const OverlaysSection({super.key});

  @override
  State<OverlaysSection> createState() => _OverlaysSectionState();
}

class _OverlaysSectionState extends State<OverlaysSection> {
  String _lastResult = '—';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        DemoGroup(
          title: 'Dialog',
          children: [
            LegendText('Last result: $_lastResult'),
            PrimaryLegendButton(
              text: 'Open dialog',
              onPressed: () async {
                final result = await showLegendDialog<String>(
                  context: context,
                  builder: (context) => LegendDialog(
                    title: 'Delete file?',
                    content: const LegendText(
                      'This action cannot be undone.',
                      variant: LegendTextVariant.b2,
                    ),
                    actions: [
                      LegendTextButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.pop(context, 'cancelled'),
                      ),
                      PrimaryLegendButton(
                        text: 'Delete',
                        onPressed: () => Navigator.pop(context, 'deleted'),
                      ),
                    ],
                  ),
                );
                if (result != null) setState(() => _lastResult = result);
              },
            ),
          ],
        ),
        DemoGroup(
          title: 'Sheet (edge-aligned modal)',
          children: [
            SecondaryLegendButton(
              text: 'Open bottom sheet',
              onPressed: () => showLegendModal<void>(
                context: context,
                alignment: Alignment.bottomCenter,
                builder: (context) => LegendDialog(
                  title: 'Bottom sheet',
                  maxWidth: double.infinity,
                  content: const LegendText(
                    'The same modal engine, aligned to an edge — it slides '
                    'instead of scaling.',
                    variant: LegendTextVariant.b2,
                  ),
                  actions: [
                    PrimaryLegendButton(
                      text: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        DemoGroup(
          title: 'Cards',
          children: [
            LegendCard(
              onTap: () {},
              child: const LegendText('A tappable card on LegendSurface.'),
            ),
          ],
        ),
      ],
    );
  }
}
