import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 128, height: 128, cell: 16);
  });

  testWidgets('default loading shown before image ready', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.pumpWidget(MaterialApp(home: CropView(controller: c)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.runAsync(() => c.whenReady);
    await tester.pump();
    c.dispose();
  });

  testWidgets('default error widget on bad bytes', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0, 1, 2, 3])),
    );
    await tester.pumpWidget(MaterialApp(home: CropView(controller: c)));
    await tester.runAsync(
      () => c.whenReady.catchError((Object _) => null),
    );
    await tester.pump();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    c.dispose();
  });

  testWidgets('custom loading builder used', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final c = CropController(source: ImageSource.memory(samplePng));
    await tester.pumpWidget(
      MaterialApp(
        home: CropView(
          controller: c,
          loadingBuilder: (_) => const Text('LOADING'),
        ),
      ),
    );
    expect(find.text('LOADING'), findsOneWidget);

    await tester.runAsync(() => c.whenReady);
    await tester.pump();
    c.dispose();
  });
}
