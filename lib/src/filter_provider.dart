/// Interface that all filter classes must implement.
/// In PHP this was done via reflection; in Dart we use an explicit map
/// so the code is AOT/Flutter-safe.
///
/// Example:
/// ```dart
/// class MyFilters implements FilterProvider {
///   @override
///   Map<String, Function> get filters => {
///     'slug': (dynamic input) => input.toString().toLowerCase().replaceAll(' ', '-'),
///     'shout': (dynamic input, [dynamic times = 3]) => '${input}!' * times,
///   };
/// }
/// ```
abstract interface class FilterProvider {
  Map<String, Function> get filters;
}
