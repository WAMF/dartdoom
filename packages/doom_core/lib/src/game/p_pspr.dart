import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _WeaponConstants {
  static const int lowerSpeed = 6 * Fixed32.fracUnit;
  static const int raiseSpeed = 6 * Fixed32.fracUnit;
  static const int weaponBottom = 128 * Fixed32.fracUnit;
  static const int weaponTop = 32 * Fixed32.fracUnit;
  static const int numPsprites = 2;
  static const int psWeapon = 0;
  static const int psFlash = 1;
}

enum PsprState {
  none,
  ready,
  lower,
  raise,
  attack,
  flash,
}

class PspriteDef {
  int state = 0;
  int tics = 0;
  int sx = 0;
  int sy = 0;
  PsprState psprState = PsprState.none;
}

class WeaponInfo {
  const WeaponInfo({
    required this.ammo,
    required this.upState,
    required this.downState,
    required this.readyState,
    required this.attackState,
    required this.flashState,
  });

  final AmmoType ammo;
  final int upState;
  final int downState;
  final int readyState;
  final int attackState;
  final int flashState;
}

const List<WeaponInfo> weaponInfo = [
  WeaponInfo(ammo: AmmoType.noAmmo, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.clip, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.shell, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.clip, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.missile, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.cell, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.cell, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.noAmmo, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
  WeaponInfo(ammo: AmmoType.shell, upState: 0, downState: 0, readyState: 0, attackState: 0, flashState: 0),
];

void setupPsprites(Player player) {
  player.psprites.clear();
  for (var i = 0; i < _WeaponConstants.numPsprites; i++) {
    player.psprites.add(PspriteDef());
  }

  player.pendingWeapon = WeaponType.noChange;
  bringUpWeapon(player);
}

void bringUpWeapon(Player player) {
  if (player.pendingWeapon == WeaponType.noChange) {
    player.pendingWeapon = player.readyWeapon;
  }

  if (player.pendingWeapon == WeaponType.chainsaw) {
    // TODO: play sound
  }

  final newWeapon = player.pendingWeapon;
  player.pendingWeapon = WeaponType.noChange;
  player.readyWeapon = newWeapon;

  final psp = player.psprites[_WeaponConstants.psWeapon];
  psp.sy = _WeaponConstants.weaponBottom;
  psp.psprState = PsprState.raise;
}

void lowerWeapon(Player player) {
  final psp = player.psprites[_WeaponConstants.psWeapon];
  psp.psprState = PsprState.lower;
}

void movePsprites(Player player, LevelLocals level) {
  for (var i = 0; i < _WeaponConstants.numPsprites; i++) {
    final psp = player.psprites[i];

    switch (psp.psprState) {
      case PsprState.none:
        break;
      case PsprState.ready:
        _weaponReady(player, psp, level);
      case PsprState.lower:
        _lowerWeapon(player, psp);
      case PsprState.raise:
        _raiseWeapon(player, psp);
      case PsprState.attack:
        _weaponAttack(player, psp, level);
      case PsprState.flash:
        break;
    }
  }
}

void _weaponReady(Player player, PspriteDef psp, LevelLocals level) {
  if (player.pendingWeapon != WeaponType.noChange || player.health == 0) {
    lowerWeapon(player);
    return;
  }

  final cmd = player.cmd;
  final isAttacking = (cmd.buttons & TicCmdButtons.attack) != 0;
  if (isAttacking) {
    final isAutoRepeatWeapon =
        player.readyWeapon == WeaponType.fist ||
        player.readyWeapon == WeaponType.chainsaw;
    if (!player.attackDown || isAutoRepeatWeapon) {
      player.attackDown = true;
      psp.psprState = PsprState.attack;
      return;
    }
  } else {
    player.attackDown = false;
  }

  final fineAngle = (level.levelTime << 6) & Angle.fineMask;
  psp.sx = Fixed32.fracUnit + Fixed32.mul(Fixed32.fracUnit, fineCosine(fineAngle));
  psp.sy = _WeaponConstants.weaponTop + Fixed32.mul(Fixed32.fracUnit, fineSine((fineAngle * 2) & Angle.fineMask));
}

void _lowerWeapon(Player player, PspriteDef psp) {
  psp.sy += _WeaponConstants.lowerSpeed;

  if (psp.sy >= _WeaponConstants.weaponBottom) {
    if (player.playerState == PlayerState.dead) {
      psp.sy = _WeaponConstants.weaponBottom;
      psp.psprState = PsprState.none;
      return;
    }

    if (player.health == 0) {
      psp.psprState = PsprState.none;
      return;
    }

    bringUpWeapon(player);
  }
}

void _raiseWeapon(Player player, PspriteDef psp) {
  psp.sy -= _WeaponConstants.raiseSpeed;

  if (psp.sy <= _WeaponConstants.weaponTop) {
    psp.sy = _WeaponConstants.weaponTop;
    psp.psprState = PsprState.ready;
  }
}

void _weaponAttack(Player player, PspriteDef psp, LevelLocals level) {
  final weapon = player.readyWeapon;
  final info = weaponInfo[weapon.index];

  if (info.ammo != AmmoType.noAmmo) {
    if (player.ammo[info.ammo.index] <= 0) {
      psp.psprState = PsprState.ready;
      return;
    }
    player.ammo[info.ammo.index]--;
  }

  player.refire++;

  switch (weapon) {
    case WeaponType.fist:
    case WeaponType.chainsaw:
      _punchAttack(player, level);
    case WeaponType.pistol:
    case WeaponType.chaingun:
      _gunAttack(player, level, 1);
    case WeaponType.shotgun:
      _gunAttack(player, level, 7);
    case WeaponType.superShotgun:
      _gunAttack(player, level, 20);
    case WeaponType.missile:
    case WeaponType.plasma:
    case WeaponType.bfg:
      break;
    case WeaponType.numWeapons:
    case WeaponType.noChange:
      break;
  }

  psp.psprState = PsprState.ready;
}

void _punchAttack(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final damage = ((level.levelTime % 10) + 1) * 2;

  final angle = mobj.angle;
  final slope = _aimLineAttack(mobj, angle, GameConstants.meleeRange, level);

  _lineAttack(mobj, angle, GameConstants.meleeRange, slope, damage, level);

  if (_lineTarget != null) {
    mobj.angle = _pointToAngle(mobj.x, mobj.y, _lineTarget!.x, _lineTarget!.y);
  }
}

void _gunAttack(Player player, LevelLocals level, int pellets) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final damage = 5 * ((level.levelTime % 3) + 1);

  final baseAngle = mobj.angle;
  final slope = _aimLineAttack(mobj, baseAngle, GameConstants.missileRange, level);

  for (var i = 0; i < pellets; i++) {
    final spread = ((level.levelTime + i) % 17 - 8) << 20;
    final angle = baseAngle + spread;

    _lineAttack(mobj, angle, GameConstants.missileRange, slope, damage, level);
  }
}

Mobj? _lineTarget;
int _aimSlope = 0;

int _aimLineAttack(Mobj source, int angle, int distance, LevelLocals level) {
  _lineTarget = null;
  _aimSlope = 0;

  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  final dx = fineCosine(fineAngle);
  final dy = fineSine(fineAngle);

  Mobj? bestTarget;
  var bestDist = distance;

  for (final sector in level.renderState.sectors) {
    var mobj = sector.thingList;
    while (mobj != null) {
      if ((mobj.flags & MobjFlag.shootable) == 0) {
        mobj = mobj.sNext;
        continue;
      }

      if (mobj == source) {
        mobj = mobj.sNext;
        continue;
      }

      final tx = mobj.x - source.x;
      final ty = mobj.y - source.y;

      final dist = _approxDist(tx, ty);
      if (dist >= bestDist) {
        mobj = mobj.sNext;
        continue;
      }

      final cross = Fixed32.mul(tx, dy) - Fixed32.mul(ty, dx);
      final crossAbs = cross < 0 ? -cross : cross;
      if (crossAbs > mobj.radius + (dist >> 4)) {
        mobj = mobj.sNext;
        continue;
      }

      final dot = Fixed32.mul(tx, dx) + Fixed32.mul(ty, dy);
      if (dot < 0) {
        mobj = mobj.sNext;
        continue;
      }

      bestTarget = mobj;
      bestDist = dist;

      mobj = mobj.sNext;
    }
  }

  if (bestTarget != null) {
    _lineTarget = bestTarget;
    final dz = (bestTarget.z + (bestTarget.height >> 1)) - (source.z + (source.height >> 1));
    if (bestDist > 0) {
      _aimSlope = Fixed32.div(dz, bestDist);
    }
  }

  return _aimSlope;
}

void _lineAttack(Mobj source, int angle, int distance, int slope, int damage, LevelLocals level) {
  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  final dx = fineCosine(fineAngle);
  final dy = fineSine(fineAngle);

  Mobj? hitTarget;
  var bestDist = distance;

  for (final sector in level.renderState.sectors) {
    var mobj = sector.thingList;
    while (mobj != null) {
      if ((mobj.flags & MobjFlag.shootable) == 0) {
        mobj = mobj.sNext;
        continue;
      }

      if (mobj == source) {
        mobj = mobj.sNext;
        continue;
      }

      final tx = mobj.x - source.x;
      final ty = mobj.y - source.y;

      final dist = _approxDist(tx, ty);
      if (dist >= bestDist) {
        mobj = mobj.sNext;
        continue;
      }

      final cross = Fixed32.mul(tx, dy) - Fixed32.mul(ty, dx);
      final crossAbs = cross < 0 ? -cross : cross;
      if (crossAbs > mobj.radius + (dist >> 4)) {
        mobj = mobj.sNext;
        continue;
      }

      final dot = Fixed32.mul(tx, dx) + Fixed32.mul(ty, dy);
      if (dot < 0) {
        mobj = mobj.sNext;
        continue;
      }

      hitTarget = mobj;
      bestDist = dist;

      mobj = mobj.sNext;
    }
  }

  if (hitTarget != null) {
    spec.damageMobj(hitTarget, source, source, damage, level);
  }
}

int _approxDist(int dx, int dy) {
  final adx = dx < 0 ? -dx : dx;
  final ady = dy < 0 ? -dy : dy;
  if (adx > ady) {
    return adx + (ady >> 1);
  }
  return ady + (adx >> 1);
}

int _pointToAngle(int x1, int y1, int x2, int y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  if (dx == 0 && dy == 0) {
    return 0;
  }

  if (dx >= 0) {
    if (dy >= 0) {
      if (dx > dy) {
        return _tanToAngleValue(Fixed32.div(dy, dx));
      } else {
        return Angle.ang90 - 1 - _tanToAngleValue(Fixed32.div(dx, dy));
      }
    } else {
      final ady = -dy;
      if (dx > ady) {
        return -_tanToAngleValue(Fixed32.div(ady, dx));
      } else {
        return Angle.ang270 + _tanToAngleValue(Fixed32.div(dx, ady));
      }
    }
  } else {
    final adx = -dx;
    if (dy >= 0) {
      if (adx > dy) {
        return Angle.ang180 - 1 - _tanToAngleValue(Fixed32.div(dy, adx));
      } else {
        return Angle.ang90 + _tanToAngleValue(Fixed32.div(adx, dy));
      }
    } else {
      final ady = -dy;
      if (adx > ady) {
        return Angle.ang180 + _tanToAngleValue(Fixed32.div(ady, adx));
      } else {
        return Angle.ang270 - 1 - _tanToAngleValue(Fixed32.div(adx, ady));
      }
    }
  }
}

int _tanToAngleValue(int tan) {
  final index = tan >> Angle.dBits;
  if (index >= 0 && index <= Angle.slopeRange) {
    return tanToAngle(index);
  }
  return 0;
}
