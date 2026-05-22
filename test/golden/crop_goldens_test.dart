@Tags(['golden'])
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Uint8List samplePng;
  setUpAll(() async {
    samplePng = await makeCheckerboardPng(width: 256, height: 256, cell: 16);
  });

  Future<Widget> view({
    required MaskShape mask,
    GridOverlay grid = GridOverlay.thirds,
    double rotation = 0,
  }) async {
    final c = CropController(
      source: ImageSource.memory(samplePng),
      mask: mask,
      rotation: rotation,
    );
    return MaterialApp(
      home: _GoldenHost(controller: c, grid: grid),
    );
  }

  testWidgets('rect_crop_default_theme', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(await view(mask: const MaskShape.rect()));
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('rect_crop_default_theme.png'),
    );
  });

  testWidgets('circle_mask', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(await view(mask: const MaskShape.circle()));
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('circle_mask.png'),
    );
  });

  testWidgets('oval_mask', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(await view(mask: const MaskShape.oval()));
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('oval_mask.png'),
    );
  });

  testWidgets('polygon_mask_star', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    final star = MaskShape.polygon(const [
      Offset(0.5, 0.0),
      Offset(0.62, 0.38),
      Offset(1.0, 0.38),
      Offset(0.68, 0.59),
      Offset(0.79, 1.0),
      Offset(0.5, 0.75),
      Offset(0.21, 1.0),
      Offset(0.32, 0.59),
      Offset(0.0, 0.38),
      Offset(0.38, 0.38),
    ]);
    await t.pumpWidget(await view(mask: star));
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('polygon_mask_star.png'),
    );
  });

  testWidgets('grid_overlay_thirds', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    final w =
        await view(mask: const MaskShape.rect(), grid: GridOverlay.thirds);
    await t.pumpWidget(w);
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('grid_overlay_thirds.png'),
    );
  });

  testWidgets('rotation_45deg', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    final w =
        await view(mask: const MaskShape.rect(), rotation: 0.7853981633974483);
    await t.pumpWidget(w);
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('rotation_45deg.png'),
    );
  });

  testWidgets('handles_at_corners', (t) async {
    t.view.physicalSize = const Size(400, 400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);

    await t.pumpWidget(await view(mask: const MaskShape.rect()));
    await t.runAsync(_settle);
    await t.pump();
    await expectLater(
      find.byType(CropView),
      matchesGoldenFile('handles_at_corners.png'),
    );
  });
}

Future<void> _settle() async {
  await Future<void>.delayed(const Duration(milliseconds: 50));
}

class _GoldenHost extends StatefulWidget {
  const _GoldenHost({required this.controller, required this.grid});
  final CropController controller;
  final GridOverlay grid;
  @override
  State<_GoldenHost> createState() => _GoldenHostState();
}

class _GoldenHostState extends State<_GoldenHost> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CropView(controller: widget.controller, gridOverlay: widget.grid);
  }
}
