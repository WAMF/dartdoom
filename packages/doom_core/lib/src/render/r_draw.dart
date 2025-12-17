import 'dart:typed_data';

import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _DrawConstants {
  static const int flatSize = 64;
  static const int flatMask = flatSize - 1;
  static const int flatShift = 6;
}

final Int32List _fuzzOffset = Int32List.fromList([
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
  ScreenDimensions.width,
  -ScreenDimensions.width,
  ScreenDimensions.width,
]);

class ColumnDrawer {
  int x = 0;
  int yl = 0;
  int yh = 0;
  int iscale = 0;
  int textureMid = 0;
  int centerY = ScreenDimensions.centerY;
  Uint8List? source;
  Uint8List? colormap;
  Int32List? yLookup;
  Int32List? columnOfs;

  void draw(Uint8List dest) {
    var count = yh - yl;
    if (count < 0) return;

    final src = source;
    final cmap = colormap;
    if (src == null || cmap == null) return;

    var destIndex = yLookup![yl] + columnOfs![x];

    final fracStep = iscale;
    var frac = textureMid + (yl - centerY) * fracStep;

    final srcLen = src.length;

    do {
      var texIndex = (frac >> Fixed32.fracBits) % srcLen;
      if (texIndex < 0) texIndex += srcLen;
      dest[destIndex] = cmap[src[texIndex]];
      destIndex += ScreenDimensions.width;
      frac += fracStep;
      count--;
    } while (count >= 0);
  }

  void drawLow(Uint8List dest) {
    var count = yh - yl;
    if (count < 0) return;

    final src = source;
    final cmap = colormap;
    if (src == null || cmap == null) return;

    final x2 = x << 1;
    var destIndex = yLookup![yl] + columnOfs![x2];

    final fracStep = iscale;
    var frac = textureMid + (yl - centerY) * fracStep;
    final srcLen = src.length;

    do {
      var texIndex = (frac >> Fixed32.fracBits) % srcLen;
      if (texIndex < 0) texIndex += srcLen;
      final pixel = cmap[src[texIndex]];
      dest[destIndex] = pixel;
      dest[destIndex + 1] = pixel;
      destIndex += ScreenDimensions.width;
      frac += fracStep;
      count--;
    } while (count >= 0);
  }
}

class FuzzColumnDrawer {
  int x = 0;
  int yl = 0;
  int yh = 0;
  int viewHeight = ScreenDimensions.viewHeight;
  Uint8List? colormap;
  Int32List? yLookup;
  Int32List? columnOfs;
  int fuzzPos = 0;

  void draw(Uint8List dest) {
    var count = yh - yl;
    if (count < 0) return;

    final cmap = colormap;
    if (cmap == null) return;

    if (yl == 0) {
      yl = 1;
      count--;
    }

    if (yh == viewHeight - 1) {
      yh = viewHeight - 2;
      count--;
    }

    if (count < 0) return;

    var destIndex = yLookup![yl] + columnOfs![x];

    do {
      dest[destIndex] = cmap[6 * 256 + dest[destIndex + _fuzzOffset[fuzzPos]]];
      fuzzPos = (fuzzPos + 1) % _fuzzOffset.length;
      destIndex += ScreenDimensions.width;
      count--;
    } while (count >= 0);
  }
}

class TranslatedColumnDrawer {
  int x = 0;
  int yl = 0;
  int yh = 0;
  int iscale = 0;
  int textureMid = 0;
  int centerY = ScreenDimensions.centerY;
  Uint8List? source;
  Uint8List? colormap;
  Uint8List? translation;
  Int32List? yLookup;
  Int32List? columnOfs;

  void draw(Uint8List dest) {
    var count = yh - yl;
    if (count < 0) return;

    final src = source;
    final cmap = colormap;
    final trans = translation;
    if (src == null || cmap == null || trans == null) return;

    var destIndex = yLookup![yl] + columnOfs![x];

    final fracStep = iscale;
    var frac = textureMid + (yl - centerY) * fracStep;

    final srcLen = src.length;

    do {
      var texIndex = (frac >> Fixed32.fracBits) % srcLen;
      if (texIndex < 0) texIndex += srcLen;
      dest[destIndex] = cmap[trans[src[texIndex]]];
      destIndex += ScreenDimensions.width;
      frac += fracStep;
      count--;
    } while (count >= 0);
  }
}

class SpanDrawer {
  int y = 0;
  int x1 = 0;
  int x2 = 0;
  int xFrac = 0;
  int yFrac = 0;
  int xStep = 0;
  int yStep = 0;
  Uint8List? source;
  Uint8List? colormap;
  Int32List? yLookup;
  Int32List? columnOfs;

  void draw(Uint8List dest) {
    var count = x2 - x1;
    if (count < 0) return;

    final src = source;
    final cmap = colormap;
    if (src == null || cmap == null) return;

    var destIndex = yLookup![y] + columnOfs![x1];

    var xf = xFrac;
    var yf = yFrac;

    do {
      final spot = ((yf >> (Fixed32.fracBits - _DrawConstants.flatShift)) &
              (_DrawConstants.flatMask * _DrawConstants.flatSize)) +
          ((xf >> Fixed32.fracBits) & _DrawConstants.flatMask);

      dest[destIndex] = cmap[src[spot]];
      destIndex++;

      xf += xStep;
      yf += yStep;
      count--;
    } while (count >= 0);
  }

  void drawLow(Uint8List dest) {
    var count = x2 - x1;
    if (count < 0) return;

    final src = source;
    final cmap = colormap;
    if (src == null || cmap == null) return;

    var destIndex = yLookup![y] + columnOfs![x1];

    var xf = xFrac;
    var yf = yFrac;

    do {
      final spot = ((yf >> (Fixed32.fracBits - _DrawConstants.flatShift)) &
              (_DrawConstants.flatMask * _DrawConstants.flatSize)) +
          ((xf >> Fixed32.fracBits) & _DrawConstants.flatMask);

      final pixel = cmap[src[spot]];
      dest[destIndex] = pixel;
      dest[destIndex + 1] = pixel;
      destIndex += 2;

      xf += xStep;
      yf += yStep;
      count--;
    } while (count >= 0);
  }
}

enum DrawerType { column, columnLow, fuzz, translated, span, spanLow }

class DrawContext {
  final ColumnDrawer column = ColumnDrawer();
  final FuzzColumnDrawer fuzz = FuzzColumnDrawer();
  final TranslatedColumnDrawer translated = TranslatedColumnDrawer();
  final SpanDrawer span = SpanDrawer();

  DrawerType columnFunc = DrawerType.column;
  DrawerType baseColumnFunc = DrawerType.column;
  DrawerType spanFunc = DrawerType.span;

  void setLookups(Int32List yLookup, Int32List columnOfs, int centerY, int viewHeight) {
    column
      ..yLookup = yLookup
      ..columnOfs = columnOfs
      ..centerY = centerY;
    fuzz
      ..yLookup = yLookup
      ..columnOfs = columnOfs
      ..viewHeight = viewHeight;
    translated
      ..yLookup = yLookup
      ..columnOfs = columnOfs
      ..centerY = centerY;
    span
      ..yLookup = yLookup
      ..columnOfs = columnOfs;
  }

  void drawColumn(Uint8List dest) {
    switch (columnFunc) {
      case DrawerType.column:
        column.draw(dest);
      case DrawerType.columnLow:
        column.drawLow(dest);
      case DrawerType.fuzz:
        fuzz.draw(dest);
      case DrawerType.translated:
        translated.draw(dest);
      case DrawerType.span:
      case DrawerType.spanLow:
        break;
    }
  }

  void drawSpan(Uint8List dest) {
    switch (spanFunc) {
      case DrawerType.span:
        span.draw(dest);
      case DrawerType.spanLow:
        span.drawLow(dest);
      case DrawerType.column:
      case DrawerType.columnLow:
      case DrawerType.fuzz:
      case DrawerType.translated:
        break;
    }
  }
}
