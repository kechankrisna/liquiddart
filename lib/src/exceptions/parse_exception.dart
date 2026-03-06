import 'liquid_exception.dart';

class ParseException extends LiquidException {
  ParseException(super.message);

  @override
  String toString() => 'ParseException: $message';
}
