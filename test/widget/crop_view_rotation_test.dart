import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_view.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 256, height: 256, cell: 16);
  });

  testWidgets('rotateBy90 rebuilds widget', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.runAsync(() => c.whenReady);
    await tester.pumpWidget(MaterialApp(home: CropView(controller: c)));
    await tester.pump();

    c.rotateBy90();
    await tester.pump();
    expect(c.rotation, closeTo(math.pi / 2, 1e-9));
    c.dispose();
  });

  testWidgets('setRotation accepts free angle', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.runAsync(() => c.whenReady);
    await tester.pumpWidget(MaterialApp(home: CropView(controller: c)));
    await tester.pump();

    c.setRotation(0.5);
    await tester.pump();
    expect(c.rotation, 0.5);
    c.dispose();
  });
}
