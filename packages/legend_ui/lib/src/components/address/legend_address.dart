import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/annotations/annotations.dart';
import 'package:legend_ui/src/components/copy_button/legend_copy_button.dart';
import 'package:legend_ui/src/components/text/legend_text.dart';
import 'package:legend_ui/src/components/tooltip/legend_tooltip.dart';
import 'package:legend_ui/src/theme/legend_theme.dart';
import 'package:legend_ui/src/tokens/legend_tokens.dart';

part 'legend_address.theme.g.dart';

/// A blockchain address (or any long identifier) middle-truncated to its
/// first [prefixChars] and last [suffixChars] characters —
/// `0x8f3Cf7…A063`-style — in a monospace token style.
///
/// Composes [LegendText] (the truncated run), [LegendTooltip] (the full
/// address on hover/focus/long-press), and [LegendCopyButton] (the
/// optional trailing copy affordance — which always copies the full
/// address, never the elided form).
///
/// Truncation is character-based and deterministic — no layout measuring,
/// so the same address renders identically everywhere. Assistive tech
/// reads the full address, never the visual ellipsis; an address short
/// enough to fit whole renders untouched, without separator or tooltip.
@LegendThemeable()
class LegendAddress extends StatelessWidget {
  const LegendAddress(
    this.address, {
    super.key,
    this.prefixChars = 6,
    this.suffixChars = 4,
    this.copyable = true,
    this.onCopied,
    this.textStyle,
    this.separator,
  }) : assert(
         prefixChars >= 0 && suffixChars >= 0,
         'prefixChars and suffixChars must not be negative.',
       );

  /// The full address; what the tooltip shows, semantics announce, and
  /// the copy affordance copies.
  final String address;

  /// Characters kept before the separator.
  final int prefixChars;

  /// Characters kept after the separator.
  final int suffixChars;

  /// Whether the trailing [LegendCopyButton] renders.
  final bool copyable;

  /// Called after the copy affordance has written [address] to the
  /// clipboard.
  final VoidCallback? onCopied;

  /// Monospace style of the truncated run (and the tooltip's full
  /// address).
  @Style<TextStyle>.resolve(_textStyle)
  final TextStyle? textStyle;

  /// String standing in for the elided middle.
  @Style<String>('…')
  final String? separator;

  @override
  Widget build(BuildContext context) {
    final theme = _theme(context);
    final truncated = _truncate(theme.separator);

    Widget text = Semantics(
      label: address,
      // The control announces the full address — without this the elided
      // run would be read out, ellipsis and all.
      child: ExcludeSemantics(
        child: LegendText(truncated, style: theme.textStyle),
      ),
    );
    if (truncated != address) {
      text = LegendTooltip(
        message: address,
        // The full address is mono content too — its tooltip rides the
        // same resolved style as the visible run.
        textStyle: theme.textStyle,
        child: text,
      );
    }
    if (!copyable) return text;

    final tokens = LegendTheme.of(context).tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: tokens.sizes.xs,
      children: [
        Flexible(child: text),
        LegendCopyButton(value: address, onCopied: onCopied),
      ],
    );
  }

  /// Character-based middle truncation. The full address renders whenever
  /// eliding would not actually shorten it.
  String _truncate(String separator) {
    if (address.length <= prefixChars + suffixChars + separator.length) {
      return address;
    }
    return '${address.substring(0, prefixChars)}'
        '$separator'
        '${address.substring(address.length - suffixChars)}';
  }
}

TextStyle _textStyle(LegendTokens t) => t.typography.b2.copyWith(
  fontFamily: 'monospace',
  fontFamilyFallback: const ['Menlo', 'Courier'],
);
