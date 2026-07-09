import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:nomo_ui_kit/nomo_ui_kit.dart';

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
            NomoText('Last result: $_lastResult'),
            PrimaryNomoButton(
              text: 'Open dialog',
              onPressed: () async {
                final result = await showNomoDialog<String>(
                  context: context,
                  builder: (context) => NomoDialog(
                    title: 'Delete file?',
                    content: const NomoText(
                      'This action cannot be undone.',
                      variant: NomoTextVariant.b2,
                    ),
                    actions: [
                      NomoTextButton(
                        text: 'Cancel',
                        onPressed: () => Navigator.pop(context, 'cancelled'),
                      ),
                      PrimaryNomoButton(
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
            SecondaryNomoButton(
              text: 'Open bottom sheet',
              onPressed: () => showNomoModal<void>(
                context: context,
                alignment: Alignment.bottomCenter,
                builder: (context) => NomoDialog(
                  title: 'Bottom sheet',
                  maxWidth: double.infinity,
                  content: const NomoText(
                    'The same modal engine, aligned to an edge — it slides '
                    'instead of scaling.',
                    variant: NomoTextVariant.b2,
                  ),
                  actions: [
                    PrimaryNomoButton(
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
            NomoCard(
              onTap: () {},
              child: const NomoText('A tappable card on NomoSurface.'),
            ),
          ],
        ),
      ],
    );
  }
}
