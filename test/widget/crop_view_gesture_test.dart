import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/error/crop_exception.dart';
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

  Future<CropController> makeController() async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await c.whenReady;
    return c;
  }

  testWidgets('shows loading then image', (tester) async {
    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: CropView(controller: c),
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Let the async image load complete, then pump one frame to rebuild.
    await tester.runAsync(() => c.whenReady);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    c.dispose();
  });

  testWidgets('drag near corner resizes crop rect', (tester) async {
    // Force the surface to 400x400 so the crop canvas is exactly that size.
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = await tester.runAsync(makeController) as CropController;
    await tester.pumpWidget(
      MaterialApp(
        home: CropView(controller: c),
      ),
    );
    await tester.pump();

    final before = c.cropRect;
    // 256x256 image in 400x400 canvas: fitScale = 400/256 = 1.5625.
    // Canvas-space cropRect = (0,0,400,400). SE corner = (400,400).
    // Drag from (392,392) -- 8px inside the corner -- inward by (-50,-50).
    const dragStart = Offset(392, 392);
    await tester.dragFrom(dragStart, const Offset(-50, -50));
    await tester.pump();

    expect(c.cropRect, isNot(equals(before)));
    c.dispose();
  });

  testWidgets('error builder is shown on bad bytes', (tester) async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0, 1, 2, 3])),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 400,
          child: CropView(
            controller: c,
            errorBuilder: (BuildContext _, CropException e) =>
                Text('ERR:${e.message}'),
          ),
        ),
      ),
    );
    await tester.runAsync(() => c.whenReady.catchError((Object _) => null));
    await tester.pump();
    expect(find.textContaining('ERR:'), findsOneWidget);
    c.dispose();
  });
}
