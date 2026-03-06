import '../abstract_block.dart';
import '../context.dart';
import '../exceptions/parse_exception.dart';
import '../liquid_config.dart';

/// {% for item in collection %} ... {% endfor %}
/// {% for i in (1..10) %} ... {% endfor %}
class TagFor extends AbstractBlock {
  late final String _variableName;
  late final String _collectionName; // also used as end for digit range
  String? _start; // only for digit range
  late final String _name;
  bool _isDigit = false;

  TagFor(super.markup, super.tokens, [super.fileSystem]) {
    // Collection syntax: for item in collection
    final collectionRe =
        RegExp('(\\w+)\\s+in\\s+(${LiquidConfig.variableName})');
    // Digit range syntax: for i in (start..end)
    final digitRe = RegExp(
        '(\\w+)\\s+in\\s+\\((\\d+|${LiquidConfig.variableName})\\s*\\.\\.\\s*(\\d+|${LiquidConfig.variableName})\\)');

    final colMatch = collectionRe.firstMatch(markup);
    if (colMatch != null) {
      _variableName = colMatch.group(1)!;
      _collectionName = colMatch.group(2)!;
      _name = '$_variableName-$_collectionName';
      extractAttributes(markup);
    } else {
      final digitMatch = digitRe.firstMatch(markup);
      if (digitMatch != null) {
        _isDigit = true;
        _variableName = digitMatch.group(1)!;
        _start = digitMatch.group(2)!;
        _collectionName = digitMatch.group(3)!;
        _name = '$_variableName-digit';
        extractAttributes(markup);
      } else {
        throw ParseException(
            "Syntax Error in 'for loop' - Valid syntax: for [item] in [collection]");
      }
    }
  }

  @override
  String blockDelimiter() => 'endfor';

  @override
  String render(Context context) {
    context.registers.putIfAbsent('for', () => <String, dynamic>{});
    return _isDigit
        ? _renderDigit(context)
        : _renderCollection(context);
  }

  String _renderCollection(Context context) {
    dynamic raw = context.get(_collectionName);
    if (raw == null) return '';
    if (raw is! List) {
      if (raw is Map) {
        raw = raw.entries.map((e) => [e.key, e.value]).toList();
      } else {
        return '';
      }
    }
    // raw is already verified to be a List above
    // ignore: unnecessary_cast
    final List<dynamic> collection = raw as List;
    if (collection.isEmpty) return '';

    int offset = 0;
    int? limit;
    if (attributes.containsKey('offset')) {
      final ov = attributes['offset'];
      if (ov == 'continue') {
        final forRegs = context.registers['for'] as Map;
        offset = (forRegs[_name] as int?) ?? 0;
      } else {
        offset = int.tryParse(ov ?? '0') ?? 0;
      }
    }
    if (attributes.containsKey('limit')) {
      limit = int.tryParse(attributes['limit']!);
    }

    final segment = collection.skip(offset).take(limit ?? collection.length).toList();
    if (segment.isEmpty) return '';

    final forRegs = context.registers['for'] as Map;
    forRegs[_name] = offset + segment.length;

    context.push();
    final buf = StringBuffer();
    final length = segment.length;

    for (int index = 0; index < length; index++) {
      final rawKey = offset + index;
      final item = collection is List<MapEntry>
          ? segment[index]
          : (rawKey < collection.length && collection[rawKey] is! List
              ? segment[index]
              : segment[index]);

      context.set(_variableName, item);
      context.set('forloop', {
        'name': _name,
        'length': length,
        'index': index + 1,
        'index0': index,
        'rindex': length - index,
        'rindex0': length - index - 1,
        'first': index == 0,
        'last': index == length - 1,
      });

      buf.write(renderAll(nodelist, context));

      if (context.registers.containsKey('break')) {
        context.registers.remove('break');
        break;
      }
      if (context.registers.containsKey('continue')) {
        context.registers.remove('continue');
      }
    }

    context.pop();
    return buf.toString();
  }

  String _renderDigit(Context context) {
    int start;
    final rawStart = _start!;
    start = int.tryParse(rawStart) ?? (context.get(rawStart) as num?)?.toInt() ?? 0;

    int end;
    end = int.tryParse(_collectionName) ??
        (context.get(_collectionName) as num?)?.toInt() ?? 0;

    context.push();
    final buf = StringBuffer();
    final length = end - start + 1; // inclusive range: (1..5) has 5 elements

    int index = 0;
    for (int i = start; i <= end; i++) {
      context.set(_variableName, i);
      context.set('forloop', {
        'name': _name,
        'length': length,
        'index': index + 1,
        'index0': index,
        'rindex': length - index,
        'rindex0': length - index - 1,
        'first': index == 0,
        'last': index == length - 1,
      });

      buf.write(renderAll(nodelist, context));
      index++;

      if (context.registers.containsKey('break')) {
        context.registers.remove('break');
        break;
      }
      if (context.registers.containsKey('continue')) {
        context.registers.remove('continue');
      }
    }

    context.pop();
    return buf.toString();
  }
}
