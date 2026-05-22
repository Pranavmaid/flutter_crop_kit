import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_crop_kit/flutter_crop_kit.dart';
import 'package:image_picker/image_picker.dart' as picker;

void main() => runApp(const DemoApp());

/// Root widget for the flutter_crop_kit demo application.
class DemoApp extends StatelessWidget {
  /// Creates the demo app.
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'flutter_crop_kit demo',
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
        home: const DemoHome(),
      );
}

/// Top-level demo screen. Pick a source, route to the cropper, see result.
class DemoHome extends StatefulWidget {
  /// Creates the demo home screen.
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final _picker = picker.ImagePicker();
  Uint8List? _sourceBytes;
  Uint8List? _result;
  bool _picking = false;

  Future<void> _pickGallery() async {
    setState(() => _picking = true);
    try {
      final p = await _picker.pickImage(source: picker.ImageSource.gallery);
      if (p == null) return;
      final bytes = await p.readAsBytes();
      if (!mounted) return;
      setState(() {
        _sourceBytes = bytes;
        _result = null;
      });
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _showAsModal() async {
    if (_sourceBytes == null) return;
    final out = await showCropper(
      context,
      source: ImageSource.memory(_sourceBytes!),
      mask: const MaskShape.circle(),
      aspectRatio: CropAspectRatio.square,
      theme: const CropTheme(
        maskColor: Color(0xCC000000),
        borderColor: Colors.amber,
        handleColor: Colors.amber,
      ),
    );
    if (!mounted || out == null) return;
    setState(() => _result = out);
  }

  void _useBadBytes() {
    setState(() {
      _sourceBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('flutter_crop_kit demo')),
      body: _result != null
          ? _ResultView(
              bytes: _result!,
              onReset: () => setState(() => _result = null),
              onPickAnother: _pickGallery,
            )
          : _sourceBytes != null
              ? _CropScreen(
                  bytes: _sourceBytes!,
                  onCropped: (b) => setState(() => _result = b),
                  onCancel: () => setState(() => _sourceBytes = null),
                  onOpenModal: _showAsModal,
                )
              : _SourcePicker(
                  busy: _picking,
                  onPickGallery: _pickGallery,
                  onBadBytes: _useBadBytes,
                ),
    );
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({
    required this.busy,
    required this.onPickGallery,
    required this.onBadBytes,
  });
  final bool busy;
  final VoidCallback onPickGallery;
  final VoidCallback onBadBytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Pick a source',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy ? null : onPickGallery,
            icon: const Icon(Icons.photo_library),
            label: const Text('Gallery (memory source)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: busy ? null : onBadBytes,
            icon: const Icon(Icons.warning_amber),
            label: const Text('Bad bytes (error demo)'),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.bytes,
    required this.onReset,
    required this.onPickAnother,
  });
  final Uint8List bytes;
  final VoidCallback onReset;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text('Cropped output (${bytes.length} bytes)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ColoredBox(
                color: Colors.grey.shade200,
                child: Image.memory(bytes),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.crop),
                label: const Text('Re-crop'),
              ),
              FilledButton.icon(
                onPressed: onPickAnother,
                icon: const Icon(Icons.image),
                label: const Text('Pick another'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CropScreen extends StatefulWidget {
  const _CropScreen({
    required this.bytes,
    required this.onCropped,
    required this.onCancel,
    required this.onOpenModal,
  });
  final Uint8List bytes;
  final void Function(Uint8List) onCropped;
  final VoidCallback onCancel;
  final VoidCallback onOpenModal;

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  late final CropController _controller;
  StreamSubscription<Rect>? _rectSub;
  Rect _liveRect = Rect.zero;

  _MaskChoice _maskChoice = _MaskChoice.rect;
  _AspectChoice _aspect = _AspectChoice.free;
  GridOverlay _grid = GridOverlay.thirds;
  Color _maskColor = const Color(0x99000000);
  Color _accent = Colors.white;
  double _handleSize = 24;
  int? _targetWidth;
  bool _exporting = false;
  double _freeRot = 0;
  _Panel _panel = _Panel.aspect;

  @override
  void initState() {
    super.initState();
    _controller = CropController(source: ImageSource.memory(widget.bytes));
    _controller.whenReady.then((_) {
      if (!mounted) return;
      setState(() => _liveRect = _controller.cropRect);
    }).catchError((Object _) {});
    _rectSub = _controller.cropRectStream.listen((r) {
      if (mounted) setState(() => _liveRect = r);
    });
  }

  @override
  void dispose() {
    _rectSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _setMask(_MaskChoice c) {
    setState(() => _maskChoice = c);
    _controller.setMask(c.build());
  }

  void _setAspect(_AspectChoice a) {
    setState(() => _aspect = a);
    _controller.setAspectRatio(a.ratio);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final bytes = await _controller.crop(targetWidth: _targetWidth);
      widget.onCropped(bytes);
    } on CropException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  CropTheme get _theme => CropTheme(
        maskColor: _maskColor,
        handleColor: _accent,
        borderColor: _accent,
        handleSize: _handleSize,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              CropView(
                controller: _controller,
                theme: _theme,
                gridOverlay: _grid,
                errorBuilder: (_, e) => SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Custom errorBuilder: ${e.message}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                loadingBuilder: (_) => const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Custom loading...'),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: _LiveRectChip(rect: _liveRect),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 64,
                  child: _PanelContent(
                    panel: _panel,
                    controller: _controller,
                    aspect: _aspect,
                    onAspect: _setAspect,
                    mask: _maskChoice,
                    onMask: _setMask,
                    grid: _grid,
                    onGrid: (g) => setState(() => _grid = g),
                    maskColor: _maskColor,
                    accent: _accent,
                    handleSize: _handleSize,
                    onMaskColor: (c) => setState(() => _maskColor = c),
                    onAccent: (c) => setState(() => _accent = c),
                    onHandleSize: (v) => setState(() => _handleSize = v),
                    freeRot: _freeRot,
                    onFreeRot: (v) {
                      setState(() => _freeRot = v);
                      _controller.setRotation(v);
                    },
                    targetWidth: _targetWidth,
                    onTargetWidth: (v) => setState(() => _targetWidth = v),
                  ),
                ),
                SizedBox(
                  height: 56,
                  child: _PanelTabs(
                    value: _panel,
                    onChange: (p) => setState(() => _panel = p),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _exporting ? null : widget.onCancel,
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _exporting ? null : widget.onOpenModal,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Modal'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _exporting ? null : _export,
                          child: Text(_exporting ? 'Exporting...' : 'Crop'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class _LiveRectChip extends StatelessWidget {
  const _LiveRectChip({required this.rect});
  final Rect rect;

  @override
  Widget build(BuildContext context) {
    final w = rect.width.toStringAsFixed(0);
    final h = rect.height.toStringAsFixed(0);
    final x = rect.left.toStringAsFixed(0);
    final y = rect.top.toStringAsFixed(0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          '($x,$y) ${w}x$h',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

enum _AspectChoice {
  free('Free', null),
  square('1:1', CropAspectRatio.square),
  r4x3('4:3', CropAspectRatio.r4x3),
  r16x9('16:9', CropAspectRatio.r16x9),
  r3x4('3:4', CropAspectRatio(3, 4));

  const _AspectChoice(this.label, this.ratio);
  final String label;
  final CropAspectRatio? ratio;
}

enum _MaskChoice {
  rect('Rect'),
  circle('Circle'),
  oval('Oval'),
  star('Star'),
  rounded('Rounded');

  const _MaskChoice(this.label);
  final String label;

  MaskShape build() {
    switch (this) {
      case _MaskChoice.rect:
        return const MaskShape.rect();
      case _MaskChoice.circle:
        return const MaskShape.circle();
      case _MaskChoice.oval:
        return const MaskShape.oval();
      case _MaskChoice.star:
        return MaskShape.polygon(const [
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
      case _MaskChoice.rounded:
        return MaskShape.custom(
          (r) => Path()
            ..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(24))),
        );
    }
  }
}

enum _Panel {
  aspect('Aspect', Icons.aspect_ratio),
  mask('Mask', Icons.format_shapes),
  grid('Grid', Icons.grid_on),
  theme('Theme', Icons.palette),
  rotation('Rotate', Icons.rotate_right),
  export('Size', Icons.photo_size_select_large);

  const _Panel(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _PanelTabs extends StatelessWidget {
  const _PanelTabs({required this.value, required this.onChange});
  final _Panel value;
  final ValueChanged<_Panel> onChange;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      children: [
        for (final p in _Panel.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(p.icon, size: 16),
                  const SizedBox(width: 4),
                  Text(p.label),
                ],
              ),
              selected: value == p,
              onSelected: (_) => onChange(p),
              selectedColor: scheme.primaryContainer,
              showCheckmark: false,
            ),
          ),
      ],
    );
  }
}

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.panel,
    required this.controller,
    required this.aspect,
    required this.onAspect,
    required this.mask,
    required this.onMask,
    required this.grid,
    required this.onGrid,
    required this.maskColor,
    required this.accent,
    required this.handleSize,
    required this.onMaskColor,
    required this.onAccent,
    required this.onHandleSize,
    required this.freeRot,
    required this.onFreeRot,
    required this.targetWidth,
    required this.onTargetWidth,
  });

  final _Panel panel;
  final CropController controller;
  final _AspectChoice aspect;
  final ValueChanged<_AspectChoice> onAspect;
  final _MaskChoice mask;
  final ValueChanged<_MaskChoice> onMask;
  final GridOverlay grid;
  final ValueChanged<GridOverlay> onGrid;
  final Color maskColor;
  final Color accent;
  final double handleSize;
  final ValueChanged<Color> onMaskColor;
  final ValueChanged<Color> onAccent;
  final ValueChanged<double> onHandleSize;
  final double freeRot;
  final ValueChanged<double> onFreeRot;
  final int? targetWidth;
  final ValueChanged<int?> onTargetWidth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: switch (panel) {
        _Panel.aspect => _ChipRow<_AspectChoice>(
            values: _AspectChoice.values,
            label: (v) => v.label,
            current: aspect,
            onChange: onAspect,
          ),
        _Panel.mask => _ChipRow<_MaskChoice>(
            values: _MaskChoice.values,
            label: (v) => v.label,
            current: mask,
            onChange: onMask,
          ),
        _Panel.grid => _ChipRow<GridOverlay>(
            values: GridOverlay.values,
            label: (v) => switch (v) {
              GridOverlay.none => 'None',
              GridOverlay.thirds => 'Thirds',
              GridOverlay.golden => 'Golden',
              GridOverlay.grid3x3 => '3x3',
            },
            current: grid,
            onChange: onGrid,
          ),
        _Panel.theme => _ThemePanel(
            maskColor: maskColor,
            accent: accent,
            handleSize: handleSize,
            onMaskColor: onMaskColor,
            onAccent: onAccent,
            onHandleSize: onHandleSize,
          ),
        _Panel.rotation => _RotationPanel(
            freeValue: freeRot,
            onFree: onFreeRot,
            onCw: () => controller.rotateBy90(),
            onCcw: () => controller.rotateBy90(clockwise: false),
            onReset: () {
              onFreeRot(0);
              controller.reset();
            },
          ),
        _Panel.export => _ChipRow<int?>(
            values: const [null, 256, 512, 1024, 2048],
            label: (v) => v == null ? 'Original' : '${v}px',
            current: targetWidth,
            onChange: onTargetWidth,
          ),
      },
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.label,
    required this.current,
    required this.onChange,
  });
  final List<T> values;
  final String Function(T) label;
  final T current;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        for (final v in values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(label(v)),
              selected: v == current,
              onSelected: (_) => onChange(v),
              showCheckmark: false,
            ),
          ),
      ],
    );
  }
}

class _ThemePanel extends StatelessWidget {
  const _ThemePanel({
    required this.maskColor,
    required this.accent,
    required this.handleSize,
    required this.onMaskColor,
    required this.onAccent,
    required this.onHandleSize,
  });
  final Color maskColor;
  final Color accent;
  final double handleSize;
  final ValueChanged<Color> onMaskColor;
  final ValueChanged<Color> onAccent;
  final ValueChanged<double> onHandleSize;

  @override
  Widget build(BuildContext context) {
    final accents = [Colors.white, Colors.amber, Colors.cyan, Colors.pink];
    final masks = [
      const Color(0x99000000),
      const Color(0xCC000000),
      const Color(0x66FF0000),
    ];
    return ListView(
      scrollDirection: Axis.horizontal,
      children: [
        const Center(child: Text('Accent ')),
        for (final c in accents)
          _Swatch(color: c, selected: c == accent, onTap: () => onAccent(c)),
        const SizedBox(width: 16),
        const Center(child: Text('Mask ')),
        for (final c in masks)
          _Swatch(
            color: c,
            selected: c == maskColor,
            onTap: () => onMaskColor(c),
          ),
        const SizedBox(width: 16),
        SizedBox(
          width: 220,
          child: Row(
            children: [
              const Text('Handle '),
              Expanded(
                child: Slider(
                  min: 12,
                  max: 40,
                  value: handleSize,
                  onChanged: onHandleSize,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black : Colors.grey,
                width: selected ? 3 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RotationPanel extends StatelessWidget {
  const _RotationPanel({
    required this.freeValue,
    required this.onFree,
    required this.onCw,
    required this.onCcw,
    required this.onReset,
  });
  final double freeValue;
  final ValueChanged<double> onFree;
  final VoidCallback onCw;
  final VoidCallback onCcw;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Rotate 90 CCW',
          onPressed: onCcw,
          icon: const Icon(Icons.rotate_left),
        ),
        IconButton(
          tooltip: 'Rotate 90 CW',
          onPressed: onCw,
          icon: const Icon(Icons.rotate_right),
        ),
        Expanded(
          child: Slider(
            min: -3.14159,
            max: 3.14159,
            value: freeValue.clamp(-3.14159, 3.14159),
            onChanged: onFree,
          ),
        ),
        IconButton(
          tooltip: 'Reset',
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
