import 'dart:math' as math;
import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/p_pspr.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/hud/st_lib.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _FaceConstants {
  static const int numPainFaces = 5;
  static const int numStraightFaces = 3;
  static const int numTurnFaces = 2;
  static const int numSpecialFaces = 3;
  static const int faceStride = numStraightFaces + numTurnFaces + numSpecialFaces;

  static const int turnOffset = numStraightFaces;
  static const int ouchOffset = turnOffset + numTurnFaces;
  static const int evilGrinOffset = ouchOffset + 1;
  static const int rampageOffset = evilGrinOffset + 1;
  static const int godFace = numPainFaces * faceStride;
  static const int deadFace = godFace + 1;

  static const int evilGrinCount = 2 * GameConstants.ticRate;
  static const int straightFaceCount = GameConstants.ticRate ~/ 2;
  static const int turnCount = GameConstants.ticRate;
  static const int rampageDelay = 2 * GameConstants.ticRate;
  static const int muchPain = 20;
}

abstract final class _WidgetPositions {
  static const int ammoX = 44;
  static const int ammoY = 171;
  static const int ammoWidth = 3;

  static const int healthX = 90;
  static const int healthY = 171;

  static const int armorX = 221;
  static const int armorY = 171;

  static const int faceX = 143;
  static const int faceY = 168;

  static const int armsX = 111;
  static const int armsY = 172;
  static const int armsBgX = 104;
  static const int armsBgY = 168;
  static const int armsXSpace = 12;
  static const int armsYSpace = 10;

  static const int key0X = 239;
  static const int key0Y = 171;
  static const int key1Y = 181;
  static const int key2Y = 191;

  static const int ammo0X = 288;
  static const int ammo0Y = 173;
  static const int ammo1Y = 179;
  static const int ammo2Y = 191;
  static const int ammo3Y = 185;

  static const int maxAmmo0X = 314;
  static const int maxAmmo0Y = 173;
  static const int maxAmmo1Y = 179;
  static const int maxAmmo2Y = 191;
  static const int maxAmmo3Y = 185;
}

abstract final class _ScreenIndices {
  static const int background = 4;
  static const int foreground = 0;
}

class StatusBar {
  late Player _player;
  late List<Uint8List> _screens;
  final _random = math.Random();

  late List<Patch> _tallNum;
  late List<Patch> _shortNum;
  late Patch _tallPercent;
  late Patch _minusPatch;
  late Patch _statusBarBg;
  late List<Patch> _faces;
  late List<Patch> _keys;
  late Patch _armsBg;
  late List<List<Patch>> _arms;

  late StNumber _readyAmmo;
  late StPercent _healthWidget;
  late StPercent _armorWidget;
  late StMultIcon _faceWidget;
  late List<StMultIcon> _keyWidgets;
  late List<StMultIcon> _armsWidgets;
  late StBinIcon _armsBgWidget;
  late List<StNumber> _ammoWidgets;
  late List<StNumber> _maxAmmoWidgets;

  int _faceIndex = 0;
  int _faceCount = 0;
  int _priority = 0;
  int _oldHealth = -1;
  int _lastAttackDown = -1;
  final List<bool> _oldWeaponsOwned = List.filled(9, false);
  final List<int> _keyBoxes = List.filled(3, -1);

  bool statusBarOn = true;
  bool armsOn = true;

  void loadGraphics(WadManager wad) {
    _tallNum = List.generate(10, (i) {
      final data = wad.cacheLumpName('STTNUM$i');
      return Patch.parse(data);
    });

    _shortNum = List.generate(10, (i) {
      final data = wad.cacheLumpName('STYSNUM$i');
      return Patch.parse(data);
    });

    _tallPercent = Patch.parse(wad.cacheLumpName('STTPRCNT'));
    _minusPatch = Patch.parse(wad.cacheLumpName('STTMINUS'));
    _statusBarBg = Patch.parse(wad.cacheLumpName('STBAR'));
    _armsBg = Patch.parse(wad.cacheLumpName('STARMS'));

    _keys = List.generate(6, (i) {
      final data = wad.cacheLumpName('STKEYS$i');
      return Patch.parse(data);
    });

    _arms = List.generate(6, (i) {
      final gray = Patch.parse(wad.cacheLumpName('STGNUM${i + 2}'));
      return [gray, _shortNum[i + 2]];
    });

    _loadFaces(wad);
  }

  void _loadFaces(WadManager wad) {
    _faces = [];

    for (var painLevel = 0; painLevel < _FaceConstants.numPainFaces; painLevel++) {
      for (var straight = 0; straight < _FaceConstants.numStraightFaces; straight++) {
        _faces.add(Patch.parse(wad.cacheLumpName('STFST$painLevel$straight')));
      }
      _faces
        ..add(Patch.parse(wad.cacheLumpName('STFTR${painLevel}0')))
        ..add(Patch.parse(wad.cacheLumpName('STFTL${painLevel}0')))
        ..add(Patch.parse(wad.cacheLumpName('STFOUCH$painLevel')))
        ..add(Patch.parse(wad.cacheLumpName('STFEVL$painLevel')))
        ..add(Patch.parse(wad.cacheLumpName('STFKILL$painLevel')));
    }

    _faces
      ..add(Patch.parse(wad.cacheLumpName('STFGOD0')))
      ..add(Patch.parse(wad.cacheLumpName('STFDEAD0')));
  }

  void init(Player player, List<Uint8List> screens) {
    _player = player;
    _screens = screens;
    _faceIndex = 0;
    _oldHealth = -1;
    _priority = 0;

    for (var i = 0; i < _player.weaponOwned.length && i < _oldWeaponsOwned.length; i++) {
      _oldWeaponsOwned[i] = _player.weaponOwned[i];
    }

    for (var i = 0; i < 3; i++) {
      _keyBoxes[i] = -1;
    }

    _createWidgets();
  }

  void _createWidgets() {
    _readyAmmo = StNumber(
      x: _WidgetPositions.ammoX,
      y: _WidgetPositions.ammoY,
      width: _WidgetPositions.ammoWidth,
      patches: _tallNum,
      getValue: _getReadyAmmo,
    );

    _healthWidget = StPercent(
      x: _WidgetPositions.healthX,
      y: _WidgetPositions.healthY,
      patches: _tallNum,
      percentPatch: _tallPercent,
      getValue: () => _player.health,
    );

    _armorWidget = StPercent(
      x: _WidgetPositions.armorX,
      y: _WidgetPositions.armorY,
      patches: _tallNum,
      percentPatch: _tallPercent,
      getValue: () => _player.armorPoints,
    );

    _faceWidget = StMultIcon(
      x: _WidgetPositions.faceX,
      y: _WidgetPositions.faceY,
      patches: _faces,
      getIndex: () => _faceIndex,
    );

    _keyWidgets = [
      StMultIcon(
        x: _WidgetPositions.key0X,
        y: _WidgetPositions.key0Y,
        patches: _keys,
        getIndex: () => _keyBoxes[0],
      ),
      StMultIcon(
        x: _WidgetPositions.key0X,
        y: _WidgetPositions.key1Y,
        patches: _keys,
        getIndex: () => _keyBoxes[1],
      ),
      StMultIcon(
        x: _WidgetPositions.key0X,
        y: _WidgetPositions.key2Y,
        patches: _keys,
        getIndex: () => _keyBoxes[2],
      ),
    ];

    _armsBgWidget = StBinIcon(
      x: _WidgetPositions.armsBgX,
      y: _WidgetPositions.armsBgY,
      patch: _armsBg,
      getValue: () => armsOn,
    );

    _armsWidgets = List.generate(6, (i) {
      final weaponIndex = i + 1;
      return StMultIcon(
        x: _WidgetPositions.armsX + (i % 3) * _WidgetPositions.armsXSpace,
        y: _WidgetPositions.armsY + (i ~/ 3) * _WidgetPositions.armsYSpace,
        patches: _arms[i],
        getIndex: () => _player.weaponOwned[weaponIndex] ? 1 : 0,
      );
    });

    _ammoWidgets = [
      StNumber(x: _WidgetPositions.ammo0X, y: _WidgetPositions.ammo0Y, width: 3, patches: _shortNum, getValue: () => _player.ammo[0]),
      StNumber(x: _WidgetPositions.ammo0X, y: _WidgetPositions.ammo1Y, width: 3, patches: _shortNum, getValue: () => _player.ammo[1]),
      StNumber(x: _WidgetPositions.ammo0X, y: _WidgetPositions.ammo2Y, width: 3, patches: _shortNum, getValue: () => _player.ammo[2]),
      StNumber(x: _WidgetPositions.ammo0X, y: _WidgetPositions.ammo3Y, width: 3, patches: _shortNum, getValue: () => _player.ammo[3]),
    ];

    _maxAmmoWidgets = [
      StNumber(x: _WidgetPositions.maxAmmo0X, y: _WidgetPositions.maxAmmo0Y, width: 3, patches: _shortNum, getValue: () => _player.maxAmmo[0]),
      StNumber(x: _WidgetPositions.maxAmmo0X, y: _WidgetPositions.maxAmmo1Y, width: 3, patches: _shortNum, getValue: () => _player.maxAmmo[1]),
      StNumber(x: _WidgetPositions.maxAmmo0X, y: _WidgetPositions.maxAmmo2Y, width: 3, patches: _shortNum, getValue: () => _player.maxAmmo[2]),
      StNumber(x: _WidgetPositions.maxAmmo0X, y: _WidgetPositions.maxAmmo3Y, width: 3, patches: _shortNum, getValue: () => _player.maxAmmo[3]),
    ];
  }

  int _getReadyAmmo() {
    final weaponIndex = _player.readyWeapon.index;
    if (weaponIndex >= weaponInfo.length) return StLibConstants.naValue;
    final ammoType = weaponInfo[weaponIndex].ammo;
    if (ammoType == AmmoType.noAmmo) return StLibConstants.naValue;
    return _player.ammo[ammoType.index];
  }

  void ticker() {
    _updateKeyBoxes();
    _updateFace();
    _oldHealth = _player.health;
  }

  void _updateKeyBoxes() {
    for (var i = 0; i < 3; i++) {
      _keyBoxes[i] = _player.cards[i] ? i : -1;
      if (_player.cards[i + 3]) {
        _keyBoxes[i] = i + 3;
      }
    }
  }

  int _calcPainOffset() {
    final health = _player.health > 100 ? 100 : _player.health;
    return _FaceConstants.faceStride * (((100 - health) * _FaceConstants.numPainFaces) ~/ 101);
  }

  void _updateFace() {
    if (_priority < 10) {
      if (_player.health <= 0) {
        _priority = 9;
        _faceIndex = _FaceConstants.deadFace;
        _faceCount = 1;
      }
    }

    if (_priority < 9) {
      if (_player.bonusCount > 0) {
        var doEvilGrin = false;
        for (var i = 0; i < _player.weaponOwned.length && i < _oldWeaponsOwned.length; i++) {
          if (_oldWeaponsOwned[i] != _player.weaponOwned[i]) {
            doEvilGrin = true;
            _oldWeaponsOwned[i] = _player.weaponOwned[i];
          }
        }
        if (doEvilGrin) {
          _priority = 8;
          _faceCount = _FaceConstants.evilGrinCount;
          _faceIndex = _calcPainOffset() + _FaceConstants.evilGrinOffset;
        }
      }
    }

    if (_priority < 8) {
      if (_player.damageCount > 0 && _player.attacker != null && _player.attacker != _player.mobj) {
        _priority = 7;

        if (_oldHealth - _player.health > _FaceConstants.muchPain) {
          _faceCount = _FaceConstants.turnCount;
          _faceIndex = _calcPainOffset() + _FaceConstants.ouchOffset;
        } else {
          _faceCount = _FaceConstants.turnCount;
          _faceIndex = _calcPainOffset() + _FaceConstants.rampageOffset;
        }
      }
    }

    if (_priority < 7) {
      if (_player.damageCount > 0) {
        if (_oldHealth - _player.health > _FaceConstants.muchPain) {
          _priority = 7;
          _faceCount = _FaceConstants.turnCount;
          _faceIndex = _calcPainOffset() + _FaceConstants.ouchOffset;
        } else {
          _priority = 6;
          _faceCount = _FaceConstants.turnCount;
          _faceIndex = _calcPainOffset() + _FaceConstants.rampageOffset;
        }
      }
    }

    if (_priority < 6) {
      if (_player.attackDown) {
        if (_lastAttackDown == -1) {
          _lastAttackDown = _FaceConstants.rampageDelay;
        } else {
          _lastAttackDown--;
          if (_lastAttackDown == 0) {
            _priority = 5;
            _faceIndex = _calcPainOffset() + _FaceConstants.rampageOffset;
            _faceCount = 1;
            _lastAttackDown = 1;
          }
        }
      } else {
        _lastAttackDown = -1;
      }
    }

    if (_priority < 5) {
      if ((_player.cheats & _CheatFlags.godMode) != 0 ||
          _player.powers[PowerType.invulnerability.index] > 0) {
        _priority = 4;
        _faceIndex = _FaceConstants.godFace;
        _faceCount = 1;
      }
    }

    if (_faceCount == 0) {
      _faceIndex = _calcPainOffset() + (_random.nextInt(256) % 3);
      _faceCount = _FaceConstants.straightFaceCount;
      _priority = 0;
    }

    _faceCount--;
  }

  void drawer({required bool refresh}) {
    if (statusBarOn) {
      _refreshBackground();
      _drawWidgets(true);
    }
  }

  void _refreshBackground() {
    if (!statusBarOn) return;

    VVideo.drawPatch(_screens[_ScreenIndices.background], 0, 0, _statusBarBg);

    VVideo.copyRect(
      src: _screens[_ScreenIndices.background],
      srcX: 0,
      srcY: 0,
      dst: _screens[_ScreenIndices.foreground],
      dstX: 0,
      dstY: StLibConstants.stY,
      width: ScreenConstants.width,
      height: 32,
    );
  }

  void _drawWidgets(bool refresh) {
    _readyAmmo.update(_screens, _minusPatch, refresh: refresh);
    _healthWidget.update(_screens, _minusPatch, refresh: refresh);
    _armorWidget.update(_screens, _minusPatch, refresh: refresh);

    _armsBgWidget.update(_screens, refresh: refresh);
    for (final widget in _armsWidgets) {
      widget
        ..enabled = armsOn
        ..update(_screens, refresh: refresh);
    }

    _faceWidget.update(_screens, refresh: refresh);

    for (final widget in _keyWidgets) {
      widget.update(_screens, refresh: refresh);
    }

    for (final widget in _ammoWidgets) {
      widget.update(_screens, null, refresh: refresh);
    }

    for (final widget in _maxAmmoWidgets) {
      widget.update(_screens, null, refresh: refresh);
    }
  }
}

abstract final class _CheatFlags {
  static const int godMode = 1;
}
