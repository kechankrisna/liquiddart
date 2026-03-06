import 'liquid_exception.dart';

class RenderException extends LiquidException {
  RenderException(super.message);

  @override
  String toString() => 'RenderException: $message';
}
