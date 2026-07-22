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
          'Structural pieces: cards, dividers, expandables, info rows, '
          'stats, lists, badges, and avatars — all thin compositions over '
          'LegendSurface and LegendInteractive.',
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
          title: 'Accordion',
          description:
              'A group of expandables where opening one closes the others '
              '— the FAQ pattern. Pass allowMultiple to let several stay '
              'open, or expandedIndices/onChanged to control the open set '
              'yourself.',
          demo: LegendAccordion(
            items: const [
              LegendAccordionItem(
                title: 'Is it Material-free?',
                child: LegendText(
                  'Yes — components compose the five kit primitives; no '
                  'Scaffold, InkWell, or Material theme anywhere.',
                  variant: LegendTextVariant.b2,
                ),
              ),
              LegendAccordionItem(
                title: 'How is it themed?',
                child: LegendText(
                  'Design tokens are the only global theme; component '
                  'themes are generated from decorators on the widget.',
                  variant: LegendTextVariant.b2,
                ),
              ),
              LegendAccordionItem(
                title: 'Can I keep several open?',
                child: LegendText(
                  'Pass allowMultiple: true and every section toggles '
                  'independently.',
                  variant: LegendTextVariant.b2,
                ),
              ),
            ],
          ),
          code: '''
LegendAccordion(
  // allowMultiple: true,        // let several sections stay open
  // expandedIndices: {0},       // or control the open set yourself
  // onChanged: (open) => ...,
  items: const [
    LegendAccordionItem(title: 'Is it Material-free?', child: LegendText('Yes ...')),
    LegendAccordionItem(title: 'How is it themed?', child: LegendText('Tokens ...')),
  ],
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
        DocSection(
          title: 'Avatar',
          description:
              'A fallback ladder — image, then initials, then a placeholder, '
              'then a generic silhouette. A seed string derives a stable '
              'identity color from the tokens; badge overlays a caller-owned '
              'widget at a corner (the network-badge-on-token-icon case).',
          demo: Wrap(
            spacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const LegendAvatar(initials: 'TF'),
              const LegendAvatar(seed: 'alice', initials: 'AL'),
              const LegendAvatar(seed: 'bob', initials: 'BO'),
              const LegendAvatar(seed: 'carol', initials: 'CA'),
              const LegendAvatar(),
              LegendAvatar(
                initials: 'TF',
                size: 48,
                badge: LegendSurface(
                  color: tokens.colors.secondary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: tokens.colors.surface),
                  child: const SizedBox(width: 12, height: 12),
                ),
              ),
            ],
          ),
          code: '''
LegendAvatar(
  image: NetworkImage(logoUrl),  // falls back to initials on error
  initials: 'TF',
  seed: account.address,         // deterministic identity color
  badge: NetworkDot(),           // overlaid bottom-end
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
        DocSection(
          title: 'Stat',
          description:
              'An emphasized KPI — a small muted label over a large value, '
              'with an optional colored delta (a painted arrow spoken as '
              '"up"/"down" by screen readers) and a muted caption. Derive '
              'the direction from a signed change with '
              'LegendStatDirection.fromChange; lay several out with a Wrap.',
          demo: Wrap(
            spacing: tokens.sizes.xl,
            runSpacing: tokens.sizes.md,
            children: const [
              LegendStat(
                label: 'Balance',
                value: r'$12,480.30',
                delta: '4.2%',
                deltaDirection: LegendStatDirection.up,
                caption: 'vs last week',
              ),
              LegendStat(
                label: 'ETH',
                value: r'$3,120.55',
                delta: '1.8%',
                deltaDirection: LegendStatDirection.down,
                caption: '24h',
              ),
              LegendStat(
                label: 'USDC',
                value: r'$1.00',
                delta: '0.0%',
                caption: '24h',
              ),
            ],
          ),
          code: '''
LegendStat(
  label: 'Balance',
  value: formatUsd(total),
  delta: formatPercent(change),
  deltaDirection: LegendStatDirection.fromChange(change),
  caption: 'vs last week',
)''',
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
        DocSection(
          title: 'Badge',
          description:
              'A status dot, count pill, or label — standalone, or anchored '
              'over a corner of a child with a contrast ring. Counts '
              'overflow as max+ and hide at zero.',
          demo: Wrap(
            spacing: tokens.sizes.md,
            runSpacing: tokens.sizes.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const LegendBadge('Mainnet'),
              const LegendBadge.count(3),
              const LegendBadge.count(250),
              LegendBadge.count(
                12,
                child: LegendSurface(
                  color: tokens.colors.background2,
                  borderRadius: tokens.sizes.borderRadiusMd,
                  child: const SizedBox(width: 32, height: 32),
                ),
              ),
              LegendBadge.dot(
                alignment: AlignmentDirectional.bottomEnd,
                background: tokens.colors.secondary,
                semanticLabel: 'Online',
                child: LegendSurface(
                  color: tokens.colors.background2,
                  borderRadius: BorderRadius.circular(999),
                  child: const SizedBox(width: 32, height: 32),
                ),
              ),
            ],
          ),
          code: '''
LegendBadge.count(unread, child: navIcon)   // 99+ overflow, hides at 0
LegendBadge.dot(
  alignment: AlignmentDirectional.bottomEnd,
  background: tokens.colors.secondary,
  semanticLabel: 'Online',
  child: avatar,
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
