import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_crop_kit/src/export/png_encoder.dart';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../_helpers/test_images.dart';

// ignore: avoid_relative_lib_imports
// Rect is dart:ui.Rect re-exported; bring it unaliased.
typedef Rect = ui.Rect;

Future<ui.Image> _decode(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ui.Image sample;
  setUpAll(() async {
    final bytes = await makeCheckerboardPng(width: 512, height: 512, cell: 32);
    sample = await _decode(bytes);
  });

  test('fast path: output bytes decode to cropRect size', () async {
    final bytes = await encodePng(
      image: sample,
      cropRect: const Rect.fromLTWH(64, 64, 256, 128),
      rotation: 0,
      mask: const MaskShape.rect(),
    );
    final out = await _decode(bytes);
    expect(out.width, 256);
    expect(out.height, 128);
  });

  test('rotated path: 90deg output is axis-aligned bbox of rotated rect',
      () async {
    final bytes = await encodePng(
      image: sample,
      cropRect: const Rect.fromLTWH(100, 100, 200, 100),
      rotation: 1.5707963267948966,
      mask: const MaskShape.rect(),
    );
    final out = await _decode(bytes);
    expect(out.width, closeTo(100, 1));
    expect(out.height, closeTo(200, 1));
  });

  test('targetWidth resizes output preserving aspect', () async {
    final bytes = await encodePng(
      image: sample,
      cropRect: const Rect.fromLTWH(0, 0, 400, 200),
      rotation: 0,
      mask: const MaskShape.rect(),
      targetWidth: 200,
    );
    final out = await _decode(bytes);
    expect(out.width, 200);
    expect(out.height, 100);
  });
}
