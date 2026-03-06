import '../abstract_tag.dart';
import '../context.dart';

/// {% break %}
/// Sets `registers['break'] = true` to exit a for loop.
class TagBreak extends AbstractTag {
  TagBreak(super.markup, super.tokens, [super.fileSystem]);

  @override
  String render(Context context) {
    context.registers['break'] = true;
    return '';
  }
}
