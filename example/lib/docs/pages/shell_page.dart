import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  static const _wallet = LegendNavItem(
    label: 'Wallet',
    children: [
      LegendNavItem(label: 'Balances'),
      LegendNavItem(label: 'History'),
    ],
  );
  static const _menuItems = [
    LegendNavItem(label: 'Dashboard'),
    _wallet,
    LegendNavItem(label: 'Settings'),
  ];

  static const _tabItems = [
    LegendNavItem(label: 'Tokens'),
    LegendNavItem(label: 'NFTs'),
    LegendNavItem(label: 'Activity'),
  ];

  LegendNavItem _menuSelected = _menuItems.first;
  var _tabSelected = 0;

  @override
  Widget build(BuildContext context) {
    final breakpoints = LegendBreakpoints.of(context);
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Shell & breakpoints',
      intro:
          'Responsiveness is not theming: chrome flips by breakpoint tier '
          '(LegendBreakpointScope), never by swapping themes. This site '
          'uses the shell you are looking at — resize the window and the '
          'sider gives way below the compact threshold.',
      children: [
        DocSection(
          title: 'Your current tier (live)',
          demo: Column(
            children: [
              LegendInfoItem(label: 'Tier', value: breakpoints.tier.name),
              LegendInfoItem(
                label: 'Window width',
                value: '${breakpoints.width.toStringAsFixed(0)} px',
              ),
              const LegendInfoItem(
                label: 'Defaults',
                value: 'compact < 600 ≤ medium < 1080 ≤ expanded',
              ),
            ],
          ),
          code: '''
final tier = LegendBreakpoints.tierOf(context);
switch (tier) {
  case LegendTier.compact:   ...   // < 600
  case LegendTier.medium:    ...   // 600–1079
  case LegendTier.expanded:  ...   // >= 1080
}''',
        ),
        const DocSection(
          title: 'The scaffold',
          description:
              'LegendScaffold shows the sider at medium and above and the '
              'bottom bar on compact — one LegendNavItem list drives both. '
              'No Material Scaffold underneath.',
          code: '''
LegendScaffold(
  appBar: LegendAppBar(title: 'My app', actions: [...]),
  sider: LegendSider(items: nav, selectedIndex: i, onSelected: go),
  bottomBar: LegendBottomBar(items: nav, selectedIndex: i, onSelected: go),
  body: page,
)''',
        ),
        const DocSection(
          title: 'Custom thresholds',
          description:
              'Override the defaults app-wide through LegendApp, or locally '
              'with a nested LegendBreakpointScope.',
          code: '''
LegendApp(
  compactBelow: 700,
  expandedFrom: 1200,
  ...
)''',
        ),
        DocSection(
          title: 'Tabs',
          description:
              'LegendTabs switches between peer views — a controlled '
              'component on LegendInteractive + LegendSurface, fed by the '
              'same LegendNavItem model as the sider and bottom bar. Arrow '
              'keys rove focus between tabs (Home/End jump, mirrored under '
              'RTL), Enter/Space activates, and each tab announces proper '
              'tab semantics with its selected state.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendTabs(
                items: _tabItems,
                selectedIndex: _tabSelected,
                onSelected: (index) => setState(() => _tabSelected = index),
              ),
              LegendText('Selected: ${_tabItems[_tabSelected].label}'),
            ],
          ),
          code: '''
LegendTabs(
  items: const [
    LegendNavItem(label: 'Tokens'),
    LegendNavItem(label: 'NFTs'),
    LegendNavItem(label: 'Activity'),
  ],
  selectedIndex: selected,
  onSelected: (index) => setState(() => selected = index),
)''',
        ),
        DocSection(
          title: 'Vertical menu',
          description:
              'LegendVerticalMenu is a nesting navigation list on '
              'LegendInteractive + LegendSurface — expandable sections '
              '(items with children), a selected state, all from the shared '
              'LegendNavItem model. Expansion is plain setState + '
              'AnimatedSize; unlike the legacy tile it needs no per-row '
              'AnimationController or post-frame reveal.',
          demo: SizedBox(
            width: 280,
            child: LegendVerticalMenu(
              items: _menuItems,
              selected: _menuSelected,
              initiallyExpanded: const {_wallet},
              onSelected: (item) => setState(() => _menuSelected = item),
            ),
          ),
          code: '''
LegendVerticalMenu(
  items: const [
    LegendNavItem(label: 'Dashboard'),
    LegendNavItem(label: 'Wallet', children: [
      LegendNavItem(label: 'Balances'),
      LegendNavItem(label: 'History'),
    ]),
  ],
  selected: current,
  onSelected: (item) => setState(() => current = item),
)''',
        ),
      ],
    );
  }
}
