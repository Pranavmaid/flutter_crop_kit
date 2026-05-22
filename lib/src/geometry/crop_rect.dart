import 'dart:ui';

import '../widgets/crop_theme.dart';

/// Which part of the crop rect is being manipulated.
enum HandleTarget {
  /// Top-left corner.
  cornerNW,

  /// Top-right corner.
  cornerNE,

  /// Bottom-right corner.
  cornerSE,

  /// Bottom-left corner.
  cornerSW,

  /// Top edge.
  edgeN,

  /// Right edge.
  edgeE,

  /// Bottom edge.
  edgeS,

  /// Left edge.
  edgeW,

  /// Anywhere inside the rect (pan).
  inside,

  /// Outside the rect (pinch-zoom).
  outside,
}

/// Returns [rect] adjusted to lie entirely within [bounds].
/// If [rect] is larger than [bounds], it is clamped to [bounds].
Rect clampToBounds(Rect rect, Rect bounds) {
  final w = rect.width.clamp(0.0, bounds.width).toDouble();
  final h = rect.height.clamp(0.0, bounds.height).toDouble();
  final left = rect.left.clamp(bounds.left, bounds.right - w).toDouble();
  final top = rect.top.clamp(bounds.top, bounds.bottom - h).toDouble();
  return Rect.fromLTWH(left, top, w, h);
}

/// Ensures [rect] is at least [min] on both sides, growing from its center.
Rect enforceMinSize(Rect rect, double min) {
  if (rect.width >= min && rect.height >= min) return rect;
  final w = rect.width < min ? min : rect.width;
  final h = rect.height < min ? min : rect.height;
  return Rect.fromCenter(center: rect.center, width: w, height: h);
}

/// Applies a gesture delta to [rect] based on [target].
/// If [aspect] is non-null, preserves the ratio.
Rect resizeWithHandle(
  Rect rect,
  HandleTarget target,
  Offset delta, {
  required CropAspectRatio? aspect,
}) {
  double l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
  switch (target) {
    case HandleTarget.inside:
      return rect.shift(delta);
    case HandleTarget.outside:
      return rect;
    case HandleTarget.cornerNW:
      l += delta.dx;
      t += delta.dy;
    case HandleTarget.cornerNE:
      r += delta.dx;
      t += delta.dy;
    case HandleTarget.cornerSE:
      r += delta.dx;
      b += delta.dy;
    case HandleTarget.cornerSW:
      l += delta.dx;
      b += delta.dy;
    case HandleTarget.edgeN:
      t += delta.dy;
    case HandleTarget.edgeE:
      r += delta.dx;
    case HandleTarget.edgeS:
      b += delta.dy;
    case HandleTarget.edgeW:
      l += delta.dx;
  }
  var out = Rect.fromLTRB(
    l < r ? l : r,
    t < b ? t : b,
    l < r ? r : l,
    t < b ? b : t,
  );
  if (aspect != null) {
    out = _applyAspect(out, target, aspect.ratio());
  }
  return out;
}

Rect _applyAspect(Rect rect, HandleTarget target, double ratio) {
  final w = rect.width;
  final h = rect.height;
  final bool useWidth;
  switch (target) {
    case HandleTarget.edgeN:
    case HandleTarget.edgeS:
      useWidth = false;
    case HandleTarget.edgeE:
    case HandleTarget.edgeW:
      useWidth = true;
    default:
      useWidth = w / h > ratio;
  }
  if (useWidth) {
    final newH = w / ratio;
    switch (target) {
      case HandleTarget.cornerNW:
      case HandleTarget.cornerNE:
      case HandleTarget.edgeN:
        return Rect.fromLTRB(
          rect.left,
          rect.bottom - newH,
          rect.right,
          rect.bottom,
        );
      case HandleTarget.cornerSW:
      case HandleTarget.cornerSE:
      case HandleTarget.edgeS:
        return Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + newH);
      default:
        return Rect.fromCenter(center: rect.center, width: w, height: newH);
    }
  } else {
    final newW = h * ratio;
    switch (target) {
      case HandleTarget.cornerNW:
      case HandleTarget.cornerSW:
      case HandleTarget.edgeW:
        return Rect.fromLTRB(
          rect.right - newW,
          rect.top,
          rect.right,
          rect.bottom,
        );
      case HandleTarget.cornerNE:
      case HandleTarget.cornerSE:
      case HandleTarget.edgeE:
        return Rect.fromLTRB(
          rect.left,
          rect.top,
          rect.left + newW,
          rect.bottom,
        );
      default:
        return Rect.fromCenter(center: rect.center, width: newW, height: h);
    }
  }
}
