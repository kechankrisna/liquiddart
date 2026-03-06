# liquiddart — Implementation Reference

A faithful Dart port of the PHP [`liquid/liquid`](https://github.com/kalimatas/php-liquid) v1.4 library. This document describes every architectural decision, class, and design pattern used in the implementation.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Package Structure](#2-package-structure)
3. [Core Classes](#3-core-classes)
   - [LiquidEngine](#liquidengine)
   - [Template](#template)
   - [Document](#document)
   - [Context](#context)
   - [Variable](#variable)
   - [LiquidConfig](#liquidconfig)
4. [Node Hierarchy](#4-node-hierarchy)
5. [Tag System](#5-tag-system)
   - [AbstractTag](#abstracttag)
   - [AbstractBlock](#abstractblock)
   - [Built-in Tags](#built-in-tags)
   - [Custom Tags](#custom-tags)
6. [Filter System](#6-filter-system)
   - [FilterProvider Interface](#filterprovider-interface)
   - [Filterbank](#filterbank)
   - [StandardFilters](#standardfilters)
   - [CustomFilters](#customfilters)
7. [Drop System](#7-drop-system)
8. [File System API](#8-file-system-api)
9. [Caching](#9-caching)
10. [Exceptions](#10-exceptions)
11. [Key Design Decisions](#11-key-design-decisions)
12. [Dart-vs-PHP Differences](#12-dart-vs-php-differences)

---

## 1. Architecture Overview

```
User code
   │
   ▼
LiquidEngine          ← high-level facade (parse + render)
   │
   ▼
Template              ← owns the static tag registry, cache, and parsing
   │           parse()
   ▼
Document              ← root node (extends AbstractBlock)
   │
   ├── String          ← plain text literal
   ├── Variable        ← {{ expr | filter }}
   └── AbstractTag     ← {% tag %}
        └── AbstractBlock  ← {% block %}...{% endblock %}
```

Rendering is a single recursive `render(Context)` call starting at `Document`.

---

## 2. Package Structure

```
lib/
├── liquiddart.dart            ← barrel export (public API)
└── src/
    ├── liquid_engine.dart     ← LiquidEngine facade
    ├── template.dart          ← Template: parse/render + tag registry
    ├── document.dart          ← Document root node
    ├── context.dart           ← Context: variable scopes + filter dispatch
    ├── variable.dart          ← Variable output node  {{ ... }}
    ├── decision.dart          ← Condition evaluation (if/unless/case)
    ├── abstract_tag.dart      ← AbstractTag base + FileSystemInterface
    ├── abstract_block.dart    ← AbstractBlock base + tokenizer loop
    ├── drop.dart              ← Drop: safe object exposure to templates
    ├── filter_provider.dart   ← FilterProvider interface
    ├── filterbank.dart        ← Filterbank: filter registry + dispatch
    ├── liquid_config.dart     ← Static constants + compiled RegExps
    ├── regexp_helper.dart     ← RegexpHelper utility wrapper
    ├── node.dart              ← LiquidNode interface
    ├── cache.dart             ← LiquidCache + MemoryCache
    ├── file_system.dart       ← LiquidFileSystem + LocalFileSystem
    ├── exceptions/
    │   ├── liquid_exception.dart
    │   ├── parse_exception.dart
    │   ├── render_exception.dart
    │   └── wrong_argument_exception.dart
    ├── filters/
    │   ├── standard_filters.dart   ← ~45 standard Liquid filters
    │   └── custom_filters.dart     ← app-specific extra filters
    └── tags/
        ├── tag_assign.dart
        ├── tag_break.dart
        ├── tag_capture.dart
        ├── tag_case.dart
        ├── tag_comment.dart
        ├── tag_continue.dart
        ├── tag_cycle.dart
        ├── tag_decrement.dart
        ├── tag_for.dart
        ├── tag_if.dart
        ├── tag_ifchanged.dart
        ├── tag_include.dart
        ├── tag_increment.dart
        ├── tag_raw.dart
        └── tag_unless.dart
```

---

## 3. Core Classes

### LiquidEngine

**File:** `lib/src/liquid_engine.dart`

High-level façade. Most application code only needs this class.

| Method | Description |
|--------|-------------|
| `LiquidEngine({FileSystemInterface?})` | Constructor; auto-registers `StandardFilters` and `CustomFilters` |
| `parse(String source) → LiquidEngine` | Parse a template; returns `this` for chaining |
| `render({assigns, registers}) → String` | Render previously-parsed template |
| `renderString(String, {assigns}) → String` | Parse + render in one call |
| `registerFilter(FilterProvider) → LiquidEngine` | Add a filter provider |
| `registerNamedFilter(String, Function) → LiquidEngine` | Add a single named filter |
| `static setCache(LiquidCache?)` | Set global parse cache |
| `template` getter | Access underlying `Template` for advanced use |

---

### Template

**File:** `lib/src/template.dart`

Owns the static tag registry (`_tags`), optional parse cache, and the `_root` document.

#### Static State
- `Map<String, TagFactory> _tags` — tag name → factory function registry
- `LiquidCache? _cache` — global shared parse cache
- `bool _builtinsRegistered` — one-time built-in tag registration guard

#### Key Methods

| Method | Description |
|--------|-------------|
| `static tokenize(String) → List<String?>` | Splits source into raw tokens |
| `parse(String) → Template` | Tokenizes and builds the `Document` tree; respects cache |
| `render([assigns, filters, registers]) → String` | Creates a `Context` and calls `_root.render(ctx)` |
| `static registerTag(name, TagFactory)` | Register a custom tag globally |
| `_ensureBuiltinTags()` | One-time registration of all 15 built-in tags |

#### Tokenizer

The tokenizer uses `LiquidConfig.tokenizationRegExp` (`r'({%.*?%}|{{.*?}})'`) but Dart's `String.split()` **does not** preserve capturing-group delimiters (unlike PHP's `preg_split` with `PREG_SPLIT_DELIM_CAPTURE`). The implementation therefore uses `RegExp.allMatches()` to walk the string manually:

```dart
for (final m in re.allMatches(source)) {
  if (m.start > pos) result.add(source.substring(pos, m.start)); // text
  result.add(m.group(0)!);                                        // token
  pos = m.end;
}
```

---

### Document

**File:** `lib/src/document.dart`

`Document extends AbstractBlock` is the root node produced by `Template.parse()`.

- `blockDelimiter()` returns `''` — the root has no closing tag.
- `assertMissingDelimitation()` is a no-op (root always closes at EOF).
- `hasIncludes()` checks whether any `TagInclude` nodes exist (used by cache invalidation).

---

### Context

**File:** `lib/src/context.dart`

Holds variable scope stacks and dispatches filter invocations.

#### Scope Stack

```
_assigns: [ innermost scope, ..., outermost scope ]
environments[0]: mutable override (increment/decrement counters)
environments[1]: reserved
```

`push()`/`pop()` manage nested scopes (used by `for`, `include`, `capture`). `set(key, value, {global: false})` writes to the innermost scope by default; with `global: true` it writes to every scope.

> **Key fix:** The constructor copies the passed-in maps with `Map.of()` to prevent mutations of `const {}` caller maps.

#### Resolution Order

`get(key)` → `resolve(key)`:
1. Null / `'null'` / `'nil'` → `null`
2. `'true'` / `'false'` → bool
3. Non-`String` → returned as-is
4. Quoted string literal → unquoted value
5. Numeric literal → `num`
6. `_variable(key)` — dot-notation / array-index path lookup

#### Path Resolution (`_variable`)

`[N]` is normalised to `.N`, then the key is split on `.` and each segment traverses: `Drop` → `invokeDrop`, `Map` → key lookup (`.size` / `.first` / `.last` shortcuts), `List` → index or `.size/.first/.last`, `String` → `.size`.

---

### Variable

**File:** `lib/src/variable.dart`

Represents a `{{ expression | filter: arg }}` output node.

The constructor receives the content between `{{` and `}}`, already trimmed by the regex. It then:
1. Splits on `|` (quote-aware via `_splitOnPipe`)
2. Trims the first segment → variable name
3. For each subsequent segment: parses `filterName: arg1, arg2` → stores as `(String, List<dynamic>)`

`render(Context)`:
1. Resolves the name via `context.get(_name)`
2. For each filter: resolves any non-literal arguments via `context.get(arg)`, then calls `context.invoke(filterName, value, resolvedArgs)`
3. `null` → `''`, `bool` → `'true'`/`'false'`, otherwise `toString()`

---

### LiquidConfig

**File:** `lib/src/liquid_config.dart`

Central constants and compiled regular expressions.

| Constant | Value |
|----------|-------|
| `tagStart` | `{%` |
| `tagEnd` | `%}` |
| `variableStart` | `{{` |
| `variableEnd` | `}}` |
| `whitespaceControl` | `-` |

Compiled getters (new instance each call — use in hot paths sparingly):

| Getter | Purpose |
|--------|---------|
| `tokenizationRegExp` | Split source into tag/variable/text tokens |
| `tagAttributesRegExp` | Parse `key: value` attribute pairs |
| `variableTokenRegExp` | Strip `{{` / `}}` from a variable token |
| `tagTokenRegExp` | Extract tag name + markup from a tag token |

---

## 4. Node Hierarchy

```
LiquidNode (interface)
├── Variable          — {{ expr }}
└── AbstractTag
    ├── TagAssign
    ├── TagBreak
    ├── TagComment
    ├── TagContinue
    ├── TagCycle
    ├── TagDecrement
    ├── TagIncrement
    ├── TagIfchanged
    ├── TagInclude
    └── AbstractBlock
        ├── Document
        ├── TagCapture
        ├── TagCase
        ├── TagFor
        ├── TagIf
        │   └── TagUnless
        └── TagRaw
```

---

## 5. Tag System

### AbstractTag

**File:** `lib/src/abstract_tag.dart`

```dart
abstract class AbstractTag implements LiquidNode {
  AbstractTag(this.markup, List<String?> tokens, [this.fileSystem]) {
    parse(tokens);  // called in constructor
  }
  void parse(List<String?> tokens) {}       // override to consume tokens
  void extractAttributes(String m) { ... } // parses key:value pairs
}
```

The shared `FileSystemInterface` is also defined here to avoid circular imports with `AbstractBlock`.

---

### AbstractBlock

**File:** `lib/src/abstract_block.dart`

The tokenizer loop lives in `AbstractBlock.parse()`:

```
for each token:
  {%...%}  → find factory → factory(markup, tokens, fs)
              tag == blockDelimiter() → endTag(); return
  {{...}}  → Variable(inner)
  text     → String (with whitespace-control ltrim if previous token was -%})
```

Whitespace control (`{%-` / `-%}`) is handled in `_whitespaceHandler`:
- `{%-` strips trailing whitespace from the last text node.
- `-%}` sets `trimWhitespace = true`; the next plain-text token is left-trimmed.

`renderAll(list, context)`:
- Iterates `nodelist`; calls `render(context)` on each `LiquidNode`.
- Checks `registers['break']` / `registers['continue']` after each node.
- Calls `context.tick()` for render-loop monitoring.

#### Tag Factory Registry (`_Template`)

A private `_Template` class owns the static `Map<String, TagFactory>` so tag lookups don't need a `Template` import in every tag file. The public top-level function `registerTagFactory(name, factory)` delegates to it.

---

### Built-in Tags

| Tag | Class | Description |
|-----|-------|-------------|
| `assign` | `TagAssign` | `{% assign var = expr %}` — sets a context variable |
| `capture` | `TagCapture` | `{% capture var %}...{% endcapture %}` — captures rendered output |
| `comment` | `TagComment` | `{% comment %}...{% endcomment %}` — discards content |
| `raw` | `TagRaw` | `{% raw %}...{% endraw %}` — verbatim output (no parsing) |
| `break` | `TagBreak` | Sets `registers['break'] = true` |
| `continue` | `TagContinue` | Sets `registers['continue'] = true` |
| `if` | `TagIf` | `{% if %}...{% elsif %}...{% else %}...{% endif %}` |
| `unless` | `TagUnless` | Extend `TagIf`; negates the first condition |
| `case` | `TagCase` | `{% case %}...{% when %}...{% else %}{% endcase %}` |
| `for` | `TagFor` | Collection + integer range iteration with `forloop.*` vars |
| `cycle` | `TagCycle` | Round-robin cycle through values; keyed by name |
| `increment` | `TagIncrement` | Starts counter at 0, increments per call |
| `decrement` | `TagDecrement` | Starts counter at -1, decrements per call |
| `ifchanged` | `TagIfchanged` | Outputs content only when the rendered value changes |
| `include` | `TagInclude` | Loads and renders a sub-template from the file system |

#### `for` Tag (`TagFor`)

Supports:
- **Collection mode:** `{% for item in collection %}`
- **Range mode:** `{% for i in (1..5) %}`
- **Attributes:** `limit`, `offset`
- **`forloop` context:** `index`, `index0`, `rindex`, `rindex0`, `first`, `last`, `length`
- **`break` / `continue`** via `TagBreak` / `TagContinue`

Iteration uses `context.push()` / `context.pop()` to isolate loop variables. Break/continue flags are stored in `registers` and cleared between iterations.

#### `include` Tag (`TagInclude`)

Uses a `static Function(String) _documentBuilder` callback set by `Template._setupIncludeBuilder()` to avoid circular imports between `TagInclude` and `Template`.

Modes:
- `{% include 'partial' %}` — renders the partial with current context
- `{% include 'partial' with variable %}` — exposes `variable` to the partial
- `{% include 'partial' for collection %}` — renders partial once per item

---

### Custom Tags

Register a custom tag globally:

```dart
Template.registerTag('mytag', (markup, tokens, fs) => MyTag(markup, tokens, fs));
```

`MyTag` should extend either `AbstractTag` (simple, no body) or `AbstractBlock` (with `{% endmytag %}`).

---

## 6. Filter System

### FilterProvider Interface

**File:** `lib/src/filter_provider.dart`

```dart
abstract interface class FilterProvider {
  Map<String, Function> get filters;
}
```

This AOT-safe design avoids reflection. Every filter is an explicit `Function` reference in a `Map`.

---

### Filterbank

**File:** `lib/src/filterbank.dart`

Owns the `Map<String, Function> _methodMap`. Constructed by `Context`; auto-registers `StandardFilters` and `CustomFilters`.

`invoke(name, value, args)`:
- Maps `'default'` → `'_default'` (Dart keyword avoidance).
- Uses a `switch` on `args.length` (0–4) for fast dispatch; falls back to `Function.apply`.
- Catches all exceptions and returns `value` unchanged on error (graceful degradation).

---

### StandardFilters

**File:** `lib/src/filters/standard_filters.dart`

All ~45 standard Liquid filters, grouped:

**String:** `append`, `prepend`, `upcase`, `downcase`, `capitalize`, `strip`, `lstrip`, `rstrip`, `replace`, `replace_first`, `remove`, `remove_first`, `split`, `truncate`, `truncatewords`, `slice`, `size`, `escape`, `escape_once`, `strip_html`, `strip_newlines`, `newline_to_br`, `string`, `raw`, `json`, `default`

**Math:** `plus`, `minus`, `times`, `divided_by`, `modulo`, `ceil`, `floor`, `round`

**Date:** `date` — full strftime-style format codes via manual mapping

**Array:** `first`, `last`, `join`, `reverse`, `sort`, `sort_natural`, `map`, `where`, `uniq`, `compact`

**URL:** `url_encode`, `url_decode`

#### Integer vs. Float Behaviour

`plus`, `minus`, `times`, `modulo` return `int` when both operands are integer-like (no `.` in string representation, or `is int`). `divided_by` performs integer (floor) division when both operands are integers; float otherwise. This mirrors PHP Liquid exactly.

#### `truncate`

Total output length (including the ending) is capped to `chars`. The cut point is `chars - ending.length`:

```dart
final cutAt = (limit - tail.length).clamp(0, input.length);
return input.substring(0, cutAt) + tail;
```

---

### CustomFilters

**File:** `lib/src/filters/custom_filters.dart`

Application-specific filters that extend the standard set:

| Filter | Signature | Description |
|--------|-----------|-------------|
| `sort_key` | `(list, key)` | Sort a `List<Map>` by a map key |
| `zero_pad` | `(input, width)` | Left-pad with zeros to `width` |
| `money` | `(input, symbol, decimals)` | Format as currency with thousands separator |
| `moneyFormat` | `(input, symbol, decimals)` | Alias for `money` with default symbol `$` |
| `stringAsFixed` | `(input, decimals)` | `toStringAsFixed` wrapper |
| `number_format` | `(input, decimals, decSep, thousandsSep)` | Fully configurable number formatting |

---

## 7. Drop System

**File:** `lib/src/drop.dart`

`Drop` is an abstract class for safely exposing Dart objects to templates. Only properties listed in `liquidMethods` are accessible.

```dart
class ProductDrop extends Drop {
  final Product _product;
  ProductDrop(this._product);

  @override
  Map<String, dynamic> get liquidMethods => {
    'title': _product.title,
    'price': () => _product.price,  // lazy function — called on access
  };
}
```

`invokeDrop(name)` checks `liquidMethods`, and if the value is a `Function`, calls it (zero-argument).

`setContext(context)` is called when the drop is resolved by `Context._fetch`; override to receive a reference to the current `Context`.

---

## 8. File System API

**File:** `lib/src/file_system.dart`

```dart
abstract class LiquidFileSystem implements FileSystemInterface {
  String readTemplateFile(String name);
}
```

`LocalFileSystem(String root)` is provided but throws `UnsupportedError` on `readTemplateFile` by default, since `dart:io` is not imported (to keep the package web-safe). Subclass it and add `dart:io` if you need file-based includes.

Pass a `FileSystemInterface` to `LiquidEngine`:

```dart
final engine = LiquidEngine(fileSystem: MyFileSystem('templates/'));
```

---

## 9. Caching

**File:** `lib/src/cache.dart`

`LiquidCache` is an abstract interface with `read`, `write`, `exists`. `MemoryCache` implements it with a `Map<String, dynamic>`.

The cache stores parsed `Document` trees keyed by a simple djb2-style hash of the source string. Cache hits skip tokenization and document construction.

Templates containing `{% include %}` are never cached (the sub-template may change independently):

```dart
if (cached == null || (cached as Document).hasIncludes()) {
  _parseAlways(source);
  _cache!.write(hash, _root!);
}
```

Enable caching globally:

```dart
LiquidEngine.setCache(MemoryCache());
```

---

## 10. Exceptions

All exceptions extend `LiquidException implements Exception`.

| Class | When thrown |
|-------|-------------|
| `ParseException` | Malformed tags, unterminated blocks, missing include file system |
| `RenderException` | Errors during template rendering |
| `WrongArgumentException` | Invalid arguments to `Filterbank.addFilter` |

---

## 11. Key Design Decisions

### AOT Safety (No Reflection)

Dart's `dart:mirrors` is unavailable in AOT-compiled Flutter/Dart apps. Filters and Drop properties are therefore registered via explicit `Map<String, Function>` getters rather than mirrored method discovery.

### Static Tag Registry via `_Template`

Tag factories are stored in a private `_Template` class in `abstract_block.dart` rather than in `Template` itself. This avoids circular imports: all tag files import `abstract_block.dart`, not `template.dart`.

### Context Copies Immutable Maps

Dart `const {}` maps are truly immutable. `Context` copies all incoming `assigns` and `registers` with `Map.of()` so tags can freely mutate them.

### Tokenizer Uses `allMatches` Not `split`

`String.split(RegExp(r'({%.*?%}|{{.*?}})'))` in Dart silently drops the matched delimiters (unlike PHP's `preg_split` with `PREG_SPLIT_DELIM_CAPTURE`). The tokenizer uses `RegExp.allMatches` to manually interleave text segments and matched tokens.

### `include` Uses a Callback to Break Circular Import

`TagInclude` needs to tokenize and build a `Document`, but `Document` imports `abstract_block.dart` and `TagInclude` must be imported by `template.dart`. The circular dependency is broken by a static `Function(String) _documentBuilder` callback set by `Template._setupIncludeBuilder()`.

---

## 12. Dart-vs-PHP Differences

| Concern | PHP | Dart |
|---------|-----|------|
| Filter discovery | `get_class_methods` (reflection) | Explicit `Map<String, Function>` |
| Drop | PHP magic `__get` | Explicit `liquidMethods` map |
| `split` with delimiters | `preg_split(..., PREG_SPLIT_DELIM_CAPTURE)` | Manual `allMatches` walk |
| Integer arithmetic | PHP integers | Dart `double` internally; converted back to `int` when appropriate |
| `default` filter | Method name `'default'` | Internally stored as `'_default'` (Dart keyword) |
| File system | `file_get_contents` | Abstract `FileSystemInterface`; no `dart:io` dependency |
| `date` filter | PHP `date()` / `strftime()` | Manual format-code mapping |
| Reflection-based cache key | `serialize` | djb2 hash of source string |
