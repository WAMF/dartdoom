import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/game/p_user.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/game/thinker.dart';

class GameTicker {
  void tick(LevelLocals level) {
    for (final player in level.players) {
      if (player.mobj != null) {
        playerThink(player, level);
        _runPlayerMobj(player, level);
      }
    }

    level.thinkers.runAll();
    level.levelTime++;
  }

  void _runPlayerMobj(Player player, LevelLocals level) {
    final mobj = player.mobj;
    if (mobj == null) return;

    mobjThinker(mobj, level);
  }
}

class MobjThinker extends Thinker {
  MobjThinker(this.level);

  final LevelLocals level;
}
