import 'context.dart';

/// Base interface for all renderable nodes in the AST.
abstract interface class LiquidNode {
  String render(Context context);
}
