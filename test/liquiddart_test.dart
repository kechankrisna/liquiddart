import 'package:liquiddart/liquiddart.dart';
import 'package:test/test.dart';

String render(String source, [Map<String, dynamic> assigns = const {}]) {
  return LiquidEngine().renderString(source, assigns: assigns);
}

void main() {
  // ── Variables ────────────────────────────────────────────────────────────
  group('Variables', () {
    test('plain variable', () {
      expect(render('Hello, {{ name }}!', {'name': 'World'}), 'Hello, World!');
    });

    test('dot notation', () {
      expect(render('{{ user.name }}', {
        'user': {'name': 'Alice'}
      }), 'Alice');
    });

    test('array index', () {
      expect(render('{{ list[0] }}', {'list': ['a', 'b', 'c']}), 'a');
    });

    test('null variable renders empty', () {
      expect(render('{{ missing }}'), '');
    });
  });

  // ── String filters ────────────────────────────────────────────────────────
  group('String filters', () {
    test('upcase', () => expect(render('{{ "hello" | upcase }}'), 'HELLO'));
    test('downcase', () => expect(render('{{ "HELLO" | downcase }}'), 'hello'));
    test('capitalize', () => expect(render('{{ "hello world" | capitalize }}'), 'Hello World'));
    test('strip', () => expect(render('{{ "  hi  " | strip }}'), 'hi'));
    test('append', () => expect(render('{{ "foo" | append: "bar" }}'), 'foobar'));
    test('prepend', () => expect(render('{{ "bar" | prepend: "foo" }}'), 'foobar'));
    test('replace', () => expect(render('{{ "aabbcc" | replace: "b", "x" }}'), 'aaxxcc'));
    test('replace_first', () => expect(render('{{ "aabbcc" | replace_first: "b", "x" }}'), 'aaxbcc'));
    test('remove', () => expect(render('{{ "aabbcc" | remove: "b" }}'), 'aacc'));
    test('remove_first', () => expect(render('{{ "aabbcc" | remove_first: "b" }}'), 'aabcc'));
    test('truncate', () => expect(render('{{ "hello world" | truncate: 7 }}'), 'hell...'));
    test('truncatewords', () => expect(render('{{ "one two three four" | truncatewords: 2 }}'), 'one two...'));
    test('size string', () => expect(render('{{ "hello" | size }}'), '5'));
    test('split+join', () => expect(render('{{ "a,b,c" | split: "," | join: "-" }}'), 'a-b-c'));
    test('strip_html', () => expect(render('{{ "<b>hi</b>" | strip_html }}'), 'hi'));
    test('newline_to_br', () => expect(render('{{ "a\nb" | newline_to_br }}'), 'a<br />\nb'));
    test('escape', () => expect(render('{{ "<>&" | escape }}'), '&lt;&gt;&amp;'));
    test('slice', () => expect(render('{{ "hello" | slice: 1, 3 }}'), 'ell'));
    test('slice negative', () => expect(render('{{ "hello" | slice: -3, 3 }}'), 'llo'));
    test('default', () => expect(render('{{ nil | default: "fallback" }}'), 'fallback'));
    test('default no-op on truthy', () => expect(render('{{ "x" | default: "y" }}'), 'x'));
  });

  // ── Math filters ─────────────────────────────────────────────────────────
  group('Math filters', () {
    test('plus', () => expect(render('{{ 3 | plus: 4 }}'), '7'));
    test('minus', () => expect(render('{{ 10 | minus: 3 }}'), '7'));
    test('times', () => expect(render('{{ 3 | times: 4 }}'), '12'));
    test('divided_by int', () => expect(render('{{ 10 | divided_by: 3 }}'), '3'));
    test('divided_by float', () => expect(render('{{ 10.0 | divided_by: 3.0 }}'), '${10.0 / 3.0}'));
    test('modulo', () => expect(render('{{ 10 | modulo: 3 }}'), '1'));
    test('ceil', () => expect(render('{{ 4.1 | ceil }}'), '5'));
    test('floor', () => expect(render('{{ 4.9 | floor }}'), '4'));
    test('round', () => expect(render('{{ 4.5 | round }}'), '5'));
    test('round with decimals', () => expect(render('{{ 4.567 | round: 2 }}'), '4.57'));
  });

  // ── Array filters ─────────────────────────────────────────────────────────
  group('Array filters', () {
    test('first', () => expect(render('{{ list | first }}', {'list': [1, 2, 3]}), '1'));
    test('last', () => expect(render('{{ list | last }}', {'list': [1, 2, 3]}), '3'));
    test('join', () => expect(render('{{ list | join: ", " }}', {'list': ['a', 'b', 'c']}), 'a, b, c'));
    test('reverse', () => expect(render('{{ list | reverse | join: "" }}', {'list': ['a', 'b', 'c']}), 'cba'));
    test('sort', () => expect(render('{{ list | sort | join: "" }}', {'list': ['c', 'a', 'b']}), 'abc'));
    test('size list', () => expect(render('{{ list | size }}', {'list': [1, 2, 3]}), '3'));
    test('uniq', () => expect(render('{{ list | uniq | join: "" }}', {'list': ['a', 'b', 'a']}), 'ab'));
    test('compact', () => expect(render('{{ list | compact | size }}', {'list': [1, null, 2, null]}), '2'));
    test('map', () => expect(render('{{ list | map: "name" | join: ", " }}', {
      'list': [{'name': 'Alice'}, {'name': 'Bob'}]
    }), 'Alice, Bob'));
  });

  // ── Tags: assign / capture ────────────────────────────────────────────────
  group('assign + capture', () {
    test('assign', () => expect(render('{% assign x = "hello" %}{{ x }}'), 'hello'));
    test('assign with filter', () => expect(render('{% assign x = "hello" | upcase %}{{ x }}'), 'HELLO'));
    test('capture', () => expect(render('{% capture x %}hello{% endcapture %}{{ x }}'), 'hello'));
  });

  // ── Tags: if / unless ─────────────────────────────────────────────────────
  group('if / unless', () {
    test('if true', () => expect(render('{% if x %}yes{% endif %}', {'x': true}), 'yes'));
    test('if false', () => expect(render('{% if x %}yes{% endif %}', {'x': false}), ''));
    test('if else', () => expect(render('{% if x %}yes{% else %}no{% endif %}', {'x': false}), 'no'));
    test('elsif', () => expect(render('{% if x == 1 %}one{% elsif x == 2 %}two{% else %}other{% endif %}', {'x': 2}), 'two'));
    test('unless', () => expect(render('{% unless x %}no{% endunless %}', {'x': false}), 'no'));
    test('if with and', () => expect(render('{% if a and b %}yes{% endif %}', {'a': true, 'b': true}), 'yes'));
    test('if with or', () => expect(render('{% if a or b %}yes{% endif %}', {'a': false, 'b': true}), 'yes'));
    test('if contains', () => expect(render('{% if list contains "a" %}yes{% endif %}', {'list': ['a', 'b']}), 'yes'));
  });

  // ── Tags: case ────────────────────────────────────────────────────────────
  group('case', () {
    test('case when match', () => expect(
        render('{% case x %}{% when "a" %}alpha{% when "b" %}beta{% else %}other{% endcase %}', {'x': 'a'}),
        'alpha'));
    test('case else', () => expect(
        render('{% case x %}{% when "a" %}alpha{% else %}other{% endcase %}', {'x': 'z'}),
        'other'));
  });

  // ── Tags: for ─────────────────────────────────────────────────────────────
  group('for', () {
    test('for collection', () => expect(
        render('{% for i in list %}{{ i }}{% endfor %}', {'list': [1, 2, 3]}),
        '123'));
    test('for range', () => expect(
        render('{% for i in (1..3) %}{{ i }}{% endfor %}'),
        '123'));
    test('for with limit', () => expect(
        render('{% for i in list limit: 2 %}{{ i }}{% endfor %}', {'list': [1, 2, 3]}),
        '12'));
    test('for break', () => expect(
        render('{% for i in (1..5) %}{% if i == 3 %}{% break %}{% endif %}{{ i }}{% endfor %}'),
        '12'));
    test('for continue', () => expect(
        render('{% for i in (1..4) %}{% if i == 2 %}{% continue %}{% endif %}{{ i }}{% endfor %}'),
        '134'));
    test('forloop.index', () => expect(
        render('{% for i in list %}{{ forloop.index }}{% endfor %}', {'list': ['a', 'b', 'c']}),
        '123'));
  });

  // ── Tags: comment / raw ───────────────────────────────────────────────────
  group('comment / raw', () {
    test('comment', () => expect(render('{% comment %}ignored{% endcomment %}'), ''));
    test('raw', () => expect(render('{% raw %}{{ not_rendered }}{% endraw %}'), '{{ not_rendered }}'));
  });

  // ── Tags: cycle ───────────────────────────────────────────────────────────
  group('cycle', () {
    test('basic cycle', () => expect(
        render('{% cycle "a", "b", "c" %}{% cycle "a", "b", "c" %}{% cycle "a", "b", "c" %}{% cycle "a", "b", "c" %}'),
        'abca'));
  });

  // ── Tags: increment / decrement ───────────────────────────────────────────
  group('increment / decrement', () {
    test('increment starts at 0', () => expect(
        render('{% increment x %}{% increment x %}{% increment x %}'),
        '012'));
    test('decrement starts at -1', () => expect(
        render('{% decrement x %}{% decrement x %}{% decrement x %}'),
        '-1-2-3'));
  });

  // ── Tags: ifchanged ───────────────────────────────────────────────────────
  group('ifchanged', () {
    test('only outputs when changed', () => expect(
        render('{% for i in list %}{% ifchanged %}{{ i }}{% endifchanged %}{% endfor %}', {
          'list': ['a', 'a', 'b', 'b', 'c']
        }),
        'abc'));
  });

  // ── Custom filters ────────────────────────────────────────────────────────
  group('Custom filters', () {
    test('zero_pad', () => expect(render('{{ 5 | zero_pad: 4 }}'), '0005'));
    test('number_format', () => expect(render('{{ 1234567 | number_format }}'), '1,234,567'));
    test('stringAsFixed', () => expect(render('{{ 3.14159 | stringAsFixed: 2 }}'), '3.14'));
    test('money', () => expect(render('{{ 1234.5 | money: "\$" }}'), '\$1,234.50'));
  });

  // ── LiquidEngine API ─────────────────────────────────────────────────────
  group('LiquidEngine API', () {
    test('parse then render', () {
      final e = LiquidEngine();
      e.parse('{{ x }}');
      expect(e.render(assigns: {'x': 42}), '42');
    });

    test('chained render same engine', () {
      final e = LiquidEngine();
      e.parse('{{ x }}');
      expect(e.render(assigns: {'x': 1}), '1');
      // re-parse
      e.parse('{{ y }}');
      expect(e.render(assigns: {'y': 2}), '2');
    });

    test('custom filter provider', () {
      final e = LiquidEngine();
      e.registerNamedFilter('double_it', (dynamic v) => (v is num ? v * 2 : v));
      expect(e.renderString('{{ 5 | double_it }}'), '10');
    });
  });

  // ── Drop ─────────────────────────────────────────────────────────────────
  group('Drop', () {
    test('drop property access', () {
      final drop = _PersonDrop('Alice', 30);
      expect(render('{{ p.name }} is {{ p.age }}', {'p': drop}), 'Alice is 30');
    });

    test('drop undefined property returns empty', () {
      final drop = _PersonDrop('Alice', 30);
      expect(render('{{ p.unknown }}', {'p': drop}), '');
    });
  });
}

class _PersonDrop extends Drop {
  final String _name;
  final int _age;

  _PersonDrop(this._name, this._age);

  @override
  Map<String, dynamic> get liquidMethods => {
        'name': _name,
        'age': _age,
      };
}

