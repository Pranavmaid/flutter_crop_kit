import 'dart:typed_data';
import 'dart:ui' as ui;

/// Generates a deterministic checkerboard PNG.
/// Requires a live Flutter binding (use `TestWidgetsFlutterBinding.ensureInitialized()`
/// in the calling test).
Future<Uint8List> makeCheckerboardPng({
  required int width,
  required int height,
  required int cell,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final p1 = ui.Paint()..color = const ui.Color(0xFF000000);
  final p2 = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  for (var y = 0; y < height; y += cell) {
    for (var x = 0; x < width; x += cell) {
      final paint = ((x ~/ cell) + (y ~/ cell)) % 2 == 0 ? p1 : p2;
      canvas.drawRect(
        ui.Rect.fromLTWH(
          x.toDouble(),
          y.toDouble(),
          cell.toDouble(),
          cell.toDouble(),
        ),
        paint,
      );
    }
  }
  final img = await recorder.endRecording().toImage(width, height);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}
