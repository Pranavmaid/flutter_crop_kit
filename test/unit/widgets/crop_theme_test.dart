import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CropAspectRatio', () {
    test('exposes presets', () {
      expect(CropAspectRatio.square.width, 1);
      expect(CropAspectRatio.square.height, 1);
      expect(CropAspectRatio.r4x3.width, 4);
      expect(CropAspectRatio.r16x9.width, 16);
    });

    test('ratio() returns width/height', () {
      expect(const CropAspectRatio(3, 2).ratio(), closeTo(1.5, 1e-9));
    });

    test('asserts positive dimensions', () {
      expect(() => CropAspectRatio(0, 1), throwsAssertionError);
      expect(() => CropAspectRatio(1, 0), throwsAssertionError);
      expect(() => CropAspectRatio(-1, 1), throwsAssertionError);
    });
  });

  test('GridOverlay enum has 4 values', () {
    expect(GridOverlay.values, hasLength(4));
  });

  test('CropTheme defaults', () {
    const t = CropTheme();
    expect(t.handleSize, 24);
    expect(t.borderWidth, 2);
    expect(t.gridWidth, 1);
    expect(t.maskColor, const Color(0x99000000));
  });

  test('CropTheme copyWith preserves unchanged fields', () {
    const t = CropTheme();
    final t2 = t.copyWith(handleSize: 32);
    expect(t2.handleSize, 32);
    expect(t2.handleColor, t.handleColor);
  });
}
