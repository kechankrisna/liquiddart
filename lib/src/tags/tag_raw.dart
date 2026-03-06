import '../abstract_block.dart';
import '../liquid_config.dart';

/// {% raw %} ... {% endraw %}
/// Content is output verbatim — no parsing.
class TagRaw extends AbstractBlock {
  TagRaw(super.markup, super.tokens, [super.fileSystem]);

  @override
  void parse(List<String?> tokens) {
    nodelist = [];
    final tagRe = RegExp(
        '^${LiquidConfig.tagStart}\\s*(\\w+)\\s*(.*)?${LiquidConfig.tagEnd}\$');

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == null) continue;
      final token = tokens[i]!;
      tokens[i] = null;

      final m = tagRe.firstMatch(token);
      if (m != null && m.group(1) == blockDelimiter()) {
        break;
      }
      nodelist.add(token);
    }
  }

  @override
  String blockDelimiter() => 'endraw';
}
