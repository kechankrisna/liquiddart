/// A Drop is an object that exposes a restricted interface to Liquid templates.
/// Instead of exposing all properties, a Drop explicitly declares which
/// fields/methods are accessible via `liquidMethods`.
///
/// Mirrors PHP `Drop`.
abstract class Drop {
  /// The map of property names to their values/functions for template access.
  /// Each value can be a plain value or a zero-argument function `() => value`.
  Map<String, dynamic> get liquidMethods;

  /// Invoked by Context when resolving a property on this Drop.
  dynamic invokeDrop(String name) {
    if (!liquidMethods.containsKey(name)) return null;
    final v = liquidMethods[name];
    if (v is Function) return v();
    return v;
  }

  /// Called by `Context._fetch` when the Drop is placed into a context.
  void setContext(dynamic context) {}

  @override
  String toString() => '';
}
