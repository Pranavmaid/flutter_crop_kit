import 'dart:ui';

import 'mask_shape.dart';

/// Builds a [Path] that matches [shape] when drawn inside [rect].
Path buildMaskPath(MaskShape shape, Rect rect) {
  switch (shape) {
    case RectMask():
      return Path()..addRect(rect);
    case OvalMask():
      return Path()..addOval(rect);
    case CircleMask():
      final side = rect.shortestSide;
      final r = Rect.fromCenter(center: rect.center, width: side, height: side);
      return Path()..addOval(r);
    case PolygonMask(:final points):
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final pt = points[i];
        final x = rect.left + pt.dx * rect.width;
        final y = rect.top + pt.dy * rect.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    case CustomMask(:final builder):
      return builder(rect);
  }
}
