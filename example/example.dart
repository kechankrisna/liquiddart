// ignore_for_file: avoid_print

/// This file demonstrates the full feature set of the liquiddart package.
///
/// Run with:
///     dart run example/example.dart
library;

import 'package:liquiddart/liquiddart.dart';

// ──────────────────────────────────────────────────────────────────────────────
// MODEL CLASSES
// ──────────────────────────────────────────────────────────────────────────────

class User {
  final String name;
  final String email;
  final bool isAdmin;
  final List<String> roles;

  User({
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.roles,
  });
}

class Product {
  final String sku;
  final String name;
  final double price;
  final int stock;
  final String category;

  Product({
    required this.sku,
    required this.name,
    required this.price,
    required this.stock,
    required this.category,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// DROP OBJECTS (safe model exposure)
// ──────────────────────────────────────────────────────────────────────────────

class UserDrop extends Drop {
  final User _user;
  UserDrop(this._user);

  @override
  Map<String, dynamic> get liquidMethods => {
        'name': _user.name,
        'email': _user.email,
        'is_admin': _user.isAdmin,
        'roles': _user.roles,
        'display_name': () => _user.name.toUpperCase(),
        'initial': () => _user.name[0],
      };
}

class ProductDrop extends Drop {
  final Product _p;
  ProductDrop(this._p);

  @override
  Map<String, dynamic> get liquidMethods => {
        'sku': _p.sku,
        'name': _p.name,
        'price': _p.price,
        'stock': _p.stock,
        'category': _p.category,
        'in_stock': _p.stock > 0,
        'display_price': () => '\$${_p.price.toStringAsFixed(2)}',
      };
}

// ──────────────────────────────────────────────────────────────────────────────
// CUSTOM FILTERS
// ──────────────────────────────────────────────────────────────────────────────

class ShopFilters implements FilterProvider {
  @override
  Map<String, Function> get filters => {
        'badge': badge,
        'tax': tax,
        'stars': stars,
        'plural': plural,
      };

  /// Wraps a value in an HTML badge span.
  static String badge(dynamic input, [dynamic cssClass = 'badge']) {
    return '<span class="$cssClass">${input ?? ''}</span>';
  }

  /// Adds tax to a numeric price at the given rate (default 10%).
  static dynamic tax(dynamic input, [dynamic rate = 0.1]) {
    final n = double.tryParse(input.toString()) ?? 0.0;
    final r = double.tryParse(rate.toString()) ?? 0.1;
    return (n * (1 + r)).toStringAsFixed(2);
  }

  /// Returns a star rating string, e.g. stars(4) → ★★★★☆
  static String stars(dynamic input, [dynamic max = 5]) {
    final score = (double.tryParse(input.toString()) ?? 0).round();
    final total = (double.tryParse(max.toString()) ?? 5).round();
    return ('★' * score.clamp(0, total)).padRight(total, '☆');
  }

  /// Returns singular or plural form based on count.
  static String plural(dynamic count, [dynamic singular = '', dynamic pluralForm = 's']) {
    final n = double.tryParse(count.toString()) ?? 0;
    return n == 1 ? '$count $singular' : '$count $singular$pluralForm';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// CUSTOM TAG
// ──────────────────────────────────────────────────────────────────────────────

/// {% highlight %}...{% endhighlight %} — wraps content in <mark> tags.
class TagHighlight extends AbstractBlock {
  TagHighlight(super.markup, super.tokens, [super.fileSystem]);

  @override
  String blockDelimiter() => 'endhighlight';

  @override
  String render(Context context) {
    return '<mark>${renderAll(nodelist, context)}</mark>';
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// HELPERS
// ──────────────────────────────────────────────────────────────────────────────

void header(String title) {
  final sep = '═' * 60;
  print('\n$sep');
  print(' $title');
  print(sep);
}

void demo(String label, String result) {
  print('  [$label]');
  print('  → $result');
}

// ──────────────────────────────────────────────────────────────────────────────
// EXAMPLES
// ──────────────────────────────────────────────────────────────────────────────

void example1BasicVariables(LiquidEngine engine) {
  header('1. Basic Variables');

  demo(
    'plain variable',
    engine.renderString('Hello, {{ name }}!', assigns: {'name': 'World'}),
  );

  demo(
    'dot notation',
    engine.renderString('{{ user.name }} ({{ user.email }})', assigns: {
      'user': {'name': 'Alice', 'email': 'alice@example.com'}
    }),
  );

  demo(
    'array index',
    engine.renderString('First: {{ items[0] }}, Last: {{ items[2] }}', assigns: {
      'items': ['apple', 'banana', 'cherry']
    }),
  );

  final emptyResult = engine.renderString('Value: {{ missing }}');
  demo(
    'null renders empty',
    '"$emptyResult',
  );
}

void example2StringFilters(LiquidEngine engine) {
  header('2. String Filters');

  demo('upcase',         engine.renderString('{{ "hello" | upcase }}'));
  demo('downcase',       engine.renderString('{{ "HELLO" | downcase }}'));
  demo('capitalize',     engine.renderString('{{ "hello world" | capitalize }}'));
  demo('strip',          engine.renderString('{{ "  hi  " | strip }}'));
  demo('truncate',       engine.renderString('{{ "The quick brown fox" | truncate: 13 }}'));
  demo('truncatewords',  engine.renderString('{{ "one two three four five" | truncatewords: 3 }}'));
  demo('replace',        engine.renderString('{{ "Hello PHP!" | replace: "PHP", "Dart" }}'));
  demo('split + join',   engine.renderString('{{ "a,b,c,d" | split: "," | join: " | " }}'));
  demo('escape',         engine.renderString('{{ "<script>alert(1)</script>" | escape }}'));
  demo('strip_html',     engine.renderString('{{ "<h1>Hello <b>World</b></h1>" | strip_html }}'));
  demo('default (nil)',  engine.renderString('{{ nil | default: "No value" }}'));
  demo('default (skip)', engine.renderString('{{ "existing" | default: "No value" }}'));
  demo('slice',          engine.renderString('{{ "Hello, World!" | slice: 7, 5 }}'));
}

void example3MathFilters(LiquidEngine engine) {
  header('3. Math Filters');

  demo('plus',        engine.renderString('{{ 10 | plus: 5 }}'));
  demo('minus',       engine.renderString('{{ 10 | minus: 3 }}'));
  demo('times',       engine.renderString('{{ 6 | times: 7 }}'));
  demo('divided_by',  engine.renderString('{{ 22 | divided_by: 7 }}'));
  demo('modulo',      engine.renderString('{{ 17 | modulo: 5 }}'));
  demo('ceil',        engine.renderString('{{ 4.2 | ceil }}'));
  demo('floor',       engine.renderString('{{ 4.8 | floor }}'));
  demo('round',       engine.renderString('{{ 3.14159 | round: 2 }}'));
  demo('chained',     engine.renderString('{{ 9.99 | times: 1.21 | round: 2 }}'));
}

void example4ArrayFilters(LiquidEngine engine) {
  header('4. Array Filters');

  final assigns = {
    'nums': [5, 3, 1, 4, 2],
    'names': ['Charlie', 'Alice', 'Bob'],
    'words': ['foo', 'bar', 'foo', 'baz', 'bar'],
    'values': [1, null, 2, null, 3],
    'products': [
      {'name': 'Widget', 'price': 9.99},
      {'name': 'Gadget', 'price': 24.99},
      {'name': 'Doohickey', 'price': 4.99},
    ],
  };

  demo('first',    engine.renderString('{{ nums | first }}', assigns: assigns));
  demo('last',     engine.renderString('{{ nums | last }}', assigns: assigns));
  demo('sort',     engine.renderString('{{ nums | sort | join: ", " }}', assigns: assigns));
  demo('reverse',  engine.renderString('{{ names | sort | reverse | join: ", " }}', assigns: assigns));
  demo('uniq',     engine.renderString('{{ words | uniq | join: ", " }}', assigns: assigns));
  demo('compact',  engine.renderString('{{ values | compact | size }} items after compact', assigns: assigns));
  demo('map',      engine.renderString('{{ products | map: "name" | join: ", " }}', assigns: assigns));
  demo('size',     engine.renderString('{{ products | size }} products', assigns: assigns));
}

void example5ControlFlow(LiquidEngine engine) {
  header('5. Control Flow');

  demo(
    'if / elsif / else',
    engine.renderString('''
{%- if score >= 90 -%}A{%- elsif score >= 80 -%}B{%- elsif score >= 70 -%}C{%- else -%}F{%- endif -%}
'''.trim(), assigns: {'score': 85}),
  );

  demo(
    'unless',
    engine.renderString(
      '{% unless logged_in %}Please sign in.{% endunless %}',
      assigns: {'logged_in': false},
    ),
  );

  demo(
    'case / when',
    engine.renderString('''
{%- case status -%}
  {%- when "active" -%}✓ Active
  {%- when "pending" -%}⏳ Pending
  {%- else -%}✗ Unknown
{%- endcase -%}''', assigns: {'status': 'pending'}),
  );

  demo(
    'if contains (string)',
    engine.renderString(
      '{% if email contains "@" %}valid{% else %}invalid{% endif %}',
      assigns: {'email': 'user@example.com'},
    ),
  );

  demo(
    'if contains (array)',
    engine.renderString(
      '{% if roles contains "admin" %}Admin access{% else %}No access{% endif %}',
      assigns: {'roles': ['editor', 'admin', 'viewer']},
    ),
  );
}

void example6ForLoop(LiquidEngine engine) {
  header('6. For Loops');

  final assigns = {
    'fruits': ['apple', 'banana', 'cherry', 'date', 'elderberry'],
    'products': [
      {'name': 'Widget', 'price': 9.99},
      {'name': 'Gadget', 'price': 24.99},
      {'name': 'Doohickey', 'price': 4.99},
    ],
  };

  demo(
    'basic for',
    engine.renderString(
      '{% for f in fruits %}{{ forloop.index }}:{{ f }} {% endfor %}',
      assigns: assigns,
    ),
  );

  demo(
    'for with limit + offset',
    engine.renderString(
      '{% for f in fruits limit: 3 offset: 1 %}{{ f }} {% endfor %}',
      assigns: assigns,
    ),
  );

  demo(
    'integer range',
    engine.renderString('{% for i in (1..5) %}{{ i }}{% unless forloop.last %},{% endunless %}{% endfor %}'),
  );

  demo(
    'forloop.first / last',
    engine.renderString('''
{%- for f in fruits -%}
  {%- if forloop.first -%}[{%- endif -%}
  {{- f -}}
  {%- if forloop.last -%}]{%- else -%},{%- endif -%}
{%- endfor -%}''', assigns: assigns),
  );

  demo(
    'for with break',
    engine.renderString(
      '{% for f in fruits %}{% if forloop.index == 3 %}{% break %}{% endif %}{{ f }} {% endfor %}',
      assigns: assigns,
    ),
  );

  demo(
    'products table',
    engine.renderString('''
{%- for p in products -%}
  {{ forloop.index }}. {{ p.name }} - \${{ p.price }}
{% endfor -%}''', assigns: assigns),
  );
}

void example7AssignCapture(LiquidEngine engine) {
  header('7. Assign & Capture');

  demo(
    'assign',
    engine.renderString('''
{%- assign greeting = "Hello" -%}
{%- assign name = "World" -%}
{{ greeting }}, {{ name }}!'''),
  );

  demo(
    'assign with filter',
    engine.renderString('''
{%- assign loud_name = "alice" | upcase | prepend: "★ " -%}
{{ loud_name }}'''),
  );

  demo(
    'capture',
    engine.renderString('''
{%- capture item_list -%}
  {%- for i in (1..3) -%}Item {{ i }}{%- unless forloop.last %}, {% endunless %}{%- endfor -%}
{%- endcapture -%}
Items: {{ item_list }}'''),
  );
}

void example8Cycle(LiquidEngine engine) {
  header('8. Cycle');

  demo(
    'row striping',
    engine.renderString('''
{%- for i in (1..6) -%}
Row {{ i }}: {% cycle "odd", "even" %}
{% endfor -%}'''),
  );

  demo(
    'named cycle',
    engine.renderString('''
{%- for i in (1..4) -%}
  col-{% cycle 'col': "1", "2", "3" %} {% endfor -%}'''),
  );
}

void example9CounterTags(LiquidEngine engine) {
  header('9. Increment & Decrement');

  demo(
    'increment',
    engine.renderString('''
{%- increment n %} {%- increment n %} {%- increment n -%}'''),
  );

  demo(
    'decrement',
    engine.renderString('''
{%- decrement n %} {%- decrement n %} {%- decrement n -%}'''),
  );

  demo(
    'independent counters',
    engine.renderString('''
{%- increment a %},{%- increment b %},{%- increment a %},{%- increment b -%}'''),
  );
}

void example10DropObjects(LiquidEngine engine) {
  header('10. Drop Objects');

  final user = UserDrop(User(
    name: 'Alice Smith',
    email: 'alice@example.com',
    isAdmin: true,
    roles: ['editor', 'admin'],
  ));

  final products = [
    ProductDrop(Product(sku: 'WGT-01', name: 'Widget', price: 9.99, stock: 42, category: 'tools')),
    ProductDrop(Product(sku: 'GDG-02', name: 'Gadget', price: 24.99, stock: 0, category: 'electronics')),
    ProductDrop(Product(sku: 'DHK-03', name: 'Doohickey', price: 4.99, stock: 7, category: 'tools')),
  ];

  demo(
    'user drop',
    engine.renderString('''
{%- if user.is_admin -%}[ADMIN] {%- endif -%}
{{ user.display_name }} <{{ user.email }}>''', assigns: {'user': user}),
  );

  demo(
    'product drops',
    engine.renderString('''
{%- for p in products -%}
  {{ p.sku }}: {{ p.name }} {{ p.display_price }}
  {%- unless p.in_stock %} [OUT OF STOCK]{% endunless %}
{% endfor -%}''', assigns: {'products': products}),
  );
}

void example11CustomFilters(LiquidEngine engine) {
  header('11. Custom Filters (ShopFilters)');

  demo('badge',  engine.renderString('{{ "New" | badge: "badge-primary" }}'));
  demo('tax',    engine.renderString('{{ 99.00 | tax: 0.1 }}'));
  demo('stars',  engine.renderString('Rating: {{ 4 | stars }}'));
  demo('plural', engine.renderString('You have {{ count | plural: "message" }}', assigns: {'count': 1}));
  demo('plural', engine.renderString('You have {{ count | plural: "message" }}', assigns: {'count': 3}));
}

void example12CustomTag(LiquidEngine engine) {
  header('12. Custom Tag: highlight');

  demo(
    'inline',
    engine.renderString('{% highlight %}important notice{% endhighlight %}'),
  );

  demo(
    'with variables',
    engine.renderString(
      '{% highlight %}{{ message | upcase }}{% endhighlight %}',
      assigns: {'message': 'warning: read this'},
    ),
  );
}

void example13Caching(LiquidEngine engine) {
  header('13. Template Caching');

  LiquidEngine.setCache(MemoryCache());

  final sw = Stopwatch()..start();

  // First parse (populates cache)
  const tmpl = '{% for i in (1..100) %}{{ i | times: 2 }} {% endfor %}';
  engine.renderString(tmpl);
  final firstMs = sw.elapsedMicroseconds;
  sw.reset();

  // Subsequent parses (cache hit)
  for (int i = 0; i < 10; i++) {
    engine.renderString(tmpl, assigns: {'x': i});
  }
  final cachedAvgUs = sw.elapsedMicroseconds / 10;

  print('  First parse: $firstMsµs');
  print('  Avg with cache: ${cachedAvgUs.toStringAsFixed(0)}µs');
  final cacheStatus = LiquidEngine.getCache() != null ? 'active' : 'inactive';
  print('  Cache is $cacheStatus');

  // Disable cache again for other examples
  LiquidEngine.setCache(null);
}

void example14WhitespaceControl(LiquidEngine engine) {
  header('14. Whitespace Control');

  demo(
    'without control',
    engine.renderString('{% if true %}\n  Hello\n{% endif %}'),
  );

  demo(
    'with {%- and -%}',
    engine.renderString('{%- if true -%}\n  Hello\n{%- endif -%}'),
  );

  demo(
    'compact list',
    engine.renderString('''
{%- for i in (1..5) -%}
  {{- i -}}
{%- endfor -%}'''),
  );
}

void example15ParseThenRender(LiquidEngine engine) {
  header('15. Parse-then-Render (Batch Rendering)');

  const template = '''
Order #{{ order_id }} for {{ customer }}
Items:
{%- for item in items %}
  - {{ item.qty }}x {{ item.name }}: \${{ item.price | times: item.qty | money }}
{%- endfor %}
Total: \${{ items | map: "price" | join: "," }}
''';

  engine.parse(template);

  final orders = [
    {
      'order_id': '1001',
      'customer': 'Alice',
      'items': [
        {'name': 'Widget', 'qty': 2, 'price': 9.99},
        {'name': 'Gadget', 'qty': 1, 'price': 24.99},
      ],
    },
    {
      'order_id': '1002',
      'customer': 'Bob',
      'items': [
        {'name': 'Doohickey', 'qty': 5, 'price': 4.99},
      ],
    },
  ];

  for (final order in orders) {
    print(engine.render(assigns: order));
    print('  ---');
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// MAIN
// ──────────────────────────────────────────────────────────────────────────────

void main() {
  // Register the custom highlight tag before creating engines
  Template.registerTag(
    'highlight',
    (markup, tokens, fs) => TagHighlight(markup, tokens, fs),
  );

  // Single engine with custom filters for most examples
  final engine = LiquidEngine()..registerFilter(ShopFilters());

  example1BasicVariables(engine);
  example2StringFilters(engine);
  example3MathFilters(engine);
  example4ArrayFilters(engine);
  example5ControlFlow(engine);
  example6ForLoop(engine);
  example7AssignCapture(engine);
  example8Cycle(engine);
  example9CounterTags(engine);
  example10DropObjects(engine);
  example11CustomFilters(engine);
  example12CustomTag(engine);
  example13Caching(engine);
  example14WhitespaceControl(engine);
  example15ParseThenRender(engine);

  print('\n${'═' * 60}');
  print(' All examples complete.');
  print('${'═' * 60}\n');
}
