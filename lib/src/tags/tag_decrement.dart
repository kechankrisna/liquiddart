import '../abstract_tag.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';
import '../liquid_config.dart';

/// {% decrement var %}
/// Outputs a decrementing counter starting at -1 (independent of the variable
/// scope — uses environments[0]).
class TagDecrement extends AbstractTag {
  late final String _name;

  TagDecrement(super.markup, super.tokens, [super.fileSystem]) {
    final re = RegExp('(${LiquidConfig.variableName})');
    final m = re.firstMatch(markup);
    if (m == null) {
      throw ParseException(
          "Syntax Error in 'decrement' - Valid syntax: decrement [var]");
    }
    _name = m.group(0)!;
  }

  @override
  String render(Context context) {
    if (!context.environments[0].containsKey(_name)) {
      context.environments[0][_name] = context.get(_name) ?? 0;
    }
    final current = (context.environments[0][_name] as num).toInt() - 1;
    context.environments[0][_name] = current;
    return current.toString();
  }
}
