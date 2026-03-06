import 'liquid_exception.dart';

class WrongArgumentException extends LiquidException {
  WrongArgumentException(super.message);

  @override
  String toString() => 'WrongArgumentException: $message';
}
