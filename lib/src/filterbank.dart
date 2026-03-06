import 'context.dart';
import 'exceptions/wrong_argument_exception.dart';
import 'filters/standard_filters.dart';
import 'filters/custom_filters.dart';

/// Holds all registered filters and dispatches filter invocations.
/// Mirrors PHP `Filterbank`.
class Filterbank {
  /// Maps filter name → callable Function(dynamic value, ...args)
  final Map<String, Function> _methodMap = {};

  Filterbank(Context _) {
    addFilter(StandardFilters());
    addFilter(CustomFilters());
  }

  /// Register a [FilterProvider] object — calls `.filters` getter for the map.
  void addFilter(dynamic provider) {
    if (provider == null) return;

    // If it provides a filters map (FilterProvider interface)
    try {
      final Map<String, Function> map = (provider as dynamic).filters as Map<String, Function>;
      _methodMap.addAll(map);
      return;
    } catch (_) {}

    throw WrongArgumentException(
        'addFilter: provider must implement FilterProvider (expose a `Map<String, Function> get filters`)');
  }

  /// Register a single named function as a filter.
  void addNamedFilter(String name, Function fn) {
    _methodMap[name] = fn;
  }

  /// Invoke filter [name] on [value] with positional [args].
  /// Returns [value] unchanged if no matching filter is found.
  dynamic invoke(String name, dynamic value, List<dynamic> args) {
    // PHP special-case: 'default' → '_default'
    final resolvedName = name == 'default' ? '_default' : name;

    final fn = _methodMap[resolvedName];
    if (fn == null) return value;

    try {
      switch (args.length) {
        case 0:
          return fn(value);
        case 1:
          return fn(value, args[0]);
        case 2:
          return fn(value, args[0], args[1]);
        case 3:
          return fn(value, args[0], args[1], args[2]);
        case 4:
          return fn(value, args[0], args[1], args[2], args[3]);
        default:
          return Function.apply(fn, [value, ...args]);
      }
    } catch (_) {
      return value;
    }
  }
}
