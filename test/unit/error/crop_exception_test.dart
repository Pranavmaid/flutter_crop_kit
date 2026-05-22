import 'package:flutter_crop_kit/src/error/crop_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CropException subtypes carry message', () {
    expect(const CropLoadException('boom').message, 'boom');
    expect(const CropImageTooLargeException('big').message, 'big');
    expect(const CropExportException('export').message, 'export');
  });

  test('toString includes type and message', () {
    expect(
      const CropLoadException('x').toString(),
      'CropLoadException: x',
    );
  });
}
