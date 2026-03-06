/// Central configuration for the Liquid template engine.
/// Mirrors PHP liquid/liquid `Liquid::$config` and `Liquid::get()`.
class LiquidConfig {
  static const String filterSeparator = r'\|';
  static const String argumentSeparator = ',';
  static const String filterArgumentSeparator = ':';
  static const String variableAttributeSeparator = '.';
  static const String whitespaceControl = '-';

  static const String tagStart = r'{%';
  static const String tagEnd = r'%}';
  static const String variableStart = r'{{';
  static const String variableEnd = r'}}';

  static const String variableName = r'[a-zA-Z_][a-zA-Z_0-9.\-]*';
  static const String quotedString = r'''(?:"[^"]*"|'[^']*')''';
  static const String quotedStringFilterArg = r'''"[^"]*"|'[^']*'|[^\s,|'"]+''';

  static bool escapeByDefault = false;

  static const String includeSuffix = 'liquid';
  static const String includePrefix = '_';
  static const bool includeAllowExt = false;

  /// `(?:"[^"]*"|'[^']*'|[^\s,|'"]+)`
  static String get quotedFragment =>
      "(?:$quotedString|[^\\s,|'\"]+)";

  /// `/(\w+)\s*:\s*((?:"[^"]*"|'[^']*'|[^\s,|'"]+))/`
  static RegExp get tagAttributesRegExp => RegExp(
      r'''(\w+)\s*:\s*((?:"[^"]*"|'[^']*'|[^\s,|'"]+))''');

  /// Tokenization: splits source into tag tokens `{%...%}`, variable tokens `{{...}}`, and raw text.
  static RegExp get tokenizationRegExp => RegExp(
      r'({%.*?%}|{{.*?}})',
      dotAll: true);

  /// Matches a variable output token `{{ ... }}`
  static RegExp get variableStartRegExp =>
      RegExp(r'^' + RegExp.escape(variableStart));

  /// Matches a tag token `{% ... %}`
  static RegExp get tagStartRegExp =>
      RegExp(r'^' + RegExp.escape(tagStart));

  /// Full variable token regexp (strips `{{` / `}}` and whitespace control `-`)
  static RegExp get variableTokenRegExp => RegExp(
      r'^{{-?\s*(.*?)\s*-?}}$',
      dotAll: true);

  /// Full tag token regexp — captures tag name and rest of markup
  static RegExp get tagTokenRegExp => RegExp(
      r'^{%-?\s*(\w+)\s*(.*?)\s*-?%}$',
      dotAll: true);

  /// Used to split on `|` filter separator: avoids splitting inside quotes.
  static RegExp get filterSeparatorRegExp =>
      RegExp(r'''\|(?=(?:[^'"]*['"][^'"]*['"])*[^'"]*$)''');
}
