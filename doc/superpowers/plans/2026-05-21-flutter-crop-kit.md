# flutter_crop_kit Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship v0.1 of `flutter_crop_kit`, a pure-Dart cross-platform Flutter image cropper, to pub.dev.

**Architecture:** Monolithic `CropView` (StatefulWidget) listens to a `CropController extends ChangeNotifier`. One `CustomPainter` (`CropPainter`) paints image + mask + grid + handles in a single pass. One `RawGestureRecognizer` (`CropGestureRecognizer`) handles corner/edge/inside/outside pinch+pan. PNG export uses `dart:ui` `PictureRecorder` + `toByteData(png)`.

**Tech Stack:** Dart 3.4+, Flutter SDK only (no third-party runtime deps), `dart:ui`, `dart:io` (non-web sources), `flutter_test`, `dart:async`.

---

## File Map

| Path | Responsibility |
|---|---|
| `pubspec.yaml` | Package manifest, Flutter only dep |
| `lib/flutter_crop_kit.dart` | Public barrel export |
| `lib/src/geometry/crop_rect.dart` | Rect clamp + aspect lock + resize math |
| `lib/src/geometry/transform.dart` | Image↔canvas↔gesture transform matrices |
| `lib/src/geometry/handle_hit_test.dart` | Map gesture pos → corner/edge/inside/outside |
| `lib/src/mask/mask_shape.dart` | Sealed `MaskShape` types |
| `lib/src/mask/path_builder.dart` | Build `Path` from `MaskShape` + `Rect` |
| `lib/src/source/image_source.dart` | Sealed `ImageSource` + loader |
| `lib/src/widgets/crop_theme.dart` | `CropTheme`, `CropAspectRatio`, `GridOverlay` |
| `lib/src/error/crop_exception.dart` | Exception hierarchy |
| `lib/src/controller/crop_controller.dart` | State + lifecycle + stream + crop() |
| `lib/src/export/png_encoder.dart` | PictureRecorder → PNG bytes |
| `lib/src/painter/crop_painter.dart` | Paint image+mask+grid+handles |
| `lib/src/gestures/crop_gesture_recognizer.dart` | Pan/pinch recognizer |
| `lib/src/widgets/crop_view.dart` | The main widget |
| `lib/src/widgets/crop_dialog.dart` | `showCropper` route helper |
| `example/` | Demo app |
| `test/` | unit/widget/golden tests |
| `.github/workflows/ci.yaml` | CI matrix |

---

### Task 1: Project scaffold

**Files:**
- Create: `pubspec.yaml`
- Create: `analysis_options.yaml`
- Create: `LICENSE`
- Create: `CHANGELOG.md`
- Create: `README.md`
- Create: `lib/flutter_crop_kit.dart`
- Create: `.gitignore`

- [ ] **Step 1: Write pubspec.yaml**

```yaml
name: flutter_crop_kit
description: A pure-Dart Flutter image cropper that runs identically on mobile, web, desktop, and embedded targets.
version: 0.1.0
homepage: https://github.com/pranavmaid/flutter_crop_kit
repository: https://github.com/pranavmaid/flutter_crop_kit
issue_tracker: https://github.com/pranavmaid/flutter_crop_kit/issues
environment:
  sdk: ^3.4.0
  flutter: ">=3.22.0"
dependencies:
  flutter:
    sdk: flutter
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
flutter:
```

- [ ] **Step 2: Write analysis_options.yaml**

```yaml
include: package:flutter_lints/flutter.yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    invalid_annotation_target: ignore
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_constructors_in_immutables
    - prefer_const_declarations
    - prefer_final_locals
    - require_trailing_commas
    - public_member_api_docs
```

- [ ] **Step 3: Write LICENSE (MIT)**

```
MIT License

Copyright (c) 2026 pranav

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Write CHANGELOG.md stub**

```markdown
# Changelog

## 0.1.0

Initial release.
```

- [ ] **Step 5: Write minimal README.md stub**

```markdown
# flutter_crop_kit

Pure-Dart Flutter image cropper.

See [docs/superpowers/specs/2026-05-21-flutter-crop-kit-design.md](docs/superpowers/specs/2026-05-21-flutter-crop-kit-design.md) for design.
```

- [ ] **Step 6: Write barrel file with TODO comment for now**

```dart
/// Pure-Dart Flutter image cropper.
library flutter_crop_kit;
```

- [ ] **Step 7: Write .gitignore**

```
.dart_tool/
.packages
build/
.pub-cache/
.pub/
pubspec.lock
*.iml
.idea/
.vscode/
coverage/
```

- [ ] **Step 8: Verify pub install + analyze pass**

Run: `flutter pub get && flutter analyze`
Expected: `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add pubspec.yaml analysis_options.yaml LICENSE CHANGELOG.md README.md lib/flutter_crop_kit.dart .gitignore
git commit -m "chore: scaffold pub package"
```

---

### Task 2: CropAspectRatio, GridOverlay, CropTheme

**Files:**
- Create: `lib/src/widgets/crop_theme.dart`
- Test: `test/unit/widgets/crop_theme_test.dart`

- [ ] **Step 1: Write failing test**

```dart
// test/unit/widgets/crop_theme_test.dart
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
```

- [ ] **Step 2: Run test, expect fail**

Run: `flutter test test/unit/widgets/crop_theme_test.dart`
Expected: import fails, file missing.

- [ ] **Step 3: Implement crop_theme.dart**

```dart
import 'package:flutter/material.dart';

/// Width/height aspect ratio used to constrain the crop rect.
@immutable
class CropAspectRatio {
  /// Creates an aspect ratio. Both dimensions must be > 0.
  const CropAspectRatio(this.width, this.height)
      : assert(width > 0, 'width must be > 0'),
        assert(height > 0, 'height must be > 0');

  /// 1:1.
  static const CropAspectRatio square = CropAspectRatio(1, 1);

  /// 4:3.
  static const CropAspectRatio r4x3 = CropAspectRatio(4, 3);

  /// 16:9.
  static const CropAspectRatio r16x9 = CropAspectRatio(16, 9);

  /// Width side of the ratio.
  final double width;

  /// Height side of the ratio.
  final double height;

  /// width / height.
  double ratio() => width / height;

  @override
  bool operator ==(Object other) =>
      other is CropAspectRatio && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);
}

/// Grid overlay variant drawn on top of the crop rect.
enum GridOverlay {
  /// No grid.
  none,

  /// Rule of thirds (2 vertical + 2 horizontal lines).
  thirds,

  /// Golden ratio split.
  golden,

  /// 3×3 (2 vertical + 2 horizontal, same as thirds; reserved for future variants).
  grid3x3,
}

/// Visual theme for a [CropView].
@immutable
class CropTheme {
  /// Creates a theme.
  const CropTheme({
    this.maskColor = const Color(0x99000000),
    this.handleColor = Colors.white,
    this.handleSize = 24,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.gridColor = const Color(0x66FFFFFF),
    this.gridWidth = 1,
  })  : assert(handleSize > 0, 'handleSize must be > 0'),
        assert(borderWidth >= 0, 'borderWidth must be >= 0'),
        assert(gridWidth >= 0, 'gridWidth must be >= 0');

  /// Color used to dim the area outside the crop rect.
  final Color maskColor;

  /// Color of the resize handles.
  final Color handleColor;

  /// Visual size of a handle in logical pixels.
  final double handleSize;

  /// Color of the rect border.
  final Color borderColor;

  /// Width of the rect border in logical pixels.
  final double borderWidth;

  /// Color of the grid lines.
  final Color gridColor;

  /// Width of the grid lines in logical pixels.
  final double gridWidth;

  /// Returns a copy with the given fields replaced.
  CropTheme copyWith({
    Color? maskColor,
    Color? handleColor,
    double? handleSize,
    Color? borderColor,
    double? borderWidth,
    Color? gridColor,
    double? gridWidth,
  }) =>
      CropTheme(
        maskColor: maskColor ?? this.maskColor,
        handleColor: handleColor ?? this.handleColor,
        handleSize: handleSize ?? this.handleSize,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        gridColor: gridColor ?? this.gridColor,
        gridWidth: gridWidth ?? this.gridWidth,
      );
}
```

- [ ] **Step 4: Run test, expect pass**

Run: `flutter test test/unit/widgets/crop_theme_test.dart`
Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/widgets/crop_theme.dart test/unit/widgets/crop_theme_test.dart
git commit -m "feat(theme): add CropTheme, CropAspectRatio, GridOverlay"
```

---

### Task 3: CropException hierarchy

**Files:**
- Create: `lib/src/error/crop_exception.dart`
- Test: `test/unit/error/crop_exception_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'package:flutter_crop_kit/src/error/crop_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CropException subtypes carry message', () {
    expect(const CropLoadException('boom').message, 'boom');
    expect(const CropImageTooLargeException('big').message, 'big');
    expect(const CropExportException('export').message, 'export');
  });

  test('toString includes type and message', () {
    expect(const CropLoadException('x').toString(),
        'CropLoadException: x');
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/error/crop_exception_test.dart`
Expected: import unresolved.

- [ ] **Step 3: Implement**

```dart
/// Base class for all errors emitted by flutter_crop_kit.
sealed class CropException implements Exception {
  /// Creates an exception with a [message].
  const CropException(this.message);

  /// Human-readable message.
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Thrown when an [ImageSource] fails to load.
final class CropLoadException extends CropException {
  /// Creates a load exception.
  const CropLoadException(super.message);
}

/// Thrown when a decoded image exceeds the configured pixel budget.
final class CropImageTooLargeException extends CropException {
  /// Creates a too-large exception.
  const CropImageTooLargeException(super.message);
}

/// Thrown when PNG export fails.
final class CropExportException extends CropException {
  /// Creates an export exception.
  const CropExportException(super.message);
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/error/crop_exception_test.dart`
Expected: All pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/error/crop_exception.dart test/unit/error/crop_exception_test.dart
git commit -m "feat(error): add CropException hierarchy"
```

---

### Task 4: MaskShape sealed types

**Files:**
- Create: `lib/src/mask/mask_shape.dart`
- Test: `test/unit/mask/mask_shape_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:ui';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('factories return correct subtype', () {
    expect(const MaskShape.rect(), isA<RectMask>());
    expect(const MaskShape.oval(), isA<OvalMask>());
    expect(const MaskShape.circle(), isA<CircleMask>());
    expect(MaskShape.polygon(const [Offset(0,0), Offset(1,0), Offset(0,1)]),
        isA<PolygonMask>());
    expect(MaskShape.custom((r) => Path()), isA<CustomMask>());
  });

  test('PolygonMask < 3 points throws assertion in debug', () {
    expect(() => MaskShape.polygon(const [Offset(0,0), Offset(1,1)]),
        throwsAssertionError);
  });

  test('PolygonMask retains points list', () {
    final pts = const [Offset(0,0), Offset(1,0), Offset(0,1)];
    final m = MaskShape.polygon(pts) as PolygonMask;
    expect(m.points, pts);
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/mask/mask_shape_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:ui';

/// Shape of the crop mask. Sealed; use the factories.
sealed class MaskShape {
  const MaskShape._();

  /// Rectangular mask.
  const factory MaskShape.rect() = RectMask;

  /// Oval inscribed in the crop rect.
  const factory MaskShape.oval() = OvalMask;

  /// Circle inscribed in the crop rect (uses shorter side).
  const factory MaskShape.circle() = CircleMask;

  /// Polygon in unit space (0..1) mapped into the crop rect.
  /// [points] must contain at least 3 entries in `[0,1]×[0,1]`.
  factory MaskShape.polygon(List<Offset> points) = PolygonMask;

  /// Custom mask via a [Path] builder receiving the crop rect.
  factory MaskShape.custom(Path Function(Rect rect) builder) = CustomMask;
}

/// Rect mask.
final class RectMask extends MaskShape {
  /// Creates a rect mask.
  const RectMask() : super._();
}

/// Oval mask.
final class OvalMask extends MaskShape {
  /// Creates an oval mask.
  const OvalMask() : super._();
}

/// Circle mask (inscribed using shorter side of the crop rect).
final class CircleMask extends MaskShape {
  /// Creates a circle mask.
  const CircleMask() : super._();
}

/// Polygon mask with vertices in unit space.
final class PolygonMask extends MaskShape {
  /// Creates a polygon mask. Requires at least 3 points.
  PolygonMask(this.points)
      : assert(points.length >= 3, 'polygon needs >= 3 points'),
        super._();

  /// Unit-space vertices.
  final List<Offset> points;
}

/// Mask defined by a caller-supplied [Path] builder.
final class CustomMask extends MaskShape {
  /// Creates a custom mask.
  CustomMask(this.builder) : super._();

  /// Builds the path given the current crop rect.
  final Path Function(Rect rect) builder;
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/mask/mask_shape_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/mask/mask_shape.dart test/unit/mask/mask_shape_test.dart
git commit -m "feat(mask): add sealed MaskShape types"
```

---

### Task 5: PathBuilder (MaskShape → Path)

**Files:**
- Create: `lib/src/mask/path_builder.dart`
- Test: `test/unit/mask/path_builder_test.dart`

- [ ] **Step 1: Write failing test**

```dart
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
    final m = PolygonMask(const [Offset(0,0), Offset(1,0), Offset(0.5,1)]);
    final p = buildMaskPath(m, rect);
    final b = p.getBounds();
    expect(b.left, closeTo(rect.left, 1e-3));
    expect(b.top, closeTo(rect.top, 1e-3));
    expect(b.right, closeTo(rect.right, 1e-3));
    expect(b.bottom, closeTo(rect.bottom, 1e-3));
  });

  test('custom mask passes rect to builder', () {
    Rect? seen;
    final m = CustomMask((r) { seen = r; return Path()..addRect(r); });
    buildMaskPath(m, rect);
    expect(seen, rect);
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/mask/path_builder_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:ui';

import 'mask_shape.dart';

/// Builds a [Path] that matches [shape] when drawn inside [rect].
Path buildMaskPath(MaskShape shape, Rect rect) {
  switch (shape) {
    case RectMask():
      return Path()..addRect(rect);
    case OvalMask():
      return Path()..addOval(rect);
    case CircleMask():
      final side = rect.shortestSide;
      final r = Rect.fromCenter(center: rect.center, width: side, height: side);
      return Path()..addOval(r);
    case PolygonMask(:final points):
      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final pt = points[i];
        final x = rect.left + pt.dx * rect.width;
        final y = rect.top + pt.dy * rect.height;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      return path;
    case CustomMask(:final builder):
      return builder(rect);
  }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/mask/path_builder_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/mask/path_builder.dart test/unit/mask/path_builder_test.dart
git commit -m "feat(mask): build Path from MaskShape"
```

---

### Task 6: CropRect geometry (clamp + aspect + resize)

**Files:**
- Create: `lib/src/geometry/crop_rect.dart`
- Test: `test/unit/geometry/crop_rect_test.dart`

- [ ] **Step 1: Write failing test**

```dart
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
        start, HandleTarget.cornerNE, const Offset(-10, 10),
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
        start, HandleTarget.edgeE, const Offset(20, 0),
        aspect: const CropAspectRatio(2, 1),
      );
      expect(out.width / out.height, closeTo(2.0, 1e-9));
    });

    test('inside translate moves rect', () {
      const start = Rect.fromLTWH(10, 10, 50, 50);
      final out = resizeWithHandle(
        start, HandleTarget.inside, const Offset(5, -3),
        aspect: null,
      );
      expect(out, const Rect.fromLTWH(15, 7, 50, 50));
    });
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/geometry/crop_rect_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:ui';

import '../widgets/crop_theme.dart';

/// Which part of the crop rect is being manipulated.
enum HandleTarget {
  /// Top-left corner.
  cornerNW,
  /// Top-right corner.
  cornerNE,
  /// Bottom-right corner.
  cornerSE,
  /// Bottom-left corner.
  cornerSW,
  /// Top edge.
  edgeN,
  /// Right edge.
  edgeE,
  /// Bottom edge.
  edgeS,
  /// Left edge.
  edgeW,
  /// Anywhere inside the rect (pan).
  inside,
  /// Outside the rect (pinch-zoom).
  outside,
}

/// Returns [rect] adjusted to lie entirely within [bounds].
/// If [rect] is larger than [bounds], it is clamped to [bounds].
Rect clampToBounds(Rect rect, Rect bounds) {
  final w = rect.width.clamp(0.0, bounds.width).toDouble();
  final h = rect.height.clamp(0.0, bounds.height).toDouble();
  final left = rect.left.clamp(bounds.left, bounds.right - w).toDouble();
  final top = rect.top.clamp(bounds.top, bounds.bottom - h).toDouble();
  return Rect.fromLTWH(left, top, w, h);
}

/// Ensures [rect] is at least [min] on both sides, growing from its center.
Rect enforceMinSize(Rect rect, double min) {
  if (rect.width >= min && rect.height >= min) return rect;
  final w = rect.width < min ? min : rect.width;
  final h = rect.height < min ? min : rect.height;
  return Rect.fromCenter(center: rect.center, width: w, height: h);
}

/// Applies a gesture delta to [rect] based on [target].
/// If [aspect] is non-null, preserves the ratio.
Rect resizeWithHandle(
  Rect rect,
  HandleTarget target,
  Offset delta, {
  required CropAspectRatio? aspect,
}) {
  double l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
  switch (target) {
    case HandleTarget.inside:
      return rect.shift(delta);
    case HandleTarget.outside:
      return rect;
    case HandleTarget.cornerNW:
      l += delta.dx; t += delta.dy;
    case HandleTarget.cornerNE:
      r += delta.dx; t += delta.dy;
    case HandleTarget.cornerSE:
      r += delta.dx; b += delta.dy;
    case HandleTarget.cornerSW:
      l += delta.dx; b += delta.dy;
    case HandleTarget.edgeN:
      t += delta.dy;
    case HandleTarget.edgeE:
      r += delta.dx;
    case HandleTarget.edgeS:
      b += delta.dy;
    case HandleTarget.edgeW:
      l += delta.dx;
  }
  var out = Rect.fromLTRB(
    l < r ? l : r,
    t < b ? t : b,
    l < r ? r : l,
    t < b ? b : t,
  );
  if (aspect != null) {
    out = _applyAspect(out, target, aspect.ratio());
  }
  return out;
}

Rect _applyAspect(Rect rect, HandleTarget target, double ratio) {
  final w = rect.width;
  final h = rect.height;
  final useWidth = switch (target) {
    HandleTarget.edgeN || HandleTarget.edgeS => false,
    HandleTarget.edgeE || HandleTarget.edgeW => true,
    _ => w / h > ratio,
  };
  if (useWidth) {
    final newH = w / ratio;
    switch (target) {
      case HandleTarget.cornerNW || HandleTarget.cornerNE || HandleTarget.edgeN:
        return Rect.fromLTRB(rect.left, rect.bottom - newH, rect.right, rect.bottom);
      case HandleTarget.cornerSW || HandleTarget.cornerSE || HandleTarget.edgeS:
        return Rect.fromLTRB(rect.left, rect.top, rect.right, rect.top + newH);
      default:
        return Rect.fromCenter(center: rect.center, width: w, height: newH);
    }
  } else {
    final newW = h * ratio;
    switch (target) {
      case HandleTarget.cornerNW || HandleTarget.cornerSW || HandleTarget.edgeW:
        return Rect.fromLTRB(rect.right - newW, rect.top, rect.right, rect.bottom);
      case HandleTarget.cornerNE || HandleTarget.cornerSE || HandleTarget.edgeE:
        return Rect.fromLTRB(rect.left, rect.top, rect.left + newW, rect.bottom);
      default:
        return Rect.fromCenter(center: rect.center, width: newW, height: h);
    }
  }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/geometry/crop_rect_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/geometry/crop_rect.dart test/unit/geometry/crop_rect_test.dart
git commit -m "feat(geometry): add CropRect clamp/resize/aspect math"
```

---

### Task 7: Transform composition

**Files:**
- Create: `lib/src/geometry/transform.dart`
- Test: `test/unit/geometry/transform_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/geometry/transform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identity when rotation=0 scale=1 image centered on canvas same size', () {
    const imageSize = Size(100, 100);
    const canvasSize = Size(100, 100);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: 0,
      scale: 1,
    );
    final p = MatrixUtils.transformPoint(m, const Offset(50, 50));
    expect(p.dx, closeTo(50, 1e-6));
    expect(p.dy, closeTo(50, 1e-6));
  });

  test('rotate 90deg maps top-center of image to right-center of canvas', () {
    const imageSize = Size(100, 100);
    const canvasSize = Size(100, 100);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: math.pi / 2,
      scale: 1,
    );
    final p = MatrixUtils.transformPoint(m, const Offset(50, 0));
    expect(p.dx, closeTo(100, 1e-6));
    expect(p.dy, closeTo(50, 1e-6));
  });

  test('invertTransform produces inverse', () {
    const imageSize = Size(200, 100);
    const canvasSize = Size(400, 200);
    final m = buildImageTransform(
      imageSize: imageSize,
      canvasSize: canvasSize,
      rotation: 0.5,
      scale: 1.2,
    );
    final inv = invertTransform(m);
    final src = const Offset(37, 19);
    final fwd = MatrixUtils.transformPoint(m, src);
    final back = MatrixUtils.transformPoint(inv, fwd);
    expect(back.dx, closeTo(src.dx, 1e-3));
    expect(back.dy, closeTo(src.dy, 1e-3));
  });

  test('fitScale returns scale that fits image inside canvas preserving ratio', () {
    expect(fitScale(const Size(200, 100), const Size(100, 100)),
        closeTo(0.5, 1e-9));
    expect(fitScale(const Size(100, 200), const Size(100, 100)),
        closeTo(0.5, 1e-9));
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/geometry/transform_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show Matrix4;

/// Builds the matrix that maps image-space → canvas-space.
///
/// Composition: T(canvasCenter) * R(rotation) * S(scale) * T(-imageCenter).
Matrix4 buildImageTransform({
  required Size imageSize,
  required Size canvasSize,
  required double rotation,
  required double scale,
}) {
  final m = Matrix4.identity();
  m.translate(canvasSize.width / 2, canvasSize.height / 2);
  m.rotateZ(rotation);
  m.scale(scale, scale);
  m.translate(-imageSize.width / 2, -imageSize.height / 2);
  return m;
}

/// Returns the inverse of [m].
///
/// Throws [StateError] if [m] is singular.
Matrix4 invertTransform(Matrix4 m) {
  final inv = Matrix4.copy(m);
  final det = inv.invert();
  if (det == 0) {
    throw StateError('Transform is singular and cannot be inverted');
  }
  return inv;
}

/// Returns the uniform scale factor that fits [contentSize] inside [boxSize]
/// preserving aspect ratio (i.e. `min(sx, sy)`).
double fitScale(Size contentSize, Size boxSize) {
  final sx = boxSize.width / contentSize.width;
  final sy = boxSize.height / contentSize.height;
  return math.min(sx, sy);
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/geometry/transform_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/geometry/transform.dart test/unit/geometry/transform_test.dart
git commit -m "feat(geometry): add image transform + inverse"
```

---

### Task 8: HandleHitTest

**Files:**
- Create: `lib/src/geometry/handle_hit_test.dart`
- Test: `test/unit/geometry/handle_hit_test_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:ui';
import 'package:flutter_crop_kit/src/geometry/crop_rect.dart';
import 'package:flutter_crop_kit/src/geometry/handle_hit_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const rect = Rect.fromLTWH(50, 50, 100, 100);
  const tol = 12.0;

  test('hit NW corner', () {
    expect(hitTestHandles(const Offset(52, 52), rect, tol),
        HandleTarget.cornerNW);
  });

  test('hit SE corner', () {
    expect(hitTestHandles(const Offset(148, 148), rect, tol),
        HandleTarget.cornerSE);
  });

  test('hit N edge mid', () {
    expect(hitTestHandles(const Offset(100, 52), rect, tol),
        HandleTarget.edgeN);
  });

  test('hit E edge mid', () {
    expect(hitTestHandles(const Offset(148, 100), rect, tol),
        HandleTarget.edgeE);
  });

  test('inside rect', () {
    expect(hitTestHandles(const Offset(100, 100), rect, tol),
        HandleTarget.inside);
  });

  test('outside rect', () {
    expect(hitTestHandles(const Offset(10, 10), rect, tol),
        HandleTarget.outside);
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/geometry/handle_hit_test_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:ui';

import 'crop_rect.dart';

/// Returns which [HandleTarget] [point] lies in for a crop [rect],
/// using [tolerance] (logical px) as the corner/edge fuzz radius.
HandleTarget hitTestHandles(Offset point, Rect rect, double tolerance) {
  bool near(double a, double b) => (a - b).abs() <= tolerance;

  final nearLeft = near(point.dx, rect.left);
  final nearRight = near(point.dx, rect.right);
  final nearTop = near(point.dy, rect.top);
  final nearBottom = near(point.dy, rect.bottom);

  final insideX = point.dx >= rect.left - tolerance &&
      point.dx <= rect.right + tolerance;
  final insideY = point.dy >= rect.top - tolerance &&
      point.dy <= rect.bottom + tolerance;

  if (nearLeft && nearTop) return HandleTarget.cornerNW;
  if (nearRight && nearTop) return HandleTarget.cornerNE;
  if (nearRight && nearBottom) return HandleTarget.cornerSE;
  if (nearLeft && nearBottom) return HandleTarget.cornerSW;
  if (nearTop && insideX) return HandleTarget.edgeN;
  if (nearBottom && insideX) return HandleTarget.edgeS;
  if (nearLeft && insideY) return HandleTarget.edgeW;
  if (nearRight && insideY) return HandleTarget.edgeE;
  if (rect.contains(point)) return HandleTarget.inside;
  return HandleTarget.outside;
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/geometry/handle_hit_test_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/geometry/handle_hit_test.dart test/unit/geometry/handle_hit_test_test.dart
git commit -m "feat(geometry): add HandleHitTest"
```

---

### Task 9: ImageSource sealed + loaders

**Files:**
- Create: `lib/src/source/image_source.dart`
- Create: `test/fixtures/sample_image.png` (programmatic, see step 1)
- Test: `test/unit/source/image_source_test.dart`

- [ ] **Step 1: Generate test fixtures script**

Create file `tool/gen_fixtures.dart`:

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<Uint8List> _checkerboard(int w, int h, int cell) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final p1 = ui.Paint()..color = const ui.Color(0xFF000000);
  final p2 = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
  for (var y = 0; y < h; y += cell) {
    for (var x = 0; x < w; x += cell) {
      final paint = ((x ~/ cell) + (y ~/ cell)) % 2 == 0 ? p1 : p2;
      canvas.drawRect(
          ui.Rect.fromLTWH(x.toDouble(), y.toDouble(), cell.toDouble(), cell.toDouble()),
          paint);
    }
  }
  final img = await recorder.endRecording().toImage(w, h);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  return bd!.buffer.asUint8List();
}

Future<void> main() async {
  Directory('test/fixtures').createSync(recursive: true);
  await File('test/fixtures/sample_image.png').writeAsBytes(await _checkerboard(512, 512, 32));
  await File('test/fixtures/tall_image.png').writeAsBytes(await _checkerboard(200, 800, 25));
  await File('test/fixtures/wide_image.png').writeAsBytes(await _checkerboard(800, 200, 25));
  print('Fixtures generated.');
}
```

Run: `dart run tool/gen_fixtures.dart`
Expected: three PNGs created under `test/fixtures/`.

- [ ] **Step 2: Write failing test**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MemorySource loads decoded image', () async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final src = ImageSource.memory(Uint8List.fromList(bytes));
    final img = await loadImageSource(src);
    expect(img.width, 512);
    expect(img.height, 512);
  });

  test('FileSource loads from disk', () async {
    final src = ImageSource.file(File('test/fixtures/wide_image.png'));
    final img = await loadImageSource(src);
    expect(img.width, 800);
    expect(img.height, 200);
  });

  test('FileSource missing file throws CropLoadException', () async {
    final src = ImageSource.file(File('does/not/exist.png'));
    expect(loadImageSource(src), throwsA(isA<Exception>()));
  });

  test('MemorySource empty bytes asserts', () {
    expect(() => ImageSource.memory(Uint8List(0)), throwsAssertionError);
  });
}
```

- [ ] **Step 3: Run, expect fail**

Run: `flutter test test/unit/source/image_source_test.dart`

- [ ] **Step 4: Implement**

```dart
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../error/crop_exception.dart';

/// Where to read the image bytes from.
sealed class ImageSource {
  const ImageSource._();

  /// Source from in-memory bytes.
  factory ImageSource.memory(Uint8List bytes) = MemorySource;

  /// Source from a [File] on disk (non-web).
  factory ImageSource.file(File file) = FileSource;

  /// Source from a network URL (HTTPS recommended).
  factory ImageSource.network(String url, {Map<String, String>? headers}) =
      NetworkSource;

  /// Source from a Flutter asset.
  factory ImageSource.asset(String path, {AssetBundle? bundle}) = AssetSource;
}

/// In-memory bytes.
final class MemorySource extends ImageSource {
  /// Creates a memory source. Bytes must be non-empty.
  MemorySource(this.bytes)
      : assert(bytes.length > 0, 'bytes must be non-empty'),
        super._();

  /// Raw image bytes.
  final Uint8List bytes;
}

/// File-system source.
final class FileSource extends ImageSource {
  /// Creates a file source.
  FileSource(this.file) : super._();

  /// File handle to read.
  final File file;
}

/// Network source.
final class NetworkSource extends ImageSource {
  /// Creates a network source.
  NetworkSource(this.url, {this.headers}) : super._();

  /// URL to GET.
  final String url;

  /// Optional headers.
  final Map<String, String>? headers;
}

/// Asset bundle source.
final class AssetSource extends ImageSource {
  /// Creates an asset source. Uses [rootBundle] when [bundle] is null.
  AssetSource(this.path, {this.bundle}) : super._();

  /// Asset path.
  final String path;

  /// Optional bundle.
  final AssetBundle? bundle;
}

/// Loads an [ImageSource] and decodes it via `dart:ui`.
///
/// Throws [CropLoadException] on any I/O or decode failure.
Future<ui.Image> loadImageSource(ImageSource source) async {
  final bytes = await _loadBytes(source);
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (e) {
    throw CropLoadException('Failed to decode image: $e');
  }
}

Future<Uint8List> _loadBytes(ImageSource source) async {
  try {
    switch (source) {
      case MemorySource(:final bytes):
        return bytes;
      case FileSource(:final file):
        return await file.readAsBytes();
      case NetworkSource(:final url, :final headers):
        return await _fetchHttp(url, headers);
      case AssetSource(:final path, :final bundle):
        final data = await (bundle ?? rootBundle).load(path);
        return data.buffer.asUint8List();
    }
  } on CropLoadException {
    rethrow;
  } catch (e) {
    throw CropLoadException('Failed to load image source: $e');
  }
}

Future<Uint8List> _fetchHttp(String url, Map<String, String>? headers) async {
  final client = HttpClient();
  try {
    final req = await client.getUrl(Uri.parse(url));
    headers?.forEach(req.headers.add);
    final res = await req.close();
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw CropLoadException('HTTP ${res.statusCode} for $url');
    }
    final bb = BytesBuilder(copy: false);
    await for (final chunk in res) {
      bb.add(chunk);
    }
    return bb.takeBytes();
  } finally {
    client.close(force: true);
  }
}
```

- [ ] **Step 5: Run, expect pass**

Run: `flutter test test/unit/source/image_source_test.dart`

- [ ] **Step 6: Commit**

```bash
git add lib/src/source/image_source.dart test/unit/source/image_source_test.dart tool/gen_fixtures.dart test/fixtures
git commit -m "feat(source): sealed ImageSource + loader with fixtures"
```

---

### Task 10: PNG encoder (fast + rotated paths)

**Files:**
- Create: `lib/src/export/png_encoder.dart`
- Test: `test/unit/export/png_encoder_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_crop_kit/src/export/png_encoder.dart';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Image> _decode(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes));
  return (await codec.getNextFrame()).image;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fast path: output bytes decode to cropRect size', () async {
    final img = await _decode('test/fixtures/sample_image.png');
    final bytes = await encodePng(
      image: img,
      cropRect: const Rect.fromLTWH(64, 64, 256, 128),
      rotation: 0,
      mask: const MaskShape.rect(),
    );
    final outCodec = await ui.instantiateImageCodec(bytes);
    final out = (await outCodec.getNextFrame()).image;
    expect(out.width, 256);
    expect(out.height, 128);
  });

  test('rotated path: output is axis-aligned bbox of rotated rect', () async {
    final img = await _decode('test/fixtures/sample_image.png');
    final bytes = await encodePng(
      image: img,
      cropRect: const Rect.fromLTWH(100, 100, 200, 100),
      rotation: 1.5707963267948966, // 90 deg
      mask: const MaskShape.rect(),
    );
    final outCodec = await ui.instantiateImageCodec(bytes);
    final out = (await outCodec.getNextFrame()).image;
    // 90deg rotation swaps w/h
    expect(out.width, 100);
    expect(out.height, 200);
  });

  test('targetWidth resizes output preserving aspect', () async {
    final img = await _decode('test/fixtures/sample_image.png');
    final bytes = await encodePng(
      image: img,
      cropRect: const Rect.fromLTWH(0, 0, 400, 200),
      rotation: 0,
      mask: const MaskShape.rect(),
      targetWidth: 200,
    );
    final outCodec = await ui.instantiateImageCodec(bytes);
    final out = (await outCodec.getNextFrame()).image;
    expect(out.width, 200);
    expect(out.height, 100);
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/export/png_encoder_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../error/crop_exception.dart';
import '../mask/mask_shape.dart';
import '../mask/path_builder.dart';

/// Encodes the cropped region of [image] as a PNG.
///
/// When [rotation] is 0, takes the fast path (drawImageRect from src to dst).
/// Otherwise rotates the canvas and clips appropriately; the output dims are
/// the axis-aligned bounding box of the rotated [cropRect].
Future<Uint8List> encodePng({
  required ui.Image image,
  required Rect cropRect,
  required double rotation,
  required MaskShape mask,
  int? targetWidth,
}) async {
  ui.Image rendered;
  if (rotation == 0) {
    rendered = await _renderFast(image, cropRect, mask);
  } else {
    rendered = await _renderRotated(image, cropRect, rotation, mask);
  }

  if (targetWidth != null && targetWidth != rendered.width) {
    rendered = await _resize(rendered, targetWidth);
  }

  final byteData =
      await rendered.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw const CropExportException('toByteData returned null');
  }
  return byteData.buffer.asUint8List();
}

Future<ui.Image> _renderFast(
    ui.Image image, Rect cropRect, MaskShape mask) async {
  final w = cropRect.width.round();
  final h = cropRect.height.round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final dst = Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble());
  canvas.clipPath(buildMaskPath(mask, dst));
  canvas.drawImageRect(image, cropRect, dst, ui.Paint());
  return recorder.endRecording().toImage(w, h);
}

Future<ui.Image> _renderRotated(
    ui.Image image, Rect cropRect, double rotation, MaskShape mask) async {
  final cos = math.cos(rotation).abs();
  final sin = math.sin(rotation).abs();
  final outW = (cropRect.width * cos + cropRect.height * sin).round();
  final outH = (cropRect.width * sin + cropRect.height * cos).round();

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.translate(outW / 2, outH / 2);
  canvas.rotate(-rotation);
  canvas.translate(-cropRect.center.dx, -cropRect.center.dy);

  canvas.clipPath(buildMaskPath(mask, cropRect));
  canvas.drawImage(image, Offset.zero, ui.Paint());

  return recorder.endRecording().toImage(outW, outH);
}

Future<ui.Image> _resize(ui.Image image, int targetWidth) async {
  final ratio = image.height / image.width;
  final targetHeight = (targetWidth * ratio).round();
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawImageRect(
    image,
    Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
    Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()),
    ui.Paint()..filterQuality = ui.FilterQuality.medium,
  );
  return recorder.endRecording().toImage(targetWidth, targetHeight);
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/export/png_encoder_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/export/png_encoder.dart test/unit/export/png_encoder_test.dart
git commit -m "feat(export): PNG encoder with fast + rotated paths"
```

---

### Task 11: CropController init + state

**Files:**
- Create: `lib/src/controller/crop_controller.dart`
- Test: `test/unit/controller/crop_controller_test.dart`

- [ ] **Step 1: Write failing test (init + lifecycle)**

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Uint8List> sample() async =>
      File('test/fixtures/sample_image.png').readAsBytes();

  test('isReady transitions from false to true after load', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(await sample())),
    );
    expect(c.isReady, false);
    await c.whenReady;
    expect(c.isReady, true);
    expect(c.image, isA<ui.Image>());
    expect(c.cropRect, const Rect.fromLTWH(0, 0, 512, 512));
    c.dispose();
  });

  test('mutations notify listeners exactly once', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(await sample())),
    );
    await c.whenReady;
    var calls = 0;
    c.addListener(() => calls++);
    c.setAspectRatio(CropAspectRatio.square);
    expect(calls, 1);
    c.setMask(const MaskShape.circle());
    expect(calls, 2);
    c.rotateBy90();
    expect(calls, 3);
    c.dispose();
  });

  test('rotateBy90 increments by pi/2', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(await sample())),
    );
    await c.whenReady;
    c.rotateBy90();
    expect(c.rotation, closeTo(1.5707963267948966, 1e-9));
    c.rotateBy90();
    expect(c.rotation, closeTo(3.141592653589793, 1e-9));
    c.dispose();
  });

  test('reset restores initial cropRect, rotation', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(await sample())),
    );
    await c.whenReady;
    c.rotateBy90();
    c.reset();
    expect(c.rotation, 0);
    expect(c.cropRect, const Rect.fromLTWH(0, 0, 512, 512));
    c.dispose();
  });

  test('error state set on invalid bytes', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0, 1, 2, 3])),
    );
    await c.whenReady.catchError((_) => null);
    expect(c.isReady, false);
    expect(c.error, isNotNull);
    c.dispose();
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/controller/crop_controller_test.dart`

- [ ] **Step 3: Implement controller**

```dart
import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../error/crop_exception.dart';
import '../export/png_encoder.dart';
import '../mask/mask_shape.dart';
import '../source/image_source.dart';
import '../widgets/crop_theme.dart';

/// Source of truth for a crop session.
///
/// Mutations call [notifyListeners] exactly once each. Subscribe to
/// [cropRectStream] for a debounced stream of the live crop rect.
class CropController extends ChangeNotifier {
  /// Creates a controller bound to [source].
  CropController({
    required ImageSource source,
    CropAspectRatio? aspectRatio,
    MaskShape mask = const MaskShape.rect(),
    double rotation = 0,
  })  : _source = source,
        _aspectRatio = aspectRatio,
        _mask = mask,
        _rotation = rotation {
    _ready = _load();
  }

  final ImageSource _source;
  late final Future<void> _ready;
  ui.Image? _image;
  Rect _cropRect = Rect.zero;
  double _rotation;
  CropAspectRatio? _aspectRatio;
  MaskShape _mask;
  CropException? _error;
  bool _disposed = false;

  final StreamController<Rect> _rectController =
      StreamController<Rect>.broadcast();
  Timer? _streamDebounce;

  /// Future that completes when image is loaded (or errors).
  Future<void> get whenReady => _ready;

  /// Decoded image, or null if not yet loaded.
  ui.Image? get image => _image;

  /// Current crop rect in image space.
  Rect get cropRect => _cropRect;

  /// Current rotation in radians.
  double get rotation => _rotation;

  /// Current mask shape.
  MaskShape get mask => _mask;

  /// Current aspect ratio lock, or null for free.
  CropAspectRatio? get aspectRatio => _aspectRatio;

  /// True after the image has loaded successfully.
  bool get isReady => _image != null;

  /// Most recent load/export error, or null.
  CropException? get error => _error;

  /// Broadcast stream of crop rect updates, debounced ~16ms.
  Stream<Rect> get cropRectStream => _rectController.stream;

  Future<void> _load() async {
    try {
      final img = await loadImageSource(_source);
      if (_disposed) {
        img.dispose();
        return;
      }
      _image = img;
      _cropRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      _error = null;
      notifyListeners();
    } on CropException catch (e) {
      _error = e;
      notifyListeners();
    } catch (e) {
      _error = CropLoadException(e.toString());
      notifyListeners();
    }
  }

  /// Sets the aspect ratio lock. Pass null to clear.
  void setAspectRatio(CropAspectRatio? r) {
    _aspectRatio = r;
    notifyListeners();
  }

  /// Sets the mask shape.
  void setMask(MaskShape m) {
    _mask = m;
    notifyListeners();
  }

  /// Rotates by 90 degrees [clockwise].
  void rotateBy90({bool clockwise = true}) {
    const quarter = 1.5707963267948966;
    _rotation += clockwise ? quarter : -quarter;
    notifyListeners();
  }

  /// Sets rotation to [radians] absolute.
  void setRotation(double radians) {
    assert(radians.isFinite, 'rotation must be finite');
    _rotation = radians;
    notifyListeners();
  }

  /// Updates the crop rect (internal, used by gesture handlers).
  @protected
  void updateCropRect(Rect rect) {
    _cropRect = rect;
    notifyListeners();
    _streamDebounce?.cancel();
    _streamDebounce = Timer(const Duration(milliseconds: 16), () {
      if (!_disposed && !_rectController.isClosed) {
        _rectController.add(_cropRect);
      }
    });
  }

  /// Resets crop rect to full image and rotation to 0.
  void reset() {
    final img = _image;
    if (img != null) {
      _cropRect = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    }
    _rotation = 0;
    notifyListeners();
  }

  /// Exports the current crop region as PNG bytes.
  ///
  /// Optionally resizes to [targetWidth] preserving aspect.
  Future<Uint8List> crop({int? targetWidth}) async {
    final img = _image;
    if (img == null) {
      throw StateError('Image not loaded');
    }
    if (_disposed) {
      throw StateError('Controller disposed');
    }
    try {
      return await encodePng(
        image: img,
        cropRect: _cropRect,
        rotation: _rotation,
        mask: _mask,
        targetWidth: targetWidth,
      );
    } catch (e) {
      _error = e is CropException
          ? e
          : CropExportException(e.toString());
      throw _error!;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _streamDebounce?.cancel();
    _rectController.close();
    _image?.dispose();
    super.dispose();
  }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/controller/crop_controller_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/controller/crop_controller.dart test/unit/controller/crop_controller_test.dart
git commit -m "feat(controller): CropController lifecycle + mutations"
```

---

### Task 12: Controller crop() + stream tests

**Files:**
- Modify: `test/unit/controller/crop_controller_test.dart`

- [ ] **Step 1: Add failing test for crop() output**

Append to existing test file:

```dart
  test('crop() returns PNG bytes matching cropRect dimensions', () async {
    final c = CropController(
      source: ImageSource.memory(
          Uint8List.fromList(await File('test/fixtures/sample_image.png').readAsBytes())),
    );
    await c.whenReady;
    final bytes = await c.crop();
    final codec = await ui.instantiateImageCodec(bytes);
    final out = (await codec.getNextFrame()).image;
    expect(out.width, 512);
    expect(out.height, 512);
    c.dispose();
  });

  test('cropRectStream emits debounced updates', () async {
    final c = CropController(
      source: ImageSource.memory(
          Uint8List.fromList(await File('test/fixtures/sample_image.png').readAsBytes())),
    );
    await c.whenReady;
    final emissions = <Rect>[];
    final sub = c.cropRectStream.listen(emissions.add);
    c.updateCropRect(const Rect.fromLTWH(0, 0, 100, 100));
    c.updateCropRect(const Rect.fromLTWH(0, 0, 200, 200));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.length, 1);
    expect(emissions.last, const Rect.fromLTWH(0, 0, 200, 200));
    await sub.cancel();
    c.dispose();
  });

  test('crop() before ready throws StateError', () async {
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList([0,1,2,3])),
    );
    expect(c.crop, throwsStateError);
    c.dispose();
  });
```

- [ ] **Step 2: Run, expect pass**

Run: `flutter test test/unit/controller/crop_controller_test.dart`
Expected: all tests including new ones pass.

- [ ] **Step 3: Commit**

```bash
git add test/unit/controller/crop_controller_test.dart
git commit -m "test(controller): cover crop() and rectStream"
```

---

### Task 13: CropPainter

**Files:**
- Create: `lib/src/painter/crop_painter.dart`
- Test: `test/unit/painter/crop_painter_test.dart`

- [ ] **Step 1: Write failing test (smoke + no-image fallback)**

```dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/mask/mask_shape.dart';
import 'package:flutter_crop_kit/src/painter/crop_painter.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shouldRepaint returns true on different state', () {
    final a = CropPainter(
      image: null,
      cropRect: const Rect.fromLTWH(0,0,10,10),
      rotation: 0,
      scale: 1,
      mask: const MaskShape.rect(),
      theme: const CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: const Size(100,100),
    );
    final b = CropPainter(
      image: null,
      cropRect: const Rect.fromLTWH(0,0,20,20),
      rotation: 0,
      scale: 1,
      mask: const MaskShape.rect(),
      theme: const CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: const Size(100,100),
    );
    expect(b.shouldRepaint(a), true);
  });

  test('shouldRepaint false on identical state', () {
    CropPainter make() => CropPainter(
      image: null,
      cropRect: const Rect.fromLTWH(0,0,10,10),
      rotation: 0,
      scale: 1,
      mask: const MaskShape.rect(),
      theme: const CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: const Size(100,100),
    );
    expect(make().shouldRepaint(make()), false);
  });

  test('paint with null image does not throw', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final painter = CropPainter(
      image: null,
      cropRect: const Rect.fromLTWH(0,0,10,10),
      rotation: 0,
      scale: 1,
      mask: const MaskShape.rect(),
      theme: const CropTheme(),
      grid: GridOverlay.thirds,
      canvasSize: const Size(100,100),
    );
    expect(() => painter.paint(canvas, const Size(100, 100)), returnsNormally);
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/unit/painter/crop_painter_test.dart`

- [ ] **Step 3: Implement painter**

```dart
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../geometry/transform.dart';
import '../mask/mask_shape.dart';
import '../mask/path_builder.dart';
import '../widgets/crop_theme.dart';

/// Paints the image, mask overlay, grid, border, and handles in one pass.
class CropPainter extends CustomPainter {
  /// Creates a painter snapshot.
  const CropPainter({
    required this.image,
    required this.cropRect,
    required this.rotation,
    required this.scale,
    required this.mask,
    required this.theme,
    required this.grid,
    required this.canvasSize,
  });

  /// Decoded image (null while loading).
  final ui.Image? image;

  /// Image-space crop rect.
  final Rect cropRect;

  /// Rotation in radians.
  final double rotation;

  /// Image scale relative to fit.
  final double scale;

  /// Mask shape.
  final MaskShape mask;

  /// Theme.
  final CropTheme theme;

  /// Grid overlay.
  final GridOverlay grid;

  /// Logical canvas size.
  final Size canvasSize;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null) return;

    final imgSize = Size(img.width.toDouble(), img.height.toDouble());
    final base = fitScale(imgSize, size);
    final m = buildImageTransform(
      imageSize: imgSize,
      canvasSize: size,
      rotation: rotation,
      scale: base * scale,
    );

    canvas.save();
    canvas.transform(m.storage);
    canvas.drawImage(img, Offset.zero, Paint());
    canvas.restore();

    final canvasCrop = MatrixUtils.transformRect(m, cropRect);
    _drawMaskOverlay(canvas, size, canvasCrop);
    _drawGrid(canvas, canvasCrop);
    _drawBorder(canvas, canvasCrop);
    _drawHandles(canvas, canvasCrop);
  }

  void _drawMaskOverlay(Canvas canvas, Size size, Rect canvasCrop) {
    final outer = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = buildMaskPath(mask, canvasCrop);
    final overlay = Path.combine(PathOperation.difference, outer, hole);
    canvas.drawPath(overlay, Paint()..color = theme.maskColor);
  }

  void _drawBorder(Canvas canvas, Rect rect) {
    if (theme.borderWidth <= 0) return;
    canvas.drawPath(
      buildMaskPath(mask, rect),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = theme.borderWidth
        ..color = theme.borderColor,
    );
  }

  void _drawHandles(Canvas canvas, Rect rect) {
    final paint = Paint()..color = theme.handleColor;
    final r = theme.handleSize / 2;
    final pts = <Offset>[
      rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight,
    ];
    for (final p in pts) {
      canvas.drawRect(Rect.fromCenter(center: p, width: r * 2, height: r * 2), paint);
    }
  }

  void _drawGrid(Canvas canvas, Rect rect) {
    if (grid == GridOverlay.none || theme.gridWidth <= 0) return;
    final paint = Paint()
      ..color = theme.gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = theme.gridWidth;
    final fractions = switch (grid) {
      GridOverlay.thirds || GridOverlay.grid3x3 => const [1/3, 2/3],
      GridOverlay.golden => const [0.382, 0.618],
      GridOverlay.none => const <double>[],
    };
    for (final f in fractions) {
      final x = rect.left + rect.width * f;
      final y = rect.top + rect.height * f;
      canvas.drawLine(Offset(x, rect.top), Offset(x, rect.bottom), paint);
      canvas.drawLine(Offset(rect.left, y), Offset(rect.right, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CropPainter old) {
    return image != old.image ||
        cropRect != old.cropRect ||
        rotation != old.rotation ||
        scale != old.scale ||
        mask != old.mask ||
        theme != old.theme ||
        grid != old.grid ||
        canvasSize != old.canvasSize;
  }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/unit/painter/crop_painter_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/painter/crop_painter.dart test/unit/painter/crop_painter_test.dart
git commit -m "feat(painter): CropPainter with mask/grid/handles"
```

---

### Task 14: CropGestureRecognizer

**Files:**
- Create: `lib/src/gestures/crop_gesture_recognizer.dart`

This component wires gestures into the controller. We test it via widget tests in Task 15. No standalone unit test (PointerEvent plumbing is testable only through widgets).

- [ ] **Step 1: Implement**

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Callback for pan updates with the local position and delta.
typedef CropPanCallback = void Function(Offset localPosition, Offset delta);

/// Callback for two-finger scale.
typedef CropScaleCallback = void Function(double scaleDelta);

/// Custom recognizer that emits pan + pinch events, accepting eagerly to win
/// over enclosing scrollables.
class CropGestureRecognizer extends OneSequenceGestureRecognizer {
  /// Creates a recognizer.
  CropGestureRecognizer({
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onScaleUpdate,
    super.debugOwner,
  });

  /// Called on first pointer down with the local position.
  final void Function(Offset) onPanStart;

  /// Called for every move with delta in local space.
  final CropPanCallback onPanUpdate;

  /// Called when all pointers go up.
  final VoidCallback onPanEnd;

  /// Called when 2 pointers move; delta is the scale multiplier.
  final CropScaleCallback onScaleUpdate;

  final Map<int, Offset> _pointers = {};
  double? _lastPinchDist;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event);
    _pointers[event.pointer] = event.localPosition;
    if (_pointers.length == 1) {
      onPanStart(event.localPosition);
    }
    resolve(GestureDisposition.accepted);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final prev = _pointers[event.pointer];
      _pointers[event.pointer] = event.localPosition;
      if (_pointers.length == 1 && prev != null) {
        onPanUpdate(event.localPosition, event.localPosition - prev);
      } else if (_pointers.length == 2) {
        final pts = _pointers.values.toList();
        final dist = (pts[0] - pts[1]).distance;
        if (_lastPinchDist != null && _lastPinchDist! > 0) {
          onScaleUpdate(dist / _lastPinchDist!);
        }
        _lastPinchDist = dist;
      }
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      stopTrackingPointer(event.pointer);
      _pointers.remove(event.pointer);
      if (_pointers.isEmpty) {
        _lastPinchDist = null;
        onPanEnd();
      } else if (_pointers.length < 2) {
        _lastPinchDist = null;
      }
    }
  }

  @override
  String get debugDescription => 'cropGesture';

  @override
  void didStopTrackingLastPointer(int pointer) {}
}
```

- [ ] **Step 2: Verify compile**

Run: `flutter analyze`
Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add lib/src/gestures/crop_gesture_recognizer.dart
git commit -m "feat(gestures): pan+pinch recognizer"
```

---

### Task 15: CropView widget

**Files:**
- Create: `lib/src/widgets/crop_view.dart`
- Test: `test/widget/crop_view_gesture_test.dart`

- [ ] **Step 1: Write failing widget test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<CropController> makeController() async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(bytes)),
    );
    await c.whenReady;
    return c;
  }

  testWidgets('shows loading then image', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    c.dispose();
  });

  testWidgets('drag inside crop rect translates', (tester) async {
    final c = await makeController();
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    await tester.pumpAndSettle();
    final before = c.cropRect;
    final center = tester.getCenter(find.byType(CropView));
    await tester.dragFrom(center, const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(c.cropRect, isNot(equals(before)));
    c.dispose();
  });

  testWidgets('error builder is shown on bad bytes', (tester) async {
    final c = CropController(source: ImageSource.memory(Uint8List.fromList([0,1,2,3])));
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400, height: 400,
        child: CropView(
          controller: c,
          errorBuilder: (_, e) => Text('ERR:${e.message}'),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('ERR:'), findsOneWidget);
    c.dispose();
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/widget/crop_view_gesture_test.dart`

- [ ] **Step 3: Implement CropView**

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../controller/crop_controller.dart';
import '../error/crop_exception.dart';
import '../geometry/crop_rect.dart';
import '../geometry/handle_hit_test.dart';
import '../geometry/transform.dart';
import '../gestures/crop_gesture_recognizer.dart';
import '../painter/crop_painter.dart';
import 'crop_theme.dart';

/// Builder for a custom error widget given an exception.
typedef CropErrorBuilder = Widget Function(BuildContext, CropException);

/// Builder for a custom loading widget.
typedef CropLoadingBuilder = Widget Function(BuildContext);

/// Main cropper widget. Drive it via a [CropController].
class CropView extends StatefulWidget {
  /// Creates a [CropView].
  const CropView({
    required this.controller,
    this.theme = const CropTheme(),
    this.gridOverlay = GridOverlay.thirds,
    this.errorBuilder,
    this.loadingBuilder,
    super.key,
  });

  /// Controller (lifecycle managed by caller).
  final CropController controller;

  /// Visual theme.
  final CropTheme theme;

  /// Grid overlay variant.
  final GridOverlay gridOverlay;

  /// Custom error widget builder.
  final CropErrorBuilder? errorBuilder;

  /// Custom loading widget builder.
  final CropLoadingBuilder? loadingBuilder;

  @override
  State<CropView> createState() => _CropViewState();
}

class _CropViewState extends State<CropView> {
  HandleTarget _activeTarget = HandleTarget.inside;
  double _userScale = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void didUpdateWidget(covariant CropView old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_onChange);
      widget.controller.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.error != null) {
      return (widget.errorBuilder ?? _defaultError)(context, c.error!);
    }
    if (!c.isReady) {
      return (widget.loadingBuilder ?? _defaultLoading)(context);
    }
    return LayoutBuilder(builder: (ctx, constraints) {
      final size = constraints.biggest;
      return RawGestureDetector(
        gestures: <Type, GestureRecognizerFactory>{
          CropGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<CropGestureRecognizer>(
            () => CropGestureRecognizer(
              onPanStart: (pos) => _onStart(pos, size),
              onPanUpdate: (pos, delta) => _onUpdate(pos, delta, size),
              onPanEnd: () {},
              onScaleUpdate: _onScale,
            ),
            (_) {},
          ),
        },
        child: CustomPaint(
          size: size,
          painter: CropPainter(
            image: c.image,
            cropRect: c.cropRect,
            rotation: c.rotation,
            scale: _userScale,
            mask: c.mask,
            theme: widget.theme,
            grid: widget.gridOverlay,
            canvasSize: size,
          ),
        ),
      );
    });
  }

  void _onStart(Offset localPos, Size size) {
    final c = widget.controller;
    final img = c.image!;
    final m = buildImageTransform(
      imageSize: Size(img.width.toDouble(), img.height.toDouble()),
      canvasSize: size,
      rotation: c.rotation,
      scale: fitScale(
              Size(img.width.toDouble(), img.height.toDouble()), size) *
          _userScale,
    );
    final canvasRect = MatrixUtils.transformRect(m, c.cropRect);
    _activeTarget = hitTestHandles(localPos, canvasRect, 24);
  }

  void _onUpdate(Offset localPos, Offset delta, Size size) {
    final c = widget.controller;
    final img = c.image!;
    final imgSize = Size(img.width.toDouble(), img.height.toDouble());
    final m = buildImageTransform(
      imageSize: imgSize,
      canvasSize: size,
      rotation: c.rotation,
      scale: fitScale(imgSize, size) * _userScale,
    );
    final inv = invertTransform(m);
    final imageDelta =
        MatrixUtils.transformPoint(inv, delta) - MatrixUtils.transformPoint(inv, Offset.zero);
    final next = resizeWithHandle(
      c.cropRect,
      _activeTarget,
      imageDelta,
      aspect: c.aspectRatio,
    );
    final imgBounds = Rect.fromLTWH(0, 0, imgSize.width, imgSize.height);
    final clamped =
        clampToBounds(enforceMinSize(next, 32), imgBounds);
    c.updateCropRect(clamped);
  }

  void _onScale(double scaleDelta) {
    setState(() {
      _userScale = (_userScale * scaleDelta).clamp(0.5, 8.0);
    });
  }
}

Widget _defaultLoading(BuildContext _) =>
    const Center(child: CircularProgressIndicator());

Widget _defaultError(BuildContext _, CropException e) => Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image),
          Text(e.message),
        ],
      ),
    );
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/widget/crop_view_gesture_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/widgets/crop_view.dart test/widget/crop_view_gesture_test.dart
git commit -m "feat(widget): CropView with gesture wiring"
```

---

### Task 16: Aspect-lock and rotation widget tests

**Files:**
- Test: `test/widget/crop_view_aspect_lock_test.dart`
- Test: `test/widget/crop_view_rotation_test.dart`

- [ ] **Step 1: Write aspect-lock test**

```dart
// test/widget/crop_view_aspect_lock_test.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_theme.dart';
import 'package:flutter_crop_kit/src/widgets/crop_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setting aspectRatio reshapes rect to that ratio after gesture',
      (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await c.whenReady;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.setAspectRatio(CropAspectRatio.square);

    final center = tester.getCenter(find.byType(CropView));
    await tester.dragFrom(
        center + const Offset(195, 0), const Offset(-50, 0));
    await tester.pumpAndSettle();

    final r = c.cropRect;
    expect(r.width / r.height, closeTo(1.0, 1e-2));
    c.dispose();
  });
}
```

- [ ] **Step 2: Write rotation test**

```dart
// test/widget/crop_view_rotation_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/controller/crop_controller.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('rotateBy90 rebuilds widget', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await c.whenReady;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.rotateBy90();
    await tester.pump();
    expect(c.rotation, closeTo(math.pi / 2, 1e-9));
    c.dispose();
  });

  testWidgets('setRotation accepts free angle', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await c.whenReady;
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    await tester.pumpAndSettle();
    c.setRotation(0.5);
    await tester.pump();
    expect(c.rotation, 0.5);
    c.dispose();
  });
}
```

- [ ] **Step 3: Run tests, expect pass**

Run: `flutter test test/widget/`
Expected: All widget tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/widget/crop_view_aspect_lock_test.dart test/widget/crop_view_rotation_test.dart
git commit -m "test(widget): aspect lock + rotation behavior"
```

---

### Task 17: CropDialog + showCropper

**Files:**
- Create: `lib/src/widgets/crop_dialog.dart`
- Test: `test/widget/crop_dialog_test.dart`

- [ ] **Step 1: Write failing test**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_crop_kit/src/widgets/crop_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('showCropper returns null on cancel', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    Uint8List? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () async {
            result = await showCropper(ctx,
                source: ImageSource.memory(Uint8List.fromList(bytes)));
          },
          child: const Text('open'),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isNull);
  });

  testWidgets('showCropper returns bytes on confirm', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    Uint8List? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (ctx) {
        return ElevatedButton(
          onPressed: () async {
            result = await showCropper(ctx,
                source: ImageSource.memory(Uint8List.fromList(bytes)));
          },
          child: const Text('open'),
        );
      }),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(result, isNotNull);
    expect(result!.length, greaterThan(0));
  });
}
```

- [ ] **Step 2: Run, expect fail**

Run: `flutter test test/widget/crop_dialog_test.dart`

- [ ] **Step 3: Implement**

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../controller/crop_controller.dart';
import '../mask/mask_shape.dart';
import '../source/image_source.dart';
import 'crop_theme.dart';
import 'crop_view.dart';

/// Pushes a full-screen cropper route. Returns PNG bytes on confirm, or null
/// on cancel.
Future<Uint8List?> showCropper(
  BuildContext context, {
  required ImageSource source,
  CropAspectRatio? aspectRatio,
  MaskShape mask = const MaskShape.rect(),
  CropTheme theme = const CropTheme(),
  String confirmLabel = 'Done',
  String cancelLabel = 'Cancel',
}) {
  return Navigator.of(context).push<Uint8List?>(
    MaterialPageRoute<Uint8List?>(
      fullscreenDialog: true,
      builder: (_) => _CropperScaffold(
        source: source,
        aspectRatio: aspectRatio,
        mask: mask,
        theme: theme,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    ),
  );
}

class _CropperScaffold extends StatefulWidget {
  const _CropperScaffold({
    required this.source,
    required this.aspectRatio,
    required this.mask,
    required this.theme,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  final ImageSource source;
  final CropAspectRatio? aspectRatio;
  final MaskShape mask;
  final CropTheme theme;
  final String confirmLabel;
  final String cancelLabel;

  @override
  State<_CropperScaffold> createState() => _CropperScaffoldState();
}

class _CropperScaffoldState extends State<_CropperScaffold> {
  late final CropController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = CropController(
      source: widget.source,
      aspectRatio: widget.aspectRatio,
      mask: widget.mask,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final bytes = await _controller.crop();
      if (!mounted) return;
      Navigator.of(context).pop(bytes);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancelLabel),
        ),
        leadingWidth: 100,
        actions: [
          TextButton(
            onPressed: _busy ? null : _confirm,
            child: Text(widget.confirmLabel),
          ),
        ],
      ),
      body: SafeArea(
        child: CropView(controller: _controller, theme: widget.theme),
      ),
    );
  }
}
```

- [ ] **Step 4: Run, expect pass**

Run: `flutter test test/widget/crop_dialog_test.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/src/widgets/crop_dialog.dart test/widget/crop_dialog_test.dart
git commit -m "feat(widget): showCropper route helper"
```

---

### Task 18: Public barrel exports

**Files:**
- Modify: `lib/flutter_crop_kit.dart`

- [ ] **Step 1: Replace barrel contents**

```dart
/// Pure-Dart Flutter image cropper.
library flutter_crop_kit;

export 'src/controller/crop_controller.dart';
export 'src/error/crop_exception.dart';
export 'src/mask/mask_shape.dart';
export 'src/source/image_source.dart';
export 'src/widgets/crop_dialog.dart';
export 'src/widgets/crop_theme.dart';
export 'src/widgets/crop_view.dart';
```

- [ ] **Step 2: Add public-API smoke test**

Create `test/unit/public_api_test.dart`:

```dart
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('public API surface compiles', () {
    expect(CropController, isNotNull);
    expect(CropView, isNotNull);
    expect(showCropper, isNotNull);
    expect(MaskShape.rect, isNotNull);
    expect(ImageSource.memory, isNotNull);
    expect(CropTheme, isNotNull);
    expect(CropAspectRatio.square, isNotNull);
    expect(GridOverlay.thirds, isNotNull);
    expect(CropLoadException, isNotNull);
  });
}
```

- [ ] **Step 3: Run analyze + test**

Run: `flutter analyze && flutter test test/unit/public_api_test.dart`
Expected: clean, test passes.

- [ ] **Step 4: Commit**

```bash
git add lib/flutter_crop_kit.dart test/unit/public_api_test.dart
git commit -m "feat: public barrel exports"
```

---

### Task 19: Error-states widget tests

**Files:**
- Test: `test/widget/error_states_test.dart`

- [ ] **Step 1: Write tests**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('default loading shown before image ready', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    c.dispose();
  });

  testWidgets('default error widget on bad bytes', (tester) async {
    final c = CropController(source: ImageSource.memory(Uint8List.fromList([0,1,2,3])));
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 400, child: CropView(controller: c)),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
    c.dispose();
  });

  testWidgets('custom loading builder used', (tester) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(source: ImageSource.memory(Uint8List.fromList(bytes)));
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400, height: 400,
        child: CropView(
          controller: c,
          loadingBuilder: (_) => const Text('LOADING'),
        ),
      ),
    ));
    expect(find.text('LOADING'), findsOneWidget);
    await tester.pumpAndSettle();
    c.dispose();
  });
}
```

- [ ] **Step 2: Run, expect pass**

Run: `flutter test test/widget/error_states_test.dart`

- [ ] **Step 3: Commit**

```bash
git add test/widget/error_states_test.dart
git commit -m "test(widget): error and loading states"
```

---

### Task 20: Golden tests

**Files:**
- Test: `test/golden/crop_goldens_test.dart`
- (Golden PNGs are generated/updated via `flutter test --update-goldens`.)

- [ ] **Step 1: Write golden tests**

```dart
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> view({
    required MaskShape mask,
    GridOverlay grid = GridOverlay.thirds,
    double rotation = 0,
  }) async {
    final bytes = await File('test/fixtures/sample_image.png').readAsBytes();
    final c = CropController(
      source: ImageSource.memory(Uint8List.fromList(bytes)),
      mask: mask,
      rotation: rotation,
    );
    await c.whenReady;
    return MaterialApp(
      home: SizedBox(
        width: 400,
        height: 400,
        child: CropView(
          controller: c,
          gridOverlay: grid,
        ),
      ),
    );
  }

  testWidgets('rect_crop_default_theme', (t) async {
    await t.pumpWidget(await view(mask: const MaskShape.rect()));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('rect_crop_default_theme.png'));
  });

  testWidgets('circle_mask', (t) async {
    await t.pumpWidget(await view(mask: const MaskShape.circle()));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('circle_mask.png'));
  });

  testWidgets('oval_mask', (t) async {
    await t.pumpWidget(await view(mask: const MaskShape.oval()));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('oval_mask.png'));
  });

  testWidgets('polygon_mask_star', (t) async {
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
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('polygon_mask_star.png'));
  });

  testWidgets('grid_overlay_thirds', (t) async {
    await t.pumpWidget(await view(
      mask: const MaskShape.rect(),
      grid: GridOverlay.thirds,
    ));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('grid_overlay_thirds.png'));
  });

  testWidgets('rotation_45deg', (t) async {
    await t.pumpWidget(await view(
      mask: const MaskShape.rect(),
      rotation: 0.7853981633974483,
    ));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('rotation_45deg.png'));
  });

  testWidgets('handles_at_corners', (t) async {
    await t.pumpWidget(await view(mask: const MaskShape.rect()));
    await t.pumpAndSettle();
    await expectLater(find.byType(CropView),
        matchesGoldenFile('handles_at_corners.png'));
  });
}
```

- [ ] **Step 2: Generate goldens**

Run: `flutter test --update-goldens test/golden/`
Expected: PNGs written under `test/golden/`.

- [ ] **Step 3: Run goldens normally**

Run: `flutter test test/golden/`
Expected: all 7 tests pass.

- [ ] **Step 4: Commit**

```bash
git add test/golden
git commit -m "test(golden): add 7 golden snapshots"
```

---

### Task 21: Example app

**Files:**
- Create: `example/pubspec.yaml`
- Create: `example/lib/main.dart`
- Create: `example/README.md`

- [ ] **Step 1: Write example pubspec**

```yaml
name: flutter_crop_kit_example
description: Demo app for flutter_crop_kit.
publish_to: 'none'
version: 0.0.1
environment:
  sdk: ^3.4.0
  flutter: ">=3.22.0"
dependencies:
  flutter:
    sdk: flutter
  flutter_crop_kit:
    path: ../
dev_dependencies:
  flutter_lints: ^4.0.0
flutter:
  uses-material-design: true
  assets:
    - assets/demo.png
```

- [ ] **Step 2: Copy a demo asset**

```bash
mkdir -p example/assets
cp test/fixtures/sample_image.png example/assets/demo.png
```

- [ ] **Step 3: Write example/lib/main.dart**

```dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) =>
      const MaterialApp(home: DemoHome());
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  Uint8List? _result;

  Future<void> _crop() async {
    final out = await showCropper(
      context,
      source: ImageSource.asset('assets/demo.png'),
      aspectRatio: CropAspectRatio.square,
    );
    setState(() => _result = out);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_crop_kit demo')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_result != null)
              SizedBox(
                width: 200, height: 200,
                child: Image.memory(_result!),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _crop,
              child: const Text('Crop demo image'),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Write example README**

```markdown
# flutter_crop_kit example

Run: `flutter run` from this directory.
```

- [ ] **Step 5: Verify it builds**

Run: `cd example && flutter pub get && flutter analyze && cd ..`
Expected: no analyzer issues.

- [ ] **Step 6: Commit**

```bash
git add example
git commit -m "example: showCropper demo app"
```

---

### Task 22: README polish

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Write full README**

````markdown
# flutter_crop_kit

A pure-Dart Flutter image cropper. Works identically on Android, iOS, web, desktop, and embedded. No platform channels.

## Install

```yaml
dependencies:
  flutter_crop_kit: ^0.1.0
```

## Quick start

### Inline widget

```dart
final controller = CropController(
  source: ImageSource.asset('assets/photo.png'),
  aspectRatio: CropAspectRatio.r16x9,
);

CropView(controller: controller);
// then: final bytes = await controller.crop();
```

### Modal route

```dart
final bytes = await showCropper(
  context,
  source: ImageSource.network('https://example.com/photo.png'),
  mask: const MaskShape.circle(),
);
```

## Features

- Rect, circle, oval, polygon, and custom `Path` masks.
- Aspect ratio lock (free, presets, custom).
- 90° quick rotation and free rotation.
- Pinch-zoom and pan.
- Grid overlay (thirds, golden, 3×3).
- 4 input sources: memory, file, network, asset.
- PNG output and live `Stream<Rect>` of the crop rect.
- Themed via `CropTheme`.

## Sources

```dart
ImageSource.memory(Uint8List bytes);
ImageSource.file(File file);
ImageSource.network(String url, {Map<String, String>? headers});
ImageSource.asset(String path, {AssetBundle? bundle});
```

## Masks

```dart
const MaskShape.rect();
const MaskShape.oval();
const MaskShape.circle();
MaskShape.polygon([Offset(0, 0), Offset(1, 0), Offset(0.5, 1)]); // unit space
MaskShape.custom((rect) => Path()..addRRect(RRect.fromRectXY(rect, 12, 12)));
```

## Errors

`CropController.error` exposes a `CropException`. `CropView` accepts `errorBuilder` and `loadingBuilder`.

## Goldens

CI runs golden tests only on Linux. Locally:

```sh
flutter test --update-goldens
```

## License

MIT.
````

- [ ] **Step 2: Commit**

```bash
git add README.md
git commit -m "docs: README with usage examples"
```

---

### Task 23: CHANGELOG and pub readiness check

**Files:**
- Modify: `CHANGELOG.md`

- [ ] **Step 1: Write CHANGELOG entry**

```markdown
# Changelog

## 0.1.0

- Initial release.
- `CropView` inline widget and `showCropper` route helper.
- Rect, circle, oval, polygon, and custom mask shapes.
- Aspect ratio lock (free, presets, custom).
- 90° and free rotation.
- Pinch-zoom + pan.
- Grid overlay (thirds, golden, 3×3).
- Image sources: memory, file, network, asset.
- PNG export via `dart:ui`, optional `targetWidth` resize.
- Live `Stream<Rect>` of crop rect.
- `CropTheme` for visual customization.
```

- [ ] **Step 2: Pub publish dry-run**

Run: `flutter pub publish --dry-run`
Expected: `Package has 0 warnings.` (or document any remaining warnings).

- [ ] **Step 3: Commit**

```bash
git add CHANGELOG.md
git commit -m "docs: CHANGELOG for 0.1.0"
```

---

### Task 24: CI workflow

**Files:**
- Create: `.github/workflows/ci.yaml`

- [ ] **Step 1: Write workflow**

```yaml
name: ci

on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
        channel: [stable, beta]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: ${{ matrix.channel }}
      - run: flutter pub get
      - run: dart format --set-exit-if-changed .
      - run: flutter analyze
      - name: Test (no goldens on non-linux)
        if: matrix.os != 'ubuntu-latest'
        run: flutter test --exclude-tags=golden
      - name: Test (with goldens on linux)
        if: matrix.os == 'ubuntu-latest'
        run: flutter test
      - run: flutter pub publish --dry-run
```

- [ ] **Step 2: Tag goldens so non-Linux runners skip them**

Modify `test/golden/crop_goldens_test.dart`: wrap `void main()` body, adding `@Tags(['golden'])` annotation at top of file:

```dart
@Tags(['golden'])
library;

import 'dart:io';
// ... rest unchanged
```

Create `dart_test.yaml` at repo root:

```yaml
tags:
  golden:
    skip: false
```

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yaml test/golden/crop_goldens_test.dart dart_test.yaml
git commit -m "ci: GitHub Actions matrix, gate goldens to linux"
```

---

### Task 25: Coverage gate

**Files:**
- Modify: `.github/workflows/ci.yaml`

- [ ] **Step 1: Add coverage step**

Insert after Linux test step:

```yaml
      - name: Coverage
        if: matrix.os == 'ubuntu-latest' && matrix.channel == 'stable'
        run: |
          flutter test --coverage
          dart run tool/check_coverage.dart 85
```

- [ ] **Step 2: Write `tool/check_coverage.dart`**

```dart
import 'dart:io';

void main(List<String> args) {
  final threshold = double.parse(args.first);
  final lines = File('coverage/lcov.info').readAsLinesSync();
  var hit = 0, total = 0;
  for (final l in lines) {
    if (l.startsWith('DA:')) {
      total++;
      final count = int.parse(l.split(',')[1]);
      if (count > 0) hit++;
    }
  }
  final pct = total == 0 ? 0 : (hit / total) * 100;
  // ignore: avoid_print
  print('Coverage: ${pct.toStringAsFixed(2)}% ($hit/$total)');
  if (pct < threshold) {
    exitCode = 1;
  }
}
```

- [ ] **Step 3: Run locally to confirm**

Run: `flutter test --coverage && dart run tool/check_coverage.dart 85`
Expected: prints `Coverage: NN.NN%` and exits 0 when ≥85%.

If under 85%, add unit tests for the lowest-covered file until threshold met.

- [ ] **Step 4: Commit**

```bash
git add tool/check_coverage.dart .github/workflows/ci.yaml
git commit -m "ci: enforce 85% coverage gate"
```

---

### Task 26: Final analyze + test pass

- [ ] **Step 1: Format**

Run: `dart format .`

- [ ] **Step 2: Analyze**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 3: Full test**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 4: Pub dry-run**

Run: `flutter pub publish --dry-run`
Expected: `Package has 0 warnings.`

- [ ] **Step 5: Final commit if anything reformatted**

```bash
git status
# if dirty:
git add -A
git commit -m "chore: final format/analyze pass"
```

---

## Done

All v0.1 spec items implemented and tested. Ready to publish via `flutter pub publish` (run separately, requires pub.dev auth).
