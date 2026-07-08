import 'package:flutter/painting.dart';

/// The single elevation system (replaces legacy ElevatedBox + NomoElevation).
class NomoShadows {
  const NomoShadows({
    this.none = const [],
    this.low = const [
      BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
    ],
    this.medium = const [
      BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 3)),
    ],
    this.high = const [
      BoxShadow(color: Color(0x29000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
  });

  final List<BoxShadow> none;
  final List<BoxShadow> low;
  final List<BoxShadow> medium;
  final List<BoxShadow> high;

  NomoShadows copyWith({
    List<BoxShadow>? none,
    List<BoxShadow>? low,
    List<BoxShadow>? medium,
    List<BoxShadow>? high,
  }) {
    return NomoShadows(
      none: none ?? this.none,
      low: low ?? this.low,
      medium: medium ?? this.medium,
      high: high ?? this.high,
    );
  }

  static NomoShadows lerp(NomoShadows a, NomoShadows b, double t) {
    return NomoShadows(
      none: BoxShadow.lerpList(a.none, b.none, t)!,
      low: BoxShadow.lerpList(a.low, b.low, t)!,
      medium: BoxShadow.lerpList(a.medium, b.medium, t)!,
      high: BoxShadow.lerpList(a.high, b.high, t)!,
    );
  }
}
