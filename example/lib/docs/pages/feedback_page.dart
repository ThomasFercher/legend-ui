import 'package:example/docs/doc_page.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/legend_ui.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  var _shimmer = true;

  @override
  Widget build(BuildContext context) {
    final tokens = LegendTheme.of(context).tokens;
    return DocPage(
      title: 'Feedback',
      intro:
          'Progress, loading indicators and shimmer placeholders. Toasts '
          'live on the Overlays page — same engine.',
      children: [
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
