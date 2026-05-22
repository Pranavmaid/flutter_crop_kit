import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

/// Callback for pan updates with the local position and delta.
typedef CropPanCallback = void Function(Offset localPosition, Offset delta);

/// Callback for two-finger scale (delta is the multiplicative factor).
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

  /// Called for every move with delta in local space (single-pointer pan).
  final CropPanCallback onPanUpdate;

  /// Called when all pointers go up.
  final VoidCallback onPanEnd;

  /// Called when 2 pointers move; delta is the scale multiplier.
  final CropScaleCallback onScaleUpdate;

  final Map<int, Offset> _pointers = {};
  double? _lastPinchDist;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
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
