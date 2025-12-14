import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_map.dart';
import 'package:doom_core/src/game/p_pspr.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _BobConstants {
  static const int bobAngleScale = Angle.fineAngles ~/ 20;
}

void playerThink(Player player, LevelLocals level) {
  final cmd = player.cmd;
  final mobj = player.mobj;

  if (player.playerState == PlayerState.dead) {
    _deathThink(player);
    return;
  }

  if (mobj == null) return;

  if ((mobj.flags & MobjFlag.justHit) != 0) {
    mobj.flags &= ~MobjFlag.justHit;
  }

  if (cmd.angleTurn != 0) {
    mobj.angle = (mobj.angle + (cmd.angleTurn << 16)).u32.s32;
  }

  _movePlayer(player);
  _calcBob(player);

  _calcHeight(player, level.levelTime);

  if ((cmd.buttons & TicCmdButtons.use) != 0) {
    if (!player.useDown) {
      useLines(player, level);
      player.useDown = true;
    }
  } else {
    player.useDown = false;
  }

  movePsprites(player, level);
}

void _movePlayer(Player player) {
  final cmd = player.cmd;
  final mobj = player.mobj;
  if (mobj == null) return;

  final onGround = mobj.z <= mobj.floorZ;

  if (cmd.forwardMove != 0 && onGround) {
    thrust(mobj, mobj.angle, cmd.forwardMove * 2048);
  }

  if (cmd.sideMove != 0 && onGround) {
    final sideAngle = (mobj.angle - Angle.ang90).u32.s32;
    thrust(mobj, sideAngle, cmd.sideMove * 2048);
  }
}

void thrust(Mobj mobj, int angle, int move) {
  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  mobj.momX += Fixed32.mul(move, fineCosine(fineAngle));
  mobj.momY += Fixed32.mul(move, fineSine(fineAngle));
}

void _calcBob(Player player) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final momX = mobj.momX;
  final momY = mobj.momY;

  player.bob = Fixed32.mul(momX, momX) + Fixed32.mul(momY, momY);
  player.bob >>= 2;

  if (player.bob > PlayerConstants.maxBob) {
    player.bob = PlayerConstants.maxBob;
  }
}

void _calcHeight(Player player, int levelTime) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final onGround = mobj.z <= mobj.floorZ;

  if (!onGround) {
    player.viewZ = mobj.z + PlayerConstants.viewHeight;
    if (player.viewZ > mobj.ceilingZ - 4 * Fixed32.fracUnit) {
      player.viewZ = mobj.ceilingZ - 4 * Fixed32.fracUnit;
    }
    return;
  }

  final bobAngle = (_BobConstants.bobAngleScale * levelTime) & Angle.fineMask;
  final bob = Fixed32.mul(player.bob >> 1, fineSine(bobAngle));

  if (player.playerState == PlayerState.live) {
    player.viewHeight += player.deltaViewHeight;

    if (player.viewHeight > PlayerConstants.viewHeight) {
      player.viewHeight = PlayerConstants.viewHeight;
      player.deltaViewHeight = 0;
    }

    if (player.viewHeight < PlayerConstants.viewHeight ~/ 2) {
      player.viewHeight = PlayerConstants.viewHeight ~/ 2;
      if (player.deltaViewHeight <= 0) {
        player.deltaViewHeight = 1;
      }
    }

    if (player.deltaViewHeight != 0) {
      player.deltaViewHeight += Fixed32.fracUnit ~/ 4;
      if (player.deltaViewHeight == 0) {
        player.deltaViewHeight = 1;
      }
    }
  }

  player.viewZ = mobj.z + player.viewHeight + bob;

  if (player.viewZ > mobj.ceilingZ - 4 * Fixed32.fracUnit) {
    player.viewZ = mobj.ceilingZ - 4 * Fixed32.fracUnit;
  }
}

void _deathThink(Player player) {
  final mobj = player.mobj;
  if (mobj == null) return;

  if (player.viewHeight > 6 * Fixed32.fracUnit) {
    player.viewHeight -= Fixed32.fracUnit;
  }

  if (player.viewHeight < 6 * Fixed32.fracUnit) {
    player.viewHeight = 6 * Fixed32.fracUnit;
  }

  player.deltaViewHeight = 0;

  player.viewZ = mobj.z + player.viewHeight;
}

void useLines(Player player, LevelLocals level) {
  if (player.mobj == null) return;
  useLinesFrom(player.mobj!, level);
}
