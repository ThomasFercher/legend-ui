import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class ShellPage extends StatelessWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final breakpoints = LegendBreakpoints.of(context);
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
      ],
    );
  }
}
