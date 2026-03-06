import '../context.dart';
import '../decision.dart';
import '../exceptions/parse_exception.dart';
import '../liquid_config.dart';

/// {% case variable %}
///   {% when value1 %} ...
///   {% when value2, value3 %} ...
///   {% else %} ...
/// {% endcase %}
class TagCase extends Decision {
  late final String _left; // The variable/expression to switch on

  /// List of [(rightValues, nodelist), …]
  final List<(List<String>, List<dynamic>)> _nodelists = [];

  /// The else nodelist
  List<dynamic> _elseNodelist = [];

  List<String>? _currentRightValues;

  TagCase(super.markup, super.tokens, [super.fileSystem]) {
    final re = RegExp(LiquidConfig.quotedFragment);
    final m = re.firstMatch(markup);
    if (m == null) {
      throw ParseException(
          "Syntax Error in tag 'case' - Valid syntax: case [condition]");
    }
    _left = m.group(0)!;
  }

  void _pushNodelist() {
    if (_currentRightValues != null) {
      _nodelists.add((_currentRightValues!, [...nodelist]));
      _currentRightValues = null;
    }
  }

  @override
  void endTag() => _pushNodelist();

  @override
  void unknownTag(String tag, String params, List<String?> tokens) {
    switch (tag) {
      case 'when':
        _pushNodelist();
        // Parse comma/or-separated values
        final whenRe = RegExp(
            '(?:,|or|^)\\s*(${LiquidConfig.quotedFragment})');
        final matches = whenRe.allMatches(params);
        _currentRightValues = matches.map((m) => m.group(1)!).toList();
        nodelist = [];
        break;
      case 'else':
        _pushNodelist();
        _currentRightValues = null;
        _elseNodelist = nodelist = [];
        break;
      default:
        super.unknownTag(tag, params, tokens);
    }
  }

  @override
  String blockDelimiter() => 'endcase';

  @override
  String render(Context context) {
    var output = '';
    var runElseBlock = true;

    for (final (rightValues, list) in _nodelists) {
      for (final varExpr in rightValues) {
        if (equalVariables(_left, varExpr, context)) {
          runElseBlock = false;
          context.push();
          output += renderAll(list, context);
          context.pop();
          break;
        }
      }
    }

    if (runElseBlock) {
      context.push();
      output += renderAll(_elseNodelist, context);
      context.pop();
    }

    return output;
  }
}
