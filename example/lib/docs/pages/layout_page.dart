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
        DocSection(
          title: 'Body',
          description:
              'The page scroll pipeline: one always-CustomScrollView core '
              'behind named constructors — LegendBody(children:) for a plain '
              'page, .pinnedFooter for a form whose footer pins to the bottom '
              'when the content is short and flows after it when long, '
              '.slivers for raw slivers (with LegendSliverPinnedHeader / '
              'LegendSliverSection), and .fixed for a non-scrolling fill '
              'page. It owns padding, a centered maxContentWidth reading '
              'column, the safe area, and the keyboard inset — this page '
              'itself is a LegendBody.',
          demo: LegendSurface(
            color: tokens.colors.background1,
            borderRadius: tokens.sizes.borderRadiusMd,
            child: SizedBox(
              height: 220,
              child: LegendBody.pinnedFooter(
                maxContentWidth: 320,
                footer: PrimaryLegendButton(text: 'Submit', onPressed: () {}),
                children: const [
                  LegendText(
                    'Pinned-footer archetype',
                    variant: LegendTextVariant.h3,
                  ),
                  LegendText(
                    'The footer pins to the bottom while the content is '
                    'short, and flows after it once the content scrolls.',
                    variant: LegendTextVariant.b2,
                  ),
                ],
              ),
            ),
          ),
          code: '''
LegendBody.pinnedFooter(
  maxContentWidth: 320,
  footer: PrimaryLegendButton(text: 'Submit', onPressed: submit),
  children: const [
    LegendText('Title', variant: LegendTextVariant.h3),
    LegendText('Body copy ...'),
  ],
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
        const DocSection(
          title: 'List',
          description:
              'LegendListItem is the tappable row every list is made of: '
              'title + optional subtitle between free-form leading/trailing '
              'slots. Pass selected and it announces selected state through '
              'LegendSelectionControl instead of a plain button; LegendList '
              'groups rows under a section header with token spacing or '
              'divider rules. (LegendInfoItem above stays the static '
              'label/value row.)',
          demo: _ListDemo(),
          code: '''
LegendList(
  header: 'Tokens',
  children: [
    for (final token in tokens)
      LegendListItem(
        title: token.name,
        subtitle: token.symbol,
        leading: TokenAvatar(token),
        trailing: LegendText(token.value),
        selected: token == selected,
        onTap: () => select(token),
      ),
  ],
)''',
        ),
      ],
    );
  }
}

/// A self-contained selectable token list for the List section: leading
/// avatar slot, trailing value slot, one selected row owned by this state.
class _ListDemo extends StatefulWidget {
  const _ListDemo();

  @override
  State<_ListDemo> createState() => _ListDemoState();
}

class _ListDemoState extends State<_ListDemo> {
  static const _tokens = [
    ('Ethereum', 'ETH', r'$3,120.55'),
    ('Bitcoin', 'BTC', r'$67,004.10'),
    ('Solana', 'SOL', r'$142.87'),
  ];

  var _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return LegendList(
      header: 'Tokens',
      children: [
        for (final (index, (title, symbol, value)) in _tokens.indexed)
          LegendListItem(
            title: title,
            subtitle: symbol,
            leading: LegendSurface(
              color: tokens.colors.primaryContainer,
              borderRadius: BorderRadius.circular(999),
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: Text(
                    title.substring(0, 1),
                    style: tokens.typography.b3.copyWith(
                      color: tokens.colors.primary,
                    ),
                  ),
                ),
              ),
            ),
            trailing: LegendText(value, variant: LegendTextVariant.b3),
            selected: index == _selected,
            onTap: () => setState(() => _selected = index),
          ),
      ],
    );
  }
}
