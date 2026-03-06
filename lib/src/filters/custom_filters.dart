// ignore_for_file: non_constant_identifier_names

import '../filter_provider.dart';

/// Custom filters that extend the base Liquid filter set.
/// Mirrors PHP `LiquidCustomFilters` and `CustomFilters`.
class CustomFilters implements FilterProvider {
  @override
  Map<String, Function> get filters => {
        'sort_key': sort_key,
        'zero_pad': zero_pad,
        'money': money,
        'moneyFormat': moneyFormat,
        'stringAsFixed': stringAsFixed,
        'number_format': number_format,
      };

  // ── sort_key ───────────────────────────────────────────────────────────────
  /// Sort an array of maps by the given key.
  static dynamic sort_key(dynamic input, [dynamic key]) {
    if (input is! List || key == null) return input;
    final list = [...input];
    list.sort((a, b) {
      final va = a is Map ? (a[key]?.toString() ?? '') : '';
      final vb = b is Map ? (b[key]?.toString() ?? '') : '';
      return va.compareTo(vb);
    });
    return list;
  }

  // ── zero_pad ───────────────────────────────────────────────────────────────
  /// Left-pad a number with zeros to the given width.
  static dynamic zero_pad(dynamic input, [dynamic width = 2]) {
    final w = width is num ? width.toInt() : int.tryParse(width.toString()) ?? 2;
    return input.toString().padLeft(w, '0');
  }

  // ── money ──────────────────────────────────────────────────────────────────
  /// Format a number as money with 2 decimal places and an optional currency symbol.
  static dynamic money(dynamic input, [dynamic symbol = '', dynamic decimals = 2]) {
    final d = decimals is num ? decimals.toInt() : int.tryParse(decimals.toString()) ?? 2;
    final n = _toDouble(input);
    final formatted = n.toStringAsFixed(d);
    final parts = formatted.split('.');
    final intPart = _addThousandsSeparator(parts[0]);
    final decPart = parts.length > 1 ? '.${parts[1]}' : '';
    return '${symbol ?? ''}$intPart$decPart';
  }

  // ── moneyFormat ────────────────────────────────────────────────────────────
  /// Same as `money` but always uses the provided symbol prefix.
  static dynamic moneyFormat(dynamic input, [dynamic symbol = '\$', dynamic decimals = 2]) {
    return money(input, symbol, decimals);
  }

  // ── stringAsFixed ──────────────────────────────────────────────────────────
  /// Returns a string representation of the number with [decimals] decimal places.
  static dynamic stringAsFixed(dynamic input, [dynamic decimals = 2]) {
    final d = decimals is num ? decimals.toInt() : int.tryParse(decimals.toString()) ?? 2;
    return _toDouble(input).toStringAsFixed(d);
  }

  // ── number_format ──────────────────────────────────────────────────────────
  /// Format a number with grouped thousands and a given decimal count.
  /// Mirrors PHP's `number_format($n, $decimals, '.', ',')`.
  static dynamic number_format(dynamic input, [dynamic decimals = 0]) {
    final d = decimals is num ? decimals.toInt() : int.tryParse(decimals.toString()) ?? 0;
    final n = _toDouble(input);
    final formatted = n.toStringAsFixed(d);
    final parts = formatted.split('.');
    final intPart = _addThousandsSeparator(parts[0]);
    if (d == 0) return intPart;
    final decPart = parts.length > 1 ? parts[1] : '0' * d;
    return '$intPart.$decPart';
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static String _addThousandsSeparator(String intPart) {
    final isNeg = intPart.startsWith('-');
    final digits = isNeg ? intPart.substring(1) : intPart;
    final buf = StringBuffer();
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) buf.write(',');
      buf.write(digits[i]);
      count++;
    }
    final reversed = buf.toString().split('').reversed.join();
    return isNeg ? '-$reversed' : reversed;
  }
}
