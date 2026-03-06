import '../abstract_block.dart';
import '../context.dart';

/// {% comment %} ... {% endcomment %}
/// Everything inside is ignored.
class TagComment extends AbstractBlock {
  TagComment(super.markup, super.tokens, [super.fileSystem]);

  @override
  String render(Context context) => '';
}
