/// Abstract cache interface.
/// Mirrors PHP `Cache`.
abstract class LiquidCache {
  /// Read a cached document.
  dynamic read(String hash);

  /// Write a document into the cache.
  void write(String hash, dynamic document);

  /// Check if a hash exists.
  bool exists(String hash);
}

/// Simple in-memory cache backed by a [Map].
/// Mirrors PHP `Cache\Memory`.
class MemoryCache extends LiquidCache {
  final Map<String, dynamic> _store = {};

  @override
  dynamic read(String hash) => _store[hash];

  @override
  void write(String hash, dynamic document) => _store[hash] = document;

  @override
  bool exists(String hash) => _store.containsKey(hash);
}
