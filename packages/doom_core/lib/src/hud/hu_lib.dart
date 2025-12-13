import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class HuConstants {
  static const int maxLines = 4;
  static const int maxLineLength = 80;
  static const int fontStart = 33;
  static const int fontEnd = 95;
  static const int spaceWidth = 4;
}

class HuTextLine {
  HuTextLine({
    required this.x,
    required this.y,
    required this.font,
    this.startChar = HuConstants.fontStart,
  });

  final int x;
  final int y;
  final List<Patch> font;
  final int startChar;

  String _text = '';
  int needsUpdate = 0;

  String get text => _text;
  int get length => _text.length;

  void clear() {
    _text = '';
    needsUpdate = 4;
  }

  bool addChar(int charCode) {
    if (_text.length >= HuConstants.maxLineLength) return false;
    _text += String.fromCharCode(charCode);
    needsUpdate = 4;
    return true;
  }

  bool deleteChar() {
    if (_text.isEmpty) return false;
    _text = _text.substring(0, _text.length - 1);
    needsUpdate = 4;
    return true;
  }

  void draw(Uint8List screen, {bool drawCursor = false}) {
    var drawX = x;

    for (var i = 0; i < _text.length; i++) {
      var c = _text.codeUnitAt(i);

      if (c >= 97 && c <= 122) {
        c -= 32;
      }

      if (c != 32 && c >= startChar && c <= 95) {
        final patchIndex = c - startChar;
        if (patchIndex < font.length) {
          final patch = font[patchIndex];
          if (drawX + patch.width > ScreenConstants.width) break;
          VVideo.drawPatchDirect(screen, drawX, y, patch);
          drawX += patch.width;
        }
      } else {
        drawX += HuConstants.spaceWidth;
        if (drawX >= ScreenConstants.width) break;
      }
    }

    if (drawCursor) {
      final cursorIndex = 95 - startChar;
      if (cursorIndex < font.length) {
        final cursorPatch = font[cursorIndex];
        if (drawX + cursorPatch.width <= ScreenConstants.width) {
          VVideo.drawPatchDirect(screen, drawX, y, cursorPatch);
        }
      }
    }
  }
}

class HuScrollText {
  HuScrollText({
    required this.x,
    required this.y,
    required this.height,
    required this.font,
    this.startChar = HuConstants.fontStart,
  }) {
    final lineHeight = font.isNotEmpty ? font[0].height + 1 : 8;
    for (var i = 0; i < height; i++) {
      _lines.add(HuTextLine(
        x: x,
        y: y - i * lineHeight,
        font: font,
        startChar: startChar,
      ),);
    }
  }

  final int x;
  final int y;
  final int height;
  final List<Patch> font;
  final int startChar;

  final List<HuTextLine> _lines = [];
  int _currentLine = 0;
  bool on = true;

  void addLine() {
    _currentLine++;
    if (_currentLine >= height) {
      _currentLine = 0;
    }
    _lines[_currentLine].clear();

    for (final line in _lines) {
      line.needsUpdate = 4;
    }
  }

  void addMessage(String? prefix, String message) {
    addLine();

    if (prefix != null) {
      for (final char in prefix.codeUnits) {
        _lines[_currentLine].addChar(char);
      }
    }

    for (final char in message.codeUnits) {
      _lines[_currentLine].addChar(char);
    }
  }

  void draw(Uint8List screen) {
    if (!on) return;

    for (var i = 0; i < height; i++) {
      var idx = _currentLine - i;
      if (idx < 0) {
        idx += height;
      }
      _lines[idx].draw(screen);
    }
  }
}

class HuInputText {
  HuInputText({
    required this.x,
    required this.y,
    required this.font,
    this.startChar = HuConstants.fontStart,
  }) : line = HuTextLine(x: x, y: y, font: font, startChar: startChar);

  final int x;
  final int y;
  final List<Patch> font;
  final int startChar;
  final HuTextLine line;

  int leftMargin = 0;
  bool on = false;

  void deleteChar() {
    if (line.length > leftMargin) {
      line.deleteChar();
    }
  }

  void eraseLine() {
    while (line.length > leftMargin) {
      line.deleteChar();
    }
  }

  void reset() {
    leftMargin = 0;
    line.clear();
  }

  void addPrefix(String prefix) {
    for (final char in prefix.codeUnits) {
      line.addChar(char);
    }
    leftMargin = line.length;
  }

  bool keyInput(int charCode) {
    if (charCode >= 32 && charCode <= 95) {
      line.addChar(charCode);
      return true;
    } else if (charCode == 8) {
      deleteChar();
      return true;
    } else if (charCode == 13) {
      return true;
    }
    return false;
  }

  void draw(Uint8List screen) {
    if (!on) return;
    line.draw(screen, drawCursor: true);
  }
}
