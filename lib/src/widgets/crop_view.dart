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
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final size = constraints.biggest;
        return RawGestureDetector(
          behavior: HitTestBehavior.opaque,
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
      },
    );
  }

  void _onStart(Offset localPos, Size size) {
    final c = widget.controller;
    final img = c.image!;
    final imgSize = Size(img.width.toDouble(), img.height.toDouble());
    final m = buildImageTransform(
      imageSize: imgSize,
      canvasSize: size,
      rotation: c.rotation,
      scale: fitScale(imgSize, size) * _userScale,
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
    final imageDelta = MatrixUtils.transformPoint(inv, delta) -
        MatrixUtils.transformPoint(inv, Offset.zero);
    final next = resizeWithHandle(
      c.cropRect,
      _activeTarget,
      imageDelta,
      aspect: c.aspectRatio,
    );
    final imgBounds = Rect.fromLTWH(0, 0, imgSize.width, imgSize.height);
    final clamped = clampToBounds(enforceMinSize(next, 32), imgBounds);
    // ignore: invalid_use_of_protected_member
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
          Flexible(child: Text(e.message, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
