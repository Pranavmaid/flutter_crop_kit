import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_crop_kit/src/error/crop_exception.dart';
import 'package:flutter_crop_kit/src/source/image_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../_helpers/test_images.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('MemorySource loads decoded image', () async {
    final bytes = await makeCheckerboardPng(width: 64, height: 64, cell: 16);
    final src = ImageSource.memory(bytes);
    final img = await loadImageSource(src);
    expect(img.width, 64);
    expect(img.height, 64);
  });

  test('FileSource loads from disk', () async {
    final bytes = await makeCheckerboardPng(width: 80, height: 20, cell: 10);
    final tmp = await File(
      '${Directory.systemTemp.path}/fck_test_${DateTime.now().microsecondsSinceEpoch}.png',
    ).writeAsBytes(bytes);
    try {
      final src = ImageSource.file(tmp);
      final img = await loadImageSource(src);
      expect(img.width, 80);
      expect(img.height, 20);
    } finally {
      if (await tmp.exists()) await tmp.delete();
    }
  });

  test('FileSource missing file throws CropLoadException', () async {
    final src = ImageSource.file(File('does/not/exist.png'));
    expect(loadImageSource(src), throwsA(isA<CropLoadException>()));
  });

  test('MemorySource empty bytes asserts', () {
    expect(() => ImageSource.memory(Uint8List(0)), throwsAssertionError);
  });
}
