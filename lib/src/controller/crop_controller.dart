import 'dart:async';
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
  ui.Rect _cropRect = ui.Rect.zero;
  double _rotation;
  CropAspectRatio? _aspectRatio;
  MaskShape _mask;
  CropException? _error;
  bool _disposed = false;

  final StreamController<ui.Rect> _rectController =
      StreamController<ui.Rect>.broadcast();
  Timer? _streamDebounce;

  /// Future that completes when image is loaded (or errors).
  Future<void> get whenReady => _ready;

  /// Decoded image, or null if not yet loaded.
  ui.Image? get image => _image;

  /// Current crop rect in image space.
  ui.Rect get cropRect => _cropRect;

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
  Stream<ui.Rect> get cropRectStream => _rectController.stream;

  Future<void> _load() async {
    try {
      final img = await loadImageSource(_source);
      if (_disposed) {
        img.dispose();
        return;
      }
      _image = img;
      _cropRect =
          ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
      _error = null;
      notifyListeners();
    } on CropException catch (e) {
      if (_disposed) return;
      _error = e;
      notifyListeners();
    } catch (e) {
      if (_disposed) return;
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
  void updateCropRect(ui.Rect rect) {
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
      _cropRect =
          ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
    }
    _rotation = 0;
    notifyListeners();
  }

  /// Exports the current crop region as PNG bytes.
  ///
  /// Optionally resizes to [targetWidth] preserving aspect.
  Future<Uint8List> crop({int? targetWidth}) async {
    if (_disposed) {
      throw StateError('Controller disposed');
    }
    final img = _image;
    if (img == null) {
      throw StateError('Image not loaded');
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
      _error = e is CropException ? e : CropExportException(e.toString());
      if (!_disposed) notifyListeners();
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
