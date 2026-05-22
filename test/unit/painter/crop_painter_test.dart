import 'dart:ui';

import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_crop_kit/src/painter/crop_painter.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shouldRepaint returns true on different state', () {
    const a = CropPainter(
      image: null,
      cropRect: Rect.fromLTWH(0, 0, 10, 10),
      rotation: 0,
      scale: 1,
      mask: MaskShape.rect(),
      theme: CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: Size(100, 100),
    );
    const b = CropPainter(
      image: null,
      cropRect: Rect.fromLTWH(0, 0, 20, 20),
      rotation: 0,
      scale: 1,
      mask: MaskShape.rect(),
      theme: CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: Size(100, 100),
    );
    expect(b.shouldRepaint(a), true);
  });

  test('shouldRepaint false on identical state', () {
    CropPainter make() => const CropPainter(
          image: null,
          cropRect: Rect.fromLTWH(0, 0, 10, 10),
          rotation: 0,
          scale: 1,
          mask: MaskShape.rect(),
          theme: CropTheme(),
          grid: GridOverlay.thirds,
          canvasSize: Size(100, 100),
        );
    expect(make().shouldRepaint(make()), false);
  });

  test('paint with null image does not throw', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const painter = CropPainter(
      image: null,
      cropRect: Rect.fromLTWH(0, 0, 10, 10),
      rotation: 0,
      scale: 1,
      mask: MaskShape.rect(),
      theme: CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: Size(100, 100),
    );
    expect(
      () => painter.paint(canvas, const Size(100, 100)),
      returnsNormally,
    );
  });
}
