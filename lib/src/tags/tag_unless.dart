import 'tag_if.dart';

/// {% unless condition %} ... {% endunless %}
/// The inverse of `if`.
class TagUnless extends TagIf {
  TagUnless(super.markup, super.tokens, [super.fileSystem]);

  @override
  bool negateIfUnless(bool display) => !display;

  @override
  String blockDelimiter() => 'endunless';
}
