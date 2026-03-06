import 'abstract_block.dart';
import 'abstract_tag.dart';
import 'context.dart';
import 'tags/tag_include.dart';

/// The root document node; the result of parsing a full template source.
/// Mirrors PHP `Document`.
class Document extends AbstractBlock {
  Document(List<String?> tokens, [FileSystemInterface? fileSystem])
      : super('', tokens, fileSystem);

  /// A Document is not opened by a tag, so it never has a missing delimiter.
  @override
  void assertMissingDelimitation() {}

  /// Document has no delimiter (it's the root).
  @override
  String blockDelimiter() => '';

  /// Check whether any nodes are TagInclude instances.
  /// Used for cache invalidation.
  bool hasIncludes() {
    for (final node in nodelist) {
      if (node is TagInclude) return true;
    }
    return false;
  }

  @override
  String render(Context context) => renderAll(nodelist, context);
}
