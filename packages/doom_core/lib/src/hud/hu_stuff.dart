import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/hud/hu_lib.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _HuStuffConstants {
  static const int fontStart = 33;
  static const int fontSize = 63;
  static const int msgX = 0;
  static const int msgY = 0;
  static const int msgHeight = 1;
  static const int msgTimeout = 4 * GameConstants.ticRate;
  static const int titleX = 0;
}

class HudMessages {
  late List<Patch> _font;
  late HuScrollText _messageWidget;
  late HuTextLine _titleWidget;

  late Player _player;
  late Uint8List _screen;

  bool _messageOn = false;
  int _messageCounter = 0;
  bool showMessages = true;

  void loadFont(WadManager wad) {
    _font = [];
    var charCode = _HuStuffConstants.fontStart;

    for (var i = 0; i < _HuStuffConstants.fontSize; i++) {
      final lumpName = 'STCFN${charCode.toString().padLeft(3, '0')}';
      final lumpNum = wad.checkNumForName(lumpName);
      if (lumpNum >= 0) {
        final data = wad.cacheLumpNum(lumpNum);
        _font.add(Patch.parse(data));
      } else if (_font.isNotEmpty) {
        _font.add(_font[0]);
      }
      charCode++;
    }
  }

  void init(Player player, Uint8List screen, {String? levelName}) {
    _player = player;
    _screen = screen;
    _messageOn = false;
    _messageCounter = 0;

    final fontHeight = _font.isNotEmpty ? _font[0].height : 8;
    final titleY = 167 - fontHeight;

    _messageWidget = HuScrollText(
      x: _HuStuffConstants.msgX,
      y: _HuStuffConstants.msgY,
      height: _HuStuffConstants.msgHeight,
      font: _font,
    );

    _titleWidget = HuTextLine(
      x: _HuStuffConstants.titleX,
      y: titleY,
      font: _font,
    );

    if (levelName != null) {
      for (final char in levelName.codeUnits) {
        _titleWidget.addChar(char);
      }
    }
  }

  void ticker() {
    if (_messageCounter > 0) {
      _messageCounter--;
      if (_messageCounter == 0) {
        _messageOn = false;
      }
    }

    if (showMessages && _player.message != null) {
      _messageWidget.addMessage(null, _player.message!);
      _player.message = null;
      _messageOn = true;
      _messageCounter = _HuStuffConstants.msgTimeout;
    }
  }

  void drawer({bool automapActive = false}) {
    if (_messageOn) {
      _messageWidget.draw(_screen);
    }

    if (automapActive) {
      _titleWidget.draw(_screen);
    }
  }
}
