import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/geometry/transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identity when rotation=0 scale=1 image centered on canvas same size',
      () {
    const imageSize = Size(100, 100);
    const canvasSize = Size(100, 100);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: 0,
      scale: 1,
    );
    final p = MatrixUtils.transformPoint(m, const Offset(50, 50));
    expect(p.dx, closeTo(50, 1e-6));
    expect(p.dy, closeTo(50, 1e-6));
  });

  test('rotate 90deg maps top-center of image to right-center of canvas', () {
    const imageSize = Size(100, 100);
    const canvasSize = Size(100, 100);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: math.pi / 2,
      scale: 1,
    );
    final p = MatrixUtils.transformPoint(m, const Offset(50, 0));
    expect(p.dx, closeTo(100, 1e-6));
    expect(p.dy, closeTo(50, 1e-6));
  });

  test('invertTransform produces inverse', () {
    const imageSize = Size(200, 100);
    const canvasSize = Size(400, 200);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: 0.5,
      scale: 1.2,
    );
    final inv = invertTransform(m);
    const src = Offset(37, 19);
    final fwd = MatrixUtils.transformPoint(m, src);
    final back = MatrixUtils.transformPoint(inv, fwd);
    expect(back.dx, closeTo(src.dx, 1e-3));
    expect(back.dy, closeTo(src.dy, 1e-3));
  });

  test('fitScale returns scale that fits image inside canvas preserving ratio',
      () {
    expect(
      fitScale(const Size(200, 100), const Size(100, 100)),
      closeTo(0.5, 1e-9),
    );
    expect(
      fitScale(const Size(100, 200), const Size(100, 100)),
      closeTo(0.5, 1e-9),
    );
  });
}
