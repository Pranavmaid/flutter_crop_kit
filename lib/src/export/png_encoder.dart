import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../error/crop_exception.dart';
import '../mask/mask_shape.dart';
import '../mask/path_builder.dart';

/// Encodes the cropped region of [image] as a PNG.
///
/// When [rotation] is 0, takes the fast path (drawImageRect from src to dst).
/// Otherwise rotates the canvas and clips appropriately; the output dims are
/// the axis-aligned bounding box of the rotated [cropRect].
Future<Uint8List> encodePng({
  required ui.Image image,
  required ui.Rect cropRect,
  required double rotation,
  required MaskShape mask,
  int? targetWidth,
}) async {
  ui.Image rendered;
  if (rotation == 0) {
    rendered = await _renderFast(image, cropRect, mask);
  } else {
    rendered = await _renderRotated(image, cropRect, rotation, mask);
  }

  if (targetWidth != null && targetWidth != rendered.width) {
    rendered = await _resize(rendered, targetWidth);
  }

  final byteData = await rendered.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw const CropExportException('toByteData returned null');
  }
  return byteData.buffer.asUint8List();
}

Future<ui.Image> _renderFast(
  ui.Image image,
  ui.Rect cropRect,
  MaskShape mask,
) async {
  final w = cropRect.width.round();
  final h = cropRect.height.round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final dst = ui.Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  canvas.clipPath(buildMaskPath(mask, dst));
  canvas.drawImageRect(image, cropRect, dst, ui.Paint());
  return recorder.endRecording().toImage(w, h);
}

Future<ui.Image> _renderRotated(
  ui.Image image,
  ui.Rect cropRect,
  double rotation,
  MaskShape mask,
) async {
  final cos = math.cos(rotation).abs();
  final sin = math.sin(rotation).abs();
  final outW = (cropRect.width * cos + cropRect.height * sin).round();
  final outH = (cropRect.width * sin + cropRect.height * cos).round();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(outW / 2, outH / 2);
  canvas.rotate(-rotation);
  canvas.translate(-cropRect.center.dx, -cropRect.center.dy);

  canvas.clipPath(buildMaskPath(mask, cropRect));
  canvas.drawImage(image, ui.Offset.zero, ui.Paint());

  return recorder.endRecording().toImage(outW, outH);
}

Future<ui.Image> _resize(ui.Image image, int targetWidth) async {
  final ratio = image.height / image.width;
  final targetHeight = (targetWidth * ratio).round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    ui.Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  return recorder.endRecording().toImage(targetWidth, targetHeight);
}
