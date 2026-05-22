import 'package:flutter/material.dart';

/// Width/height aspect ratio used to constrain the crop rect.
///
/// Named [CropAspectRatio] (not `AspectRatio`) to avoid colliding with
/// Flutter's `AspectRatio` widget in user code.
@immutable
class CropAspectRatio {
  /// Creates an aspect ratio. Both dimensions must be > 0.
  const CropAspectRatio(this.width, this.height)
      : assert(width > 0, 'width must be > 0'),
        assert(height > 0, 'height must be > 0');

  /// 1:1.
  static const CropAspectRatio square = CropAspectRatio(1, 1);

  /// 4:3.
  static const CropAspectRatio r4x3 = CropAspectRatio(4, 3);

  /// 16:9.
  static const CropAspectRatio r16x9 = CropAspectRatio(16, 9);

  /// Width side of the ratio.
  final double width;

  /// Height side of the ratio.
  final double height;

  /// width / height.
  double ratio() => width / height;

  @override
  bool operator ==(Object other) =>
      other is CropAspectRatio &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Grid overlay variant drawn on top of the crop rect.
enum GridOverlay {
  /// No grid.
  none,

  /// Rule of thirds (2 vertical + 2 horizontal lines).
  thirds,

  /// Golden ratio split.
  golden,

  /// 3x3 (2 vertical + 2 horizontal, same as thirds; reserved for future variants).
  grid3x3,
}

/// Visual theme for a [CropView].
@immutable
class CropTheme {
  /// Creates a theme.
  const CropTheme({
    this.maskColor = const Color(0x99000000),
    this.handleColor = Colors.white,
    this.handleSize = 24,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.gridColor = const Color(0x66FFFFFF),
    this.gridWidth = 1,
  })  : assert(handleSize > 0, 'handleSize must be > 0'),
        assert(borderWidth >= 0, 'borderWidth must be >= 0'),
        assert(gridWidth >= 0, 'gridWidth must be >= 0');

  /// Color used to dim the area outside the crop rect.
  final Color maskColor;

  /// Color of the resize handles.
  final Color handleColor;

  /// Visual size of a handle in logical pixels.
  final double handleSize;

  /// Color of the rect border.
  final Color borderColor;

  /// Width of the rect border in logical pixels.
  final double borderWidth;

  /// Color of the grid lines.
  final Color gridColor;

  /// Width of the grid lines in logical pixels.
  final double gridWidth;

  /// Returns a copy with the given fields replaced.
  CropTheme copyWith({
    Color? maskColor,
    Color? handleColor,
    double? handleSize,
    Color? borderColor,
    double? borderWidth,
    Color? gridColor,
    double? gridWidth,
  }) =>
      CropTheme(
        maskColor: maskColor ?? this.maskColor,
        handleColor: handleColor ?? this.handleColor,
        handleSize: handleSize ?? this.handleSize,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        gridColor: gridColor ?? this.gridColor,
        gridWidth: gridWidth ?? this.gridWidth,
      );
}
