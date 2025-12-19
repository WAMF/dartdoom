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

// Original C: global variable set by P_MovePlayer and used by P_CalcHeight
bool _onGround = false;

abstract final class _DeathConstants {
  static const int ang5 = Angle.ang90 ~/ 18;
}

const List<WeaponType> _weaponKeyMap = [
  WeaponType.fist,
  WeaponType.pistol,
  WeaponType.shotgun,
  WeaponType.chaingun,
  WeaponType.missile,
  WeaponType.plasma,
  WeaponType.bfg,
];

WeaponType _processWeaponChange(Player player, TicCmd cmd) {
  final weaponIndex = TicCmdButtons.weaponFromButtons(cmd.buttons);
  if (weaponIndex < 0 || weaponIndex >= _weaponKeyMap.length) {
    return WeaponType.noChange;
  }

  var newWeapon = _weaponKeyMap[weaponIndex];

  if (newWeapon == WeaponType.fist &&
      player.weaponOwned[WeaponType.chainsaw.index] &&
      !(player.readyWeapon == WeaponType.chainsaw &&
          player.powers[PowerType.strength.index] > 0)) {
    newWeapon = WeaponType.chainsaw;
  }

  return newWeapon;
}

// Original C (p_user.c):
// ```c
// void P_PlayerThink (player_t* player)
// {
//     ticcmd_t* cmd;
//     weapontype_t newweapon;
//
//     // fixme: do this in the cheat code
//     if (player->cheats & CF_NOCLIP)
//         player->mo->flags |= MF_NOCLIP;
//     else
//         player->mo->flags &= ~MF_NOCLIP;
//
//     // chain saw run forward
//     cmd = &player->cmd;
//     if (player->mo->flags & MF_JUSTATTACKED)
//     {
//         cmd->angleturn = 0;
//         cmd->forwardmove = 0xc800/512;
//         cmd->sidemove = 0;
//         player->mo->flags &= ~MF_JUSTATTACKED;
//     }
//
//     if (player->playerstate == PST_DEAD)
//     {
//         P_DeathThink (player);
//         return;
//     }
//
//     // Move around.
//     if (player->mo->reactiontime)
//         player->mo->reactiontime--;
//     else
//         P_MovePlayer (player);
//
//     P_CalcHeight (player);
//
//     // ... weapon change, use, psprites, counters ...
// }
// ```
void playerThink(Player player, LevelLocals level) {
  final cmd = player.cmd;
  final mobj = player.mobj;

  if (mobj == null) return;

  // Original C: chain saw run forward - BEFORE death check
  if ((mobj.flags & MobjFlag.justAttacked) != 0) {
    cmd.angleTurn = 0;
    cmd.forwardMove = 100; // 0xc800 / 512
    cmd.sideMove = 0;
    mobj.flags &= ~MobjFlag.justAttacked;
  }

  // Original C: death check comes AFTER chainsaw handling
  if (player.playerState == PlayerState.dead) {
    _deathThink(player, level);
    return;
  }

  // Original C: if (player->mo->reactiontime) player->mo->reactiontime--; else P_MovePlayer(player);
  if (mobj.reactionTime > 0) {
    mobj.reactionTime--;
  } else {
    _movePlayer(player);
  }

  _calcHeight(player, level.levelTime);

  if ((cmd.buttons & TicCmdButtons.change) != 0) {
    final newWeapon = _processWeaponChange(player, cmd);
    if (newWeapon != WeaponType.noChange &&
        newWeapon != player.readyWeapon &&
        player.weaponOwned[newWeapon.index]) {
      player.pendingWeapon = newWeapon;
    }
  }

  if ((cmd.buttons & TicCmdButtons.use) != 0) {
    if (!player.useDown) {
      useLines(player, level);
      player.useDown = true;
    }
  } else {
    player.useDown = false;
  }

  movePsprites(player, level);

  // Original C: Strength counts UP to diminish fade
  if (player.powers[PowerType.strength.index] > 0) {
    player.powers[PowerType.strength.index]++;
  }

  if (player.powers[PowerType.invulnerability.index] > 0) {
    player.powers[PowerType.invulnerability.index]--;
  }

  if (player.powers[PowerType.invisibility.index] > 0) {
    player.powers[PowerType.invisibility.index]--;
    if (player.powers[PowerType.invisibility.index] == 0) {
      mobj.flags &= ~MobjFlag.shadow;
    }
  }

  if (player.powers[PowerType.infrared.index] > 0) {
    player.powers[PowerType.infrared.index]--;
  }

  if (player.powers[PowerType.ironFeet.index] > 0) {
    player.powers[PowerType.ironFeet.index]--;
  }

  if (player.damageCount > 0) {
    player.damageCount--;
  }

  if (player.bonusCount > 0) {
    player.bonusCount--;
  }
}

// Original C (p_user.c):
// ```c
// void P_MovePlayer (player_t* player)
// {
//     ticcmd_t* cmd;
//     cmd = &player->cmd;
//
//     player->mo->angle += (cmd->angleturn<<16);
//
//     // Do not let the player control movement if not onground.
//     onground = (player->mo->z <= player->mo->floorz);
//
//     if (cmd->forwardmove && onground)
//         P_Thrust (player, player->mo->angle, cmd->forwardmove*2048);
//
//     if (cmd->sidemove && onground)
//         P_Thrust (player, player->mo->angle-ANG90, cmd->sidemove*2048);
//
//     if ( (cmd->forwardmove || cmd->sidemove)
//          && player->mo->state == &states[S_PLAY] )
//     {
//         P_SetMobjState (player->mo, S_PLAY_RUN1);
//     }
// }
// ```
void _movePlayer(Player player) {
  final cmd = player.cmd;
  final mobj = player.mobj;
  if (mobj == null) return;

  // Original C: angle change happens inside P_MovePlayer
  mobj.angle = (mobj.angle + (cmd.angleTurn << 16)).u32.s32;

  // Original C: onground is set HERE and used by P_CalcHeight
  _onGround = mobj.z <= mobj.floorZ;

  if (cmd.forwardMove != 0 && _onGround) {
    thrust(mobj, mobj.angle, cmd.forwardMove * 2048);
  }

  if (cmd.sideMove != 0 && _onGround) {
    final sideAngle = (mobj.angle - Angle.ang90).u32.s32;
    thrust(mobj, sideAngle, cmd.sideMove * 2048);
  }
}

void thrust(Mobj mobj, int angle, int move) {
  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  mobj.momX += Fixed32.mul(move, fineCosine(fineAngle));
  mobj.momY += Fixed32.mul(move, fineSine(fineAngle));
}

// Original C (p_user.c):
// ```c
// void P_CalcHeight (player_t* player)
// {
//     int angle;
//     fixed_t bob;
//
//     // Regular movement bobbing
//     player->bob = FixedMul(player->mo->momx, player->mo->momx)
//                 + FixedMul(player->mo->momy, player->mo->momy);
//     player->bob >>= 2;
//     if (player->bob > MAXBOB)
//         player->bob = MAXBOB;
//
//     if ((player->cheats & CF_NOMOMENTUM) || !onground)
//     {
//         player->viewz = player->mo->z + VIEWHEIGHT;
//         if (player->viewz > player->mo->ceilingz-4*FRACUNIT)
//             player->viewz = player->mo->ceilingz-4*FRACUNIT;
//         player->viewz = player->mo->z + player->viewheight;
//         return;
//     }
//
//     angle = (FINEANGLES/20*leveltime)&FINEMASK;
//     bob = FixedMul(player->bob/2, finesine[angle]);
//
//     // move viewheight
//     if (player->playerstate == PST_LIVE) { ... }
//
//     player->viewz = player->mo->z + player->viewheight + bob;
//     if (player->viewz > player->mo->ceilingz-4*FRACUNIT)
//         player->viewz = player->mo->ceilingz-4*FRACUNIT;
// }
// ```
void _calcHeight(Player player, int levelTime) {
  final mobj = player.mobj;
  if (mobj == null) return;

  // Original C: bob calculation is done HERE, not in separate function
  final momX = mobj.momX;
  final momY = mobj.momY;
  player.bob = Fixed32.mul(momX, momX) + Fixed32.mul(momY, momY);
  player.bob >>= 2;
  if (player.bob > PlayerConstants.maxBob) {
    player.bob = PlayerConstants.maxBob;
  }

  // Original C: uses global onground set by P_MovePlayer
  if (!_onGround) {
    player.viewZ = mobj.z + PlayerConstants.viewHeight;
    if (player.viewZ > mobj.ceilingZ - 4 * Fixed32.fracUnit) {
      player.viewZ = mobj.ceilingZ - 4 * Fixed32.fracUnit;
    }
    // Original C: final viewz uses viewheight, not VIEWHEIGHT constant
    player.viewZ = mobj.z + player.viewHeight;
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

// Original C (p_user.c):
// ```c
// void P_DeathThink (player_t* player)
// {
//     P_MovePsprites (player);
//     // fall to the ground
//     if (player->viewheight > 6*FRACUNIT)
//         player->viewheight -= FRACUNIT;
//     if (player->viewheight < 6*FRACUNIT)
//         player->viewheight = 6*FRACUNIT;
//     player->deltaviewheight = 0;
//     onground = (player->mo->z <= player->mo->floorz);
//     P_CalcHeight (player);
//     ...
// }
// ```
void _deathThink(Player player, LevelLocals level) {
  movePsprites(player, level);

  final mobj = player.mobj;
  if (mobj == null) return;

  if (player.viewHeight > 6 * Fixed32.fracUnit) {
    player.viewHeight -= Fixed32.fracUnit;
  }

  if (player.viewHeight < 6 * Fixed32.fracUnit) {
    player.viewHeight = 6 * Fixed32.fracUnit;
  }

  player.deltaViewHeight = 0;

  // Original C: onground is set BEFORE P_CalcHeight
  _onGround = mobj.z <= mobj.floorZ;
  _calcHeight(player, level.levelTime);

  final attacker = player.attacker;
  if (attacker != null && attacker != mobj) {
    final angle = pointToAngle(attacker.x - mobj.x, attacker.y - mobj.y);
    final delta = (angle - mobj.angle).u32;

    if (delta < _DeathConstants.ang5 ||
        delta > ((-_DeathConstants.ang5).u32)) {
      mobj.angle = angle;
      if (player.damageCount > 0) {
        player.damageCount--;
      }
    } else if (delta < Angle.ang180.u32) {
      mobj.angle = (mobj.angle + _DeathConstants.ang5).u32.s32;
    } else {
      mobj.angle = (mobj.angle - _DeathConstants.ang5).u32.s32;
    }
  } else if (player.damageCount > 0) {
    player.damageCount--;
  }

  if ((player.cmd.buttons & TicCmdButtons.use) != 0) {
    player.playerState = PlayerState.reborn;
  }
}

void useLines(Player player, LevelLocals level) {
  if (player.mobj == null) return;
  useLinesFrom(player.mobj!, level);
}
