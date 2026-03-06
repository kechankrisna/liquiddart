import '../abstract_block.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';

/// {% capture foo %} ... {% endcapture %}
class TagCapture extends AbstractBlock {
  late final String _to;

  TagCapture(super.markup, super.tokens, [super.fileSystem]) {
    final re = RegExp(r'(\w+)');
    final m = re.firstMatch(markup);
    if (m == null) {
      throw ParseException(
          "Syntax Error in 'capture' - Valid syntax: capture [var] [value]");
    }
    _to = m.group(1)!;
  }

  @override
  String render(Context context) {
    final output = super.render(context);
    context.set(_to, output, global: true);
    return '';
  }
}
