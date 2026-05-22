import 'dart:ui';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factories return correct subtype', () {
    expect(const MaskShape.rect(), isA<RectMask>());
    expect(const MaskShape.oval(), isA<OvalMask>());
    expect(const MaskShape.circle(), isA<CircleMask>());
    expect(
      MaskShape.polygon(const [Offset(0, 0), Offset(1, 0), Offset(0, 1)]),
      isA<PolygonMask>(),
    );
    expect(MaskShape.custom((r) => Path()), isA<CustomMask>());
  });

  test('PolygonMask < 3 points throws assertion in debug', () {
    expect(
      () => MaskShape.polygon(const [Offset(0, 0), Offset(1, 1)]),
      throwsAssertionError,
    );
  });

  test('PolygonMask retains points list', () {
    const pts = [Offset(0, 0), Offset(1, 0), Offset(0, 1)];
    final m = MaskShape.polygon(pts) as PolygonMask;
    expect(m.points, pts);
  });
}
