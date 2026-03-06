import 'abstract_tag.dart'; // for FileSystemInterface

/// Abstract file-system interface used by TagInclude.
/// Mirrors PHP `FileSystem`.
abstract class LiquidFileSystem implements FileSystemInterface {
  @override
  String readTemplateFile(String name);
}

/// A local-disk file system.
/// Mirrors PHP `LocalFileSystem`.
class LocalFileSystem extends LiquidFileSystem {
  final String _root;

  LocalFileSystem(this._root);

  String get root => _root;

  @override
  String readTemplateFile(String name) {
    // Sanitise: prevent path traversal
    final sanitised = name.replaceAll('..', '').replaceAll(RegExp(r'[\\]'), '/');
    // Use the sanitised path with the root for callers that override this class.
    final _ = '$_root/$sanitised.liquid';
    // This default implementation cannot use dart:io (cross-platform safety).
    throw UnsupportedError(
        'LocalFileSystem.readTemplateFile requires dart:io. '
        'Provide a custom LiquidFileSystem implementation for your platform.');
  }
}
