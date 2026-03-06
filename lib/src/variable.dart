import 'context.dart';
import 'node.dart';

/// Represents a single `{{ variable | filter: arg | filter2 }}` output node.
class Variable implements LiquidNode {
  final String _name;
  // List of [filterName, [arg1, arg2, ...]]
  final List<(String, List<dynamic>)> _filters;

  Variable._(this._name, this._filters);

  factory Variable(String markup) {
    markup = markup.trim();

    // Split on | but not inside quotes
    final parts = _splitOnPipe(markup);

    final name = parts.first.trim();
    final filters = <(String, List<dynamic>)>[];

    for (int i = 1; i < parts.length; i++) {
      final filterMarkup = parts[i].trim();
      if (filterMarkup.isEmpty) continue;

      // Parse filter name and args: filterName: arg1, arg2
      final colonIdx = filterMarkup.indexOf(':');
      String filterName;
      List<dynamic> args;

      if (colonIdx == -1) {
        filterName = filterMarkup.trim();
        args = [];
      } else {
        filterName = filterMarkup.substring(0, colonIdx).trim();
        final argString = filterMarkup.substring(colonIdx + 1);
        args = _parseArgs(argString);
      }

      filters.add((filterName.toLowerCase() == 'default'
          ? '_default'
          : filterName, args));
    }

    return Variable._(name, filters);
  }

  String get name => _name;
  List<(String, List<dynamic>)> get filters => _filters;

  @override
  String render(Context context) {
    dynamic output = context.get(_name);

    for (final (filterName, args) in _filters) {
      // Resolve any variable args
      final resolvedArgs = args.map((a) {
        if (a is String && !_isLiteral(a)) return context.get(a) ?? a;
        return _resolveLiteral(a);
      }).toList();
      output = context.invoke(filterName, output, resolvedArgs);
    }

    if (output == null) return '';
    if (output is bool) return output ? 'true' : 'false';
    return output.toString();
  }

  /// Split markup on `|` while respecting single and double quotes.
  static List<String> _splitOnPipe(String markup) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inSingle = false, inDouble = false;

    for (int i = 0; i < markup.length; i++) {
      final ch = markup[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
        buf.write(ch);
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
        buf.write(ch);
      } else if (ch == '|' && !inSingle && !inDouble) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  /// Parse comma-separated args from a filter argument string.
  static List<dynamic> _parseArgs(String argString) {
    final args = <dynamic>[];
    final parts = _splitOnComma(argString);
    for (final part in parts) {
      final trimmed = part.trim();
      if (trimmed.isNotEmpty) {
        args.add(trimmed);
      }
    }
    return args;
  }

  static List<String> _splitOnComma(String s) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inSingle = false, inDouble = false;

    for (int i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == "'" && !inDouble) {
        inSingle = !inSingle;
        buf.write(ch);
      } else if (ch == '"' && !inSingle) {
        inDouble = !inDouble;
        buf.write(ch);
      } else if (ch == ',' && !inSingle && !inDouble) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  static bool _isLiteral(String s) {
    if ((s.startsWith('"') && s.endsWith('"')) ||
        (s.startsWith("'") && s.endsWith("'"))) {
      return true;
    }
    if (s == 'true' || s == 'false' || s == 'null' || s == 'nil') {
      return true;
    }
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(s)) {
      return true;
    }
    return false;
  }

  static dynamic _resolveLiteral(dynamic val) {
    if (val is! String) return val;
    if ((val.startsWith('"') && val.endsWith('"')) ||
        (val.startsWith("'") && val.endsWith("'"))) {
      return val.substring(1, val.length - 1);
    }
    if (val == 'true') return true;
    if (val == 'false') return false;
    if (val == 'null' || val == 'nil') return null;
    final n = num.tryParse(val);
    if (n != null) return n;
    return val;
  }
}
