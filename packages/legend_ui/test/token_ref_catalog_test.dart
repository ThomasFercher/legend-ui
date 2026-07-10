import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legend_ui/legend_ui.dart';

/// The generated token Ref catalogs (RFC-002 R10 amendment): const
/// tear-off statics usable directly inside `@Style<T>.resolve`
/// annotations, replacing the hand-written one-hop tear-offs.
void main() {
  const tokens = LegendTokens.light;

  group('token Ref catalogs (RFC-002 R10 amendment)', () {
    test('every mounted catalog reads exactly its token field', () {
      // One spot-check per catalog — a wrong mount would misroute all of
      // its members the same way.
      expect(ColorRef.primary(tokens), tokens.colors.primary);
      expect(SizeRef.md(tokens), tokens.sizes.md);
      expect(TextRef.b2(tokens), tokens.typography.b2);
      expect(ShadowRef.medium(tokens), tokens.shadows.medium);
      expect(StateRef.hoverAmount(tokens), tokens.states.hoverAmount);
    });

    test('the root sentinel catalog reads directly off the tokens', () {
      expect(TokenRef.colors(tokens), tokens.colors);
      expect(TokenRef.sizes(tokens), tokens.sizes);
      expect(TokenRef.typography(tokens), tokens.typography);
      expect(TokenRef.shadows(tokens), tokens.shadows);
      expect(TokenRef.states(tokens), tokens.states);
    });

    test('a @Style default from a Ref tear-off resolves identically to '
        'the local-static form', () {
      // The pre-catalog form every migrated field used: a hand-written
      // tear-off next to the field.
      double localSpacing(LegendTokens t) => t.sizes.md;
      Color localColor(LegendTokens t) => t.colors.background3;

      // The annotation is const with the Ref member as its tear-off…
      const style = Style<double>.resolve(SizeRef.md);
      expect(style.resolve!(tokens), localSpacing(tokens));

      // …and the generated defaults() built from Ref tear-offs
      // (LegendDivider migrated all three fields to the catalog form)
      // produces the same values the local statics did.
      final theme = LegendDividerTheme.defaults(tokens);
      expect(theme.spacing, localSpacing(tokens));
      expect(theme.color, localColor(tokens));
      expect(theme.thickness, tokens.sizes.borderWidth);
    });

    test('Ref defaults track whichever token set resolution passes', () {
      // A base-theme swap cascades into Ref-derived component defaults,
      // exactly like the local-static form did.
      final dark = LegendDividerTheme.defaults(LegendTokens.dark);
      expect(dark.color, LegendTokens.dark.colors.background3);
    });
  });
}
