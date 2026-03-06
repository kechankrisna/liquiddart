import '../abstract_tag.dart';
import '../context.dart';

/// {% continue %}
/// Sets `registers['continue'] = true` to skip to the next loop iteration.
class TagContinue extends AbstractTag {
  TagContinue(super.markup, super.tokens, [super.fileSystem]);

  @override
  String render(Context context) {
    context.registers['continue'] = true;
    return '';
  }
}
