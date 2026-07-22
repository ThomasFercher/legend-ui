import 'package:example/docs/doc_page.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  var _shimmer = true;
  var _bannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    void noop() {}
    return DocPage(
      title: 'Feedback',
      intro:
          'Persistent banners, progress, loading indicators and shimmer '
          'placeholders. Toasts live on the Overlays page — same engine.',
      children: [
        DocSection(
          title: 'Banner',
          description:
              'A persistent inline alert — the non-transient sibling of the '
              'toast. Severity picks the tint, onDismissed shows the dismiss '
              'affordance, and icon/action are consumer slots.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.sizes.sm,
            children: [
              const LegendBanner(
                message: 'Deposits arrive after 12 confirmations.',
              ),
              const LegendBanner(
                severity: LegendBannerSeverity.success,
                title: 'Backup verified',
                message: 'Your recovery phrase matches this wallet.',
              ),
              LegendBanner(
                severity: LegendBannerSeverity.warning,
                title: 'Security warning',
                message:
                    'This address differs from the one you usually send to.',
                action: LegendTextButton(text: 'Review', onPressed: noop),
              ),
              if (_bannerDismissed)
                LegendTextButton(
                  text: 'Show the error banner again',
                  onPressed: () => setState(() => _bannerDismissed = false),
                )
              else
                LegendBanner(
                  severity: LegendBannerSeverity.error,
                  message: 'Signing failed — the hardware wallet timed out.',
                  icon: Icon(
                    Icons.error_outline,
                    size: tokens.sizes.iconMd,
                    color: tokens.colors.error,
                  ),
                  dismissLabel: 'Dismiss error',
                  onDismissed: () => setState(() => _bannerDismissed = true),
                ),
            ],
          ),
          code: '''
LegendBanner(
  severity: LegendBannerSeverity.warning,
  title: 'Security warning',
  message: 'This address differs from the one you usually send to.',
  action: LegendTextButton(text: 'Review', onPressed: review),
  dismissLabel: 'Dismiss warning',
  onDismissed: hide, // the banner is stateless — you hide it
)''',
        ),
        DocSection(
          title: 'Empty',
          description:
              'The zero-state placeholder a list or panel shows instead of '
              'content. Purely presentational: icon and action are consumer '
              'slots, the muted styles come from the theme, and long '
              'descriptions wrap inside a centered column.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: tokens.sizes.md,
            children: [
              LegendEmpty(
                title: 'No transactions yet',
                description:
                    'Activity shows up here after your first transfer. '
                    'Receive funds to get started.',
                icon: const Icon(Icons.inbox_outlined),
                action: SecondaryLegendButton(text: 'Receive', onPressed: noop),
              ),
              const LegendDivider(),
              LegendEmpty(
                title: 'No sources',
                description:
                    'Connect a document, site or note and its content '
                    'becomes searchable in this workspace.',
                icon: const Icon(Icons.folder_open_outlined),
                action: PrimaryLegendButton(
                  text: 'Add source',
                  onPressed: noop,
                ),
              ),
            ],
          ),
          code: '''
LegendEmpty(
  title: 'No sources',
  description: 'Connect a document, site or note and its '
      'content becomes searchable in this workspace.',
  icon: const Icon(Icons.folder_open_outlined), // inherits color + size
  action: PrimaryLegendButton(text: 'Add source', onPressed: add),
)''',
        ),
        DocSection(
          title: 'Loading',
          demo: Wrap(
            spacing: tokens.sizes.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: const [
              LegendLoading(),
              LegendLoading(size: 40, strokeWidth: 5),
            ],
          ),
          code: 'const LegendLoading(size: 40, strokeWidth: 5)',
        ),
        DocSection(
          title: 'Progress',
          description:
              'Determinate when value is set, indeterminate when null. '
              'LegendLoading stays the centered activity spinner; '
              'LegendProgress is the inline bar or ring that can report a '
              'known completion fraction.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.md,
            children: [
              const LegendProgress.bar(value: 0.35, semanticLabel: 'Download'),
              const LegendProgress.bar(semanticLabel: 'Working'),
              Wrap(
                spacing: tokens.sizes.md,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: const [
                  LegendProgress.circle(
                    value: 0.7,
                    semanticLabel: 'Confirmations',
                  ),
                  LegendProgress.circle(semanticLabel: 'Syncing'),
                ],
              ),
            ],
          ),
          code: '''
const LegendProgress.bar(value: 0.35)
const LegendProgress.circle() // value: null → indeterminate''',
        ),
        DocSection(
          title: 'Shimmer',
          description:
              'Wrap real content, or use LegendShimmer.box for a sized '
              'placeholder while data loads.',
          demo: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: tokens.sizes.sm,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const LegendText('Loading state'),
                  LegendSwitch(
                    value: _shimmer,
                    semanticLabel: 'Loading state',
                    onChanged: (v) => setState(() => _shimmer = v),
                  ),
                ],
              ),
              if (_shimmer)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: tokens.sizes.xs,
                  children: const [
                    LegendShimmer.box(width: 220, height: 20),
                    LegendShimmer.box(width: 320, height: 14),
                    LegendShimmer.box(width: 280, height: 14),
                  ],
                )
              else
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LegendText(
                      'Loaded headline',
                      variant: LegendTextVariant.h3,
                    ),
                    LegendText('The real content replaces the placeholder.'),
                  ],
                ),
            ],
          ),
          code: '''
loading
    ? const LegendShimmer.box(width: 220, height: 20)
    : const LegendText('Loaded headline')''',
        ),
      ],
    );
  }
}
