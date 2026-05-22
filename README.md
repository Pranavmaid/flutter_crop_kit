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
- 90 degree quick rotation and free rotation.
- Pinch-zoom and pan.
- Grid overlay (thirds, golden, 3x3).
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
