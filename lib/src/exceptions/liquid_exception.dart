class LiquidException implements Exception {
  final String message;
  LiquidException(this.message);

  @override
  String toString() => 'LiquidException: $message';
}
