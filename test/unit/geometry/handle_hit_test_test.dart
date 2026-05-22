import 'dart:ui';

import 'package:flutter_crop_kit/src/geometry/crop_rect.dart';
import 'package:flutter_crop_kit/src/geometry/handle_hit_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = Rect.fromLTWH(50, 50, 100, 100);
  const tol = 12.0;

  test('hit NW corner', () {
    expect(
      hitTestHandles(const Offset(52, 52), rect, tol),
      HandleTarget.cornerNW,
    );
  });

  test('hit SE corner', () {
    expect(
      hitTestHandles(const Offset(148, 148), rect, tol),
      HandleTarget.cornerSE,
    );
  });

  test('hit N edge mid', () {
    expect(
      hitTestHandles(const Offset(100, 52), rect, tol),
      HandleTarget.edgeN,
    );
  });

  test('hit E edge mid', () {
    expect(
      hitTestHandles(const Offset(148, 100), rect, tol),
      HandleTarget.edgeE,
    );
  });

  test('inside rect', () {
    expect(
      hitTestHandles(const Offset(100, 100), rect, tol),
      HandleTarget.inside,
    );
  });

  test('outside rect', () {
    expect(
      hitTestHandles(const Offset(10, 10), rect, tol),
      HandleTarget.outside,
    );
  });
}
