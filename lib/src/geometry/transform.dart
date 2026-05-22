import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show Matrix4;

/// Builds the matrix that maps image-space to canvas-space.
///
/// Composition: T(canvasCenter) * R(rotation) * S(scale) * T(-imageCenter).
Matrix4 buildImageTransform({
  required Size imageSize,
  required Size canvasSize,
  required double rotation,
  required double scale,
}) {
  final m = Matrix4.identity();
  m.translate(canvasSize.width / 2, canvasSize.height / 2);
  m.rotateZ(rotation);
  m.scale(scale, scale);
  m.translate(-imageSize.width / 2, -imageSize.height / 2);
  return m;
}

/// Returns the inverse of [m].
///
/// Throws [StateError] if [m] is singular.
Matrix4 invertTransform(Matrix4 m) {
  final inv = Matrix4.copy(m);
  final det = inv.invert();
  if (det == 0) {
    throw StateError('Transform is singular and cannot be inverted');
  }
  return inv;
}

/// Returns the uniform scale factor that fits [contentSize] inside [boxSize]
/// preserving aspect ratio (i.e. `min(sx, sy)`).
double fitScale(Size contentSize, Size boxSize) {
  final sx = boxSize.width / contentSize.width;
  final sy = boxSize.height / contentSize.height;
  return math.min(sx, sy);
}
