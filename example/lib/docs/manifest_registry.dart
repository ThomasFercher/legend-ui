// The kit's docs manifests are generated libraries living next to each
// widget's source (RFC-002 R9, one-file-in/one-file-out) — importable, but
// deliberately not barrel-exported: the aggregation below IS the consumer
// side of the open registry, mirroring how apps register their own
// generated component themes.
// ignore_for_file: implementation_imports

import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';
import 'package:legend_ui/src/components/accordion/legend_accordion.docs.g.dart';
import 'package:legend_ui/src/components/address/legend_address.docs.g.dart';
import 'package:legend_ui/src/components/avatar/legend_avatar.docs.g.dart';
import 'package:legend_ui/src/components/badge/legend_badge.docs.g.dart';
import 'package:legend_ui/src/components/banner/legend_banner.docs.g.dart';
import 'package:legend_ui/src/components/body/legend_body.docs.g.dart';
import 'package:legend_ui/src/components/breadcrumb/legend_breadcrumb.docs.g.dart';
import 'package:legend_ui/src/components/buttons/legend_text_button.docs.g.dart';
import 'package:legend_ui/src/components/buttons/primary_legend_button.docs.g.dart';
import 'package:legend_ui/src/components/buttons/secondary_legend_button.docs.g.dart';
import 'package:legend_ui/src/components/card/legend_card.docs.g.dart';
import 'package:legend_ui/src/components/checkbox/legend_checkbox.docs.g.dart';
import 'package:legend_ui/src/components/chip/legend_chip.docs.g.dart';
import 'package:legend_ui/src/components/code_block/legend_code_block.docs.g.dart';
import 'package:legend_ui/src/components/combobox/legend_combobox.docs.g.dart';
import 'package:legend_ui/src/components/context_menu/legend_context_menu.docs.g.dart';
import 'package:legend_ui/src/components/copy_button/legend_copy_button.docs.g.dart';
import 'package:legend_ui/src/components/dialog/legend_dialog.docs.g.dart';
import 'package:legend_ui/src/components/divider/legend_divider.docs.g.dart';
import 'package:legend_ui/src/components/drawer/legend_drawer.docs.g.dart';
import 'package:legend_ui/src/components/dropdown/legend_dropdown.docs.g.dart';
import 'package:legend_ui/src/components/empty/legend_empty.docs.g.dart';
import 'package:legend_ui/src/components/expandable/legend_expandable.docs.g.dart';
import 'package:legend_ui/src/components/info_item/legend_info_item.docs.g.dart';
import 'package:legend_ui/src/components/input/legend_number_field.docs.g.dart';
import 'package:legend_ui/src/components/input/legend_pin_field.docs.g.dart';
import 'package:legend_ui/src/components/input/legend_text_field.docs.g.dart';
import 'package:legend_ui/src/components/list/legend_list.docs.g.dart';
import 'package:legend_ui/src/components/list/legend_list_item.docs.g.dart';
import 'package:legend_ui/src/components/loading/legend_loading.docs.g.dart';
import 'package:legend_ui/src/components/loading/legend_shimmer.docs.g.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown.docs.g.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_editor.docs.g.dart';
import 'package:legend_ui/src/components/menu/legend_menu.docs.g.dart';
import 'package:legend_ui/src/components/pagination/legend_pagination.docs.g.dart';
import 'package:legend_ui/src/components/popover/legend_popover.docs.g.dart';
import 'package:legend_ui/src/components/progress/legend_progress.docs.g.dart';
import 'package:legend_ui/src/components/radio/legend_radio.docs.g.dart';
import 'package:legend_ui/src/components/segmented/legend_segmented.docs.g.dart';
import 'package:legend_ui/src/components/slider/legend_slider.docs.g.dart';
import 'package:legend_ui/src/components/split_pane/legend_split_pane.docs.g.dart';
import 'package:legend_ui/src/components/stat/legend_stat.docs.g.dart';
import 'package:legend_ui/src/components/steps/legend_steps.docs.g.dart';
import 'package:legend_ui/src/components/switch/legend_switch.docs.g.dart';
import 'package:legend_ui/src/components/tabs/legend_tabs.docs.g.dart';
import 'package:legend_ui/src/components/timeline/legend_timeline.docs.g.dart';
import 'package:legend_ui/src/components/toast/legend_toast.docs.g.dart';
import 'package:legend_ui/src/components/tooltip/legend_tooltip.docs.g.dart';
import 'package:legend_ui/src/primitives/legend_button_core.docs.g.dart';
import 'package:legend_ui/src/shell/legend_app_bar.docs.g.dart';
import 'package:legend_ui/src/shell/legend_bottom_bar.docs.g.dart';
import 'package:legend_ui/src/shell/legend_scaffold.docs.g.dart';
import 'package:legend_ui/src/shell/legend_sider.docs.g.dart';
import 'package:legend_ui/src/shell/legend_vertical_menu.docs.g.dart';

/// One themable component as the theme explorer sees it: the widget [type]
/// (the level-3 registry key, RFC-002 R3), its generated docs manifest
/// [entries], the stable tear-off of its generated `XThemeNullable`
/// constructor, and a live [preview].
///
/// The manifest is the single source of truth (RFC-002 R9): the
/// configurator renders whatever [entries] contains and writes overrides
/// through [overrideConstructor] by parameter *name* — so a new `@Style`
/// field shows up here on regeneration with zero playground changes.
class PlaygroundComponent {
  const PlaygroundComponent({
    required this.type,
    required this.entries,
    required this.overrideConstructor,
    required this.preview,
    this.note,
  });

  /// The widget type — both the picker identity and the components-map key.
  final Type type;

  /// The generated `*.docs.g.dart` manifest: every themed variable with
  /// its dot-path name, doc text, declared type, and default expression.
  final List<LegendDocEntry> entries;

  /// Tear-off of the generated `XThemeNullable` unnamed constructor.
  /// All its parameters are named and nullable, so a sparse override is
  /// `Function.apply(overrideConstructor, [], {#member: value})` — the
  /// tear-off never changes when fields are added, which is what makes a
  /// new manifest entry editable with no playground code.
  final Function overrideConstructor;

  /// Live instance for the explorer's preview slot (triggers for overlay
  /// components; shell pieces may point at the real site chrome).
  final WidgetBuilder preview;

  /// Extra context shown with the preview (e.g. "the site chrome is the
  /// real instance").
  final String? note;

  /// Display name, e.g. `PrimaryLegendButton`. Generic widgets stringify
  /// with their instantiated-to-bounds argument (`LegendDropdown<dynamic>`)
  /// — strip it, the manifest owner and the theme class are unparameterized.
  String get name => type.toString().split('<').first;
}

void _noop() {}

/// Constructors for `@Style`-class value types that manifest dot-path
/// members belong to (e.g. `background.hovered` inside an
/// [InteractiveColors]). Keyed by the base entry's declared type with the
/// trailing `?` stripped. One line per style class — new *members* of a
/// registered class need nothing; an unregistered class renders read-only
/// instead of crashing.
final Map<String, Function> styleClassConstructors = {
  'InteractiveColors': InteractiveColors.new,
};

/// A live [LegendMarkdownEditor] for the explorer preview slot — stateful
/// so the controller has an owner to dispose it.
class _EditorPreview extends StatefulWidget {
  const _EditorPreview();

  @override
  State<_EditorPreview> createState() => _EditorPreviewState();
}

class _EditorPreviewState extends State<_EditorPreview> {
  final _controller = LegendMarkdownEditingController(
    text: '# Heading\n\nSome **bold** source with `code`.',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LegendMarkdownEditor(controller: _controller, minLines: 3);
  }
}

/// widgetType → manifest + override constructor + preview, for every
/// `@LegendThemeable` widget the kit ships. The completeness test in
/// `example/test/manifest_registry_test.dart` fails loudly when a shipped
/// manifest is missing here.
final List<PlaygroundComponent> playgroundComponents = [
  PlaygroundComponent(
    type: LegendAccordion,
    entries: legendAccordionDocEntries,
    overrideConstructor: LegendAccordionThemeNullable.new,
    preview: (_) => SizedBox(
      width: 300,
      child: LegendAccordion(
        items: const [
          LegendAccordionItem(
            title: 'First section',
            child: LegendText('Opening a section closes the others.'),
          ),
          LegendAccordionItem(
            title: 'Second section',
            child: LegendText('Only one of us is open at a time.'),
          ),
        ],
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendAddress,
    entries: legendAddressDocEntries,
    overrideConstructor: LegendAddressThemeNullable.new,
    preview: (_) =>
        const LegendAddress('0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063'),
  ),
  PlaygroundComponent(
    type: LegendAppBar,
    entries: legendAppBarDocEntries,
    overrideConstructor: LegendAppBarThemeNullable.new,
    note:
        'The bar at the top of this site is the real instance — edits '
        'restyle it live. Below is a second, embedded one.',
    preview: (_) => const LegendAppBar(title: 'Embedded app bar'),
  ),
  PlaygroundComponent(
    type: LegendAvatar,
    entries: legendAvatarDocEntries,
    overrideConstructor: LegendAvatarThemeNullable.new,
    preview: (_) => const Wrap(
      spacing: 8,
      children: [
        LegendAvatar(initials: 'TF'),
        LegendAvatar(seed: 'alice', initials: 'AL'),
        LegendAvatar(),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendBadge,
    entries: legendBadgeDocEntries,
    overrideConstructor: LegendBadgeThemeNullable.new,
    preview: (_) => const Wrap(
      spacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [LegendBadge('Mainnet'), LegendBadge.count(120)],
    ),
  ),
  PlaygroundComponent(
    type: LegendBanner,
    entries: legendBannerDocEntries,
    overrideConstructor: LegendBannerThemeNullable.new,
    preview: (_) => const LegendBanner(
      title: 'Banner',
      message: 'An inline notice strip, per severity.',
    ),
  ),
  PlaygroundComponent(
    type: LegendBody,
    entries: legendBodyDocEntries,
    overrideConstructor: LegendBodyThemeNullable.new,
    preview: (context) {
      final tokens = LegendTheme.of(context).tokens;
      return LegendSurface(
        color: tokens.colors.background1,
        borderRadius: tokens.sizes.borderRadiusMd,
        child: const SizedBox(
          height: 140,
          child: LegendBody(
            children: [
              LegendText('Body', variant: LegendTextVariant.h3),
              LegendText('The centered reading column of every page.'),
            ],
          ),
        ),
      );
    },
  ),
  PlaygroundComponent(
    type: LegendBottomBar,
    entries: legendBottomBarDocEntries,
    overrideConstructor: LegendBottomBarThemeNullable.new,
    preview: (_) => LegendBottomBar(
      items: const [
        LegendNavItem(label: 'Home', icon: Icons.home_outlined),
        LegendNavItem(label: 'Search', icon: Icons.search),
      ],
      selectedIndex: 0,
      onSelected: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendBreadcrumb,
    entries: legendBreadcrumbDocEntries,
    overrideConstructor: LegendBreadcrumbThemeNullable.new,
    preview: (_) => LegendBreadcrumb(
      items: const [
        LegendBreadcrumbItem(label: 'Portfolio', onTap: _noop),
        LegendBreadcrumbItem(label: 'Accounts', onTap: _noop),
        LegendBreadcrumbItem(label: 'Overview'),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendButtonCore,
    entries: legendButtonCoreDocEntries,
    overrideConstructor: LegendButtonCoreThemeNullable.new,
    note:
        'The shared button chassis (RFC-002 R7.2): padding and radius set '
        'here restyle every variant that does not set its own.',
    preview: (context) {
      final tokens = LegendTheme.of(context).tokens;
      return LegendButtonCore(
        onPressed: _noop,
        background: InteractiveColors(normal: tokens.colors.background2),
        foreground: InteractiveColors(normal: tokens.colors.foreground1),
        textStyle: tokens.typography.b2,
        text: 'Custom variant on the core',
      );
    },
  ),
  PlaygroundComponent(
    type: LegendCard,
    entries: legendCardDocEntries,
    overrideConstructor: LegendCardThemeNullable.new,
    preview: (_) => const LegendCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegendText('Card', variant: LegendTextVariant.h3),
          LegendText('Surface, radius, padding and shadow are themed.'),
        ],
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendCheckbox,
    entries: legendCheckboxDocEntries,
    overrideConstructor: LegendCheckboxThemeNullable.new,
    preview: (_) =>
        LegendCheckbox(value: true, label: 'Checked', onChanged: (_) {}),
  ),
  PlaygroundComponent(
    type: LegendChip,
    entries: legendChipDocEntries,
    overrideConstructor: LegendChipThemeNullable.new,
    preview: (_) => Wrap(
      spacing: 8,
      children: [
        LegendChip(label: 'Selected', selected: true, onSelected: (_) {}),
        const LegendChip(label: 'Idle', onTap: _noop),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendCodeBlock,
    entries: legendCodeBlockDocEntries,
    overrideConstructor: LegendCodeBlockThemeNullable.new,
    preview: (_) => const LegendCodeBlock(
      'final theme = _theme(context);',
      language: 'dart',
    ),
  ),
  PlaygroundComponent(
    type: LegendCombobox,
    entries: legendComboboxDocEntries,
    overrideConstructor: LegendComboboxThemeNullable.new,
    preview: (_) => LegendCombobox<String>(
      items: const [
        LegendComboboxItem(value: 'eth', label: 'Ethereum'),
        LegendComboboxItem(value: 'btc', label: 'Bitcoin'),
      ],
      placeholder: 'Type to filter',
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendContextMenu,
    entries: legendContextMenuDocEntries,
    overrideConstructor: LegendContextMenuThemeNullable.new,
    note: 'Right-click (or long-press) the outlined area to open the menu.',
    preview: (context) {
      final tokens = LegendTheme.of(context).tokens;
      return LegendContextMenu(
        entries: const [
          LegendContextMenuEntry(label: 'Copy', onSelected: _noop),
          LegendContextMenuEntry(label: 'Paste', onSelected: _noop),
        ],
        child: LegendSurface(
          border: Border.all(color: tokens.colors.background3),
          borderRadius: tokens.sizes.borderRadiusSm,
          padding: EdgeInsets.all(tokens.sizes.md),
          child: const LegendText('Context menu target'),
        ),
      );
    },
  ),
  PlaygroundComponent(
    type: LegendCopyButton,
    entries: legendCopyButtonDocEntries,
    overrideConstructor: LegendCopyButtonThemeNullable.new,
    preview: (_) => const Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        LegendText('Copy a sample value', variant: LegendTextVariant.b2),
        LegendCopyButton(
          value: 'legend-ui',
          semanticLabel: 'Copy the sample value',
        ),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendDialog,
    entries: legendDialogDocEntries,
    overrideConstructor: LegendDialogThemeNullable.new,
    preview: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        LegendDialog(
          title: 'Inline dialog preview',
          content: const LegendText('Surface, radius and padding are themed.'),
          actions: [LegendTextButton(text: 'OK', onPressed: _noop)],
        ),
        SecondaryLegendButton(
          text: 'Open dialog',
          onPressed: () => showLegendDialog<void>(
            context: context,
            builder: (dialogContext) => LegendDialog(
              title: 'Live dialog',
              content: const LegendText('Opened through the real route.'),
              actions: [
                LegendTextButton(
                  text: 'Close',
                  onPressed: () => Navigator.pop(dialogContext),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendDivider,
    entries: legendDividerDocEntries,
    overrideConstructor: LegendDividerThemeNullable.new,
    preview: (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LegendText('Above the divider'),
        LegendDivider(),
        LegendText('Below the divider'),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendDrawer,
    entries: legendDrawerDocEntries,
    overrideConstructor: LegendDrawerThemeNullable.new,
    preview: (context) => SecondaryLegendButton(
      text: 'Open side drawer',
      onPressed: () => LegendDrawer.show<void>(
        context,
        builder: (context) => const LegendText('A live edge drawer.'),
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendDropdown,
    entries: legendDropdownDocEntries,
    overrideConstructor: LegendDropdownThemeNullable.new,
    preview: (_) => LegendDropdown<int>(
      placeholder: 'Dropdown',
      items: const [
        LegendDropdownItem(value: 1, label: 'Option one'),
        LegendDropdownItem(value: 2, label: 'Option two'),
      ],
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendEmpty,
    entries: legendEmptyDocEntries,
    overrideConstructor: LegendEmptyThemeNullable.new,
    preview: (_) => const LegendEmpty(
      title: 'Nothing here yet',
      description: 'The zero-state panel.',
      icon: Icon(Icons.inbox_outlined),
    ),
  ),
  PlaygroundComponent(
    type: LegendExpandable,
    entries: legendExpandableDocEntries,
    overrideConstructor: LegendExpandableThemeNullable.new,
    preview: (_) => LegendExpandable(
      title: 'Expandable',
      child: const LegendText('Revealed content follows the theme.'),
    ),
  ),
  PlaygroundComponent(
    type: LegendInfoItem,
    entries: legendInfoItemDocEntries,
    overrideConstructor: LegendInfoItemThemeNullable.new,
    preview: (_) => const Column(
      children: [
        LegendInfoItem(label: 'Version', value: '1.0.0'),
        LegendInfoItem(label: 'Network', value: 'Mainnet'),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendList,
    entries: legendListDocEntries,
    overrideConstructor: LegendListThemeNullable.new,
    preview: (_) => const SizedBox(
      width: 300,
      child: LegendList(
        header: 'Tokens',
        children: [
          LegendListItem(title: 'Ethereum', subtitle: 'ETH', onTap: _noop),
          LegendListItem(title: 'Bitcoin', subtitle: 'BTC', onTap: _noop),
        ],
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendListItem,
    entries: legendListItemDocEntries,
    overrideConstructor: LegendListItemThemeNullable.new,
    preview: (_) => const SizedBox(
      width: 300,
      child: LegendListItem(
        title: 'Selected row',
        subtitle: 'The selected fill is themed',
        selected: true,
        onTap: _noop,
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendLoading,
    entries: legendLoadingDocEntries,
    overrideConstructor: LegendLoadingThemeNullable.new,
    preview: (_) => const LegendLoading(),
  ),
  PlaygroundComponent(
    type: LegendMarkdown,
    entries: legendMarkdownDocEntries,
    overrideConstructor: LegendMarkdownThemeNullable.new,
    preview: (_) => LegendMarkdown(
      'A **markdown** document with `code` and '
      '[a link](https://legend.app).',
      onTapLink: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendMarkdownEditor,
    entries: legendMarkdownEditorDocEntries,
    overrideConstructor: LegendMarkdownEditorThemeNullable.new,
    preview: (_) => const SizedBox(width: 360, child: _EditorPreview()),
  ),
  PlaygroundComponent(
    type: LegendMenu,
    entries: legendMenuDocEntries,
    overrideConstructor: LegendMenuThemeNullable.new,
    preview: (_) => const LegendMenu(
      semanticLabel: 'Open the preview menu',
      trigger: LegendCard(child: LegendText('Tap for an action menu')),
      items: [
        LegendMenuItem(label: 'Rename', onSelected: _noop),
        LegendMenuDivider(),
        LegendMenuItem(label: 'Delete', destructive: true, onSelected: _noop),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendNumberField,
    entries: legendNumberFieldDocEntries,
    overrideConstructor: LegendNumberFieldThemeNullable.new,
    preview: (_) => LegendNumberField(
      title: 'Amount',
      value: 2.5,
      min: 0,
      max: 100,
      step: 0.5,
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendPagination,
    entries: legendPaginationDocEntries,
    overrideConstructor: LegendPaginationThemeNullable.new,
    preview: (_) => LegendPagination(page: 3, pageCount: 9, onChanged: (_) {}),
  ),
  PlaygroundComponent(
    type: LegendPinField,
    entries: legendPinFieldDocEntries,
    overrideConstructor: LegendPinFieldThemeNullable.new,
    preview: (_) => LegendPinField(length: 4, onCompleted: (_) {}),
  ),
  PlaygroundComponent(
    type: LegendPopover,
    entries: legendPopoverDocEntries,
    overrideConstructor: LegendPopoverThemeNullable.new,
    preview: (_) => LegendPopover(
      semanticLabel: 'Open the preview popover',
      overlay: (context) => const SizedBox(
        width: 200,
        child: LegendText('An anchored floating panel.'),
      ),
      child: const LegendCard(child: LegendText('Tap for a popover')),
    ),
  ),
  PlaygroundComponent(
    type: LegendProgress,
    entries: legendProgressDocEntries,
    overrideConstructor: LegendProgressThemeNullable.new,
    preview: (_) =>
        const LegendProgress.bar(value: 0.6, semanticLabel: 'Progress'),
  ),
  PlaygroundComponent(
    type: LegendRadio,
    entries: legendRadioDocEntries,
    overrideConstructor: LegendRadioThemeNullable.new,
    preview: (_) => LegendRadio<String>(
      value: 'selected',
      groupValue: 'selected',
      label: 'Selected radio',
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendScaffold,
    entries: legendScaffoldDocEntries,
    overrideConstructor: LegendScaffoldThemeNullable.new,
    note:
        'The page around you IS the live LegendScaffold — background '
        'edits restyle the whole site directly.',
    preview: (_) => const LegendText(
      'No embedded instance: the site chrome is the preview.',
    ),
  ),
  PlaygroundComponent(
    type: LegendSegmented,
    entries: legendSegmentedDocEntries,
    overrideConstructor: LegendSegmentedThemeNullable.new,
    preview: (_) => LegendSegmented<String>(
      segments: const [
        LegendSegment(value: 'a', label: '1H'),
        LegendSegment(value: 'b', label: '1D'),
        LegendSegment(value: 'c', label: '1W'),
      ],
      value: 'b',
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendShimmer,
    entries: legendShimmerDocEntries,
    overrideConstructor: LegendShimmerThemeNullable.new,
    preview: (_) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        LegendShimmer.box(width: 180, height: 14),
        LegendShimmer.box(width: 120, height: 14),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendSider,
    entries: legendSiderDocEntries,
    overrideConstructor: LegendSiderThemeNullable.new,
    note:
        'The navigation rail of this site is the real instance — edits '
        'restyle it live. Below is a second, embedded one.',
    preview: (_) => SizedBox(
      height: 180,
      child: LegendSider(
        items: const [
          LegendNavItem(label: 'One', icon: Icons.looks_one_outlined),
          LegendNavItem(label: 'Two', icon: Icons.looks_two_outlined),
        ],
        selectedIndex: 0,
        onSelected: (_) {},
      ),
    ),
  ),
  PlaygroundComponent(
    type: LegendSlider,
    entries: legendSliderDocEntries,
    overrideConstructor: LegendSliderThemeNullable.new,
    preview: (_) => LegendSlider(
      value: 0.6,
      semanticLabel: 'Preview slider',
      onChanged: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendSplitPane,
    entries: legendSplitPaneDocEntries,
    overrideConstructor: LegendSplitPaneThemeNullable.new,
    preview: (context) {
      final tokens = LegendTheme.of(context).tokens;
      Widget pane(String label) => LegendSurface(
        color: tokens.colors.background1,
        borderRadius: tokens.sizes.borderRadiusMd,
        padding: EdgeInsets.all(tokens.sizes.sm),
        child: LegendText(label, variant: LegendTextVariant.b3),
      );
      return SizedBox(
        height: 100,
        child: LegendSplitPane(
          semanticLabel: 'Preview split pane',
          minFirst: 64,
          minSecond: 64,
          first: pane('First pane'),
          second: pane('Second pane'),
        ),
      );
    },
  ),
  PlaygroundComponent(
    type: LegendStat,
    entries: legendStatDocEntries,
    overrideConstructor: LegendStatThemeNullable.new,
    preview: (_) => const LegendStat(
      label: 'Balance',
      value: r'$12,480.30',
      delta: '4.2%',
      deltaDirection: LegendStatDirection.up,
      caption: 'vs last week',
    ),
  ),
  PlaygroundComponent(
    type: LegendSteps,
    entries: legendStepsDocEntries,
    overrideConstructor: LegendStepsThemeNullable.new,
    preview: (_) => LegendSteps(
      currentIndex: 1,
      steps: const [
        LegendStep(title: 'Create'),
        LegendStep(title: 'Verify'),
        LegendStep(title: 'Done'),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendSwitch,
    entries: legendSwitchDocEntries,
    overrideConstructor: LegendSwitchThemeNullable.new,
    preview: (_) => Row(
      spacing: 12,
      children: [
        LegendSwitch(
          value: true,
          semanticLabel: 'Preview on',
          onChanged: (_) {},
        ),
        LegendSwitch(
          value: false,
          semanticLabel: 'Preview off',
          onChanged: (_) {},
        ),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendTabs,
    entries: legendTabsDocEntries,
    overrideConstructor: LegendTabsThemeNullable.new,
    preview: (_) => LegendTabs(
      items: const [
        LegendNavItem(label: 'Tokens'),
        LegendNavItem(label: 'NFTs'),
      ],
      selectedIndex: 0,
      onSelected: (_) {},
    ),
  ),
  PlaygroundComponent(
    type: LegendTextButton,
    entries: legendTextButtonDocEntries,
    overrideConstructor: LegendTextButtonThemeNullable.new,
    preview: (_) => LegendTextButton(text: 'Text button', onPressed: _noop),
  ),
  PlaygroundComponent(
    type: LegendTextField,
    entries: legendTextFieldDocEntries,
    overrideConstructor: LegendTextFieldThemeNullable.new,
    preview: (_) =>
        const LegendTextField(title: 'Text field', placeholder: 'Type here'),
  ),
  PlaygroundComponent(
    type: LegendTimeline,
    entries: legendTimelineDocEntries,
    overrideConstructor: LegendTimelineThemeNullable.new,
    preview: (_) => LegendTimeline(
      entries: const [
        LegendTimelineEntry(title: 'Sent 0.4 ETH', timestamp: '2 min ago'),
        LegendTimelineEntry(title: 'Wallet created', timestamp: 'Jul 12'),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendToast,
    entries: legendToastDocEntries,
    overrideConstructor: LegendToastThemeNullable.new,
    preview: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        const LegendToast(message: 'Inline toast preview'),
        SecondaryLegendButton(
          text: 'Show toast',
          onPressed: () => showLegendToast(context, 'Themed live toast'),
        ),
      ],
    ),
  ),
  PlaygroundComponent(
    type: LegendTooltip,
    entries: legendTooltipDocEntries,
    overrideConstructor: LegendTooltipThemeNullable.new,
    preview: (_) => const LegendTooltip(
      message: 'A themed hint panel.',
      child: LegendCard(child: LegendText('Hover for a tooltip')),
    ),
  ),
  PlaygroundComponent(
    type: LegendVerticalMenu,
    entries: legendVerticalMenuDocEntries,
    overrideConstructor: LegendVerticalMenuThemeNullable.new,
    preview: (_) => SizedBox(
      width: 260,
      child: LegendVerticalMenu(
        items: _verticalMenuItems,
        selected: _verticalMenuItems.first,
        onSelected: (_) {},
      ),
    ),
  ),
  PlaygroundComponent(
    type: PrimaryLegendButton,
    entries: primaryLegendButtonDocEntries,
    overrideConstructor: PrimaryLegendButtonThemeNullable.new,
    preview: (_) => PrimaryLegendButton(text: 'Primary', onPressed: _noop),
  ),
  PlaygroundComponent(
    type: SecondaryLegendButton,
    entries: secondaryLegendButtonDocEntries,
    overrideConstructor: SecondaryLegendButtonThemeNullable.new,
    preview: (_) => SecondaryLegendButton(text: 'Secondary', onPressed: _noop),
  ),
];

const _verticalMenuItems = [
  LegendNavItem(label: 'Dashboard'),
  LegendNavItem(label: 'Wallet'),
  LegendNavItem(label: 'Settings'),
];

/// [playgroundComponents] keyed by widget type.
final Map<Type, PlaygroundComponent> playgroundComponentByType = {
  for (final component in playgroundComponents) component.type: component,
};

/// Whether [entry] is the container entry of a dot-path group (e.g. the
/// `background` line when `background.hovered` entries exist) — the group
/// renders as a header plus per-member editors, never as its own editor.
bool isStyleGroupBase(List<LegendDocEntry> entries, LegendDocEntry entry) =>
    !entry.name.contains('.') &&
    entries.any((e) => e.name.startsWith('${entry.name}.'));

/// Compiles per-member override values (keyed by manifest dot-path name)
/// into the component's sparse generated `XThemeNullable` — or null when
/// nothing is set.
///
/// Plain names become named constructor arguments directly; dot-path
/// members are grouped and built through [styleClassConstructors]. Both
/// applications go by *name* (`Symbol`), so the compilation needs no
/// per-field code — this is the R9 zero-playground-change path.
Object? compileOverride(
  PlaygroundComponent component,
  Map<String, Object?> members,
) {
  final named = <Symbol, Object?>{};
  final grouped = <String, Map<Symbol, Object?>>{};
  for (final member in members.entries) {
    final value = member.value;
    if (value == null) continue;
    final dot = member.key.indexOf('.');
    if (dot == -1) {
      named[Symbol(member.key)] = value;
    } else {
      grouped.putIfAbsent(
        member.key.substring(0, dot),
        () => <Symbol, Object?>{},
      )[Symbol(member.key.substring(dot + 1))] = value;
    }
  }
  for (final group in grouped.entries) {
    final constructor =
        styleClassConstructors[_styleClassOf(component, group.key)];
    // Unregistered style class: skip gracefully (its editors are
    // read-only anyway).
    if (constructor == null) continue;
    named[Symbol(group.key)] =
        Function.apply(constructor, const [], group.value) as Object;
  }
  if (named.isEmpty) return null;
  return Function.apply(component.overrideConstructor, const [], named)
      as Object;
}

/// The declared style-class type of dot-path group [baseName], `?`
/// stripped — e.g. `InteractiveColors` for `background`.
String? _styleClassOf(PlaygroundComponent component, String baseName) {
  for (final entry in component.entries) {
    if (entry.name == baseName) {
      final type = entry.type;
      return type.endsWith('?') ? type.substring(0, type.length - 1) : type;
    }
  }
  return null;
}

/// Renders [value] as copy-pasteable Dart source for the emitted-code
/// block.
String dartLiteral(Object? value) => switch (value) {
  null => 'null',
  final Color color =>
    'Color(0x${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()})',
  final double number =>
    number == number.roundToDouble() ? '${number.round()}' : '$number',
  final Duration duration =>
    'Duration(milliseconds: ${duration.inMilliseconds})',
  final EdgeInsets insets =>
    'EdgeInsets.symmetric(horizontal: ${dartLiteral(insets.left)}, '
        'vertical: ${dartLiteral(insets.top)})',
  final BorderRadius radius =>
    'BorderRadius.circular(${dartLiteral(radius.topLeft.x)})',
  final TextStyle style =>
    'TextStyle(fontSize: ${dartLiteral(style.fontSize)}, '
        'fontWeight: ${style.fontWeight ?? FontWeight.w400})',
  final String text => "'$text'",
  _ => value.toString(),
};

/// Renders one component's set members as the Dart source of its sparse
/// override, e.g.
/// `PrimaryLegendButtonThemeNullable(background: InteractiveColors(…))`.
String overrideSource(
  PlaygroundComponent component,
  Map<String, Object?> members,
) {
  final args = <String>[];
  final grouped = <String, List<String>>{};
  for (final member in members.entries) {
    final value = member.value;
    if (value == null) continue;
    final dot = member.key.indexOf('.');
    if (dot == -1) {
      args.add('${member.key}: ${dartLiteral(value)}');
    } else {
      grouped
          .putIfAbsent(member.key.substring(0, dot), () => [])
          .add('${member.key.substring(dot + 1)}: ${dartLiteral(value)}');
    }
  }
  for (final group in grouped.entries) {
    final styleClass =
        _styleClassOf(component, group.key) ?? 'InteractiveColors';
    args.add('${group.key}: $styleClass(${group.value.join(', ')})');
  }
  return '${component.name}ThemeNullable(\n'
      '  ${args.join(',\n  ')},\n'
      ')';
}
