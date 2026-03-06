/// Thin helper that wraps Dart [RegExp] with PHP Regexp-like methods:
/// match, matchAll, scan, split — and exposes captured [matches].
class RegexpHelper {
  final RegExp _pattern;
  List<String?> matches = [];

  RegexpHelper(String pattern) : _pattern = RegExp(pattern, dotAll: true);

  RegexpHelper.fromRegExp(RegExp pattern) : _pattern = pattern;

  /// Returns true if the pattern matches [input].
  /// Populates [matches] with group(0), group(1), group(2), ...
  bool match(String input) {
    final m = _pattern.firstMatch(input);
    if (m == null) {
      matches = [];
      return false;
    }
    matches = List.generate(m.groupCount + 1, (i) => m.group(i));
    return true;
  }

  /// Returns all matches in [input].
  /// Each entry is a list of groups for that match.
  List<List<String?>> matchAll(String input) {
    final result = <List<String?>>[];
    for (final m in _pattern.allMatches(input)) {
      result.add(List.generate(m.groupCount + 1, (i) => m.group(i)));
    }
    return result;
  }

  /// Ruby-style scan: returns a flat list of the first capture group for each match,
  /// or full match if no groups.
  List<String> scan(String input) {
    final all = _pattern.allMatches(input);
    if (!all.iterator.moveNext()) return [];
    // restart
    return _pattern.allMatches(input).map((m) {
      if (m.groupCount >= 1) return m.group(1) ?? m.group(0) ?? '';
      return m.group(0) ?? '';
    }).toList();
  }

  /// Splits [input] by the pattern.
  List<String> split(String input) => input.split(_pattern);
}
