import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/p_user.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/game/thinker.dart';

class GameTicker {
  void tick(LevelLocals level) {
    for (final player in level.players) {
      if (player.mobj != null) {
        playerThink(player, level);
        _runPlayerMobj(player, level);
        spec.playerInSpecialSector(player.mobj!, level);
      }
    }

    _runAllMobjs(level);

    level.thinkers.runAll();
    spec.updateAnimations(level);
    level.levelTime++;
  }

  void _runPlayerMobj(Player player, LevelLocals level) {
    final mobj = player.mobj;
    if (mobj == null) return;

    mobjThinker(mobj, level);
  }

  void _runAllMobjs(LevelLocals level) {
    for (final sector in level.renderState.sectors) {
      var mobj = sector.thingList;
      while (mobj != null) {
        final next = mobj.sNext;

        if (mobj.player == null) {
          mobjThinker(mobj, level);
        }

        mobj = next;
      }
    }
  }
}

class MobjThinker extends Thinker {
  MobjThinker(this.level);

  final LevelLocals level;
}
