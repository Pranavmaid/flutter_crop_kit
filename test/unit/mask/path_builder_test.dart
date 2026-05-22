import 'dart:ui';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_crop_kit/src/mask/path_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = Rect.fromLTWH(10, 20, 100, 50);

  test('rect mask bounds match rect', () {
    final p = buildMaskPath(const RectMask(), rect);
    expect(p.getBounds(), rect);
  });

  test('oval mask bounds match rect', () {
    final p = buildMaskPath(const OvalMask(), rect);
    expect(p.getBounds().width, closeTo(rect.width, 1e-3));
    expect(p.getBounds().height, closeTo(rect.height, 1e-3));
  });

  test('circle mask uses shorter side, centered', () {
    final p = buildMaskPath(const CircleMask(), rect);
    final b = p.getBounds();
    expect(b.width, closeTo(50, 1e-3));
    expect(b.height, closeTo(50, 1e-3));
    expect(b.center, rect.center);
  });

  test('polygon mask maps unit space into rect', () {
    final m = PolygonMask(const [Offset(0, 0), Offset(1, 0), Offset(0.5, 1)]);
    final p = buildMaskPath(m, rect);
    final b = p.getBounds();
    expect(b.left, closeTo(rect.left, 1e-3));
    expect(b.top, closeTo(rect.top, 1e-3));
    expect(b.right, closeTo(rect.right, 1e-3));
    expect(b.bottom, closeTo(rect.bottom, 1e-3));
  });

  test('custom mask passes rect to builder', () {
    Rect? seen;
    final m = CustomMask((r) {
      seen = r;
      return Path()..addRect(r);
    });
    buildMaskPath(m, rect);
    expect(seen, rect);
  });
}
