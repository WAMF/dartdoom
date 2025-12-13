import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_mobj.dart' show MobjType, spawnPlayerMissile;
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
  static const int bfgCells = 40;
  static const int bulletRange = 16 * 64 * Fixed32.fracUnit;
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
    final isNonAutoRepeatWeapon =
        player.readyWeapon == WeaponType.missile ||
        player.readyWeapon == WeaponType.bfg;
    if (!player.attackDown || !isNonAutoRepeatWeapon) {
      player.attackDown = true;
      _fireWeapon(player, level);
      return;
    }
  } else {
    player.attackDown = false;
  }

  final fineAngle = (128 * level.levelTime) & Angle.fineMask;
  psp
    ..sx = Fixed32.fracUnit + Fixed32.mul(player.bob, fineCosine(fineAngle))
    ..sy = _WeaponConstants.weaponTop +
        Fixed32.mul(player.bob, fineSine(fineAngle & (Angle.fineAngles ~/ 2 - 1)));
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

bool _checkAmmo(Player player) {
  final ammoType = weaponInfo[player.readyWeapon.index].ammo;

  int count;
  if (player.readyWeapon == WeaponType.bfg) {
    count = _WeaponConstants.bfgCells;
  } else if (player.readyWeapon == WeaponType.superShotgun) {
    count = 2;
  } else {
    count = 1;
  }

  if (ammoType == AmmoType.noAmmo || player.ammo[ammoType.index] >= count) {
    return true;
  }

  _selectBestWeapon(player);
  lowerWeapon(player);
  return false;
}

void _selectBestWeapon(Player player) {
  if (player.weaponOwned[WeaponType.plasma.index] &&
      player.ammo[AmmoType.cell.index] > 0) {
    player.pendingWeapon = WeaponType.plasma;
  } else if (player.weaponOwned[WeaponType.superShotgun.index] &&
      player.ammo[AmmoType.shell.index] > 2) {
    player.pendingWeapon = WeaponType.superShotgun;
  } else if (player.weaponOwned[WeaponType.chaingun.index] &&
      player.ammo[AmmoType.clip.index] > 0) {
    player.pendingWeapon = WeaponType.chaingun;
  } else if (player.weaponOwned[WeaponType.shotgun.index] &&
      player.ammo[AmmoType.shell.index] > 0) {
    player.pendingWeapon = WeaponType.shotgun;
  } else if (player.ammo[AmmoType.clip.index] > 0) {
    player.pendingWeapon = WeaponType.pistol;
  } else if (player.weaponOwned[WeaponType.chainsaw.index]) {
    player.pendingWeapon = WeaponType.chainsaw;
  } else if (player.weaponOwned[WeaponType.missile.index] &&
      player.ammo[AmmoType.missile.index] > 0) {
    player.pendingWeapon = WeaponType.missile;
  } else if (player.weaponOwned[WeaponType.bfg.index] &&
      player.ammo[AmmoType.cell.index] > _WeaponConstants.bfgCells) {
    player.pendingWeapon = WeaponType.bfg;
  } else {
    player.pendingWeapon = WeaponType.fist;
  }
}

void _fireWeapon(Player player, LevelLocals level) {
  if (!_checkAmmo(player)) return;

  player.refire++;

  final psp = player.psprites[_WeaponConstants.psWeapon];
  psp.psprState = PsprState.attack;
}

void _weaponAttack(Player player, PspriteDef psp, LevelLocals level) {
  final weapon = player.readyWeapon;
  final info = weaponInfo[weapon.index];

  if (info.ammo != AmmoType.noAmmo) {
    if (player.ammo[info.ammo.index] <= 0) {
      psp.psprState = PsprState.ready;
      return;
    }
    final ammoUse = weapon == WeaponType.superShotgun ? 2 : 1;
    player.ammo[info.ammo.index] -= ammoUse;
  }

  switch (weapon) {
    case WeaponType.fist:
      _punchAttack(player, level);
    case WeaponType.chainsaw:
      _sawAttack(player, level);
    case WeaponType.pistol:
      _calcBulletSlope(player, level);
      _gunShot(player, level, player.refire == 0);
    case WeaponType.chaingun:
      _calcBulletSlope(player, level);
      _gunShot(player, level, player.refire == 0);
    case WeaponType.shotgun:
      _calcBulletSlope(player, level);
      for (var i = 0; i < 7; i++) {
        _gunShot(player, level, false);
      }
    case WeaponType.superShotgun:
      _calcBulletSlope(player, level);
      for (var i = 0; i < 20; i++) {
        _superShotgunShot(player, level);
      }
    case WeaponType.missile:
      _fireMissile(player, level);
    case WeaponType.plasma:
      _firePlasma(player, level);
    case WeaponType.bfg:
      _fireBfg(player, level);
    case WeaponType.numWeapons:
    case WeaponType.noChange:
      break;
  }

  psp.psprState = PsprState.ready;
}

void _punchAttack(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final rand = level.random;
  var damage = ((rand.pRandom() % 10) + 1) << 1;

  if (player.powers[PowerType.strength.index] > 0) {
    damage *= 10;
  }

  final spreadAngle = (rand.pRandom() - rand.pRandom()) << 18;
  final angle = mobj.angle + spreadAngle;
  final slope = aimLineAttack(mobj, angle, GameConstants.meleeRange, level);

  _lineAttack(mobj, angle, GameConstants.meleeRange, slope, damage, level);

  if (lineTarget != null) {
    mobj.angle = _pointToAngle(mobj.x, mobj.y, lineTarget!.x, lineTarget!.y);
  }
}

void _sawAttack(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final rand = level.random;
  final damage = 2 * ((rand.pRandom() % 10) + 1);
  final spreadAngle = (rand.pRandom() - rand.pRandom()) << 18;
  final angle = mobj.angle + spreadAngle;

  final slope = aimLineAttack(
    mobj,
    angle,
    GameConstants.meleeRange + Fixed32.fracUnit,
    level,
  );
  _lineAttack(
    mobj,
    angle,
    GameConstants.meleeRange + Fixed32.fracUnit,
    slope,
    damage,
    level,
  );

  if (lineTarget == null) return;

  final targetAngle = _pointToAngle(
    mobj.x,
    mobj.y,
    lineTarget!.x,
    lineTarget!.y,
  );
  final angleDiff = targetAngle - mobj.angle;
  const ang90div20 = Angle.ang90 ~/ 20;
  const ang90div21 = Angle.ang90 ~/ 21;

  if (angleDiff > Angle.ang180) {
    if (angleDiff < -ang90div20) {
      mobj.angle = targetAngle + ang90div21;
    } else {
      mobj.angle -= ang90div20;
    }
  } else {
    if (angleDiff > ang90div20) {
      mobj.angle = targetAngle - ang90div21;
    } else {
      mobj.angle += ang90div20;
    }
  }

  mobj.flags |= MobjFlag.justAttacked;
}

int _currentBulletSlope = 0;

void _calcBulletSlope(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  var angle = mobj.angle;
  _currentBulletSlope = aimLineAttack(mobj, angle, _WeaponConstants.bulletRange, level);

  if (lineTarget == null) {
    angle += 1 << 26;
    _currentBulletSlope = aimLineAttack(mobj, angle, _WeaponConstants.bulletRange, level);
    if (lineTarget == null) {
      angle -= 2 << 26;
      _currentBulletSlope = aimLineAttack(mobj, angle, _WeaponConstants.bulletRange, level);
    }
  }
}

void _gunShot(Player player, LevelLocals level, bool accurate) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final rand = level.random;
  final damage = 5 * ((rand.pRandom() % 3) + 1);
  var angle = mobj.angle;

  if (!accurate) {
    angle += (rand.pRandom() - rand.pRandom()) << 18;
  }

  _lineAttack(mobj, angle, GameConstants.missileRange, _currentBulletSlope, damage, level);
}

void _superShotgunShot(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  final rand = level.random;
  final damage = 5 * ((rand.pRandom() % 3) + 1);
  final angle = mobj.angle + ((rand.pRandom() - rand.pRandom()) << 19);
  final slope = _currentBulletSlope + ((rand.pRandom() - rand.pRandom()) << 5);

  _lineAttack(mobj, angle, GameConstants.missileRange, slope, damage, level);
}

void _fireMissile(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  spawnPlayerMissile(mobj, MobjType.rocket, level.renderState, level);
}

void _firePlasma(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  spawnPlayerMissile(mobj, MobjType.plasma, level.renderState, level);
}

void _fireBfg(Player player, LevelLocals level) {
  final mobj = player.mobj;
  if (mobj == null) return;

  spawnPlayerMissile(mobj, MobjType.bfg, level.renderState, level);
}

Mobj? lineTarget;
int _aimSlope = 0;

int aimLineAttack(Mobj source, int angle, int distance, LevelLocals level) {
  lineTarget = null;
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
    lineTarget = bestTarget;
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
