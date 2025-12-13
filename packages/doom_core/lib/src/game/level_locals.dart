import 'package:doom_core/src/game/blockmap.dart';
import 'package:doom_core/src/game/p_switch.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_state.dart';

abstract final class MaxPlayers {
  static const int count = 4;
}

class LevelLocals {
  LevelLocals(this.renderState);

  final RenderState renderState;
  final ThinkerList thinkers = ThinkerList();
  final List<Player> players = [];
  Blockmap? blockmap;
  SwitchManager? switchManager;

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
}
