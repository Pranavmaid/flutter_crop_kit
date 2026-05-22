import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 128, height: 128, cell: 16);
  });

  testWidgets('showCropper returns null on cancel', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Uint8List? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCropper(
                  ctx,
                  source: ImageSource.memory(samplePng),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    // Drive image-load real-async, then settle frames.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump();

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('showCropper returns bytes on confirm', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Uint8List? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            return ElevatedButton(
              onPressed: () async {
                result = await showCropper(
                  ctx,
                  source: ImageSource.memory(samplePng),
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pump();

    await tester.tap(find.text('Done'));
    // The crop() call is itself async; drive it via runAsync until the route pops.
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.length, greaterThan(0));
  });
}
