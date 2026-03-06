import 'abstract_block.dart';
import 'abstract_tag.dart';
import 'cache.dart';
import 'context.dart';
import 'document.dart';
import 'filter_provider.dart';
import 'liquid_config.dart';
import 'tags/tag_assign.dart';
import 'tags/tag_break.dart';
import 'tags/tag_capture.dart';
import 'tags/tag_case.dart';
import 'tags/tag_comment.dart';
import 'tags/tag_continue.dart';
import 'tags/tag_cycle.dart';
import 'tags/tag_decrement.dart';
import 'tags/tag_for.dart';
import 'tags/tag_if.dart';
import 'tags/tag_ifchanged.dart';
import 'tags/tag_include.dart';
import 'tags/tag_increment.dart';
import 'tags/tag_raw.dart';
import 'tags/tag_unless.dart';

typedef TagFactory = AbstractTag Function(
    String markup, List<String?> tokens, FileSystemInterface? fileSystem);

/// The top-level template parser and renderer.
/// Mirrors PHP `Template`.
class Template {
  // ── Static state ────────────────────────────────────────────────────────────

  static final Map<String, TagFactory> _tags = {};
  static LiquidCache? _cache;

  // ── Instance state ─────────────────────────────────────────────────────────

  Document? _root;
  FileSystemInterface? _fileSystem;
  final List<dynamic> _filters = [];
  void Function()? _tickFunction;

  Template([FileSystemInterface? fileSystem]) {
    _fileSystem = fileSystem;
    _ensureBuiltinTags();
    _setupIncludeBuilder();
  }

  // ── Configuration ──────────────────────────────────────────────────────────

  void setFileSystem(FileSystemInterface fs) => _fileSystem = fs;

  static void setCache(LiquidCache? cache) => _cache = cache;
  static LiquidCache? getCache() => _cache;

  static void registerTag(String name, TagFactory factory) {
    _tags[name] = factory;
    registerTagFactory(name, factory);
  }

  static Map<String, TagFactory> getTags() => Map.unmodifiable(_tags);

  void registerFilter(FilterProvider provider) => _filters.add(provider);
  void registerNamedFilter(String name, Function fn) =>
      _filters.add({'name': name, 'fn': fn});

  void setTickFunction(void Function() fn) => _tickFunction = fn;

  // ── Parsing ────────────────────────────────────────────────────────────────

  /// Split [source] into a flat list of tokens (tags, variables, and raw text).
  ///
  /// Dart's [String.split] does not keep capturing-group delimiters, so we
  /// manually walk through matches and collect both the text-between and the
  /// matched tokens.
  static List<String?> tokenize(String source) {
    if (source.isEmpty) return [];
    final result = <String?>[];
    int pos = 0;
    final re = LiquidConfig.tokenizationRegExp;
    for (final m in re.allMatches(source)) {
      if (m.start > pos) {
        final text = source.substring(pos, m.start);
        if (text.isNotEmpty) result.add(text);
      }
      result.add(m.group(0)!);
      pos = m.end;
    }
    if (pos < source.length) {
      final tail = source.substring(pos);
      if (tail.isNotEmpty) result.add(tail);
    }
    return result;
  }

  Template parse(String source) {
    if (_cache == null) {
      return _parseAlways(source);
    }
    final hash = _hashSource(source);
    final cached = _cache!.read(hash);
    if (cached == null || (cached as Document).hasIncludes()) {
      _parseAlways(source);
      _cache!.write(hash, _root!);
    } else {
      _root = cached;
    }
    return this;
  }

  Template _parseAlways(String source) {
    final tokens = tokenize(source);
    _root = Document(tokens, _fileSystem);
    return this;
  }

  // ── Rendering ──────────────────────────────────────────────────────────────

  String render([
    Map<String, dynamic> assigns = const {},
    List<FilterProvider>? extraFilters,
    Map<String, dynamic> registers = const {},
  ]) {
    assert(_root != null, 'Call parse() before render()');

    final context = Context(assigns, registers);

    if (_tickFunction != null) {
      context.setTickFunction(_tickFunction!);
    }

    for (final f in _filters) {
      if (f is FilterProvider) {
        context.addFilters(f);
      } else if (f is Map && f.containsKey('name')) {
        context.addNamedFilter(f['name'] as String, f['fn'] as Function);
      }
    }

    if (extraFilters != null) {
      for (final ef in extraFilters) {
        context.addFilters(ef);
      }
    }

    return _root!.render(context);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Document? get root => _root;

  static String _hashSource(String s) {
    // Very simple djb2-style hash — good enough for cache keys
    int h = 5381;
    for (int i = 0; i < s.length; i++) {
      h = ((h << 5) + h) ^ s.codeUnitAt(i);
    }
    return h.toRadixString(16);
  }

  // ── Built-in tag registration ──────────────────────────────────────────────

  static bool _builtinsRegistered = false;

  static void _ensureBuiltinTags() {
    if (_builtinsRegistered) return;
    _builtinsRegistered = true;

    final builtins = <String, TagFactory>{
      'assign': (m, t, fs) => TagAssign(m, t, fs),
      'capture': (m, t, fs) => TagCapture(m, t, fs),
      'comment': (m, t, fs) => TagComment(m, t, fs),
      'raw': (m, t, fs) => TagRaw(m, t, fs),
      'break': (m, t, fs) => TagBreak(m, t, fs),
      'continue': (m, t, fs) => TagContinue(m, t, fs),
      'if': (m, t, fs) => TagIf(m, t, fs),
      'unless': (m, t, fs) => TagUnless(m, t, fs),
      'case': (m, t, fs) => TagCase(m, t, fs),
      'for': (m, t, fs) => TagFor(m, t, fs),
      'cycle': (m, t, fs) => TagCycle(m, t, fs),
      'increment': (m, t, fs) => TagIncrement(m, t, fs),
      'decrement': (m, t, fs) => TagDecrement(m, t, fs),
      'ifchanged': (m, t, fs) => TagIfchanged(m, t, fs),
      'include': (m, t, fs) => TagInclude(m, t, fs),
    };

    for (final entry in builtins.entries) {
      _tags[entry.key] = entry.value;
      registerTagFactory(entry.key, entry.value);
    }
  }

  static void _setupIncludeBuilder() {
    TagInclude.setDocumentBuilder((source) {
      final tokens = tokenize(source);
      return Document(tokens);
    });
  }
}
