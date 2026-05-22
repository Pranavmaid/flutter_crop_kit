import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_crop_kit/src/widgets/crop_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 256, height: 256, cell: 16);
  });

  testWidgets('setting aspectRatio after corner drag locks ratio',
      (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.runAsync(() => c.whenReady);

    await tester.pumpWidget(MaterialApp(home: CropView(controller: c)));
    await tester.pump();

    // Set aspect lock to square first, then resize the rect via drag.
    // The image is 256x256 in a 400x400 canvas.
    // fitScale = 400/256 = 1.5625. Transform: T(200,200)*S(1.5625)*T(-128,-128).
    // Full image maps to canvas: left=31.25, top=31.25, right=368.75, bottom=368.75.
    // SE handle of the full image is near (368.75, 368.75).
    c.setAspectRatio(CropAspectRatio.square);
    await tester.pump();

    // Drag SE corner inward; both dx and dy move together forcing a square.
    // Start near the SE corner of the full-image canvas rect.
    await tester.dragFrom(const Offset(365, 365), const Offset(-60, -60));
    await tester.pump();

    final r = c.cropRect;
    expect(r.width / r.height, closeTo(1.0, 1e-2));

    c.dispose();
  });
}
