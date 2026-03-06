import 'exceptions/liquid_exception.dart';
import 'filterbank.dart';
import 'drop.dart';

/// Holds the variable scope stack, registers, and filter invocation.
/// Mirrors PHP `Context`.
class Context {
  /// Stack of local scopes. Index 0 is the innermost (most recent push).
  final List<Map<String, dynamic>> _assigns;

  /// Global mutable environment — used by increment/decrement etc.
  /// Index 0 is the mutable override scope; index 1 is reserved for future env.
  final List<Map<String, dynamic>> environments;

  /// Non-variable state (break, continue, for offsets, cycle counters, etc.)
  final Map<String, dynamic> registers;

  late final Filterbank _filterbank;

  Context([
    Map<String, dynamic>? assigns,
    Map<String, dynamic>? registers,
  ])  : _assigns = [if (assigns != null) Map<String, dynamic>.of(assigns) else {}],
        environments = [{}, {}],
        registers = registers != null ? Map<String, dynamic>.of(registers) : {} {
    _filterbank = Filterbank(this);
  }

  /// Add a [FilterProvider] to this context.
  void addFilters(dynamic filterProvider) {
    _filterbank.addFilter(filterProvider);
  }

  /// Register a named function as a filter.
  void addNamedFilter(String name, Function fn) {
    _filterbank.addNamedFilter(name, fn);
  }

  /// Invoke a filter by [name] on [value] with [args].
  dynamic invoke(String name, dynamic value, List<dynamic> args) {
    return _filterbank.invoke(name, value, args);
  }

  /// Push a new empty scope.
  void push([Map<String, dynamic>? scope]) {
    _assigns.insert(0, scope ?? {});
  }

  /// Pop the innermost scope.
  void pop() {
    if (_assigns.length <= 1) {
      throw LiquidException('Context: no scope to pop');
    }
    _assigns.removeAt(0);
  }

  /// Merge [newAssigns] into the current (innermost) scope.
  void merge(Map<String, dynamic> newAssigns) {
    _assigns[0].addAll(newAssigns);
  }

  /// Get a value by [key]. Handles literals, null/true/false, dot-notation.
  dynamic get(dynamic key) => resolve(key);

  /// Set [key] = [value]. If [global] is true, sets across all scopes.
  void set(String key, dynamic value, {bool global = false}) {
    if (global) {
      for (final scope in _assigns) {
        scope[key] = value;
      }
    } else {
      _assigns[0][key] = value;
    }
  }

  /// Returns true if [key] resolves to a non-null value.
  bool hasKey(String key) => resolve(key) != null;

  // ──────────────────────────────────────────────────────────────────────────
  // Internal resolution
  // ──────────────────────────────────────────────────────────────────────────

  dynamic resolve(dynamic key) {
    if (key == null || key == 'null' || key == 'nil') return null;
    if (key == 'true') return true;
    if (key == 'false') return false;
    if (key is! String) return key;

    // Single-quoted string literal
    if (key.startsWith("'") && key.endsWith("'")) {
      return key.substring(1, key.length - 1);
    }
    // Double-quoted string literal
    if (key.startsWith('"') && key.endsWith('"')) {
      return key.substring(1, key.length - 1);
    }
    // Numeric literal
    final n = num.tryParse(key);
    if (n != null) return n;

    return _variable(key);
  }

  /// Fetch [key] from environments then assigns stacks.
  dynamic _fetch(String key) {
    for (final env in environments) {
      if (env.containsKey(key)) return env[key];
    }
    for (final scope in _assigns) {
      if (scope.containsKey(key)) {
        final obj = scope[key];
        if (obj is Drop) obj.setContext(this);
        return obj;
      }
    }
    return null;
  }

  /// Resolve a potentially dot-notation / array-index key.
  dynamic _variable(String key) {
    // Replace [N] with .N
    key = key.replaceAllMapped(RegExp(r'\[(\d+)\]'), (m) => '.${m[1]}');
    // Replace [varname] with resolved value
    key = key.replaceAllMapped(RegExp(r'\[([a-zA-Z_][a-zA-Z_0-9.]*)\]'), (m) {
      final varKey = m[1] ?? '';
      final idx = get(varKey);
      if (idx != null) return '.$idx';
      return '.$varKey';
    });

    final parts = key.split('.');
    dynamic object = _fetch(parts[0]);

    for (int i = 1; i < parts.length; i++) {
      if (object == null) return null;
      final part = parts[i];

      // Drop
      if (object is Drop) {
        object.setContext(this);
        object = object.invokeDrop(part);
        continue;
      }

      // Map / plain object represented as Map
      if (object is Map) {
        if (part == 'size' && !object.containsKey('size')) {
          return object.length;
        }
        if (part == 'first' && !object.containsKey('first')) {
          if (object.isNotEmpty) return object.values.first;
          return null;
        }
        if (part == 'last' && !object.containsKey('last')) {
          if (object.isNotEmpty) return object.values.last;
          return null;
        }
        object = object[part];
        continue;
      }

      // List
      if (object is List) {
        if (part == 'size') return object.length;
        if (part == 'first') return object.isEmpty ? null : object.first;
        if (part == 'last') return object.isEmpty ? null : object.last;
        final idx = int.tryParse(part);
        if (idx != null && idx >= 0 && idx < object.length) {
          object = object[idx];
        } else {
          return null;
        }
        continue;
      }

      // String
      if (object is String) {
        if (part == 'size') return object.length;
        return null;
      }

      return null;
    }

    return object;
  }

  void Function()? _tickFunction;

  /// Register a tick function (called after each node render).
  void setTickFunction(void Function() fn) => _tickFunction = fn;

  /// Called by renderAll on each node.
  void tick() => _tickFunction?.call();
}
