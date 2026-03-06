import '../abstract_block.dart';
import '../context.dart';

/// {% ifchanged %} ... {% endifchanged %}
/// Only renders its content if the output has changed since the last time it
/// was rendered in this context.
class TagIfchanged extends AbstractBlock {
  String _lastValue = '';

  TagIfchanged(super.markup, super.tokens, [super.fileSystem]);

  @override
  String render(Context context) {
    final output = super.render(context);
    if (output == _lastValue) return '';
    _lastValue = output;
    return output;
  }

  @override
  String blockDelimiter() => 'endifchanged';
}
