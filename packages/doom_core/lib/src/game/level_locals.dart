import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/blockmap.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_switch.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class MaxPlayers {
  static const int count = 4;
}

class LevelLocals {
  LevelLocals(this.renderState);

  final RenderState renderState;
  final DoomRandom random = DoomRandom();
  final ThinkerList thinkers = ThinkerList();
  final List<Player> players = [];
  Blockmap? blockmap;
  SwitchManager? switchManager;
  List<Mobj?>? blockLinks;
  Uint8List? rejectMatrix;
  int numSectors = 0;

  Skill skill = Skill.hurtMePlenty;

  int levelTime = 0;
  int totalKills = 0;
  int totalItems = 0;
  int totalSecrets = 0;
  int killedMonsters = 0;

  bool exitLevel = false;
  bool secretExit = false;

  int teleportFlashX = 0;
  int teleportFlashY = 0;
  int teleportFlashZ = 0;
  int teleportDestX = 0;
  int teleportDestY = 0;
  int teleportDestZ = 0;
  int teleportTic = -1;

  // Blood spray effect from crushing (set by changeSector)
  int bloodSprayX = 0;
  int bloodSprayY = 0;
  int bloodSprayZ = 0;
  int bloodSprayTic = -1;

  bool floatOk = false;
  int tmFloorZ = 0;

  List<Line> scrollingLines = [];

  void init() {
    thinkers.init();
    for (var i = 0; i < MaxPlayers.count; i++) {
      players.add(Player()..playerNum = i);
    }
    _initSwitchManager();
  }

  void _initSwitchManager() {
    final textureManager = renderState.textureManager;
    if (textureManager != null) {
      switchManager = SwitchManager(textureManager)..init();
    }
  }

  void initBlockLinks() {
    final bm = blockmap;
    if (bm == null) return;

    final count = bm.columns * bm.rows;
    blockLinks = List<Mobj?>.filled(count, null);
  }

  void clearBlockLinks() {
    final links = blockLinks;
    if (links == null) return;

    for (var i = 0; i < links.length; i++) {
      links[i] = null;
    }
  }
}
