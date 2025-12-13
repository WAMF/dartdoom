import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _ButtonConstants {
  static const int maxButtons = 16;
  static const int buttonTime = 35;
}

enum ButtonWhere { top, middle, bottom }

class ButtonThinker extends Thinker {
  Line? line;
  ButtonWhere where = ButtonWhere.middle;
  int btexture = 0;
  int btimer = 0;

  void think(Thinker thinker) {
    if (btimer > 0) {
      btimer--;
      if (btimer == 0) {
        final side = line?.frontSide;
        if (side != null) {
          switch (where) {
            case ButtonWhere.top:
              side.topTexture = btexture;
            case ButtonWhere.middle:
              side.midTexture = btexture;
            case ButtonWhere.bottom:
              side.bottomTexture = btexture;
          }
        }

        function = null;
      }
    }
  }
}

class SwitchManager {
  SwitchManager(this._textureManager);

  final TextureManager _textureManager;
  final List<int> _switchList = [];
  int _numSwitches = 0;

  static const List<(String, String, int)> _alphSwitchList = [
    ('SW1BRCOM', 'SW2BRCOM', 1),
    ('SW1BRN1', 'SW2BRN1', 1),
    ('SW1BRN2', 'SW2BRN2', 1),
    ('SW1BRNGN', 'SW2BRNGN', 1),
    ('SW1BROWN', 'SW2BROWN', 1),
    ('SW1COMM', 'SW2COMM', 1),
    ('SW1COMP', 'SW2COMP', 1),
    ('SW1DIRT', 'SW2DIRT', 1),
    ('SW1EXIT', 'SW2EXIT', 1),
    ('SW1GRAY', 'SW2GRAY', 1),
    ('SW1GRAY1', 'SW2GRAY1', 1),
    ('SW1METAL', 'SW2METAL', 1),
    ('SW1PIPE', 'SW2PIPE', 1),
    ('SW1SLAD', 'SW2SLAD', 1),
    ('SW1STARG', 'SW2STARG', 1),
    ('SW1STON1', 'SW2STON1', 1),
    ('SW1STON2', 'SW2STON2', 1),
    ('SW1STONE', 'SW2STONE', 1),
    ('SW1STRTN', 'SW2STRTN', 1),
    ('SW1BLUE', 'SW2BLUE', 2),
    ('SW1CMT', 'SW2CMT', 2),
    ('SW1GARG', 'SW2GARG', 2),
    ('SW1GSTON', 'SW2GSTON', 2),
    ('SW1HOT', 'SW2HOT', 2),
    ('SW1LION', 'SW2LION', 2),
    ('SW1SATYR', 'SW2SATYR', 2),
    ('SW1SKIN', 'SW2SKIN', 2),
    ('SW1VINE', 'SW2VINE', 2),
    ('SW1WOOD', 'SW2WOOD', 2),
    ('SW1PANEL', 'SW2PANEL', 3),
    ('SW1ROCK', 'SW2ROCK', 3),
    ('SW1MET2', 'SW2MET2', 3),
    ('SW1WDMET', 'SW2WDMET', 3),
    ('SW1BRIK', 'SW2BRIK', 3),
    ('SW1MOD1', 'SW2MOD1', 3),
    ('SW1ZIM', 'SW2ZIM', 3),
    ('SW1STON6', 'SW2STON6', 3),
    ('SW1TEK', 'SW2TEK', 3),
    ('SW1MARB', 'SW2MARB', 3),
    ('SW1SKULL', 'SW2SKULL', 3),
  ];

  void init({int episode = 3}) {
    _switchList.clear();
    _numSwitches = 0;

    for (final (name1, name2, switchEpisode) in _alphSwitchList) {
      if (switchEpisode <= episode) {
        final tex1 = _textureManager.checkTextureNumForName(name1);
        final tex2 = _textureManager.checkTextureNumForName(name2);

        if (tex1 >= 0 && tex2 >= 0) {
          _switchList.add(tex1);
          _switchList.add(tex2);
          _numSwitches++;
        }
      }
    }
  }

  void changeSwitchTexture(Line line, {required bool useAgain, required LevelLocals level}) {
    if (!useAgain) {
      line.special = 0;
    }

    final side = line.frontSide;
    if (side == null) return;

    final texTop = side.topTexture;
    final texMid = side.midTexture;
    final texBot = side.bottomTexture;

    for (var i = 0; i < _numSwitches * 2; i++) {
      if (_switchList[i] == texTop) {
        side.topTexture = _switchList[i ^ 1];
        if (useAgain) {
          _startButton(line, ButtonWhere.top, _switchList[i], level);
        }
        return;
      } else if (_switchList[i] == texMid) {
        side.midTexture = _switchList[i ^ 1];
        if (useAgain) {
          _startButton(line, ButtonWhere.middle, _switchList[i], level);
        }
        return;
      } else if (_switchList[i] == texBot) {
        side.bottomTexture = _switchList[i ^ 1];
        if (useAgain) {
          _startButton(line, ButtonWhere.bottom, _switchList[i], level);
        }
        return;
      }
    }
  }

  void _startButton(Line line, ButtonWhere where, int texture, LevelLocals level) {
    for (final thinker in level.thinkers.all) {
      if (thinker is ButtonThinker && thinker.btimer > 0 && thinker.line == line) {
        return;
      }
    }

    var buttonCount = 0;
    for (final thinker in level.thinkers.all) {
      if (thinker is ButtonThinker && thinker.btimer > 0) {
        buttonCount++;
      }
    }

    if (buttonCount >= _ButtonConstants.maxButtons) {
      return;
    }

    final button = ButtonThinker()
      ..line = line
      ..where = where
      ..btexture = texture
      ..btimer = _ButtonConstants.buttonTime;
    button.function = button.think;

    level.thinkers.add(button);
  }
}
