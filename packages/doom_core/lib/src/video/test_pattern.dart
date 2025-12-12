import 'package:doom_core/src/video/frame_buffer.dart';

abstract final class _TestPatternConstants {
  static const int colorBarCount = 16;
  static const int colorBarHeight = 40;
  static const int gradientHeight = 20;
  static const int borderWidth = 2;
  static const int safeAreaMargin = 16;
  static const int headerHeight = 16;
  static const int footerHeight = 16;
}

abstract final class _PaletteIndices {
  static const int black = 0;
  static const int white = 4;
  static const int red = 176;
  static const int green = 112;
  static const int blue = 200;
  static const int yellow = 160;
  static const int cyan = 194;
  static const int magenta = 250;
}

class TestPattern {
  static const int safeAreaTop = _TestPatternConstants.headerHeight +
      _TestPatternConstants.colorBarHeight +
      _TestPatternConstants.gradientHeight +
      8;
  static const int safeAreaBottom =
      FrameBuffer.height - _TestPatternConstants.footerHeight - _TestPatternConstants.safeAreaMargin;
  static const int safeAreaLeft = _TestPatternConstants.safeAreaMargin;
  static const int safeAreaRight = FrameBuffer.width - _TestPatternConstants.safeAreaMargin - 1;

  static const List<int> colorBarPalette = [
    _PaletteIndices.white,
    _PaletteIndices.yellow,
    _PaletteIndices.cyan,
    _PaletteIndices.green,
    _PaletteIndices.magenta,
    _PaletteIndices.red,
    _PaletteIndices.blue,
    _PaletteIndices.black,
    _PaletteIndices.black,
    _PaletteIndices.blue,
    _PaletteIndices.red,
    _PaletteIndices.magenta,
    _PaletteIndices.green,
    _PaletteIndices.cyan,
    _PaletteIndices.yellow,
    _PaletteIndices.white,
  ];

  static void render(FrameBuffer frame) {
    frame.clear();

    _drawColorBars(frame);
    _drawGradientRamp(frame);
    _drawSafeAreaBorder(frame);
  }

  static void renderCrosshair(FrameBuffer frame) {
    const centerX = FrameBuffer.width ~/ 2;
    const centerY = FrameBuffer.height ~/ 2;
    const size = 20;

    _drawHorizontalLine(frame, centerX - size, centerX + size, centerY, _PaletteIndices.white);
    _drawVerticalLine(frame, centerX, centerY - size, centerY + size, _PaletteIndices.white);
  }

  static void _drawColorBars(FrameBuffer frame) {
    const startY = _TestPatternConstants.headerHeight;
    const barWidth = FrameBuffer.width ~/ _TestPatternConstants.colorBarCount;

    for (var barIndex = 0; barIndex < _TestPatternConstants.colorBarCount; barIndex++) {
      final colorIndex = colorBarPalette[barIndex % colorBarPalette.length];
      final startX = barIndex * barWidth;

      for (var y = startY; y < startY + _TestPatternConstants.colorBarHeight; y++) {
        for (var x = startX; x < startX + barWidth && x < FrameBuffer.width; x++) {
          frame.setPixel(x, y, colorIndex);
        }
      }
    }
  }

  static void _drawGradientRamp(FrameBuffer frame) {
    const startY = _TestPatternConstants.headerHeight + _TestPatternConstants.colorBarHeight + 4;

    for (var x = 0; x < FrameBuffer.width; x++) {
      final intensity = (x * 32) ~/ FrameBuffer.width;
      final colorIndex = intensity.clamp(0, 31);

      for (var y = startY; y < startY + _TestPatternConstants.gradientHeight; y++) {
        frame.setPixel(x, y, colorIndex);
      }
    }
  }

  static void _drawSafeAreaBorder(FrameBuffer frame) {
    const margin = _TestPatternConstants.safeAreaMargin;
    const borderWidth = _TestPatternConstants.borderWidth;
    const color = _PaletteIndices.white;

    const left = margin;
    const right = FrameBuffer.width - margin - 1;
    const top = _TestPatternConstants.headerHeight +
        _TestPatternConstants.colorBarHeight +
        _TestPatternConstants.gradientHeight +
        8;
    const bottom = FrameBuffer.height - _TestPatternConstants.footerHeight - margin;

    for (var i = 0; i < borderWidth; i++) {
      _drawHorizontalLine(frame, left, right, top + i, color);
      _drawHorizontalLine(frame, left, right, bottom - i, color);
      _drawVerticalLine(frame, left + i, top, bottom, color);
      _drawVerticalLine(frame, right - i, top, bottom, color);
    }

    _drawCornerMarkers(frame, left, top, right, bottom, color);
  }

  static void _drawCornerMarkers(
    FrameBuffer frame,
    int left,
    int top,
    int right,
    int bottom,
    int color,
  ) {
    const markerSize = 8;

    for (var i = 0; i < markerSize; i++) {
      frame
        ..setPixel(left + _TestPatternConstants.borderWidth + i, top + _TestPatternConstants.borderWidth, color)
        ..setPixel(left + _TestPatternConstants.borderWidth, top + _TestPatternConstants.borderWidth + i, color)
        ..setPixel(right - _TestPatternConstants.borderWidth - i, top + _TestPatternConstants.borderWidth, color)
        ..setPixel(right - _TestPatternConstants.borderWidth, top + _TestPatternConstants.borderWidth + i, color)
        ..setPixel(left + _TestPatternConstants.borderWidth + i, bottom - _TestPatternConstants.borderWidth, color)
        ..setPixel(left + _TestPatternConstants.borderWidth, bottom - _TestPatternConstants.borderWidth - i, color)
        ..setPixel(right - _TestPatternConstants.borderWidth - i, bottom - _TestPatternConstants.borderWidth, color)
        ..setPixel(right - _TestPatternConstants.borderWidth, bottom - _TestPatternConstants.borderWidth - i, color);
    }
  }

  static void _drawHorizontalLine(
    FrameBuffer frame,
    int x1,
    int x2,
    int y,
    int colorIndex,
  ) {
    for (var x = x1; x <= x2; x++) {
      frame.setPixel(x, y, colorIndex);
    }
  }

  static void _drawVerticalLine(
    FrameBuffer frame,
    int x,
    int y1,
    int y2,
    int colorIndex,
  ) {
    for (var y = y1; y <= y2; y++) {
      frame.setPixel(x, y, colorIndex);
    }
  }

  static void drawFilledRect(
    FrameBuffer frame,
    int x,
    int y,
    int width,
    int height,
    int colorIndex,
  ) {
    for (var dy = 0; dy < height; dy++) {
      for (var dx = 0; dx < width; dx++) {
        frame.setPixel(x + dx, y + dy, colorIndex);
      }
    }
  }
}
