import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_source_style.dart';
import 'package:legend_ui/src/components/markdown/legend_markdown_syntax.dart';

/// The markdown editor's controller: an ordinary [TextEditingController]
/// whose [buildTextSpan] styles the unchanged markdown source in place
/// (RFC-005 §3.1) — the value is always the plain source text.
///
/// The hard rule of the RFC: the concatenated span text always equals
/// [text] exactly. The controller only ever *styles* characters — it never
/// hides, inserts, or reorders them — so selection, IME composing (the
/// composing underline is preserved), and web input keep working exactly
/// as they do for a plain controller.
///
/// Highlighting is an incremental per-line tokenizer, not a parse
/// (RFC-005 §3.2): the source splits into lines, each line's syntax marks
/// are tokenized independently, results are cached, and an edit only
/// retokenizes the lines it touched. Fence state carries across lines, so
/// lines inside a ``` fence render as code and an edit that opens or
/// closes a fence retokenizes the lines downstream of it.
///
/// Custom notations come from the same [LegendMarkdownSyntax] registry the
/// `LegendMarkdown` renderer consumes — a registration with a
/// [LegendMarkdownSyntax.highlight] rule highlights here and renders
/// there, from one declaration.
class LegendMarkdownEditingController extends TextEditingController {
  /// Creates a controller highlighting [syntaxes] with [sourceStyle].
  ///
  /// `LegendMarkdownEditor` keeps both in sync with its resolved theme and
  /// widget configuration; standalone use sets them directly.
  LegendMarkdownEditingController({
    super.text,
    List<LegendMarkdownSyntax> syntaxes = const [],
    this.sourceStyle = const LegendMarkdownSourceStyle(),
  }) : _syntaxes = syntaxes;

  /// The resolved presentation of the source — consumed imperatively at
  /// span-build time (never a rebuild source; the owning widget repaints
  /// when its theme changes and reassigns this before the next paint).
  LegendMarkdownSourceStyle sourceStyle;

  List<LegendMarkdownSyntax> _syntaxes;

  /// The custom notations highlighted in addition to the built-in markdown
  /// syntax; assigning a different list invalidates the line cache.
  List<LegendMarkdownSyntax> get syntaxes => _syntaxes;
  set syntaxes(List<LegendMarkdownSyntax> value) {
    if (listEquals(value, _syntaxes)) return;
    _syntaxes = value;
    _cache = null;
    _cacheText = null;
  }

  List<_TokenizedLine>? _cache;
  String? _cacheText;
  int _tokenizedLineCount = 0;

  /// Total lines tokenized since creation — the incremental-retokenization
  /// counter the cache tests assert against.
  @visibleForTesting
  int get debugTokenizedLineCount => _tokenizedLineCount;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    final base = style ?? const TextStyle();
    _sync();
    var ranges = _styledRanges(base);
    if (withComposing && value.isComposingRangeValid) {
      ranges = _underlineComposing(ranges, base);
    }
    final source = text;
    return TextSpan(
      style: style,
      children: [
        for (final range in ranges)
          TextSpan(
            text: source.substring(range.start, range.end),
            style: range.style,
          ),
      ],
    );
  }

  // --- span assembly ---

  /// Flattens the cached line tokens into contiguous styled ranges over the
  /// full text (newline separators stay base-styled).
  List<_StyledRange> _styledRanges(TextStyle base) {
    final ranges = <_StyledRange>[];
    final cache = _cache!;
    var offset = 0;
    for (var i = 0; i < cache.length; i++) {
      for (final segment in cache[i].segments) {
        ranges.add(
          _StyledRange(
            offset + segment.start,
            offset + segment.end,
            _styleFor(base, segment),
          ),
        );
      }
      offset += cache[i].text.length;
      if (i < cache.length - 1) {
        ranges.add(_StyledRange(offset, offset + 1, null));
        offset += 1;
      }
    }
    return ranges;
  }

  /// Overlays the IME composing underline, splitting ranges at the
  /// composing boundaries — style only, characters untouched.
  List<_StyledRange> _underlineComposing(
    List<_StyledRange> ranges,
    TextStyle base,
  ) {
    final composing = value.composing;
    const underline = TextStyle(decoration: TextDecoration.underline);
    final result = <_StyledRange>[];
    for (final range in ranges) {
      final start = range.start < composing.start
          ? composing.start
          : range.start;
      final end = range.end > composing.end ? composing.end : range.end;
      if (start >= end) {
        result.add(range);
        continue;
      }
      if (range.start < start) {
        result.add(_StyledRange(range.start, start, range.style));
      }
      result.add(
        _StyledRange(start, end, (range.style ?? base).merge(underline)),
      );
      if (end < range.end) {
        result.add(_StyledRange(end, range.end, range.style));
      }
    }
    return result;
  }

  /// The style of one segment: base → heading emphasis → quote color →
  /// code style → inline-mark delta, so context and mark compose the way
  /// they nest in the source.
  TextStyle? _styleFor(TextStyle base, _Segment segment) {
    final s = sourceStyle;
    var style = base;
    var changed = false;
    if (segment.heading > 0) {
      final headingStyle = switch (segment.heading) {
        1 => s.h1Style,
        2 => s.h2Style,
        3 => s.h3Style,
        // h4–h6 have no dedicated token style — semibold body, matching
        // the renderer's derivation.
        _ => const TextStyle(fontWeight: FontWeight.w600),
      };
      if (headingStyle != null) {
        style = style.merge(headingStyle);
        changed = true;
      }
    }
    if (segment.quoted && s.blockquoteColor != null) {
      style = style.copyWith(color: s.blockquoteColor);
      changed = true;
    }
    if (segment.code) {
      if (s.codeStyle != null) style = style.merge(s.codeStyle);
      if (s.codeBackground != null) {
        style = style.copyWith(backgroundColor: s.codeBackground);
      }
      changed = true;
    }
    switch (segment.inline) {
      case _Inline.none:
        break;
      case _Inline.mark:
        if (s.syntaxMarkColor != null) {
          style = style.copyWith(color: s.syntaxMarkColor);
          changed = true;
        }
      case _Inline.bold:
        style = style.copyWith(fontWeight: FontWeight.w700);
        changed = true;
      case _Inline.italic:
        style = style.copyWith(fontStyle: FontStyle.italic);
        changed = true;
      case _Inline.strike:
        style = style.copyWith(decoration: TextDecoration.lineThrough);
        changed = true;
      case _Inline.linkText:
        if (s.linkColor != null) {
          style = style.copyWith(
            color: s.linkColor,
            decoration: TextDecoration.underline,
            decorationColor: s.linkColor,
          );
          changed = true;
        }
      case _Inline.linkUrl:
        if (s.syntaxMarkColor != null) {
          style = style.copyWith(color: s.syntaxMarkColor);
          changed = true;
        }
      case _Inline.marker:
        if (s.markerColor != null) {
          style = style.copyWith(color: s.markerColor);
          changed = true;
        }
      case _Inline.custom:
        final highlight = _syntaxes[segment.customIndex].highlight;
        if (highlight != null) {
          style = highlight.style(style, s);
          changed = true;
        }
    }
    return changed ? style : null;
  }

  // --- incremental line cache ---

  /// Brings the line cache up to date with [text]: unchanged prefix and
  /// suffix lines reuse their cached tokens (the suffix only while its
  /// entering fence state still matches — an edit that opens or closes a
  /// fence retokenizes everything downstream), and only the middle is
  /// tokenized fresh.
  void _sync() {
    final source = text;
    if (_cacheText == source && _cache != null) return;
    final lines = source.split('\n');
    final old = _cache;

    var prefix = 0;
    var suffix = 0;
    if (old != null) {
      final maxPrefix = lines.length < old.length ? lines.length : old.length;
      while (prefix < maxPrefix && old[prefix].text == lines[prefix]) {
        prefix++;
      }
      final maxSuffix = maxPrefix - prefix;
      while (suffix < maxSuffix &&
          old[old.length - 1 - suffix].text ==
              lines[lines.length - 1 - suffix]) {
        suffix++;
      }
    }

    final fresh = <_TokenizedLine>[];
    var inFence = false;
    for (var i = 0; i < lines.length; i++) {
      if (i < prefix) {
        // Identical prefix lines: entering state matches by induction.
        fresh.add(old![i]);
        inFence = old[i].endsInFence;
        continue;
      }
      if (old != null && i >= lines.length - suffix) {
        final cached = old[old.length - (lines.length - i)];
        if (cached.opensInFence == inFence) {
          fresh.add(cached);
          inFence = cached.endsInFence;
          continue;
        }
      }
      final tokenized = _tokenizeLine(lines[i], inFence: inFence);
      _tokenizedLineCount++;
      fresh.add(tokenized);
      inFence = tokenized.endsInFence;
    }
    _cache = fresh;
    _cacheText = source;
  }

  // --- per-line tokenization ---

  static final RegExp _fenceOpen = RegExp(r'^ {0,3}(`{3,}|~{3,})(.*)$');
  static final RegExp _fenceClose = RegExp(r'^ {0,3}(`{3,}|~{3,})[ \t]*$');
  static final RegExp _quoteMark = RegExp(' {0,3}>[ ]?');
  static final RegExp _headingMark = RegExp(r'(#{1,6})([ \t]+|$)');
  static final RegExp _listMark = RegExp(r'[ \t]*(?:[-*+]|\d{1,9}[.)])[ \t]+');
  static final RegExp _inlineCode = RegExp(r'(`+)([^`]+?)\1');
  static final RegExp _link = RegExp(r'\[([^\]`]*)\]\(([^)]*)\)');
  static final RegExp _boldStar = RegExp(r'\*\*([^`]+?)\*\*');
  static final RegExp _boldUnderscore = RegExp('__([^`]+?)__');
  static final RegExp _strike = RegExp('~~([^`]+?)~~');
  static final RegExp _italicStar = RegExp(r'\*([^*`]+?)\*');
  static final RegExp _italicUnderscore = RegExp('_([^_`]+?)_');

  _TokenizedLine _tokenizeLine(String line, {required bool inFence}) {
    final segments = <_Segment>[];
    if (inFence) {
      final close = _fenceClose.firstMatch(line);
      if (close != null) {
        if (line.isNotEmpty) {
          segments.add(_Segment(0, line.length, inline: _Inline.mark));
        }
        return _TokenizedLine(
          line,
          opensInFence: true,
          endsInFence: false,
          segments: segments,
        );
      }
      if (line.isNotEmpty) segments.add(_Segment(0, line.length, code: true));
      return _TokenizedLine(
        line,
        opensInFence: true,
        endsInFence: true,
        segments: segments,
      );
    }

    final open = _fenceOpen.firstMatch(line);
    if (open != null) {
      final markEnd = open.end - open.group(2)!.length;
      segments.add(_Segment(0, markEnd, inline: _Inline.mark));
      if (markEnd < line.length) {
        // The info string (e.g. the `dart` of ```dart) reads as code.
        segments.add(_Segment(markEnd, line.length, code: true));
      }
      return _TokenizedLine(
        line,
        opensInFence: false,
        endsInFence: true,
        segments: segments,
      );
    }

    var pos = 0;
    var quoted = false;
    // Blockquote marks — consumed repeatedly so nested `> >` quotes work.
    while (true) {
      final match = _quoteMark.matchAsPrefix(line, pos);
      if (match == null) break;
      segments.add(
        _Segment(pos, match.end, quoted: true, inline: _Inline.mark),
      );
      pos = match.end;
      quoted = true;
    }

    var heading = 0;
    final headingMatch = _headingMark.matchAsPrefix(line, pos);
    if (headingMatch != null) {
      heading = headingMatch.group(1)!.length;
      segments.add(
        _Segment(
          pos,
          headingMatch.end,
          heading: heading,
          quoted: quoted,
          inline: _Inline.mark,
        ),
      );
      pos = headingMatch.end;
    } else {
      final listMatch = _listMark.matchAsPrefix(line, pos);
      if (listMatch != null) {
        segments.add(
          _Segment(pos, listMatch.end, quoted: quoted, inline: _Inline.marker),
        );
        pos = listMatch.end;
      }
    }

    _tokenizeInline(line, pos, segments, heading: heading, quoted: quoted);
    return _TokenizedLine(
      line,
      opensInFence: false,
      endsInFence: false,
      segments: segments,
    );
  }

  /// Scans the prose run [from]..end of [line] for inline marks; plain
  /// stretches between matches become unmarked segments so the segments
  /// always cover the whole line.
  void _tokenizeInline(
    String line,
    int from,
    List<_Segment> segments, {
    required int heading,
    required bool quoted,
  }) {
    var pos = from;
    var runStart = from;

    void plain(int end) {
      if (runStart < end) {
        segments.add(_Segment(runStart, end, heading: heading, quoted: quoted));
      }
    }

    void mark(int start, int end) => segments.add(
      _Segment(
        start,
        end,
        heading: heading,
        quoted: quoted,
        inline: _Inline.mark,
      ),
    );

    void content(int start, int end, _Inline inline, {bool code = false}) {
      if (start < end) {
        segments.add(
          _Segment(
            start,
            end,
            heading: heading,
            quoted: quoted,
            code: code,
            inline: inline,
          ),
        );
      }
    }

    while (pos < line.length) {
      // Custom notations first, so domain syntax wins over the built-ins.
      Match? custom;
      var customIndex = -1;
      for (var i = 0; i < _syntaxes.length; i++) {
        final highlight = _syntaxes[i].highlight;
        if (highlight == null) continue;
        final match = highlight.pattern.matchAsPrefix(line, pos);
        if (match != null && match.end > match.start) {
          custom = match;
          customIndex = i;
          break;
        }
      }
      if (custom != null) {
        plain(pos);
        segments.add(
          _Segment(
            custom.start,
            custom.end,
            heading: heading,
            quoted: quoted,
            inline: _Inline.custom,
            customIndex: customIndex,
          ),
        );
        pos = custom.end;
        runStart = pos;
        continue;
      }

      final code = _inlineCode.matchAsPrefix(line, pos);
      if (code != null) {
        plain(pos);
        final ticks = code.group(1)!.length;
        mark(code.start, code.start + ticks);
        content(code.start + ticks, code.end - ticks, _Inline.none, code: true);
        mark(code.end - ticks, code.end);
        pos = code.end;
        runStart = pos;
        continue;
      }

      final link = _link.matchAsPrefix(line, pos);
      if (link != null) {
        plain(pos);
        final textEnd = link.start + 1 + link.group(1)!.length;
        mark(link.start, link.start + 1);
        content(link.start + 1, textEnd, _Inline.linkText);
        mark(textEnd, textEnd + 2);
        content(textEnd + 2, link.end - 1, _Inline.linkUrl);
        mark(link.end - 1, link.end);
        pos = link.end;
        runStart = pos;
        continue;
      }

      final emphasis =
          _matchDelimited(line, pos, _boldStar, 2, _Inline.bold) ??
          _matchDelimited(line, pos, _boldUnderscore, 2, _Inline.bold) ??
          _matchDelimited(line, pos, _strike, 2, _Inline.strike) ??
          _matchDelimited(line, pos, _italicStar, 1, _Inline.italic) ??
          _matchDelimited(line, pos, _italicUnderscore, 1, _Inline.italic);
      if (emphasis != null) {
        plain(pos);
        mark(emphasis.match.start, emphasis.match.start + emphasis.width);
        content(
          emphasis.match.start + emphasis.width,
          emphasis.match.end - emphasis.width,
          emphasis.inline,
        );
        mark(emphasis.match.end - emphasis.width, emphasis.match.end);
        pos = emphasis.match.end;
        runStart = pos;
        continue;
      }

      pos++;
    }
    plain(line.length);
  }

  /// One delimited emphasis match at [pos], or null. Underscore emphasis
  /// never starts mid-word (`snake_case` stays plain).
  _Emphasis? _matchDelimited(
    String line,
    int pos,
    RegExp pattern,
    int width,
    _Inline inline,
  ) {
    final match = pattern.matchAsPrefix(line, pos);
    if (match == null) return null;
    if (line[pos] == '_' && pos > 0 && _isWordChar(line.codeUnitAt(pos - 1))) {
      return null;
    }
    return _Emphasis(match, width, inline);
  }

  static bool _isWordChar(int codeUnit) =>
      (codeUnit >= 0x30 && codeUnit <= 0x39) ||
      (codeUnit >= 0x41 && codeUnit <= 0x5A) ||
      (codeUnit >= 0x61 && codeUnit <= 0x7A) ||
      codeUnit == 0x5F;
}

/// The inline mark kinds the tokenizer distinguishes.
enum _Inline {
  none,
  mark,
  bold,
  italic,
  strike,
  linkText,
  linkUrl,
  marker,
  custom,
}

/// One styled stretch of a line — [start]/[end] are line-local offsets;
/// the flags carry the block context the stretch sits in.
class _Segment {
  const _Segment(
    this.start,
    this.end, {
    this.heading = 0,
    this.quoted = false,
    this.code = false,
    this.inline = _Inline.none,
    this.customIndex = -1,
  });

  final int start;
  final int end;
  final int heading;
  final bool quoted;
  final bool code;
  final _Inline inline;
  final int customIndex;
}

/// One cached line: its text, the fence state it was tokenized under (the
/// cache-reuse key), the fence state it leaves behind, and its segments.
class _TokenizedLine {
  const _TokenizedLine(
    this.text, {
    required this.opensInFence,
    required this.endsInFence,
    required this.segments,
  });

  final String text;
  final bool opensInFence;
  final bool endsInFence;
  final List<_Segment> segments;
}

/// A contiguous text-offset range with its resolved style (null = base).
class _StyledRange {
  const _StyledRange(this.start, this.end, this.style);

  final int start;
  final int end;
  final TextStyle? style;
}

/// One matched emphasis span: the match, its delimiter width, and kind.
class _Emphasis {
  const _Emphasis(this.match, this.width, this.inline);

  final Match match;
  final int width;
  final _Inline inline;
}
