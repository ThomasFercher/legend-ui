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
          'Structural pieces: cards, dividers, expandables, info rows, and '
          'avatars — all thin compositions over LegendSurface and '
          'LegendInteractive.',
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
      ],
    );
  }
}
