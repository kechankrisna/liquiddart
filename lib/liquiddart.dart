/// Liquid template engine for Dart.
///
/// A faithful port of the PHP `liquid/liquid` v1.4 library.
///
/// ## Quick start
///
/// ```dart
/// import 'package:liquiddart/liquiddart.dart';
///
/// void main() {
///   final engine = LiquidEngine();
///   final output = engine.renderString(
///     'Hello, {{ name | upcase }}!',
///     assigns: {'name': 'world'},
///   );
///   print(output); // Hello, WORLD!
/// }
/// ```
library;

export 'src/liquid_engine.dart' show LiquidEngine;
export 'src/template.dart' show Template, TagFactory;
export 'src/document.dart' show Document;
export 'src/context.dart' show Context;
export 'src/variable.dart' show Variable;
export 'src/filter_provider.dart' show FilterProvider;
export 'src/filters/standard_filters.dart' show StandardFilters;
export 'src/filters/custom_filters.dart' show CustomFilters;
export 'src/abstract_tag.dart' show AbstractTag, FileSystemInterface;
export 'src/abstract_block.dart' show AbstractBlock, registerTagFactory;
export 'src/decision.dart' show Decision;
export 'src/drop.dart' show Drop;
export 'src/file_system.dart' show LiquidFileSystem, LocalFileSystem;
export 'src/cache.dart' show LiquidCache, MemoryCache;
export 'src/liquid_config.dart' show LiquidConfig;
export 'src/exceptions/liquid_exception.dart' show LiquidException;
export 'src/exceptions/parse_exception.dart' show ParseException;
export 'src/exceptions/render_exception.dart' show RenderException;
export 'src/exceptions/wrong_argument_exception.dart'
    show WrongArgumentException;

// Tags (exported for subclassing / testing)
export 'src/tags/tag_assign.dart' show TagAssign;
export 'src/tags/tag_break.dart' show TagBreak;
export 'src/tags/tag_capture.dart' show TagCapture;
export 'src/tags/tag_case.dart' show TagCase;
export 'src/tags/tag_comment.dart' show TagComment;
export 'src/tags/tag_continue.dart' show TagContinue;
export 'src/tags/tag_cycle.dart' show TagCycle;
export 'src/tags/tag_decrement.dart' show TagDecrement;
export 'src/tags/tag_for.dart' show TagFor;
export 'src/tags/tag_if.dart' show TagIf;
export 'src/tags/tag_ifchanged.dart' show TagIfchanged;
export 'src/tags/tag_include.dart' show TagInclude;
export 'src/tags/tag_increment.dart' show TagIncrement;
export 'src/tags/tag_raw.dart' show TagRaw;
export 'src/tags/tag_unless.dart' show TagUnless;
