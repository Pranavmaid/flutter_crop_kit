import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public API surface compiles', () {
    expect(CropController, isNotNull);
    expect(CropView, isNotNull);
    expect(showCropper, isNotNull);
    expect(const MaskShape.rect(), isNotNull);
    expect(ImageSource.memory, isNotNull);
    expect(const CropTheme(), isNotNull);
    expect(CropAspectRatio.square, isNotNull);
    expect(GridOverlay.thirds, isNotNull);
    expect(const CropLoadException('x'), isNotNull);
  });
}
