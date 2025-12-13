import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class VVideo {
  static const int _screenWidth = ScreenConstants.width;
  static const int _screenHeight = ScreenConstants.height;

  static void drawPatch(
    Uint8List screen,
    int x,
    int y,
    Patch patch,
  ) {
    final adjustedX = x - patch.leftOffset;
    final adjustedY = y - patch.topOffset;

    final startCol = adjustedX < 0 ? -adjustedX : 0;
    final endCol = adjustedX + patch.width > _screenWidth
        ? _screenWidth - adjustedX
        : patch.width;

    if (startCol >= endCol) return;

    for (var col = startCol; col < endCol; col++) {
      final screenX = adjustedX + col;
      if (screenX < 0 || screenX >= _screenWidth) continue;

      final columnPosts = patch.columns[col];

      for (final post in columnPosts) {
        final postY = adjustedY + post.topDelta;

        for (var i = 0; i < post.pixels.length; i++) {
          final screenY = postY + i;
          if (screenY >= 0 && screenY < _screenHeight) {
            screen[screenY * _screenWidth + screenX] = post.pixels[i];
          }
        }
      }
    }
  }

  static void drawPatchFlipped(
    Uint8List screen,
    int x,
    int y,
    Patch patch,
  ) {
    final adjustedX = x - patch.leftOffset;
    final adjustedY = y - patch.topOffset;
    final w = patch.width;

    final startCol = adjustedX < 0 ? -adjustedX : 0;
    final endCol = adjustedX + w > _screenWidth ? _screenWidth - adjustedX : w;

    if (startCol >= endCol) return;

    for (var col = startCol; col < endCol; col++) {
      final screenX = adjustedX + col;
      if (screenX < 0 || screenX >= _screenWidth) continue;

      final columnPosts = patch.columns[w - 1 - col];

      for (final post in columnPosts) {
        final postY = adjustedY + post.topDelta;

        for (var i = 0; i < post.pixels.length; i++) {
          final screenY = postY + i;
          if (screenY >= 0 && screenY < _screenHeight) {
            screen[screenY * _screenWidth + screenX] = post.pixels[i];
          }
        }
      }
    }
  }

  static void drawPatchDirect(
    Uint8List screen,
    int x,
    int y,
    Patch patch,
  ) {
    drawPatch(screen, x, y, patch);
  }

  static void copyRect({
    required Uint8List src,
    required int srcX,
    required int srcY,
    required Uint8List dst,
    required int dstX,
    required int dstY,
    required int width,
    required int height,
  }) {
    var startCol = 0;
    var startRow = 0;
    var endCol = width;
    var endRow = height;

    if (srcX < 0) {
      startCol = -srcX;
    }
    if (srcY < 0) {
      startRow = -srcY;
    }
    if (dstX < 0) {
      startCol = startCol > -dstX ? startCol : -dstX;
    }
    if (dstY < 0) {
      startRow = startRow > -dstY ? startRow : -dstY;
    }
    if (srcX + width > _screenWidth) {
      endCol = _screenWidth - srcX;
    }
    if (dstX + width > _screenWidth) {
      final limit = _screenWidth - dstX;
      if (limit < endCol) endCol = limit;
    }
    if (srcY + height > _screenHeight) {
      endRow = _screenHeight - srcY;
    }
    if (dstY + height > _screenHeight) {
      final limit = _screenHeight - dstY;
      if (limit < endRow) endRow = limit;
    }

    if (startCol >= endCol || startRow >= endRow) return;

    for (var row = startRow; row < endRow; row++) {
      final srcRowStart = (srcY + row) * _screenWidth + srcX;
      final dstRowStart = (dstY + row) * _screenWidth + dstX;
      for (var col = startCol; col < endCol; col++) {
        dst[dstRowStart + col] = src[srcRowStart + col];
      }
    }
  }

  static void drawBlock(
    Uint8List screen,
    int x,
    int y,
    int width,
    int height,
    Uint8List data,
  ) {
    var srcOffset = 0;
    var dstOffset = y * _screenWidth + x;

    for (var row = 0; row < height; row++) {
      for (var col = 0; col < width; col++) {
        screen[dstOffset + col] = data[srcOffset + col];
      }
      srcOffset += width;
      dstOffset += _screenWidth;
    }
  }
}
