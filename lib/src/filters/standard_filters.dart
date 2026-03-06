// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import '../filter_provider.dart';

/// All standard Liquid filters.
/// Mirrors PHP `StandardFilters` exactly.
class StandardFilters implements FilterProvider {
  @override
  Map<String, Function> get filters => {
        // ── String ──────────────────────────────────────────────────────────
        'append': append,
        'prepend': prepend,
        'upcase': upcase,
        'downcase': downcase,
        'capitalize': capitalize,
        'strip': strip,
        'lstrip': lstrip,
        'rstrip': rstrip,
        'replace': replace,
        'replace_first': replace_first,
        'remove': remove,
        'remove_first': remove_first,
        'split': split,
        'truncate': truncate,
        'truncatewords': truncatewords,
        'slice': slice,
        'size': size,
        'escape': escape,
        'escape_once': escape_once,
        'strip_html': strip_html,
        'strip_newlines': strip_newlines,
        'newline_to_br': newline_to_br,
        'string': string,
        'raw': raw,
        'json': json,
        '_default': _default,
        'default': _default,
        // ── Math ────────────────────────────────────────────────────────────
        'plus': plus,
        'minus': minus,
        'times': times,
        'divided_by': divided_by,
        'modulo': modulo,
        'ceil': ceil,
        'floor': floor,
        'round': round,
        // ── Date ────────────────────────────────────────────────────────────
        'date': date,
        // ── Array ───────────────────────────────────────────────────────────
        'first': first,
        'last': last,
        'join': join,
        'reverse': reverse,
        'sort': sort,
        'sort_natural': sort_natural,
        'map': mapFilter,
        'where': where,
        'uniq': uniq,
        'compact': compact,
        // ── HTML/URL ────────────────────────────────────────────────────────
        'url_encode': url_encode,
        'url_decode': url_decode,
      };

  // ── String filters ─────────────────────────────────────────────────────────

  static dynamic append(dynamic input, [dynamic str = '']) =>
      '${input ?? ''}${str ?? ''}';

  static dynamic prepend(dynamic input, [dynamic str = '']) =>
      '${str ?? ''}${input ?? ''}';

  static dynamic upcase(dynamic input) =>
      input is String ? input.toUpperCase() : input;

  static dynamic downcase(dynamic input) =>
      input is String ? input.toLowerCase() : input;

  static dynamic capitalize(dynamic input) {
    if (input is! String || input.isEmpty) return input;
    // Capitalize first letter of each word
    return input.splitMapJoin(RegExp(r'\b(\w)'), onMatch: (m) => m.group(0)!.toUpperCase());
  }

  static dynamic strip(dynamic input) =>
      input is String ? input.trim() : input;

  static dynamic lstrip(dynamic input) =>
      input is String ? input.trimLeft() : input;

  static dynamic rstrip(dynamic input) =>
      input is String ? input.trimRight() : input;

  static dynamic replace(dynamic input, [dynamic pattern = '', dynamic replacement = '']) =>
      input is String
          ? input.replaceAll(pattern.toString(), replacement.toString())
          : input;

  static dynamic replace_first(dynamic input, [dynamic pattern = '', dynamic replacement = '']) {
    if (input is! String) return input;
    final idx = input.indexOf(pattern.toString());
    if (idx == -1) return input;
    return input.substring(0, idx) +
        replacement.toString() +
        input.substring(idx + pattern.toString().length);
  }

  static dynamic remove(dynamic input, [dynamic str = '']) =>
      input is String ? input.replaceAll(str.toString(), '') : input;

  static dynamic remove_first(dynamic input, [dynamic str = '']) {
    if (input is! String) return input;
    final idx = input.indexOf(str.toString());
    if (idx == -1) return input;
    return input.substring(0, idx) + input.substring(idx + str.toString().length);
  }

  static dynamic split(dynamic input, [dynamic pattern = '']) {
    if (input == null || input == '') return <String>[];
    if (input is! String) return [input.toString()];
    if (pattern == '') return input.split('').toList();
    return input.split(pattern.toString());
  }

  static dynamic truncate(dynamic input, [dynamic chars = 100, dynamic ending = '...']) {
    if (input is! String) return input;
    final limit = (chars is num ? chars.toInt() : int.tryParse(chars.toString()) ?? 100);
    final tail = ending?.toString() ?? '...';
    if (input.length <= limit) return input;
    final cutAt = (limit - tail.length).clamp(0, input.length);
    return input.substring(0, cutAt) + tail;
  }

  static dynamic truncatewords(dynamic input, [dynamic words = 3, dynamic ending = '...']) {
    if (input is! String) return input;
    final limit = (words is num ? words.toInt() : int.tryParse(words.toString()) ?? 3);
    final tail = ending?.toString() ?? '...';
    final wordList = input.split(' ');
    if (wordList.length <= limit) return input;
    return wordList.take(limit).join(' ') + tail;
  }

  static dynamic slice(dynamic input, [dynamic offset = 0, dynamic length]) {
    final off = offset is num ? offset.toInt() : int.tryParse(offset.toString()) ?? 0;
    final len = length == null
        ? null
        : (length is num ? length.toInt() : int.tryParse(length.toString()));

    if (input is List) {
      final start = off < 0 ? (input.length + off).clamp(0, input.length) : off.clamp(0, input.length);
      if (len == null) return input.sublist(start);
      return input.sublist(start, (start + len).clamp(0, input.length));
    }
    if (input is String) {
      final start = off < 0 ? (input.length + off).clamp(0, input.length) : off.clamp(0, input.length);
      if (len == null) return input.substring(start);
      final end = (start + len).clamp(0, input.length);
      return input.substring(start, end);
    }
    return input;
  }

  static dynamic size(dynamic input) {
    if (input is String) return input.length;
    if (input is List) return input.length;
    if (input is Map) return input.length;
    return 0;
  }

  static dynamic escape(dynamic input) {
    if (input == null) return '';
    if (input is List) return input;
    return input.toString()
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static dynamic escape_once(dynamic input) {
    if (input == null) return '';
    if (input is List) return input;
    // Escape only unescaped entities
    return input.toString().replaceAllMapped(
        RegExp(r'&(?!(?:#\d+|#x[\da-fA-F]+|[a-zA-Z][a-zA-Z\d]*);)'),
        (m) => '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  static dynamic strip_html(dynamic input) =>
      input is String ? input.replaceAll(RegExp(r'<[^>]+>'), '') : input;

  static dynamic strip_newlines(dynamic input) =>
      input is String ? input.replaceAll(RegExp(r'\r?\n'), '') : input;

  static dynamic newline_to_br(dynamic input) =>
      input is String ? input.replaceAll('\n', '<br />\n') : input;

  static dynamic string(dynamic input) => input?.toString() ?? '';

  static dynamic raw(dynamic input) => input;

  static dynamic json(dynamic input) => jsonEncode(input);

  static dynamic _default(dynamic input, [dynamic defaultValue = '']) {
    final isBlank = input == null || input == false || input == '';
    return isBlank ? defaultValue : input;
  }

  // ── Math filters ───────────────────────────────────────────────────────────

  static dynamic plus(dynamic input, [dynamic operand = 0]) {
    final a = _toNum(input), b = _toNum(operand);
    final result = a + b;
    // return int if both are int-like, else double
    if (result == result.truncateToDouble() && !_isFloat(input) && !_isFloat(operand)) {
      return result.toInt();
    }
    return result;
  }

  static dynamic minus(dynamic input, [dynamic operand = 0]) {
    final a = _toNum(input), b = _toNum(operand);
    final result = a - b;
    if (result == result.truncateToDouble() && !_isFloat(input) && !_isFloat(operand)) {
      return result.toInt();
    }
    return result;
  }

  static dynamic times(dynamic input, [dynamic operand = 1]) {
    final a = _toNum(input), b = _toNum(operand);
    final result = a * b;
    if (result == result.truncateToDouble() && !_isFloat(input) && !_isFloat(operand)) {
      return result.toInt();
    }
    return result;
  }

  static dynamic divided_by(dynamic input, [dynamic operand = 1]) {
    final a = _toNum(input), b = _toNum(operand);
    if (b == 0) return 0;
    final result = a / b;
    // integer division if both inputs are integers
    if (!_isFloat(input) && !_isFloat(operand)) return result.floor();
    return result;
  }

  static dynamic modulo(dynamic input, [dynamic operand = 1]) {
    final a = _toNum(input), b = _toNum(operand);
    if (b == 0) return 0;
    final result = a % b;
    if (result == result.truncateToDouble() && !_isFloat(input) && !_isFloat(operand)) {
      return result.toInt();
    }
    return result;
  }

  static dynamic ceil(dynamic input) => _toNum(input).ceil();

  static dynamic floor(dynamic input) => _toNum(input).floor();

  static dynamic round(dynamic input, [dynamic decimals = 0]) {
    final n = _toNum(input);
    final d = decimals is num ? decimals.toInt() : int.tryParse(decimals.toString()) ?? 0;
    if (d == 0) return n.round();
    final factor = _pow10(d);
    return (n * factor).round() / factor;
  }

  // ── Date filter ────────────────────────────────────────────────────────────

  /// Formats a date/time value using strftime-style format codes.
  /// [input] can be `"now"`, a Unix timestamp (int), or an ISO-8601 string.
  static dynamic date(dynamic input, [dynamic fmt]) {
    if (fmt == null || fmt.toString().isEmpty) return input?.toString() ?? '';

    DateTime? dt;
    if (input == 'now' || input == 'today') {
      dt = DateTime.now();
    } else if (input is int || input is double) {
      dt = DateTime.fromMillisecondsSinceEpoch(
          (_toNum(input) * 1000).toInt());
    } else if (input is String) {
      dt = DateTime.tryParse(input) ?? DateTime.tryParse(input.replaceAll(' ', 'T'));
    } else if (input is DateTime) {
      dt = input;
    }

    if (dt == null) return input?.toString() ?? '';

    return _strftime(fmt.toString(), dt);
  }

  /// Minimal strftime implementation mapping common codes to Dart DateTime.
  static String _strftime(String format, DateTime dt) {
    String pad(int n, [int width = 2]) => n.toString().padLeft(width, '0');
    const months = ['','January','February','March','April','May','June',
        'July','August','September','October','November','December'];
    const monthsAbbr = ['','Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'];
    const weekdays = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    const weekdaysAbbr = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];

    final buf = StringBuffer();
    int i = 0;
    while (i < format.length) {
      if (format[i] == '%' && i + 1 < format.length) {
        i++;
        switch (format[i]) {
          case 'Y': buf.write(dt.year.toString().padLeft(4, '0')); break;
          case 'y': buf.write(pad(dt.year % 100)); break;
          case 'm': buf.write(pad(dt.month)); break;
          case 'B': buf.write(months[dt.month]); break;
          case 'b': case 'h': buf.write(monthsAbbr[dt.month]); break;
          case 'd': buf.write(pad(dt.day)); break;
          case 'e': buf.write(dt.day.toString()); break;
          case 'j': // day of year
            final start = DateTime(dt.year, 1, 1);
            buf.write(pad(dt.difference(start).inDays + 1, 3));
            break;
          case 'A': buf.write(weekdays[dt.weekday - 1]); break;
          case 'a': buf.write(weekdaysAbbr[dt.weekday - 1]); break;
          case 'H': buf.write(pad(dt.hour)); break;
          case 'k': buf.write(dt.hour.toString()); break;
          case 'I': buf.write(pad(dt.hour % 12 == 0 ? 12 : dt.hour % 12)); break;
          case 'l': buf.write((dt.hour % 12 == 0 ? 12 : dt.hour % 12).toString()); break;
          case 'M': buf.write(pad(dt.minute)); break;
          case 'S': buf.write(pad(dt.second)); break;
          case 'p': buf.write(dt.hour < 12 ? 'AM' : 'PM'); break;
          case 'P': buf.write(dt.hour < 12 ? 'am' : 'pm'); break;
          case 'u': buf.write(dt.weekday.toString()); break; // 1=Mon
          case 'w': buf.write((dt.weekday % 7).toString()); break; // 0=Sun
          case 'W': // week of year (Monday-based)
            final jan1 = DateTime(dt.year, 1, 1);
            final week = ((dt.difference(jan1).inDays + jan1.weekday - 1) / 7).floor() + 1;
            buf.write(pad(week));
            break;
          case 'D': // mm/dd/yy
            buf.write('${pad(dt.month)}/${pad(dt.day)}/${pad(dt.year % 100)}');
            break;
          case 'F': // YYYY-MM-DD
            buf.write('${dt.year.toString().padLeft(4, '0')}-${pad(dt.month)}-${pad(dt.day)}');
            break;
          case 'x': // locale date (use YYYY-MM-DD)
            buf.write('${pad(dt.month)}/${pad(dt.day)}/${pad(dt.year % 100)}');
            break;
          case 'T': // HH:MM:SS
            buf.write('${pad(dt.hour)}:${pad(dt.minute)}:${pad(dt.second)}');
            break;
          case 'R': // HH:MM
            buf.write('${pad(dt.hour)}:${pad(dt.minute)}');
            break;
          case 'r': // 12-hour clock
            final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
            buf.write('${pad(h)}:${pad(dt.minute)}:${pad(dt.second)} ${dt.hour < 12 ? 'AM' : 'PM'}');
            break;
          case 's': buf.write(dt.millisecondsSinceEpoch ~/ 1000); break;
          case 'n': buf.write('\n'); break;
          case 't': buf.write('\t'); break;
          case 'z': // timezone offset
            final offset = dt.timeZoneOffset;
            final sign = offset.isNegative ? '-' : '+';
            final hours = offset.inHours.abs();
            final mins = (offset.inMinutes.abs()) % 60;
            buf.write('$sign${pad(hours)}${pad(mins)}');
            break;
          case 'Z': buf.write(dt.timeZoneName); break;
          case 'c': // full date/time
            buf.write(dt.toString());
            break;
          case '%': buf.write('%'); break;
          default: buf.write('%${format[i]}');
        }
      } else {
        buf.write(format[i]);
      }
      i++;
    }
    return buf.toString();
  }

  // ── Array filters ──────────────────────────────────────────────────────────

  static dynamic first(dynamic input) {
    if (input is List) return input.isEmpty ? null : input.first;
    if (input is Map) return input.isEmpty ? null : input.values.first;
    if (input is String) return input.isEmpty ? null : input[0];
    return null;
  }

  static dynamic last(dynamic input) {
    if (input is List) return input.isEmpty ? null : input.last;
    if (input is Map) return input.isEmpty ? null : input.values.last;
    if (input is String) return input.isEmpty ? null : input[input.length - 1];
    return null;
  }

  static dynamic join(dynamic input, [dynamic glue = ' ']) {
    if (input is! List) return input?.toString() ?? '';
    return input.map((e) => e?.toString() ?? '').join(glue?.toString() ?? ' ');
  }

  static dynamic reverse(dynamic input) {
    if (input is List) return input.reversed.toList();
    if (input is String) return String.fromCharCodes(input.runes.toList().reversed);
    return input;
  }

  static dynamic sort(dynamic input, [dynamic property]) {
    if (input is! List) return input;
    final list = [...input];
    if (property == null) {
      list.sort((a, b) {
        if (a == null && b == null) return 0;
        if (a == null) return -1;
        if (b == null) return 1;
        return a.toString().compareTo(b.toString());
      });
    } else {
      list.sort((a, b) {
        final va = (a is Map ? a[property] : null)?.toString() ?? '';
        final vb = (b is Map ? b[property] : null)?.toString() ?? '';
        return va.compareTo(vb);
      });
    }
    return list;
  }

  static dynamic sort_natural(dynamic input, [dynamic property]) {
    if (input is! List) return input;
    final list = [...input];
    if (property == null) {
      list.sort((a, b) => (a?.toString() ?? '').toLowerCase()
          .compareTo((b?.toString() ?? '').toLowerCase()));
    } else {
      list.sort((a, b) {
        final va = (a is Map ? a[property] : null)?.toString().toLowerCase() ?? '';
        final vb = (b is Map ? b[property] : null)?.toString().toLowerCase() ?? '';
        return va.compareTo(vb);
      });
    }
    return list;
  }

  static dynamic mapFilter(dynamic input, [dynamic property]) {
    if (input is! List || property == null) return input;
    return input.map((e) => e is Map ? e[property] : null).toList();
  }

  static dynamic where(dynamic input, [dynamic prop, dynamic value]) {
    if (input is! List) return input;
    if (prop == null) return input;
    if (value == null) {
      // 1-arg: keep items where property is truthy
      return input.where((item) {
        if (item is Map) {
          final v = item[prop];
          return v != null && v != false && v != '';
        }
        return false;
      }).toList();
    }
    // 2-arg: keep items where property == value
    return input.where((item) {
      if (item is Map) return item[prop]?.toString() == value?.toString();
      return false;
    }).toList();
  }

  static dynamic uniq(dynamic input) {
    if (input is! List) return input;
    final seen = <dynamic>[];
    final result = <dynamic>[];
    for (final item in input) {
      if (!seen.contains(item)) {
        seen.add(item);
        result.add(item);
      }
    }
    return result;
  }

  static dynamic compact(dynamic input) {
    if (input is! List) return input;
    return input.where((e) => e != null).toList();
  }

  // ── URL ────────────────────────────────────────────────────────────────────

  static dynamic url_encode(dynamic input) =>
      input is String ? Uri.encodeQueryComponent(input) : input;

  static dynamic url_decode(dynamic input) =>
      input is String ? Uri.decodeQueryComponent(input) : input;

  // ── Internal helpers ───────────────────────────────────────────────────────

  static double _toNum(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static bool _isFloat(dynamic v) {
    if (v is double) return true;
    if (v is String && v.contains('.')) return true;
    return false;
  }

  static double _pow10(int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
