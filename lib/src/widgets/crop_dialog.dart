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
