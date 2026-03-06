import 'abstract_tag.dart' show FileSystemInterface;
import 'cache.dart';
import 'filter_provider.dart';
import 'filters/custom_filters.dart';
import 'filters/standard_filters.dart';
import 'template.dart';

/// High-level facade for using the Liquid template engine.
///
/// Example usage:
/// ```dart
/// final engine = LiquidEngine();
/// engine.registerFilter(MyFilters());
/// final result = engine.render('Hello, {{ name }}!', assigns: {'name': 'World'});
/// print(result); // Hello, World!
/// ```
class LiquidEngine {
  final Template _template;

  LiquidEngine({FileSystemInterface? fileSystem})
      : _template = Template(fileSystem) {
    // Register built-in filter sets
    _template.registerFilter(StandardFilters());
    _template.registerFilter(CustomFilters());
  }

  /// Parse a Liquid template string. Must be called before [render].
  LiquidEngine parse(String source) {
    _template.parse(source);
    return this;
  }

  /// Render the previously parsed template with [assigns].
  ///
  /// [assigns]   — the top-level variables available in the template.
  /// [registers] — internal state (break/continue/cycle counters, etc.).
  String render({
    Map<String, dynamic> assigns = const {},
    Map<String, dynamic> registers = const {},
  }) {
    return _template.render(assigns, null, registers);
  }

  /// Parse + render in one step.
  String renderString(
    String source, {
    Map<String, dynamic> assigns = const {},
  }) {
    _template.parse(source);
    return _template.render(assigns);
  }

  /// Register an additional [FilterProvider] so its filters are available.
  LiquidEngine registerFilter(FilterProvider provider) {
    _template.registerFilter(provider);
    return this;
  }

  /// Register an individual named filter function.
  LiquidEngine registerNamedFilter(String name, Function fn) {
    _template.registerNamedFilter(name, fn);
    return this;
  }

  /// Set the global cache. All engines share the same static cache.
  static void setCache(LiquidCache? cache) => Template.setCache(cache);

  static LiquidCache? getCache() => Template.getCache();

  /// Access the underlying [Template] for advanced use.
  Template get template => _template;
}
