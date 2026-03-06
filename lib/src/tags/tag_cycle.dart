import '../abstract_tag.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';
import '../liquid_config.dart';

/// {% cycle "one", "two", "three" %}
/// {% cycle "group": "one", "two" %}
class TagCycle extends AbstractTag {
  late final String _name;
  late final List<String> _variables;

  TagCycle(super.markup, super.tokens, [super.fileSystem]) {
    final namedRe = RegExp(
        '(${LiquidConfig.quotedFragment})\\s*:\\s*(.*)');
    final simpleRe = RegExp(LiquidConfig.quotedFragment);

    final namedMatch = namedRe.firstMatch(markup);
    if (namedMatch != null) {
      _variables = _variablesFromString(namedMatch.group(2)!);
      _name = namedMatch.group(1)!;
    } else if (simpleRe.hasMatch(markup)) {
      _variables = _variablesFromString(markup);
      _name = "'${_variables.join('')}'";
    } else {
      throw ParseException(
          "Syntax Error in 'cycle' - Valid syntax: cycle [name :] var [, var2, var3 ...]");
    }
  }

  List<String> _variablesFromString(String markup) {
    final re = RegExp('\\s*(${LiquidConfig.quotedFragment})\\s*');
    return markup.split(',').map((part) {
      final m = re.firstMatch(part);
      return m?.group(1) ?? part.trim();
    }).where((s) => s.isNotEmpty).toList();
  }

  @override
  String render(Context context) {
    context.push();

    final key = context.resolve(_name)?.toString() ?? _name;

    final cycleRegs = context.registers.putIfAbsent('cycle', () => <dynamic, int>{}) as Map;
    final iteration = (cycleRegs[key] as int?) ?? 0;

    final result = context.resolve(_variables[iteration])?.toString() ?? '';

    cycleRegs[key] = (iteration + 1) % _variables.length;

    context.pop();
    return result;
  }
}
