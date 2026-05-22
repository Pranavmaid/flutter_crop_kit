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
      : assert(bytes.isNotEmpty, 'bytes must be non-empty'),
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

Future<Uint8List> _fetchHttp(
  String url,
  Map<String, String>? headers,
) async {
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
