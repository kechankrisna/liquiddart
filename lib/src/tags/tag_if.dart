import '../context.dart';
import '../decision.dart';
import '../exceptions/parse_exception.dart';

/// {% if condition %} ... {% elsif cond %} ... {% else %} ... {% endif %}
class TagIf extends Decision {
  final List<List<dynamic>> _blocks = [];
  // Each block: [type, markup, nodelist_ref]
  // type: 'if' | 'elsif' | 'else'

  TagIf(super.markup, super.tokens, [super.fileSystem]);

  /// Capture the initial `nodelist` reference right after it is reset to `[]`
  /// by [AbstractBlock.parse], before any tokens are consumed. This ensures
  /// the 'if' block points to the correct (first) nodelist.
  @override
  void onNodelistReset() {
    _blocks.add(['if', markup, nodelist]);
  }

  @override
  void unknownTag(String tag, String params, List<String?> tokens) {
    if (tag == 'else' || tag == 'elsif') {
      final newNodelist = <dynamic>[];
      nodelist = newNodelist;
      _blocks.add([tag, params, newNodelist]);
    } else {
      super.unknownTag(tag, params, tokens);
    }
  }

  @override
  String blockDelimiter() => 'endif';

  @override
  String render(Context context) {
    context.push();
    var result = '';

    try {
      for (final block in _blocks) {
        final type = block[0] as String;
        final blockMarkup = block[1] as String;
        final blockNodelist = block[2] as List<dynamic>;

        if (type == 'else') {
          result = renderAll(blockNodelist, context);
          break;
        }

        if (type == 'if' || type == 'elsif') {
          final parsed = ConditionParser(blockMarkup).parse();
          final conditions = parsed.conditions;
          final operators = parsed.operators;

          if (conditions.isEmpty) {
            throw ParseException(
                "Syntax Error in tag 'if' - Valid syntax: if [condition]");
          }

          bool display = interpretCondition(
              conditions[0]['left'],
              conditions[0]['right'],
              conditions[0]['operator'],
              context);

          for (int k = 0; k < operators.length; k++) {
            final next = interpretCondition(
                conditions[k + 1]['left'],
                conditions[k + 1]['right'],
                conditions[k + 1]['operator'],
                context);
            if (operators[k] == 'and') {
              display = display && next;
            } else {
              display = display || next;
            }
          }

          display = negateIfUnless(display);

          if (display) {
            result = renderAll(blockNodelist, context);
            break;
          }
        }
      }
    } finally {
      context.pop();
    }

    return result;
  }

  /// Hook for TagUnless: flips the result.
  bool negateIfUnless(bool display) => display;
}
