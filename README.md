# liquiddart

A faithful **Dart port of the PHP [`liquid/liquid`](https://github.com/kalimatas/php-liquid) v1.4** template engine — the same engine behind Shopify's Liquid templating language.

Works in **Flutter**, **Dart CLI**, and **web** (no `dart:io` dependency in the core library).

---

## Features

- Full Liquid syntax: `{{ variables }}`, `{% tags %}`, filters
- **15 built-in tags:** `assign`, `capture`, `comment`, `raw`, `if`, `unless`, `case`, `for`, `cycle`, `break`, `continue`, `increment`, `decrement`, `ifchanged`, `include`
- **45+ standard filters:** string, math, array, date, URL
- **Custom filters** via the `FilterProvider` interface (AOT-safe, no reflection)
- **Drop objects** for safe model exposure to templates
- **Template caching** with pluggable `LiquidCache`
- **Whitespace control** (`{%-` / `-%}`)
- **Custom tags** via `Template.registerTag`

---

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  liquiddart:
    path: ../liquiddart   # or publish to pub.dev and use: liquiddart: ^1.0.0
```

Then import:

```dart
import 'package:liquiddart/liquiddart.dart';
```

---

## Quick Start

```dart
import 'package:liquiddart/liquiddart.dart';

void main() {
  final engine = LiquidEngine();

  final output = engine.renderString(
    'Hello, {{ name | upcase }}! You have {{ count }} messages.',
    assigns: {
      'name': 'alice',
      'count': 3,
    },
  );

  print(output); // Hello, ALICE! You have 3 messages.
}
```

---

## Template Syntax

### Variables

```liquid
{{ variable }}
{{ user.name }}
{{ list[0] }}
{{ product.price | money: "$" }}
```

### Filters

Filters are chained with `|`:

```liquid
{{ "hello world" | capitalize }}          → Hello World
{{ price | times: 1.2 | round: 2 }}       → calculated price
{{ items | sort | join: ", " }}            → sorted, joined list
{{ "2026-03-06" | date: "%B %d, %Y" }}    → March 06, 2026
```

### Tags

#### assign / capture

```liquid
{% assign greeting = "Hello" %}
{{ greeting }}, world!

{% capture full_name %}{{ first }} {{ last }}{% endcapture %}
Welcome, {{ full_name }}!
```

#### if / unless / elsif / else

```liquid
{% if user.admin %}
  Welcome, admin.
{% elsif user.member %}
  Welcome, member.
{% else %}
  Please sign in.
{% endif %}

{% unless cart.empty %}
  You have {{ cart.count }} items.
{% endunless %}
```

#### case / when

```liquid
{% case status %}
  {% when "active" %}  Account is active.
  {% when "pending" %} Awaiting activation.
  {% else %}           Unknown status.
{% endcase %}
```

#### for

```liquid
{% for product in products %}
  {{ forloop.index }}. {{ product.name }}
{% endfor %}

{% for i in (1..5) %}{{ i }} {% endfor %}    → 1 2 3 4 5

{% for item in list limit: 3 offset: 1 %}
  {{ item }}
{% endfor %}
```

`forloop` variables: `index`, `index0`, `rindex`, `rindex0`, `first`, `last`, `length`.

#### cycle

```liquid
{% for item in items %}
  <tr class="{% cycle 'odd', 'even' %}">...</tr>
{% endfor %}
```

#### increment / decrement

```liquid
{% increment counter %}   → 0
{% increment counter %}   → 1
{% decrement counter %}   → -1
```

#### comment / raw

```liquid
{% comment %}This is not rendered{% endcomment %}

{% raw %}{{ not_processed }}{% endraw %}
```

#### ifchanged

```liquid
{% for item in items %}
  {% ifchanged %}{{ item.category }}{% endifchanged %}
  {{ item.name }}
{% endfor %}
```

---

## All Standard Filters

### String

| Filter | Example | Output |
|--------|---------|--------|
| `upcase` | `"hello" \| upcase` | `HELLO` |
| `downcase` | `"HELLO" \| downcase` | `hello` |
| `capitalize` | `"hello world" \| capitalize` | `Hello World` |
| `strip` | `"  hi  " \| strip` | `hi` |
| `lstrip` / `rstrip` | `"  hi  " \| lstrip` | `hi  ` |
| `append` | `"foo" \| append: "bar"` | `foobar` |
| `prepend` | `"bar" \| prepend: "foo"` | `foobar` |
| `replace` | `"aabb" \| replace: "b","x"` | `aaxx` |
| `replace_first` | `"aabb" \| replace_first: "b","x"` | `aaxb` |
| `remove` | `"aabb" \| remove: "b"` | `aa` |
| `remove_first` | `"aabb" \| remove_first: "b"` | `aab` |
| `truncate` | `"hello world" \| truncate: 7` | `hell...` |
| `truncatewords` | `"one two three" \| truncatewords: 2` | `one two...` |
| `split` | `"a,b,c" \| split: ","` | `['a','b','c']` |
| `size` | `"hello" \| size` | `5` |
| `slice` | `"hello" \| slice: 1, 3` | `ell` |
| `escape` | `"<b>" \| escape` | `&lt;b&gt;` |
| `escape_once` | already-escaped input | idempotent escape |
| `strip_html` | `"<b>hi</b>" \| strip_html` | `hi` |
| `strip_newlines` | removes `\n` | |
| `newline_to_br` | `\n` → `<br />\n` | |
| `url_encode` | `"a b" \| url_encode` | `a+b` |
| `url_decode` | `"a+b" \| url_decode` | `a b` |
| `default` | `nil \| default: "n/a"` | `n/a` |
| `json` | `obj \| json` | JSON string |

### Math

| Filter | Example | Output |
|--------|---------|--------|
| `plus` | `3 \| plus: 4` | `7` |
| `minus` | `10 \| minus: 3` | `7` |
| `times` | `3 \| times: 4` | `12` |
| `divided_by` | `10 \| divided_by: 3` | `3` (integer) |
| `modulo` | `10 \| modulo: 3` | `1` |
| `ceil` | `4.1 \| ceil` | `5` |
| `floor` | `4.9 \| floor` | `4` |
| `round` | `4.567 \| round: 2` | `4.57` |

### Array

| Filter | Example |
|--------|---------|
| `first` / `last` | first/last element |
| `join` | `list \| join: ", "` |
| `reverse` | reversed list |
| `sort` / `sort_natural` | sorted list |
| `map` | `list \| map: "name"` — pluck a key |
| `where` | `list \| where: "active", true` — filter by key/value |
| `uniq` | deduplicate |
| `compact` | remove nulls |
| `size` | list length |

### Date

```liquid
{{ "now" | date: "%Y-%m-%d" }}          → 2026-03-06
{{ order.created_at | date: "%B %d" }}  → March 06
```

Supported codes: `%Y %m %d %H %M %S %A %a %B %b %p %I %e %j %Z` and more.

---

## Custom Filters

Implement `FilterProvider` and pass it to the engine:

```dart
import 'package:liquiddart/liquiddart.dart';

class AppFilters implements FilterProvider {
  @override
  Map<String, Function> get filters => {
    'shout':   shout,
    'tax':     tax,
    'kh_date': khDate,
  };

  static String shout(dynamic input) => '${input ?? ''}!!!';

  static dynamic tax(dynamic input, [dynamic rate = 0.1]) {
    final n = double.tryParse(input.toString()) ?? 0.0;
    final r = double.tryParse(rate.toString()) ?? 0.1;
    return (n * (1 + r)).toStringAsFixed(2);
  }

  static String khDate(dynamic input) {
    // Custom Khmer date formatting example
    return input.toString();
  }
}

void main() {
  final engine = LiquidEngine()..registerFilter(AppFilters());
  print(engine.renderString('{{ "hello" | shout }}')); // hello!!!
  print(engine.renderString('{{ 100 | tax: 0.1 }}'));  // 110.00
}
```

---

## Drop Objects

Expose Dart model objects to templates without leaking internal state:

```dart
import 'package:liquiddart/liquiddart.dart';

class Product {
  final String name;
  final double price;
  Product(this.name, this.price);
}

class ProductDrop extends Drop {
  final Product _p;
  ProductDrop(this._p);

  @override
  Map<String, dynamic> get liquidMethods => {
    'name':          _p.name,
    'price':         _p.price,
    'display_price': () => '\$${_p.price.toStringAsFixed(2)}',
  };
}

void main() {
  final engine = LiquidEngine();
  final output = engine.renderString(
    '{{ product.name }}: {{ product.display_price }}',
    assigns: {'product': ProductDrop(Product('Widget', 9.99))},
  );
  print(output); // Widget: $9.99
}
```

---

## Template Caching

Re-use parsed `Document` trees across renders:

```dart
// Enable globally (all LiquidEngine instances share the cache)
LiquidEngine.setCache(MemoryCache());

final engine = LiquidEngine();

// First call: parses and caches
engine.renderString('Hello, {{ name }}!', assigns: {'name': 'Alice'});

// Subsequent calls with the same source: uses cache
engine.renderString('Hello, {{ name }}!', assigns: {'name': 'Bob'});
```

---

## Custom Tags

```dart
import 'package:liquiddart/liquiddart.dart';

class TagHighlight extends AbstractBlock {
  TagHighlight(super.markup, super.tokens, [super.fileSystem]);

  @override
  String blockDelimiter() => 'endhighlight';

  @override
  String render(Context context) {
    final inner = renderAll(nodelist, context);
    return '<mark>$inner</mark>';
  }
}

void main() {
  Template.registerTag(
    'highlight',
    (markup, tokens, fs) => TagHighlight(markup, tokens, fs),
  );

  final engine = LiquidEngine();
  print(engine.renderString(
    '{% highlight %}important{% endhighlight %}',
  )); // <mark>important</mark>
}
```

---

## Parse-then-Render Pattern

For repeated rendering of the same template with different data:

```dart
final engine = LiquidEngine()..parse('Hello, {{ name }}!');

for (final name in ['Alice', 'Bob', 'Charlie']) {
  print(engine.render(assigns: {'name': name}));
}
```

---

## Template Includes

Provide a `FileSystemInterface` to use `{% include %}`:

```dart
import 'dart:io';
import 'package:liquiddart/liquiddart.dart';

class DiskFileSystem implements FileSystemInterface {
  final String root;
  DiskFileSystem(this.root);

  @override
  String readTemplateFile(String name) {
    final file = File('$root/_$name.liquid');
    return file.readAsStringSync();
  }
}

void main() {
  final engine = LiquidEngine(fileSystem: DiskFileSystem('templates/'));
  print(engine.renderString("{% include 'header' %}"));
}
```

---

## Running Tests

```bash
cd liquiddart
dart test
```

---

## Architecture

See [IMPLEMENTATION.md](IMPLEMENTATION.md) for a complete description of the internal architecture, design decisions, and Dart-vs-PHP differences.

---

## License

MIT

