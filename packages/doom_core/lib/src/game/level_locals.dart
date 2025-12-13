import 'package:doom_core/src/game/blockmap.dart';
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

  int levelTime = 0;
  int totalKills = 0;
  int totalItems = 0;
  int totalSecrets = 0;

  void init() {
    thinkers.init();
    for (var i = 0; i < MaxPlayers.count; i++) {
      players.add(Player()..playerNum = i);
    }
  }
}
