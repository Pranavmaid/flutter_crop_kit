import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../geometry/transform.dart';
import '../mask/mask_shape.dart';
import '../mask/path_builder.dart';
import '../widgets/crop_theme.dart';

/// Paints the image, mask overlay, grid, border, and handles in one pass.
class CropPainter extends CustomPainter {
  /// Creates a painter snapshot.
  const CropPainter({
    required this.image,
    required this.cropRect,
    required this.rotation,
    required this.scale,
    required this.mask,
    required this.theme,
    required this.grid,
    required this.canvasSize,
  });

  /// Decoded image (null while loading).
  final ui.Image? image;

  /// Image-space crop rect.
  final Rect cropRect;

  /// Rotation in radians.
  final double rotation;

  /// Image scale relative to fit.
  final double scale;

  /// Mask shape.
  final MaskShape mask;

  /// Theme.
  final CropTheme theme;

  /// Grid overlay.
  final GridOverlay grid;

  /// Logical canvas size.
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) return;

    final imgSize = Size(img.width.toDouble(), img.height.toDouble());
    final base = fitScale(imgSize, size);
    final m = buildImageTransform(
      imageSize: imgSize,
      canvasSize: size,
      rotation: rotation,
      scale: base * scale,
    );

    canvas.save();
    canvas.transform(m.storage);
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();

    final canvasCrop = MatrixUtils.transformRect(m, cropRect);
    _drawMaskOverlay(canvas, size, canvasCrop);
    _drawGrid(canvas, canvasCrop);
    _drawBorder(canvas, canvasCrop);
    _drawHandles(canvas, canvasCrop);
  }

  void _drawMaskOverlay(Canvas canvas, Size size, Rect canvasCrop) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = buildMaskPath(mask, canvasCrop);
    final overlay = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(overlay, Paint()..color = theme.maskColor);
  }

  void _drawBorder(Canvas canvas, Rect rect) {
    if (theme.borderWidth <= 0) return;
    canvas.drawPath(
      buildMaskPath(mask, rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.borderWidth
        ..color = theme.borderColor,
    );
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final paint = Paint()..color = theme.handleColor;
    final r = theme.handleSize / 2;
    final pts = <Offset>[
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];
    for (final p in pts) {
      canvas.drawRect(
        Rect.fromCenter(center: p, width: r * 2, height: r * 2),
        paint,
      );
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    if (grid == GridOverlay.none || theme.gridWidth <= 0) return;
    final paint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridWidth;
    final fractions = switch (grid) {
      GridOverlay.thirds => const [1 / 3, 2 / 3],
      GridOverlay.grid3x3 => const [1 / 3, 2 / 3],
      GridOverlay.golden => const [0.382, 0.618],
      GridOverlay.none => const <double>[],
    };
    for (final f in fractions) {
      final x = rect.left + rect.width * f;
      final y = rect.top + rect.height * f;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CropPainter old) {
    return image != old.image ||
        cropRect != old.cropRect ||
        rotation != old.rotation ||
        scale != old.scale ||
        mask != old.mask ||
        theme != old.theme ||
        grid != old.grid ||
        canvasSize != old.canvasSize;
  }
}
