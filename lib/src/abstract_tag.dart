import 'liquid_config.dart';
import 'node.dart';

/// Abstract base for all tags.
/// Mirrors PHP `AbstractTag`.
abstract class AbstractTag implements LiquidNode {
  final String markup;
  final FileSystemInterface? fileSystem;

  /// Named attributes parsed from markup (e.g. `limit: 3 offset: 1`)
  final Map<String, String> attributes = {};

  AbstractTag(this.markup, List<String?> tokens, [this.fileSystem]) {
    parse(tokens);
  }

  /// Override to consume tokens during parsing. No-op by default.
  void parse(List<String?> tokens) {}

  /// Parses `key: value` pairs from markup into [attributes].
  void extractAttributes(String m) {
    attributes.clear();
    final re = LiquidConfig.tagAttributesRegExp;
    for (final match in re.allMatches(m)) {
      final key = match.group(1);
      final val = match.group(2);
      if (key != null && val != null) {
        attributes[key] = val;
      }
    }
  }

  /// Returns the tag name (class name approach is not available in AOT Dart;
  /// subclasses that need a name should override this).
  String get name => runtimeType.toString().toLowerCase().replaceAll('tag', '');
}

/// Interface so AbstractBlock can reference a FileSystem without circular deps.
abstract class FileSystemInterface {
  String readTemplateFile(String name);
}
