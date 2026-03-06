import 'abstract_block.dart';
import 'context.dart';
import 'exceptions/render_exception.dart';
import 'liquid_config.dart';

/// Base class for conditional blocks (if / unless / case).
/// Mirrors PHP `Decision`.
abstract class Decision extends AbstractBlock {
  Decision(super.markup, super.tokens, [super.fileSystem]);

  // ── helpers ────────────────────────────────────────────────────────────────

  dynamic _stringValue(dynamic value) {
    if (value is List) return value;
    return value;
  }

  bool equalVariables(String left, String right, Context context) {
    final l = _stringValue(context.get(left));
    final r = _stringValue(context.get(right));
    return _looseEquals(l, r);
  }

  /// Evaluate a conditional expression.
  bool interpretCondition(
      String? left, String? right, String? op, Context context) {
    if (op == null) {
      // Single-value truthiness
      final v = _stringValue(context.get(left));
      return _isTruthy(v);
    }

    dynamic l, r;

    // special 'empty' keyword for arrays
    final leftVal = context.get(left);
    final rightVal = context.get(right);
    if (right == 'empty' && leftVal is List) {
      l = leftVal.length;
      r = 0;
    } else if (left == 'empty' && rightVal is List) {
      r = rightVal.length;
      l = 0;
    } else {
      l = _stringValue(leftVal);
      r = _stringValue(rightVal);
    }

    // null rules
    if (l == null || r == null) {
      if (op == '==' && l == null && r == null) return true;
      if (op == '!=' && (l != null || r != null)) return true;
      return false;
    }

    switch (op) {
      case '==':
        return _looseEquals(l, r);
      case '!=':
        return !_looseEquals(l, r);
      case '>':
        return _compare(l, r) > 0;
      case '<':
        return _compare(l, r) < 0;
      case '>=':
        return _compare(l, r) >= 0;
      case '<=':
        return _compare(l, r) <= 0;
      case 'contains':
        if (l is List) return l.contains(r);
        return l.toString().contains(r.toString());
      default:
        throw RenderException(
            "Error in tag '$name' - Unknown operator $op");
    }
  }

  // ── internals ───────────────────────────────────────────────────────────────

  static bool _isTruthy(dynamic v) {
    if (v == null || v == false) return false;
    if (v is String && v.isEmpty) return false;
    if (v is List && v.isEmpty) return false;
    return true;
  }

  static bool _looseEquals(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    // Numeric comparison
    final na = a is num ? a.toDouble() : double.tryParse(a.toString());
    final nb = b is num ? b.toDouble() : double.tryParse(b.toString());
    if (na != null && nb != null) return na == nb;
    return a.toString() == b.toString();
  }

  static int _compare(dynamic a, dynamic b) {
    final na = a is num ? a.toDouble() : double.tryParse(a.toString());
    final nb = b is num ? b.toDouble() : double.tryParse(b.toString());
    if (na != null && nb != null) return na.compareTo(nb);
    return a.toString().compareTo(b.toString());
  }
}

/// Parses a condition expression like `left op right` with optional and/or chains.
class ConditionParser {
  final String source;

  ConditionParser(this.source);

  /// Returns a list of [left, op, right] triples and a list of connectors.
  ({List<Map<String, String?>> conditions, List<String> operators}) parse() {
    final logicalRe = RegExp(r'\s+(and|or)\s+');
    final conditionalRe = RegExp(
        '(${LiquidConfig.quotedFragment})\\s*([=!<>a-z_]+)?\\s*(${LiquidConfig.quotedFragment})?');

    final operators = logicalRe
        .allMatches(source)
        .map((m) => m.group(1)!)
        .toList();

    final parts = source.split(logicalRe);
    final conditions = <Map<String, String?>>[];

    for (final part in parts) {
      final m = conditionalRe.firstMatch(part);
      if (m != null) {
        conditions.add({
          'left': m.group(1),
          'operator': m.group(2),
          'right': m.group(3),
        });
      }
    }

    return (conditions: conditions, operators: operators);
  }
}
