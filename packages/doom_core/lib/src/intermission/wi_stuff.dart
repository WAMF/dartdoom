import 'dart:typed_data';

import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/v_video.dart';
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

enum _IntermissionState { statCount, showNextLoc, noState }

class Intermission {
  Intermission(this._wadManager);

  final WadManager _wadManager;

  _IntermissionState _state = _IntermissionState.statCount;
  int _cnt = 0;
  int _bcnt = 0;
  bool _accelerateStage = false;

  int _episode = 0;
  int _lastMap = 0;
  int _nextMap = 0;

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
  }) {
    _episode = episode;
    _lastMap = lastMap;
    _nextMap = nextMap;
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

    _dataLoaded = true;
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
    if (--_cnt == 0 || _accelerateStage) {
      _initNoState();
    } else {
      _snlPointerOn = (_cnt & 31) < 20;
    }
  }

  void _updateNoState() {
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
    final yah = _yah[(_bcnt ~/ 8) & 1];
    if (yah == null) return;

    final loc = _getLevelLocation(_episode - 1, _nextMap - 1);
    if (loc != null) {
      VVideo.drawPatchDirect(screen, loc.$1, loc.$2, yah);
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
