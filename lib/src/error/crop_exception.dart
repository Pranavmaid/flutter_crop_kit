/// Base class for all errors emitted by flutter_crop_kit.
sealed class CropException implements Exception {
  /// Creates an exception with a [message].
  const CropException(this.message);

  /// Human-readable message.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when an [ImageSource] fails to load.
final class CropLoadException extends CropException {
  /// Creates a load exception.
  const CropLoadException(super.message);
}

/// Thrown when a decoded image exceeds the configured pixel budget.
final class CropImageTooLargeException extends CropException {
  /// Creates a too-large exception.
  const CropImageTooLargeException(super.message);
}

/// Thrown when PNG export fails.
final class CropExportException extends CropException {
  /// Creates an export exception.
  const CropExportException(super.message);
}
