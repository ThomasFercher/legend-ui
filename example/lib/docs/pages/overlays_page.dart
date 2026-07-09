import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class OverlaysPage extends StatefulWidget {
  const OverlaysPage({super.key});

  @override
  State<OverlaysPage> createState() => _OverlaysPageState();
}

class _OverlaysPageState extends State<OverlaysPage> {
  String _lastResult = '—';
  var _menuChoice = '—';

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Overlays',
      intro:
          'One overlay engine, two halves: anchored overlays (dropdowns, '
          'context menus) and modal routes (dialogs, sheets, toasts). All '
          'Material-free — centered modals fade and scale, edge-aligned '
          'ones slide from their edge.',
      children: [
        DocSection(
          title: 'Dialog',
          description: 'Returns whatever the page pops with.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
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
              LegendText(
                'Last result: $_lastResult',
                variant: LegendTextVariant.b3,
              ),
            ],
          ),
          code: '''
final result = await showLegendDialog<String>(
  context: context,
  builder: (context) => LegendDialog(
    title: 'Delete file?',
    content: const LegendText('This action cannot be undone.'),
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
);''',
        ),
        DocSection(
          title: 'Sheet — the same engine, edge-aligned',
          demo: SecondaryLegendButton(
            text: 'Open bottom sheet',
            onPressed: () => showLegendModal<void>(
              context: context,
              alignment: Alignment.bottomCenter,
              builder: (context) => LegendDialog(
                title: 'Bottom sheet',
                maxWidth: double.infinity,
                content: const LegendText(
                  'Edge-aligned modals slide instead of scaling.',
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
          code: '''
showLegendModal<void>(
  context: context,
  alignment: Alignment.bottomCenter,   // slides from the bottom
  builder: (context) => ...,
)''',
        ),
        DocSection(
          title: 'Toast',
          description:
              'Queued — rapid calls display one after another instead of '
              'stacking. No ScaffoldMessenger anywhere.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(
                text: 'Show toast',
                onPressed: () => showLegendToast(
                  context,
                  'Saved. This toast dismisses itself.',
                  severity: LegendToastSeverity.success,
                ),
              ),
              SecondaryLegendButton(
                text: 'Toast with action',
                onPressed: () => showLegendToast(
                  context,
                  'File deleted.',
                  action: LegendTextButton(text: 'Undo', onPressed: () {}),
                ),
              ),
            ],
          ),
          code: '''
showLegendToast(
  context,
  'File deleted.',
  severity: LegendToastSeverity.error,
  action: LegendTextButton(text: 'Undo', onPressed: restore),
)''',
        ),
        DocSection(
          title: 'Context menu',
          description: 'Long-press, or right-click on desktop and web.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LegendContextMenu(
                entries: [
                  LegendContextMenuEntry(
                    label: 'Rename',
                    onSelected: () => setState(() => _menuChoice = 'Rename'),
                  ),
                  LegendContextMenuEntry(
                    label: 'Duplicate',
                    onSelected: () => setState(() => _menuChoice = 'Duplicate'),
                  ),
                  LegendContextMenuEntry(
                    label: 'Delete',
                    onSelected: () => setState(() => _menuChoice = 'Delete'),
                  ),
                ],
                child: const LegendCard(
                  child: LegendText('Right-click or long-press me'),
                ),
              ),
              LegendText('Chose: $_menuChoice', variant: LegendTextVariant.b3),
            ],
          ),
          code: '''
LegendContextMenu(
  entries: [
    LegendContextMenuEntry(label: 'Rename', onSelected: rename),
    LegendContextMenuEntry(label: 'Delete', onSelected: delete),
  ],
  child: const FileTile(...),
)''',
        ),
      ],
    );
  }
}
