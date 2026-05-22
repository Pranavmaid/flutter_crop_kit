import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../_helpers/test_images.dart';

typedef Rect = ui.Rect;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 512, height: 512, cell: 32);
  });

  test('isReady transitions from false to true after load', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    expect(c.isReady, false);
    await c.whenReady;
    expect(c.isReady, true);
    expect(c.image, isA<ui.Image>());
    expect(c.cropRect, const Rect.fromLTWH(0, 0, 512, 512));
    c.dispose();
  });

  test('mutations notify listeners exactly once', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    var calls = 0;
    c.addListener(() => calls++);
    c.setAspectRatio(CropAspectRatio.square);
    expect(calls, 1);
    c.setMask(const MaskShape.circle());
    expect(calls, 2);
    c.rotateBy90();
    expect(calls, 3);
    c.dispose();
  });

  test('rotateBy90 increments by pi/2', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    c.rotateBy90();
    expect(c.rotation, closeTo(1.5707963267948966, 1e-9));
    c.rotateBy90();
    expect(c.rotation, closeTo(3.141592653589793, 1e-9));
    c.dispose();
  });

  test('reset restores initial cropRect, rotation', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    c.rotateBy90();
    c.reset();
    expect(c.rotation, 0);
    expect(c.cropRect, const Rect.fromLTWH(0, 0, 512, 512));
    c.dispose();
  });

  test('error state set on invalid bytes', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0, 1, 2, 3])),
    );
    await c.whenReady.catchError((Object _) => null);
    expect(c.isReady, false);
    expect(c.error, isNotNull);
    c.dispose();
  });

  test('crop() returns PNG bytes matching cropRect dimensions', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    final bytes = await c.crop();
    final codec = await ui.instantiateImageCodec(bytes);
    final out = (await codec.getNextFrame()).image;
    expect(out.width, 512);
    expect(out.height, 512);
    c.dispose();
  });

  test('cropRectStream emits debounced updates', () async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    final emissions = <Rect>[];
    final sub = c.cropRectStream.listen(emissions.add);
    // ignore: invalid_use_of_protected_member
    c.updateCropRect(const Rect.fromLTWH(0, 0, 100, 100));
    // ignore: invalid_use_of_protected_member
    c.updateCropRect(const Rect.fromLTWH(0, 0, 200, 200));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, 1);
    expect(emissions.last, const Rect.fromLTWH(0, 0, 200, 200));
    await sub.cancel();
    c.dispose();
  });

  test('crop() before ready throws StateError', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0, 1, 2, 3])),
    );
    await expectLater(c.crop, throwsStateError);
    c.dispose();
  });
}
