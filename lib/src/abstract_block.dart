import 'abstract_tag.dart';
import 'context.dart';
import 'exceptions/parse_exception.dart';
import 'liquid_config.dart';
import 'node.dart';
import 'variable.dart';

/// Abstract base for block tags (tags with matching `end*` tags).
/// Mirrors PHP `AbstractBlock`.
abstract class AbstractBlock extends AbstractTag {
  List<dynamic> nodelist = []; // String | Variable | AbstractTag

  /// Static flag: if true the next plain-text token should be ltrimmed.
  static bool trimWhitespace = false;

  AbstractBlock(super.markup, super.tokens, [super.fileSystem]);

  List<dynamic> getNodelist() => nodelist;

  /// Called immediately after [nodelist] is reset to `[]` at the start of
  /// [parse]. Subclasses can override this hook to capture the initial
  /// nodelist reference before parsing starts (e.g. `TagIf`).
  void onNodelistReset() {}

  @override
  void parse(List<String?> tokens) {
    nodelist = [];
    onNodelistReset();

    final startRe = RegExp('^${LiquidConfig.tagStart}');
    final tagRe = RegExp(
      '^${LiquidConfig.tagStart}${LiquidConfig.whitespaceControl}?\\s*(\\w+)\\s*(.*?)${LiquidConfig.whitespaceControl}?${LiquidConfig.tagEnd}\$',
      dotAll: true,
    );
    final varStartRe = RegExp('^${LiquidConfig.variableStart}');
    final varRe = RegExp(
      '^${LiquidConfig.variableStart}${LiquidConfig.whitespaceControl}?(.*?)${LiquidConfig.whitespaceControl}?${LiquidConfig.variableEnd}\$',
      dotAll: true,
    );

    for (int i = 0; i < tokens.length; i++) {
      if (tokens[i] == null) continue;
      final token = tokens[i]!;
      tokens[i] = null;

      if (startRe.hasMatch(token)) {
        _whitespaceHandler(token);
        final tagMatch = tagRe.firstMatch(token);
        if (tagMatch == null) {
          throw ParseException(
              'Tag $token was not properly terminated (won\'t match tag regexp)');
        }
        final tagName = tagMatch.group(1)!;
        final tagMarkup = tagMatch.group(2) ?? '';

        if (tagName == blockDelimiter()) {
          endTag();
          return;
        }

        // Look up tag factory from Template registry or built-in
        final factory = _Template.getTagFactory(tagName);
        if (factory != null) {
          nodelist.add(factory(tagMarkup, tokens, fileSystem));
          if (tagName == 'extends') return;
        } else {
          unknownTag(tagName, tagMarkup, tokens);
        }
      } else if (varStartRe.hasMatch(token)) {
        _whitespaceHandler(token);
        final varMatch = varRe.firstMatch(token);
        if (varMatch == null) {
          throw ParseException('Variable $token was not properly terminated');
        }
        nodelist.add(Variable(varMatch.group(1)!));
      } else {
        // plain text
        String t = token;
        if (trimWhitespace) {
          t = t.trimLeft();
        }
        trimWhitespace = false;
        nodelist.add(t);
      }
    }

    assertMissingDelimitation();
  }

  void _whitespaceHandler(String token) {
    final wc = LiquidConfig.whitespaceControl; // '-'
    // check opening whitespace control: {%- removes trailing whitespace of prev
    if (token.length > 2 && token[2] == wc) {
      if (nodelist.isNotEmpty && nodelist.last is String) {
        nodelist[nodelist.length - 1] =
            (nodelist.last as String).trimRight();
      }
    }
    // check closing whitespace control: -%} causes next text to ltrim
    trimWhitespace = token.length >= 3 && token[token.length - 3] == wc;
  }

  @override
  String render(Context context) => renderAll(nodelist, context);

  String renderAll(List<dynamic> list, Context context) {
    final buf = StringBuffer();
    for (final token in list) {
      String value;
      if (token is LiquidNode) {
        value = token.render(context);
      } else if (token is AbstractTag) {
        value = token.render(context);
      } else if (token is List) {
        value = token.map((e) => e?.toString() ?? '').join();
      } else {
        value = token?.toString() ?? '';
      }
      buf.write(value);

      if (context.registers.containsKey('break')) break;
      if (context.registers.containsKey('continue')) break;

      context.tick();
    }
    return buf.toString();
  }

  /// Called when the matching end-tag token is found. No-op by default.
  void endTag() {}

  /// Called for unexpected tags inside the block. Throws by default.
  void unknownTag(String tag, String params, List<String?> tokens) {
    switch (tag) {
      case 'else':
        throw ParseException('$_blockName does not expect else tag');
      case 'end':
        throw ParseException(
            "'end' is not a valid delimiter for $_blockName tags. Use ${blockDelimiter()}");
      default:
        throw ParseException('Unknown tag $tag');
    }
  }

  /// Called at the end of the token stream if the block was never closed.
  void assertMissingDelimitation() {
    throw ParseException('$_blockName tag was never closed');
  }

  /// The closing tag token (e.g. "endif").
  String blockDelimiter() => 'end$_blockName';

  String get _blockName =>
      runtimeType.toString().toLowerCase().replaceAll('tag', '');
}

/// Forward declaration stub so `AbstractBlock.parse()` can look up tag factories.
/// The real `Template` class sets `_Template.tagFactories` during its init.
class _Template {
  static final Map<String, AbstractTag Function(String, List<String?>, FileSystemInterface?)>
      tagFactories = {};

  static AbstractTag Function(String, List<String?>, FileSystemInterface?)?
      getTagFactory(String name) => tagFactories[name];
}

/// Public accessor for registering tag factories (called from Template).
void registerTagFactory(
    String name,
    AbstractTag Function(String markup, List<String?> tokens,
            FileSystemInterface? fs)
        factory) {
  _Template.tagFactories[name] = factory;
}
