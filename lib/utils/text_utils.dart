import 'dart:math' as math;

/// Text helpers used by search and typed-answer checking.
class TextUtils {
  const TextUtils._();

  /// Levenshtein edit distance between [a] and [b].
  static int levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      final current = List<int>.filled(b.length + 1, 0);
      current[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        current[j] = math.min(
          math.min(current[j - 1] + 1, previous[j] + 1),
          previous[j - 1] + cost,
        );
      }
      previous = current;
    }
    return previous[b.length];
  }

  /// Lower-cases and strips everything except letters and digits, so that
  /// "CI / CD", "ci-cd" and "CICD" compare equal.
  static String normalize(String input) =>
      input.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  /// Splits into lower-case alphanumeric words.
  static List<String> tokens(String input) => RegExp(
    r'[a-z0-9]+',
  ).allMatches(input.toLowerCase()).map((m) => m.group(0)!).toList();
}
