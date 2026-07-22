import 'package:example/docs/doc_page.dart';
import 'package:example/docs/manifest_props_table.dart';
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
  String? _crumbTarget;
  var _page = 5;

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
          title: 'Breadcrumb',
          description:
              'LegendBreadcrumb is an inline trail of ancestor links on '
              'LegendInteractive, separated by painted LegendCaret '
              'chevrons. Every item but the last navigates; the last is '
              'the current page — muted, inert, announced selected. Long '
              'trails collapse through maxVisible into a middle ellipsis.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendBreadcrumb(
                maxVisible: 4,
                items: [
                  for (final label in ['Home', 'Wallet', 'Tokens', 'Ethereum'])
                    LegendBreadcrumbItem(
                      label: label,
                      onTap: () => setState(() => _crumbTarget = label),
                    ),
                ],
              ),
              LegendText('Navigated to: ${_crumbTarget ?? '—'}'),
            ],
          ),
          code: '''
LegendBreadcrumb(
  maxVisible: 4,
  items: [
    LegendBreadcrumbItem(label: 'Home', onTap: goHome),
    LegendBreadcrumbItem(label: 'Wallet', onTap: goWallet),
    LegendBreadcrumbItem(label: 'Tokens', onTap: goTokens),
    LegendBreadcrumbItem(label: 'Ethereum'),  // current page
  ],
)''',
        ),
        DocSection(
          title: 'Pagination',
          description:
              'LegendPagination pages through a long range — a controlled '
              'component on LegendInteractive + LegendSurface. The range '
              'collapses through the standard window (1 … 4 5 6 … 20), '
              'the chevrons step one page and disable at the ends, and '
              'the current page announces selected semantics.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              LegendPagination(
                page: _page,
                pageCount: 20,
                onChanged: (page) => setState(() => _page = page),
              ),
              LegendText('Page $_page of 20'),
            ],
          ),
          code: '''
LegendPagination(
  page: page,
  pageCount: 20,
  onChanged: (next) => setState(() => page = next),
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
        const ThemeSurfaceSection(component: LegendScaffold),
        const ThemeSurfaceSection(component: LegendAppBar),
        const ThemeSurfaceSection(component: LegendSider),
        const ThemeSurfaceSection(component: LegendBottomBar),
        const ThemeSurfaceSection(component: LegendTabs),
        const ThemeSurfaceSection(component: LegendBreadcrumb),
        const ThemeSurfaceSection(component: LegendPagination),
        const ThemeSurfaceSection(component: LegendVerticalMenu),
      ],
    );
  }
}
