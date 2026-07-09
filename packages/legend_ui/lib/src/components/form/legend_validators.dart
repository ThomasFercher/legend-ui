/// The validator signature used across the form system: `null` means valid,
/// any string is the error message to display.
typedef LegendValidatorFn = String? Function(String? value);

/// The stock validators the legacy docs always claimed existed — now real
/// (DESIGN.md §3: "an actual `LegendValidator` set").
///
/// All validators except [required] treat an empty value as valid, so they
/// compose with [required] instead of duplicating it:
///
/// ```dart
/// LegendTextField(
///   formField: 'email',
///   validator: LegendValidator.compose([
///     LegendValidator.required,
///     LegendValidator.email,
///   ]),
/// )
/// ```
abstract final class LegendValidator {
  /// Rejects null, empty, and whitespace-only values.
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  /// Rejects values that are not plausibly an email address.
  /// Empty values pass — combine with [required] via [compose].
  static String? email(String? value) {
    if (value == null || value.isEmpty) return null;
    if (!_emailPattern.hasMatch(value)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  /// Rejects non-empty values shorter than [length] characters.
  /// Empty values pass — combine with [required] via [compose].
  static LegendValidatorFn minLength(int length, {String? message}) {
    return (value) {
      if (value == null || value.isEmpty) return null;
      if (value.length < length) {
        return message ?? 'Must be at least $length characters.';
      }
      return null;
    };
  }

  /// Rejects values longer than [length] characters.
  static LegendValidatorFn maxLength(int length, {String? message}) {
    return (value) {
      if (value != null && value.length > length) {
        return message ?? 'Must be at most $length characters.';
      }
      return null;
    };
  }

  /// Runs [validators] in order and returns the first error, or null when
  /// all pass.
  static LegendValidatorFn compose(List<LegendValidatorFn> validators) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
