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
  var _menuAction = '—';
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
          title: 'Drawer',
          description:
              'An edge-anchored sheet on the same modal engine. Side '
              'drawers keep a themed fixed width and resolve start/end '
              'against text direction; the bottom sheet adds a drag '
              'handle and drag-to-dismiss. Scrim tap and Escape dismiss.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            children: [
              PrimaryLegendButton(
                text: 'Start drawer',
                onPressed: () => LegendDrawer.show<void>(
                  context,
                  builder: (context) => const _DrawerBody(
                    title: 'Start drawer',
                    message:
                        'Anchored to the leading edge — the right side '
                        'under RTL.',
                  ),
                ),
              ),
              SecondaryLegendButton(
                text: 'End drawer',
                onPressed: () => LegendDrawer.show<void>(
                  context,
                  edge: LegendDrawerEdge.end,
                  builder: (context) => const _DrawerBody(
                    title: 'End drawer',
                    message: 'Anchored to the trailing edge.',
                  ),
                ),
              ),
              SecondaryLegendButton(
                text: 'Bottom sheet',
                onPressed: () => LegendDrawer.show<void>(
                  context,
                  edge: LegendDrawerEdge.bottom,
                  builder: (context) => const _DrawerBody(
                    title: 'Bottom sheet',
                    message:
                        'Drag the handle (or the sheet) down past a third '
                        'of its height to dismiss; shorter drags spring '
                        'back.',
                  ),
                ),
              ),
            ],
          ),
          code: '''
await LegendDrawer.show<void>(
  context,
  edge: LegendDrawerEdge.bottom,   // start / end / bottom
  builder: (context) => const SheetContent(...),
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
          title: 'Popover',
          description:
              'The reusable anchored-panel foundation (tooltips, action '
              'menus and combobox panels compose it). Tap to toggle; '
              'dismisses on an outside tap or Escape. Placement flips '
              'with text direction.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LegendPopover(
                semanticLabel: 'Popover below',
                offset: Offset(0, tokens.sizes.xs),
                overlay: (context) => const SizedBox(
                  width: 220,
                  child: LegendText(
                    'Anchored below the trigger, on the same overlay '
                    'engine as dropdowns and context menus.',
                    variant: LegendTextVariant.b3,
                  ),
                ),
                child: const LegendCard(child: LegendText('Below')),
              ),
              LegendPopover(
                semanticLabel: 'Popover with arrow',
                placement: LegendPopoverPlacement.top,
                showArrow: true,
                overlay: (context) => const SizedBox(
                  width: 180,
                  child: LegendText(
                    'Placed above, with the anchor arrow.',
                    variant: LegendTextVariant.b3,
                  ),
                ),
                child: const LegendCard(child: LegendText('Above + arrow')),
              ),
              LegendPopover(
                semanticLabel: 'Popover at end',
                placement: LegendPopoverPlacement.end,
                offset: Offset(tokens.sizes.xs, 0),
                overlay: (context) => const SizedBox(
                  width: 160,
                  child: LegendText(
                    'start/end resolve against text direction.',
                    variant: LegendTextVariant.b3,
                  ),
                ),
                child: const LegendCard(child: LegendText('End')),
              ),
            ],
          ),
          code: '''
LegendPopover(
  placement: LegendPopoverPlacement.top,   // top/bottom/start/end
  showArrow: true,                         // wedge pointing at the anchor
  overlay: (context) => const LegendText('Anchored panel'),
  child: const LegendCard(child: LegendText('Tap me')),
)

// Programmatic (what Tooltip/Menu/Combobox build on):
final controller = LegendPopoverController();
LegendPopover(
  controller: controller,
  trigger: LegendPopoverTrigger.manual,
  overlay: (context) => ...,
  child: anchor,
);
controller.show();   // controller.isOpen stays in sync with
controller.hide();   // outside-tap and Escape dismissal''',
        ),
        DocSection(
          title: 'Tooltip',
          description:
              'A manual-trigger popover that owns its own triggering: '
              'hover (after a themed delay), keyboard focus, and '
              'long-press on touch. Surface styling follows the popover '
              'theme; richMessage takes arbitrary content.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            runSpacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              LegendTooltip(
                message: 'A concise hint for the hovering pointer.',
                child: LegendCard(child: LegendText('Hover me')),
              ),
              LegendTooltip(
                placement: LegendPopoverPlacement.bottom,
                semanticLabel: 'Full wallet address',
                richMessage: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LegendText('Full address', variant: LegendTextVariant.h3),
                    LegendText(
                      '0x4bbeEB066eD09B7AEd07bF39EEe0460DFa261520',
                      variant: LegendTextVariant.b3,
                    ),
                  ],
                ),
                child: LegendCard(child: LegendText('0x4bbe…1520')),
              ),
            ],
          ),
          code: '''
const LegendTooltip(
  message: 'A concise hint.',        // announced as the semantic tooltip
  child: IconTrigger(...),
)

LegendTooltip(
  richMessage: AddressPreview(...),  // arbitrary widget content
  semanticLabel: 'Full wallet address',
  placement: LegendPopoverPlacement.bottom,
  child: TruncatedAddress(...),
)''',
        ),
        DocSection(
          title: 'Menu',
          description:
              'A button-anchored action menu on the popover: opens from '
              'its trigger, closes on selection, outside tap, or Escape. '
              'Arrow keys move the highlight, Enter/Space activates, and '
              'Escape returns focus to the trigger. Destructive items '
              'render in the error color.',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              LegendMenu(
                semanticLabel: 'File actions',
                offset: Offset(0, tokens.sizes.xs),
                trigger: const LegendCard(child: LegendText('File actions')),
                items: [
                  LegendMenuItem(
                    label: 'Rename',
                    onSelected: () => setState(() => _menuAction = 'Rename'),
                  ),
                  LegendMenuItem(
                    label: 'Duplicate',
                    onSelected: () => setState(() => _menuAction = 'Duplicate'),
                  ),
                  LegendMenuItem(
                    label: 'Share (soon)',
                    enabled: false,
                    onSelected: () {},
                  ),
                  const LegendMenuDivider(),
                  LegendMenuItem(
                    label: 'Delete',
                    destructive: true,
                    onSelected: () => setState(() => _menuAction = 'Delete'),
                  ),
                ],
              ),
              LegendText('Ran: $_menuAction', variant: LegendTextVariant.b3),
            ],
          ),
          code: '''
LegendMenu(
  trigger: const IconTrigger(...),   // any widget; wrapped as a button
  items: [
    LegendMenuItem(label: 'Rename', onSelected: rename),
    LegendMenuItem(label: 'Share', enabled: false, onSelected: share),
    const LegendMenuDivider(),
    LegendMenuItem(label: 'Delete', destructive: true, onSelected: delete),
  ],
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

/// Shared demo content for the drawer section — a heading, a body line
/// and a close button.
class _DrawerBody extends StatelessWidget {
  const _DrawerBody({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.sizes.md,
      children: [
        LegendText(title, variant: LegendTextVariant.h3),
        LegendText(message, variant: LegendTextVariant.b2),
        PrimaryLegendButton(
          text: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
