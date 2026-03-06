import '../abstract_tag.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';
import '../variable.dart';

/// {% assign var = expr %}
class TagAssign extends AbstractTag {
  late final String _to;
  late final Variable _from;

  TagAssign(super.markup, super.tokens, [super.fileSystem]) {
    final re = RegExp(r'(\w+)\s*=\s*(.*)\s*');
    final m = re.firstMatch(markup);
    if (m == null) {
      throw ParseException(
          "Syntax Error in 'assign' - Valid syntax: assign [var] = [source]");
    }
    _to = m.group(1)!;
    _from = Variable(m.group(2)!);
  }

  @override
  String render(Context context) {
    final output = _from.render(context);
    context.set(_to, output, global: true);
    return '';
  }
}
