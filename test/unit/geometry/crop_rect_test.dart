import 'dart:ui';
import 'package:flutter_crop_kit/src/geometry/crop_rect.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bounds = Rect.fromLTWH(0, 0, 200, 100);

  group('clampToBounds', () {
    test('rect inside bounds is unchanged', () {
      const r = Rect.fromLTWH(10, 10, 50, 30);
      expect(clampToBounds(r, bounds), r);
    });

    test('rect partially outside is shifted in', () {
      const r = Rect.fromLTWH(-10, -20, 50, 30);
      expect(clampToBounds(r, bounds), const Rect.fromLTWH(0, 0, 50, 30));
    });

    test('rect bigger than bounds is shrunk', () {
      const r = Rect.fromLTWH(0, 0, 300, 200);
      expect(clampToBounds(r, bounds), bounds);
    });
  });

  group('enforceMinSize', () {
    test('keeps rect if above min', () {
      const r = Rect.fromLTWH(0, 0, 50, 50);
      expect(enforceMinSize(r, 32), r);
    });

    test('grows from center if below min', () {
      const r = Rect.fromLTWH(10, 10, 10, 10);
      final out = enforceMinSize(r, 32);
      expect(out.width, 32);
      expect(out.height, 32);
      expect(out.center, const Offset(15, 15));
    });
  });

  group('resizeWithHandle', () {
    test('NE drag shrinks from top-right, anchored at bottom-left', () {
      const start = Rect.fromLTWH(10, 10, 80, 80);
      final out = resizeWithHandle(
        start,
        HandleTarget.cornerNE,
        const Offset(-10, 10),
        aspect: null,
      );
      expect(out.left, 10);
      expect(out.bottom, 90);
      expect(out.right, 80);
      expect(out.top, 20);
    });

    test('aspect lock 2:1 preserved when dragging E', () {
      const start = Rect.fromLTWH(0, 0, 40, 20);
      final out = resizeWithHandle(
        start,
        HandleTarget.edgeE,
        const Offset(20, 0),
        aspect: const CropAspectRatio(2, 1),
      );
      expect(out.width / out.height, closeTo(2.0, 1e-9));
    });

    test('inside translate moves rect', () {
      const start = Rect.fromLTWH(10, 10, 50, 50);
      final out = resizeWithHandle(
        start,
        HandleTarget.inside,
        const Offset(5, -3),
        aspect: null,
      );
      expect(out, const Rect.fromLTWH(15, 7, 50, 50));
    });
  });
}
