# flutter_crop_kit — Design Spec

**Date:** 2026-05-21
**Status:** Approved (brainstorming → ready for implementation plan)
**Author:** pranav
**License:** MIT
**Target:** pub.dev

## 1. Purpose

A pure-Dart Flutter image cropper package that runs identically on mobile, web, desktop, and embedded targets with zero native platform channels.

The dominant existing package, `image_cropper`, relies on platform channels into `uCrop` (Android), `TOCropViewController` (iOS), and `Cropper.js` (web). This creates three independent code paths, inconsistent UX across platforms, flaky web behavior, and no first-class desktop story. `flutter_crop_kit` fills that gap with a single Dart implementation built on `dart:ui` and Flutter widgets.

## 2. Goals & Non-Goals

### Goals
- Single-codebase cropper widget that works on all Flutter platforms identically.
- Rect crop, circle/oval crop, polygon mask, custom mask shape via `Path` builder.
- Aspect ratio lock (free + presets + custom).
- 90° rotation (instant) and free rotation (slider, any angle).
- Pinch-zoom and pan inside the crop area.
- Optional grid overlay (thirds, golden, 3×3).
- Inline widget API (`CropView` + `CropController`) and route helper (`showCropper`).
- Output as `Uint8List` (PNG) and live `Stream<Rect>` of the current crop rect.
- Accept image input from memory bytes, file path, network URL, and asset.
- Theme via a single `CropTheme` data class.
- 85%+ line coverage with unit, widget, and golden tests.

### Non-Goals (v0.1)
- Filters, color adjustments, or post-crop image processing.
- JPEG/WebP encoding (PNG only via `dart:ui` `toByteData`).
- EXIF orientation auto-correction (caller responsibility).
- Background isolate offloading (single-threaded acceptable for v0.1).
- RenderObject-level implementation (see §10 Future Work).

## 3. Architecture Decision

**Chosen approach: Monolithic widget + `ChangeNotifier` controller.**

- `CropController extends ChangeNotifier` is the single source of truth.
- `CropView` is a `StatefulWidget` that listens to the controller and rebuilds.
- Painting is handled by one `CustomPainter` (`CropPainter`) that draws image, mask, grid, and handles in a single paint pass.
- Gestures are handled by a custom `RawGestureRecognizer` that distinguishes corner-drag, edge-drag, inside-pan, and outside-pinch.

### Why not layered widgets (Approach B)?
Five RenderObjects stacked add rebuild overhead and orchestration complexity with no shipping benefit for v0.1. YAGNI.

### Why not custom RenderBox (Approach C)?
~3× development time, much harder to test and maintain, hostile to outside contributors. Kept as the v1.0 performance migration path if profiling reveals frame-budget pressure on very large images.

## 4. Package Layout

```
flutter_crop_kit/
├── pubspec.yaml          # name: flutter_crop_kit, sdk: ^3.4.0, deps: flutter only
├── LICENSE               # MIT
├── README.md
├── CHANGELOG.md
├── lib/
│   ├── flutter_crop_kit.dart        # public barrel
│   └── src/
│       ├── controller/
│       │   └── crop_controller.dart
│       ├── widgets/
│       │   ├── crop_view.dart
│       │   ├── crop_dialog.dart
│       │   └── crop_theme.dart
│       ├── painter/
│       │   └── crop_painter.dart
│       ├── gestures/
│       │   └── crop_gesture_recognizer.dart
│       ├── geometry/
│       │   ├── crop_rect.dart
│       │   ├── transform.dart
│       │   └── handle_hit_test.dart
│       ├── mask/
│       │   ├── mask_shape.dart
│       │   └── path_builder.dart
│       ├── source/
│       │   └── image_source.dart
│       └── export/
│           └── png_encoder.dart
├── test/                 # unit + widget + golden
└── example/              # demo app for pub.dev
```

## 5. Public API

### `CropView` widget

```dart
class CropView extends StatefulWidget {
  const CropView({
    required this.controller,
    this.theme = const CropTheme(),
    this.gridOverlay = GridOverlay.thirds,
    this.errorBuilder,
    this.loadingBuilder,
    super.key,
  });

  final CropController controller;
  final CropTheme theme;
  final GridOverlay gridOverlay;
  final Widget Function(BuildContext, CropException)? errorBuilder;
  final Widget Function(BuildContext)? loadingBuilder;
}
```

### `CropController`

```dart
class CropController extends ChangeNotifier {
  CropController({
    required ImageSource source,
    AspectRatio? aspectRatio,
    MaskShape mask = const MaskShape.rect(),
    double rotation = 0,
  });

  ui.Image? get image;
  Rect get cropRect;
  double get rotation;
  MaskShape get mask;
  AspectRatio? get aspectRatio;
  bool get isReady;
  CropException? get error;

  void setAspectRatio(AspectRatio? r);
  void setMask(MaskShape m);
  void rotateBy90({bool clockwise = true});
  void setRotation(double radians);
  void reset();

  Stream<Rect> get cropRectStream;

  Future<Uint8List> crop({int? targetWidth});
}
```

### `ImageSource` (sealed)

```dart
sealed class ImageSource {
  const factory ImageSource.memory(Uint8List bytes) = MemorySource;
  const factory ImageSource.file(File file) = FileSource;
  const factory ImageSource.network(String url, {Map<String, String>? headers}) = NetworkSource;
  const factory ImageSource.asset(String path, {AssetBundle? bundle}) = AssetSource;
}
```

### `MaskShape` (sealed)

```dart
sealed class MaskShape {
  const factory MaskShape.rect() = RectMask;
  const factory MaskShape.oval() = OvalMask;
  const factory MaskShape.circle() = CircleMask;
  const factory MaskShape.polygon(List<Offset> points) = PolygonMask;
  const factory MaskShape.custom(Path Function(Rect) builder) = CustomMask;
}
```

### `AspectRatio`, `GridOverlay`, `CropTheme`

```dart
class AspectRatio {
  const AspectRatio(this.width, this.height);
  static const square = AspectRatio(1, 1);
  static const r4x3 = AspectRatio(4, 3);
  static const r16x9 = AspectRatio(16, 9);
  final double width, height;
}

enum GridOverlay { none, thirds, golden, grid3x3 }

class CropTheme {
  const CropTheme({
    this.maskColor = const Color(0x99000000),
    this.handleColor = Colors.white,
    this.handleSize = 24,
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    this.gridColor = const Color(0x66FFFFFF),
    this.gridWidth = 1,
  });
}
```

### Route helper

```dart
Future<Uint8List?> showCropper(
  BuildContext context, {
  required ImageSource source,
  AspectRatio? aspectRatio,
  MaskShape mask = const MaskShape.rect(),
  CropTheme theme = const CropTheme(),
  String confirmLabel = 'Done',
  String cancelLabel = 'Cancel',
});
```

## 6. Data Flow

### Coordinate spaces

Three distinct spaces, mapped via the current transform matrix:

1. **Image space** — original pixel coordinates `(0,0)` to `(imgW, imgH)`. `cropRect` lives here. Source of truth.
2. **Canvas space** — widget paint coordinates, depends on `BoxConstraints`. Image is fit-scaled into the widget.
3. **Gesture space** — local widget coordinates from `RawGestureDetector`. Mapped to canvas → image via the inverse transform.

### Transform composition

```
finalTransform = T(center) * R(rotation) * S(scale) * T(-imageCenter)
```

Applied when painting the image, and its inverse is applied to incoming gesture deltas.

### Controller state

- `ui.Image? _image` — decoded once on init.
- `Rect _cropRect` — image-space, source of truth.
- `double _rotation` — radians, any value.
- `AspectRatio? _aspectRatio` — null means free.
- `MaskShape _mask`.
- `StreamController<Rect> _rectController` — broadcast, throttled to 16ms.

### Init flow

```
CropController(source)
  → ImageSourceLoader.load(source)   // sealed switch
  → Uint8List bytes
  → ui.instantiateImageCodec(bytes)
  → ui.Image decoded
  → _image = img; _cropRect = Rect.fromLTWH(0, 0, img.width, img.height)
  → notifyListeners()                // isReady = true
```

### Gesture flow (per frame)

```
PointerEvent (gesture space)
  → HandleHitTest.detect(localPos, currentHandles)
    → HitTarget: corner | edge | inside | outside
  → pan delta:
     - corner/edge: CropRectUpdater.resize(target, delta, aspectLock?)
     - inside: CropRectUpdater.translate(delta)
     - outside + 2 pointers: scale image transform
  → clamp _cropRect to image bounds
  → notifyListeners() + _rectController.add(_cropRect)
  → CustomPainter repaints
```

### Export flow (`controller.crop()`)

The export must handle two paths depending on rotation, because `Canvas.drawImageRect` does not interact with the canvas transform in the way a naive crop+rotate would expect.

**Path A — `rotation == 0`** (fast path):
1. `outSize = _cropRect.size`.
2. Create `ui.PictureRecorder` + `Canvas`.
3. Clip path to `MaskShape` translated to `(0, 0, outW, outH)`.
4. `canvas.drawImageRect(_image, src: _cropRect, dst: Rect.fromLTWH(0, 0, outW, outH))`.
5. `picture.toImage(outW, outH)` → `ui.Image`.
6. `image.toByteData(format: png)` → `Uint8List`.

**Path B — `rotation != 0`** (rotated path):
1. Compute the axis-aligned bounding box of the rotated crop rect → `outSize`.
2. Create `ui.PictureRecorder` + `Canvas`.
3. Translate to `outSize.center`, rotate by `-rotation`, translate by `-_cropRect.center`.
4. Clip path to `MaskShape` mapped into image space (so the mask follows the crop rect).
5. `canvas.drawImage(_image, Offset.zero)` — full image, transform handles positioning.
6. `picture.toImage(outW, outH)` → `ui.Image`.
7. `image.toByteData(format: png)` → `Uint8List`.

**Optional resize** — if `targetWidth` is specified, run a second `PictureRecorder` pass with `drawImageRect` scaling the result to `targetWidth × (targetWidth * outH / outW)`.

### Live preview stream

`cropRectStream` emits `_cropRect` on every gesture update, debounced via `Timer` to 16ms. Broadcast, late-subscriber friendly. Consumers (filter previews, etc.) downsample as needed.

## 7. Error Handling

### Failure modes

| Failure | Where | Strategy |
|---|---|---|
| Invalid/corrupt image bytes | `ui.instantiateImageCodec` throws | `CropController.error` set, `isReady` stays false, `errorBuilder` invoked |
| Network fetch fails | `NetworkSource.load` | wrap in `CropLoadException` |
| File not found | `FileSource.load` | wrap in `CropLoadException` |
| Asset missing | `AssetSource.load` | wrap in `CropLoadException` |
| Image too large | post-decode | check `w * h * 4 > cap` (default 100MP) → `CropImageTooLargeException` |
| Crop rect degenerate | gesture update | clamp to min 32×32 image-space px, no-op below |
| Polygon mask < 3 points | constructor | assert in debug, fall back to `RectMask` in release |
| `crop()` before ready | export | `StateError('Image not loaded')` |
| Dispose mid-export | export | `_disposed` guard, return `Future.error` |

### Exception types

```dart
sealed class CropException implements Exception { String get message; }
class CropLoadException extends CropException { ... }
class CropImageTooLargeException extends CropException { ... }
class CropExportException extends CropException { ... }
```

### Widget-level fallbacks

Default `loadingBuilder` returns a centered `CircularProgressIndicator`. Default `errorBuilder` returns a centered `Icon(Icons.broken_image)` and the error message. Both are overridable.

### Assertions (debug-only)

- Aspect ratio `width > 0` and `height > 0`.
- Handle size `> 0`.
- `MemorySource` bytes length `> 0`.
- Rotation is finite (not NaN / not Infinity).

No silent failures. Every catch in release logs via `debugPrint` with a `[flutter_crop_kit]` prefix.

## 8. Testing Strategy

### Layout

```
test/
├── unit/
│   ├── geometry/
│   │   ├── crop_rect_test.dart
│   │   ├── transform_test.dart
│   │   └── handle_hit_test_test.dart
│   ├── mask/
│   │   ├── mask_shape_test.dart
│   │   └── path_builder_test.dart
│   ├── controller/
│   │   └── crop_controller_test.dart
│   └── export/
│       └── png_encoder_test.dart
├── widget/
│   ├── crop_view_gesture_test.dart
│   ├── crop_view_aspect_lock_test.dart
│   ├── crop_view_rotation_test.dart
│   ├── crop_dialog_test.dart
│   └── error_states_test.dart
└── golden/
    ├── rect_crop_default_theme.png
    ├── circle_mask.png
    ├── oval_mask.png
    ├── polygon_mask_star.png
    ├── grid_overlay_thirds.png
    ├── rotation_45deg.png
    └── handles_at_corners.png
```

### Fixtures

- `test/fixtures/sample_image.png` — 512×512 deterministic checkerboard (committed).
- `test/fixtures/tall_image.png` — 200×800 (committed).
- `test/fixtures/wide_image.png` — 800×200 (committed).
- 4096×4096 large image generated programmatically per test, not committed.

### Must-pass invariants

Unit:
1. `cropRect` clamping never lets crop escape image bounds.
2. Aspect ratio lock preserved across all resize directions.
3. Controller notifies exactly once per mutation.
4. `crop()` output dimensions match `cropRect.size`.
5. Transform inverse correctness (gesture → image mapping).

Widget:
1. Drag NE corner shrinks crop, NW pinned.
2. Drag inside translates without resize.
3. Pinch zoom inside crop scales image, not crop rect.
4. `aspectRatio` setter immediately reshapes crop.
5. `showCropper` returns `null` on cancel, `Uint8List` on confirm.

### Goldens

- `flutter_test` `matchesGoldenFile`.
- CI runs goldens on Linux only (font/AA platform dependence). macOS/Windows runs skip goldens.
- README documents `flutter test --update-goldens` workflow.

### Coverage

85%+ line coverage on `lib/src/`, excluding `widgets/crop_dialog.dart` route boilerplate. Enforced via `coverage` package and CI badge.

### CI

GitHub Actions matrix on Flutter stable + beta. Runs `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed`, `flutter pub publish --dry-run`.

## 9. Risks & Open Questions

| Risk | Mitigation |
|---|---|
| Free rotation math edge cases (90° boundaries, gimbal-like artifacts) | Comprehensive unit tests on `transform.dart`; clamp rotation to `[-π, π]`. |
| Large image OOM on web (no dart:io memory headroom) | Configurable size cap, throw early. |
| Gesture conflict with parent scrollables | Use `RawGestureRecognizer` and accept gestures eagerly inside the crop bounds. |
| Golden test flake across platforms | Lock to Linux CI runner. |
| `dart:ui` PNG-only output limits adoption | Document; consider hybrid with `image` package in v0.2 if requested. |
| Network `ImageSource` requires `http` package indirectly | Use `HttpClient` from `dart:io` on non-web and `package:http` only if necessary; reassess in implementation. |

## 10. Future Work (post-v0.1)

- **v0.2:** JPEG/WebP export via optional `image` package dependency (opt-in subdir entry point).
- **v0.2:** EXIF orientation auto-correction helper.
- **v0.3:** Isolate-based export for large images.
- **v1.0:** Migrate paint layer to custom `RenderBox` (Approach C) if profiling shows frame budget pressure.
- **v1.x:** Filters/adjustments as a sibling package `flutter_crop_kit_filters`.
- **v1.x:** Interactive polygon mask editor (drag polygon vertices).

## 11. References

- `image_cropper` (the package this addresses): https://pub.dev/packages/image_cropper
- Flutter `dart:ui` Canvas API: https://api.flutter.dev/flutter/dart-ui/Canvas-class.html
- Flutter custom gesture recognizers: https://docs.flutter.dev/ui/interactivity/gestures
