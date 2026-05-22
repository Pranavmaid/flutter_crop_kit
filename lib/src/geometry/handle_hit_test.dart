import 'dart:ui';

import 'crop_rect.dart';

/// Returns which [HandleTarget] [point] lies in for a crop [rect],
/// using [tolerance] (logical px) as the corner/edge fuzz radius.
HandleTarget hitTestHandles(Offset point, Rect rect, double tolerance) {
  bool near(double a, double b) => (a - b).abs() <= tolerance;

  final nearLeft = near(point.dx, rect.left);
  final nearRight = near(point.dx, rect.right);
  final nearTop = near(point.dy, rect.top);
  final nearBottom = near(point.dy, rect.bottom);

  final insideX =
      point.dx >= rect.left - tolerance && point.dx <= rect.right + tolerance;
  final insideY =
      point.dy >= rect.top - tolerance && point.dy <= rect.bottom + tolerance;

  if (nearLeft && nearTop) return HandleTarget.cornerNW;
  if (nearRight && nearTop) return HandleTarget.cornerNE;
  if (nearRight && nearBottom) return HandleTarget.cornerSE;
  if (nearLeft && nearBottom) return HandleTarget.cornerSW;
  if (nearTop && insideX) return HandleTarget.edgeN;
  if (nearBottom && insideX) return HandleTarget.edgeS;
  if (nearLeft && insideY) return HandleTarget.edgeW;
  if (nearRight && insideY) return HandleTarget.edgeE;
  if (rect.contains(point)) return HandleTarget.inside;
  return HandleTarget.outside;
}
