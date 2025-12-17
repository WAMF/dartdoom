import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _IntermissionConstants {
  static const int ticRate = 35;
  static const int showNextLocDelay = 4;
  static const int noStateCount = 10;

  static const int titleY = 2;

  static const int spStatsX = 50;
  static const int spStatsY = 50;
  static const int spTimeX = 16;
  static const int spTimeY = ScreenConstants.height - 32;
}

enum _AnimType { always, random, level }

class _AnimDef {
  const _AnimDef({
    required this.type,
    required this.period,
    required this.numFrames,
    required this.x,
    required this.y,
    this.data1 = 0,
    // ignore: unused_element_parameter
    this.data2 = 0,
  });

  final _AnimType type;
  final int period;
  final int numFrames;
  final int x;
  final int y;
  final int data1;
  final int data2;
}

class _AnimState {
  _AnimState(this.def);

  final _AnimDef def;
  final List<Patch?> patches = [];
  int nextTic = 0;
  int ctr = -1;
}

const _epsd0Anims = [
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 224, y: 104),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 184, y: 160),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 112, y: 136),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 72, y: 112),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 88, y: 96),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 64, y: 48),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 192, y: 40),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 136, y: 16),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 80, y: 16),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 64, y: 24),
];

const _epsd1Anims = [
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 1),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 2),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 3),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 4),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 5),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 6),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 7),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 3, x: 192, y: 144, data1: 8),
  _AnimDef(type: _AnimType.level, period: 11, numFrames: 1, x: 128, y: 136, data1: 8),
];

const _epsd2Anims = [
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 104, y: 168),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 40, y: 136),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 160, y: 96),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 104, y: 80),
  _AnimDef(type: _AnimType.always, period: 11, numFrames: 3, x: 120, y: 32),
  _AnimDef(type: _AnimType.always, period: 8, numFrames: 3, x: 40, y: 0),
];

const _animDefs = [_epsd0Anims, _epsd1Anims, _epsd2Anims];

enum _IntermissionState { statCount, showNextLoc, noState }

class Intermission {
  Intermission(this._wadManager, this._random);

  final WadManager _wadManager;
  final DoomRandom _random;

  _IntermissionState _state = _IntermissionState.statCount;
  int _cnt = 0;
  int _bcnt = 0;
  bool _accelerateStage = false;

  int _episode = 0;
  int _lastMap = 0;
  int _nextMap = 0;
  bool _commercial = false;

  int _killCount = 0;
  int _maxKills = 1;
  int _itemCount = 0;
  int _maxItems = 1;
  int _secretCount = 0;
  int _maxSecrets = 1;
  int _levelTime = 0;

  int _cntKills = -1;
  int _cntItems = -1;
  int _cntSecrets = -1;
  int _cntTime = -1;
  int _cntPause = 0;
  int _spState = 1;

  bool _snlPointerOn = false;

  Patch? _background;
  final List<Patch?> _nums = List.filled(10, null);
  Patch? _percent;
  Patch? _colon;
  Patch? _finished;
  Patch? _entering;
  Patch? _killsPatch;
  Patch? _secretPatch;
  Patch? _itemsPatch;
  Patch? _timePatch;
  Patch? _sucks;
  final List<Patch?> _lnames = [];

  Patch? _splat;
  final List<Patch?> _yah = [null, null];
  final List<_AnimState> _anims = [];

  bool _dataLoaded = false;

  void Function()? onWorldDone;

  void start({
    required int episode,
    required int lastMap,
    required int nextMap,
    required int kills,
    required int maxKills,
    required int items,
    required int maxItems,
    required int secrets,
    required int maxSecrets,
    required int levelTime,
    bool commercial = false,
  }) {
    _episode = episode;
    _lastMap = lastMap;
    _nextMap = nextMap;
    _commercial = commercial;
    _killCount = kills;
    _maxKills = maxKills > 0 ? maxKills : 1;
    _itemCount = items;
    _maxItems = maxItems > 0 ? maxItems : 1;
    _secretCount = secrets;
    _maxSecrets = maxSecrets > 0 ? maxSecrets : 1;
    _levelTime = levelTime;

    _accelerateStage = false;
    _cnt = 0;
    _bcnt = 0;

    _loadData();
    _initStats();
  }

  void _loadData() {
    if (_dataLoaded) return;

    final bgName = 'WIMAP${_episode - 1}';
    final bgLump = _wadManager.checkNumForName(bgName);
    if (bgLump >= 0) {
      _background = Patch.parse(_wadManager.cacheLumpNum(bgLump));
    } else {
      final interpic = _wadManager.checkNumForName('INTERPIC');
      if (interpic >= 0) {
        _background = Patch.parse(_wadManager.cacheLumpNum(interpic));
      }
    }

    for (var i = 0; i < 10; i++) {
      final name = 'WINUM$i';
      final lump = _wadManager.checkNumForName(name);
      if (lump >= 0) {
        _nums[i] = Patch.parse(_wadManager.cacheLumpNum(lump));
      }
    }

    _percent = _loadPatch('WIPCNT');
    _colon = _loadPatch('WICOLON');
    _finished = _loadPatch('WIF');
    _entering = _loadPatch('WIENTER');
    _killsPatch = _loadPatch('WIOSTK');
    _secretPatch = _loadPatch('WISCRT2');
    _itemsPatch = _loadPatch('WIOSTI');
    _timePatch = _loadPatch('WITIME');
    _sucks = _loadPatch('WISUCKS');
    _splat = _loadPatch('WISPLAT');
    _yah[0] = _loadPatch('WIURH0');
    _yah[1] = _loadPatch('WIURH1');

    _lnames.clear();
    for (var i = 0; i < 9; i++) {
      final name = 'WILV${_episode - 1}$i';
      _lnames.add(_loadPatch(name));
    }

    _loadAnimations();

    _dataLoaded = true;
  }

  void _loadAnimations() {
    _anims.clear();
    final epsdIndex = _episode - 1;
    if (epsdIndex < 0 || epsdIndex >= _animDefs.length) return;

    final defs = _animDefs[epsdIndex];
    for (var j = 0; j < defs.length; j++) {
      final def = defs[j];
      final animState = _AnimState(def);

      for (var i = 0; i < def.numFrames; i++) {
        if (epsdIndex != 1 || j != 8) {
          final name = 'WIA$epsdIndex${j.toString().padLeft(2, '0')}${i.toString().padLeft(2, '0')}';
          animState.patches.add(_loadPatch(name));
        } else {
          animState.patches.add(_anims[4].patches[i]);
        }
      }
      _anims.add(animState);
    }
  }

  Patch? _loadPatch(String name) {
    final lump = _wadManager.checkNumForName(name);
    if (lump >= 0) {
      return Patch.parse(_wadManager.cacheLumpNum(lump));
    }
    return null;
  }

  void _initStats() {
    _state = _IntermissionState.statCount;
    _accelerateStage = false;
    _spState = 1;
    _cntKills = -1;
    _cntItems = -1;
    _cntSecrets = -1;
    _cntTime = -1;
    _cntPause = _IntermissionConstants.ticRate;
  }

  void _initShowNextLoc() {
    _state = _IntermissionState.showNextLoc;
    _accelerateStage = false;
    _cnt = _IntermissionConstants.showNextLocDelay * _IntermissionConstants.ticRate;
    _initAnimatedBack();
  }

  void _initAnimatedBack() {
    final epsdIndex = _episode - 1;
    if (epsdIndex < 0 || epsdIndex > 2) return;

    for (final anim in _anims) {
      anim.ctr = -1;

      if (anim.def.type == _AnimType.always) {
        anim.nextTic = _bcnt + 1 + (_random.mRandom() % anim.def.period);
      } else if (anim.def.type == _AnimType.random) {
        anim.nextTic = _bcnt + 1 + anim.def.data2 + (_random.mRandom() % anim.def.data1);
      } else if (anim.def.type == _AnimType.level) {
        anim.nextTic = _bcnt + 1;
      }
    }
  }

  void _updateAnimatedBack() {
    final epsdIndex = _episode - 1;
    if (epsdIndex < 0 || epsdIndex > 2) return;

    for (var i = 0; i < _anims.length; i++) {
      final anim = _anims[i];
      if (_bcnt != anim.nextTic) continue;

      switch (anim.def.type) {
        case _AnimType.always:
          anim.ctr++;
          if (anim.ctr >= anim.def.numFrames) anim.ctr = 0;
          anim.nextTic = _bcnt + anim.def.period;

        case _AnimType.random:
          anim.ctr++;
          if (anim.ctr == anim.def.numFrames) {
            anim
              ..ctr = -1
              ..nextTic = _bcnt + anim.def.data2 + (_random.mRandom() % anim.def.data1);
          } else {
            anim.nextTic = _bcnt + anim.def.period;
          }

        case _AnimType.level:
          if (!(_state == _IntermissionState.statCount && i == 7) &&
              _nextMap == anim.def.data1) {
            anim.ctr++;
            if (anim.ctr == anim.def.numFrames) anim.ctr--;
            anim.nextTic = _bcnt + anim.def.period;
          }
      }
    }
  }

  void _drawAnimatedBack(Uint8List screen) {
    final epsdIndex = _episode - 1;
    if (epsdIndex < 0 || epsdIndex > 2) return;

    for (final anim in _anims) {
      if (anim.ctr >= 0 && anim.ctr < anim.patches.length) {
        final patch = anim.patches[anim.ctr];
        if (patch != null) {
          VVideo.drawPatchDirect(screen, anim.def.x, anim.def.y, patch);
        }
      }
    }
  }

  void _initNoState() {
    _state = _IntermissionState.noState;
    _accelerateStage = false;
    _cnt = _IntermissionConstants.noStateCount;
  }

  void accelerate() {
    _accelerateStage = true;
  }

  void ticker() {
    _bcnt++;

    switch (_state) {
      case _IntermissionState.statCount:
        _updateStats();
      case _IntermissionState.showNextLoc:
        _updateShowNextLoc();
      case _IntermissionState.noState:
        _updateNoState();
    }
  }

  void _updateStats() {
    _updateAnimatedBack();

    if (_accelerateStage && _spState != 10) {
      _accelerateStage = false;
      _cntKills = (_killCount * 100) ~/ _maxKills;
      _cntItems = (_itemCount * 100) ~/ _maxItems;
      _cntSecrets = (_secretCount * 100) ~/ _maxSecrets;
      _cntTime = _levelTime ~/ _IntermissionConstants.ticRate;
      _spState = 10;
    }

    if (_spState == 2) {
      _cntKills += 2;
      if (_cntKills >= (_killCount * 100) ~/ _maxKills) {
        _cntKills = (_killCount * 100) ~/ _maxKills;
        _spState++;
      }
    } else if (_spState == 4) {
      _cntItems += 2;
      if (_cntItems >= (_itemCount * 100) ~/ _maxItems) {
        _cntItems = (_itemCount * 100) ~/ _maxItems;
        _spState++;
      }
    } else if (_spState == 6) {
      _cntSecrets += 2;
      if (_cntSecrets >= (_secretCount * 100) ~/ _maxSecrets) {
        _cntSecrets = (_secretCount * 100) ~/ _maxSecrets;
        _spState++;
      }
    } else if (_spState == 8) {
      _cntTime += 3;
      if (_cntTime >= _levelTime ~/ _IntermissionConstants.ticRate) {
        _cntTime = _levelTime ~/ _IntermissionConstants.ticRate;
        _spState++;
      }
    } else if (_spState == 10) {
      if (_accelerateStage) {
        _initShowNextLoc();
      }
    } else if (_spState & 1 != 0) {
      if (--_cntPause == 0) {
        _spState++;
        _cntPause = _IntermissionConstants.ticRate;
      }
    }
  }

  void _updateShowNextLoc() {
    _updateAnimatedBack();

    if (--_cnt == 0 || _accelerateStage) {
      _initNoState();
    } else {
      _snlPointerOn = (_cnt & 31) < 20;
    }
  }

  void _updateNoState() {
    _updateAnimatedBack();

    if (--_cnt == 0) {
      onWorldDone?.call();
    }
  }

  void drawer(Uint8List screen) {
    _slamBackground(screen);

    switch (_state) {
      case _IntermissionState.statCount:
        _drawStats(screen);
      case _IntermissionState.showNextLoc:
        _drawShowNextLoc(screen);
      case _IntermissionState.noState:
        _drawNoState(screen);
    }
  }

  void _slamBackground(Uint8List screen) {
    final bg = _background;
    if (bg != null) {
      VVideo.drawPatchDirect(screen, 0, 0, bg);
    }
  }

  void _drawStats(Uint8List screen) {
    _drawAnimatedBack(screen);
    _drawLevelFinished(screen);

    final lh = (_nums[0]?.height ?? 12) * 3 ~/ 2;

    final killsPatch = _killsPatch;
    if (killsPatch != null) {
      VVideo.drawPatchDirect(
        screen,
        _IntermissionConstants.spStatsX,
        _IntermissionConstants.spStatsY,
        killsPatch,
      );
    }
    _drawPercent(
      screen,
      ScreenConstants.width - _IntermissionConstants.spStatsX,
      _IntermissionConstants.spStatsY,
      _cntKills,
    );

    final itemsPatch = _itemsPatch;
    if (itemsPatch != null) {
      VVideo.drawPatchDirect(
        screen,
        _IntermissionConstants.spStatsX,
        _IntermissionConstants.spStatsY + lh,
        itemsPatch,
      );
    }
    _drawPercent(
      screen,
      ScreenConstants.width - _IntermissionConstants.spStatsX,
      _IntermissionConstants.spStatsY + lh,
      _cntItems,
    );

    final secretPatch = _secretPatch;
    if (secretPatch != null) {
      VVideo.drawPatchDirect(
        screen,
        _IntermissionConstants.spStatsX,
        _IntermissionConstants.spStatsY + lh * 2,
        secretPatch,
      );
    }
    _drawPercent(
      screen,
      ScreenConstants.width - _IntermissionConstants.spStatsX,
      _IntermissionConstants.spStatsY + lh * 2,
      _cntSecrets,
    );

    final timePatch = _timePatch;
    if (timePatch != null) {
      VVideo.drawPatchDirect(
        screen,
        _IntermissionConstants.spTimeX,
        _IntermissionConstants.spTimeY,
        timePatch,
      );
    }
    _drawTime(
      screen,
      ScreenConstants.width ~/ 2 - _IntermissionConstants.spTimeX,
      _IntermissionConstants.spTimeY,
      _cntTime,
    );
  }

  void _drawLevelFinished(Uint8List screen) {
    final lname = _lastMap > 0 && _lastMap <= _lnames.length ? _lnames[_lastMap - 1] : null;
    if (lname != null) {
      final x = (ScreenConstants.width - lname.width) ~/ 2;
      VVideo.drawPatchDirect(screen, x, _IntermissionConstants.titleY, lname);
    }

    final fin = _finished;
    if (fin != null) {
      final y = _IntermissionConstants.titleY + (lname?.height ?? 0) + 5;
      final x = (ScreenConstants.width - fin.width) ~/ 2;
      VVideo.drawPatchDirect(screen, x, y, fin);
    }
  }

  void _drawEnteringLevel(Uint8List screen) {
    final ent = _entering;
    if (ent != null) {
      final x = (ScreenConstants.width - ent.width) ~/ 2;
      VVideo.drawPatchDirect(screen, x, _IntermissionConstants.titleY, ent);
    }

    final lname = _nextMap > 0 && _nextMap <= _lnames.length ? _lnames[_nextMap - 1] : null;
    if (lname != null) {
      final y = _IntermissionConstants.titleY + (ent?.height ?? 0) + 5;
      final x = (ScreenConstants.width - lname.width) ~/ 2;
      VVideo.drawPatchDirect(screen, x, y, lname);
    }
  }

  void _drawShowNextLoc(Uint8List screen) {
    _drawAnimatedBack(screen);

    if (_episode <= 3) {
      _drawSplats(screen);
      if (_snlPointerOn) {
        _drawYouAreHere(screen);
      }
    }
    _drawEnteringLevel(screen);
  }

  void _drawNoState(Uint8List screen) {
    _snlPointerOn = true;
    _drawShowNextLoc(screen);
  }

  void _drawSplats(Uint8List screen) {
    final splat = _splat;
    if (splat == null) return;

    final last = _lastMap == 9 ? _nextMap - 1 : _lastMap;
    for (var i = 0; i < last; i++) {
      final loc = _getLevelLocation(_episode - 1, i);
      if (loc != null) {
        VVideo.drawPatchDirect(screen, loc.$1, loc.$2, splat);
      }
    }
  }

  void _drawYouAreHere(Uint8List screen) {
    final loc = _getLevelLocation(_episode - 1, _nextMap - 1);
    if (loc == null) return;

    for (var i = 0; i < 2; i++) {
      final patch = _yah[i];
      if (patch == null) continue;

      final left = loc.$1 - patch.leftOffset;
      final top = loc.$2 - patch.topOffset;
      final right = left + patch.width;
      final bottom = top + patch.height;

      if (left >= 0 &&
          right < ScreenConstants.width &&
          top >= 0 &&
          bottom < ScreenConstants.height) {
        VVideo.drawPatchDirect(screen, loc.$1, loc.$2, patch);
        return;
      }
    }
  }

  (int, int)? _getLevelLocation(int episode, int map) {
    const lnodes = [
      [(185, 164), (148, 143), (69, 122), (209, 102), (116, 89), (166, 55), (71, 56), (135, 29), (71, 24)],
      [(254, 25), (97, 50), (188, 64), (128, 78), (214, 92), (133, 130), (208, 136), (148, 140), (235, 158)],
      [(156, 168), (48, 154), (174, 95), (265, 75), (130, 48), (279, 23), (198, 48), (140, 25), (281, 136)],
    ];

    if (episode < 0 || episode >= lnodes.length) return null;
    if (map < 0 || map >= lnodes[episode].length) return null;
    return lnodes[episode][map];
  }

  int _drawNum(Uint8List screen, int x, int y, int n, int digits) {
    var value = n;
    var cx = x;
    final numWidth = _nums[0]?.width ?? 12;

    if (digits < 0) {
      if (value == 0) {
        final zero = _nums[0];
        if (zero != null) {
          VVideo.drawPatchDirect(screen, cx - numWidth, y, zero);
        }
        return cx - numWidth;
      }

      while (value > 0) {
        final digit = value % 10;
        value ~/= 10;
        final patch = _nums[digit];
        if (patch != null) {
          cx -= numWidth;
          VVideo.drawPatchDirect(screen, cx, y, patch);
        }
      }
    } else {
      var remaining = digits;
      while (remaining > 0) {
        final digit = value % 10;
        value ~/= 10;
        final patch = _nums[digit];
        if (patch != null) {
          cx -= numWidth;
          VVideo.drawPatchDirect(screen, cx, y, patch);
        }
        remaining--;
      }
    }

    return cx;
  }

  void _drawPercent(Uint8List screen, int x, int y, int value) {
    if (value < 0) return;

    final pct = _percent;
    if (pct != null) {
      VVideo.drawPatchDirect(screen, x - pct.width, y, pct);
    }
    _drawNum(screen, x - (pct?.width ?? 0), y, value, -1);
  }

  void _drawTime(Uint8List screen, int x, int y, int t) {
    if (t < 0) return;

    final colon = _colon;
    final colonWidth = colon?.width ?? 4;

    if (t <= 61 * 59) {
      var div = 1;
      var cx = x;
      do {
        final n = (t ~/ div) % 60;
        cx = _drawNum(screen, cx, y, n, 2) - colonWidth;
        div *= 60;
        if (div == 60 || t ~/ div > 0) {
          if (colon != null) {
            VVideo.drawPatchDirect(screen, cx, y, colon);
          }
        }
      } while (t ~/ div > 0);
    } else {
      final sucks = _sucks;
      if (sucks != null) {
        VVideo.drawPatchDirect(screen, x - sucks.width, y, sucks);
      }
    }
  }
}
