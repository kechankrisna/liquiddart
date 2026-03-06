import '../abstract_tag.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';
import '../liquid_config.dart';

/// {% include 'template_name' %}
/// {% include 'template_name' with variable %}
/// {% include 'template_name' for collection %}
///
/// Loads a sub-template from the file system and renders it.
class TagInclude extends AbstractTag {
  late final String _templateName;
  String? _variable; // the with/for variable expression
  bool _collection = false; // true → for loop mode

  /// The parsed sub-document — set during parse()
  dynamic _document; // Document (declared dynamic to avoid a circular import)

  TagInclude(super.markup, super.tokens, [super.fileSystem]);

  @override
  void parse(List<String?> tokens) {
    if (fileSystem == null) {
      throw ParseException(
          "No file system available for 'include' tag");
    }

    final re = RegExp(
        '("[^"]+"|\'[^\']+\'|[^\'"\\s]+)(\\s+(with|for)\\s+(${LiquidConfig.quotedFragment}+))?');
    final m = re.firstMatch(markup);
    if (m == null) {
      throw ParseException(
          "Error in tag 'include' - Valid syntax: include '[template]' (with|for) [object|collection]");
    }

    final raw = m.group(1)!;
    final isUnquoted = !raw.startsWith('"') && !raw.startsWith("'");
    _templateName =
        isUnquoted ? raw : raw.substring(1, raw.length - 1);

    if (m.group(3) != null) {
      _collection = m.group(3) == 'for';
      _variable = m.group(4);
    }

    extractAttributes(markup);

    // Read + tokenize the sub-template
    final source = fileSystem!.readTemplateFile(_templateName);
    _document = _buildDocument(source);
  }

  /// Uses the global Template tokeniser + Document constructor.
  /// We store a closure so we don't get a circular import with Template.
  static dynamic Function(String source)? _documentBuilder;

  static void setDocumentBuilder(dynamic Function(String) builder) {
    _documentBuilder = builder;
  }

  dynamic _buildDocument(String source) {
    if (_documentBuilder != null) return _documentBuilder!(source);
    throw ParseException(
        'TagInclude: no document builder registered. '
        'Call TagInclude.setDocumentBuilder() before rendering templates with includes.');
  }

  @override
  String render(Context context) {
    if (_document == null) return '';

    final variable = _variable != null ? context.get(_variable!) : null;

    context.push();

    // Apply with attributes
    for (final entry in attributes.entries) {
      context.set(entry.key, context.get(entry.value));
    }

    var result = '';
    if (_collection && variable is List) {
      for (final item in variable) {
        context.set(_templateName, item);
        result += (_document as dynamic).render(context) as String;
      }
    } else {
      if (_variable != null) {
        context.set(_templateName, variable);
      }
      result = (_document as dynamic).render(context) as String;
    }

    context.pop();
    return result;
  }
}
