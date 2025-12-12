import 'dart:io';
import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:image/image.dart' as img;

class FrameCapture {
  FrameCapture(this._palette);

  final DoomPalette _palette;

  Uint8List toRgba(Uint8List indexedPixels) {
    final rgba = Uint8List(indexedPixels.length * 4);
    for (var i = 0; i < indexedPixels.length; i++) {
      final colorIndex = indexedPixels[i];
      rgba[i * 4] = _palette.getRed(colorIndex);
      rgba[i * 4 + 1] = _palette.getGreen(colorIndex);
      rgba[i * 4 + 2] = _palette.getBlue(colorIndex);
      rgba[i * 4 + 3] = 255;
    }
    return rgba;
  }

  Uint8List toPng(
    Uint8List indexedPixels, {
    int width = FrameBuffer.width,
    int height = FrameBuffer.height,
    int scale = 1,
  }) {
    final rgba = toRgba(indexedPixels);

    final image = img.Image(width: width, height: height);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final i = (y * width + x) * 4;
        image.setPixelRgba(x, y, rgba[i], rgba[i + 1], rgba[i + 2], rgba[i + 3]);
      }
    }

    final scaled = scale > 1
        ? img.copyResize(
            image,
            width: width * scale,
            height: height * scale,
          )
        : image;

    return Uint8List.fromList(img.encodePng(scaled));
  }

  Future<void> savePng(
    Uint8List indexedPixels,
    String path, {
    int width = FrameBuffer.width,
    int height = FrameBuffer.height,
    int scale = 1,
  }) async {
    final pngData = toPng(
      indexedPixels,
      width: width,
      height: height,
      scale: scale,
    );
    await File(path).writeAsBytes(pngData);
  }

  void savePngSync(
    Uint8List indexedPixels,
    String path, {
    int width = FrameBuffer.width,
    int height = FrameBuffer.height,
    int scale = 1,
  }) {
    final pngData = toPng(
      indexedPixels,
      width: width,
      height: height,
      scale: scale,
    );
    File(path).writeAsBytesSync(pngData);
  }
}
