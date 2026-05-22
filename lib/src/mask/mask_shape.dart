import 'dart:ui';

/// Shape of the crop mask. Sealed; use the factories.
sealed class MaskShape {
  const MaskShape._();

  /// Rectangular mask.
  const factory MaskShape.rect() = RectMask;

  /// Oval inscribed in the crop rect.
  const factory MaskShape.oval() = OvalMask;

  /// Circle inscribed in the crop rect (uses shorter side).
  const factory MaskShape.circle() = CircleMask;

  /// Polygon in unit space (0..1) mapped into the crop rect.
  /// [points] must contain at least 3 entries in `[0,1]×[0,1]`.
  factory MaskShape.polygon(List<Offset> points) = PolygonMask;

  /// Custom mask via a [Path] builder receiving the crop rect.
  factory MaskShape.custom(Path Function(Rect rect) builder) = CustomMask;
}

/// Rect mask.
final class RectMask extends MaskShape {
  /// Creates a rect mask.
  const RectMask() : super._();
}

/// Oval mask.
final class OvalMask extends MaskShape {
  /// Creates an oval mask.
  const OvalMask() : super._();
}

/// Circle mask (inscribed using shorter side of the crop rect).
final class CircleMask extends MaskShape {
  /// Creates a circle mask.
  const CircleMask() : super._();
}

/// Polygon mask with vertices in unit space.
final class PolygonMask extends MaskShape {
  /// Creates a polygon mask. Requires at least 3 points.
  PolygonMask(this.points)
      : assert(points.length >= 3, 'polygon needs >= 3 points'),
        super._();

  /// Unit-space vertices.
  final List<Offset> points;
}

/// Mask defined by a caller-supplied [Path] builder.
final class CustomMask extends MaskShape {
  /// Creates a custom mask.
  CustomMask(this.builder) : super._();

  /// Builds the path given the current crop rect.
  final Path Function(Rect rect) builder;
}
