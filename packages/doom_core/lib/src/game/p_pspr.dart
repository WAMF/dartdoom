import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_map.dart' as map;
import 'package:doom_core/src/game/p_mobj.dart' as mobj;
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _WeaponConstants {
  static const int lowerSpeed = 6 * Fixed32.fracUnit;
  static const int raiseSpeed = 6 * Fixed32.fracUnit;
  static const int weaponBottom = 128 * Fixed32.fracUnit;
  static const int weaponTop = 32 * Fixed32.fracUnit;
  static const int numPsprites = 2;
  static const int psWeapon = 0;
  static const int bfgCells = 40;
  static const int bulletRange = 16 * 64 * Fixed32.fracUnit;
}

abstract final class _MuzzleFlashConstants {
  static const int pistolFlash = 1;
  static const int shotgunFlash = 2;
  static const int chainsawFlash = 1;
  static const int chaingunFlash = 2;
  static const int rocketFlash = 2;
  static const int plasmaFlash = 1;
  static const int bfgFlash = 2;
}

const List<int> _weaponSprites = [
  SpriteNum.pung,
  SpriteNum.pisg,
  SpriteNum.shtg,
  SpriteNum.chgg,
  SpriteNum.misg,
  SpriteNum.plsg,
  SpriteNum.bfgg,
  SpriteNum.sawg,
  SpriteNum.sht2,
];

class _WeaponFrame {
  const _WeaponFrame(this.frame, this.tics);
  final int frame;
  final int tics;
}

const List<List<_WeaponFrame>> _weaponAttackFrames = [
  [_WeaponFrame(1, 4), _WeaponFrame(2, 4), _WeaponFrame(3, 5), _WeaponFrame(2, 4), _WeaponFrame(1, 5)],
  [_WeaponFrame(0, 4), _WeaponFrame(1, 6), _WeaponFrame(2, 4), _WeaponFrame(1, 5)],
  [_WeaponFrame(0, 3), _WeaponFrame(0, 7), _WeaponFrame(1, 5), _WeaponFrame(2, 5), _WeaponFrame(3, 4), _WeaponFrame(2, 5), _WeaponFrame(1, 5), _WeaponFrame(0, 3), _WeaponFrame(0, 7)],
  [_WeaponFrame(0, 4), _WeaponFrame(1, 4)],
  [_WeaponFrame(0, 8), _WeaponFrame(1, 12)],
  [_WeaponFrame(0, 3), _WeaponFrame(1, 1)],
  [_WeaponFrame(0, 20), _WeaponFrame(1, 10), _WeaponFrame(2, 10)],
  [_WeaponFrame(0, 4), _WeaponFrame(1, 4), _WeaponFrame(2, 4)],
  [_WeaponFrame(0, 3), _WeaponFrame(0, 7), _WeaponFrame(1, 7), _WeaponFrame(2, 7), _WeaponFrame(3, 7), _WeaponFrame(4, 7), _WeaponFrame(5, 7), _WeaponFrame(6, 6), _WeaponFrame(7, 6), _WeaponFrame(0, 5), _WeaponFrame(0, 7)],
];

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
  int sprite = 0;
  int frame = 0;
  int attackFrameIndex = 0;
  int attackFrameTics = 0;
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
  psp
    ..sy = _WeaponConstants.weaponBottom
    ..psprState = PsprState.raise
    ..sprite = _weaponSprites[newWeapon.index]
    ..frame = 0;
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
  if (player.extraLight > 0) {
    player.extraLight = 0;
  }

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
  final weaponIndex = player.readyWeapon.index;
  final frames = _weaponAttackFrames[weaponIndex];

  psp
    ..psprState = PsprState.attack
    ..tics = -1
    ..attackFrameIndex = 0
    ..attackFrameTics = frames.isNotEmpty ? frames[0].tics : 1
    ..frame = frames.isNotEmpty ? frames[0].frame : 0;
}

void _weaponAttack(Player player, PspriteDef psp, LevelLocals level) {
  final weapon = player.readyWeapon;
  final weaponIndex = weapon.index;
  final frames = _weaponAttackFrames[weaponIndex];

  if (psp.tics == -1) {
    final info = weaponInfo[weaponIndex];

    if (info.ammo != AmmoType.noAmmo) {
      if (player.ammo[info.ammo.index] <= 0) {
        psp
          ..psprState = PsprState.ready
          ..frame = 0;
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
        player.extraLight = _MuzzleFlashConstants.chainsawFlash;
      case WeaponType.pistol:
        _calcBulletSlope(player, level);
        _gunShot(player, level, player.refire == 0);
        player.extraLight = _MuzzleFlashConstants.pistolFlash;
      case WeaponType.chaingun:
        _calcBulletSlope(player, level);
        _gunShot(player, level, player.refire == 0);
        player.extraLight = _MuzzleFlashConstants.chaingunFlash;
      case WeaponType.shotgun:
        _calcBulletSlope(player, level);
        for (var i = 0; i < 7; i++) {
          _gunShot(player, level, false);
        }
        player.extraLight = _MuzzleFlashConstants.shotgunFlash;
      case WeaponType.superShotgun:
        _calcBulletSlope(player, level);
        for (var i = 0; i < 20; i++) {
          _superShotgunShot(player, level);
        }
        player.extraLight = _MuzzleFlashConstants.shotgunFlash;
      case WeaponType.missile:
        _fireMissile(player, level);
        player.extraLight = _MuzzleFlashConstants.rocketFlash;
      case WeaponType.plasma:
        _firePlasma(player, level);
        player.extraLight = _MuzzleFlashConstants.plasmaFlash;
      case WeaponType.bfg:
        _fireBfg(player, level);
        player.extraLight = _MuzzleFlashConstants.bfgFlash;
      case WeaponType.numWeapons:
      case WeaponType.noChange:
        break;
    }

    psp.tics = 1;
  }

  psp.attackFrameTics--;
  if (psp.attackFrameTics <= 0) {
    psp.attackFrameIndex++;
    if (psp.attackFrameIndex >= frames.length) {
      psp
        ..psprState = PsprState.ready
        ..frame = 0
        ..attackFrameIndex = 0;
      player.extraLight = 0;
      return;
    }
    final nextFrame = frames[psp.attackFrameIndex];
    psp
      ..frame = nextFrame.frame
      ..attackFrameTics = nextFrame.tics;
  }
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
    mobj.angle = pointToAngle(lineTarget!.x - mobj.x, lineTarget!.y - mobj.y);
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

  final targetAngle =
      pointToAngle(lineTarget!.x - mobj.x, lineTarget!.y - mobj.y);
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
  final mo = player.mobj;
  if (mo == null) return;

  mobj.spawnPlayerMissile(mo, mobj.MobjType.rocket, level.renderState, level);
}

void _firePlasma(Player player, LevelLocals level) {
  final mo = player.mobj;
  if (mo == null) return;

  mobj.spawnPlayerMissile(mo, mobj.MobjType.plasma, level.renderState, level);
}

void _fireBfg(Player player, LevelLocals level) {
  final mo = player.mobj;
  if (mo == null) return;

  mobj.spawnPlayerMissile(mo, mobj.MobjType.bfg, level.renderState, level);
}

Mobj? lineTarget;

abstract final class _AimConstants {
  static const int topSlope = 100 * Fixed32.fracUnit ~/ 160;
  static const int bottomSlope = -100 * Fixed32.fracUnit ~/ 160;
}

class _AimState {
  Mobj? shootThing;
  int shootZ = 0;
  int attackRange = 0;
  int topSlope = 0;
  int bottomSlope = 0;
  int aimSlope = 0;
}

final _aimState = _AimState();

class _ShootState {
  Mobj? shootThing;
  int shootZ = 0;
  int attackRange = 0;
  int aimSlope = 0;
  int damage = 0;
}

final _shootState = _ShootState();

int aimLineAttack(Mobj source, int angle, int distance, LevelLocals level) {
  lineTarget = null;

  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  final x2 = source.x + (distance >> Fixed32.fracBits) * fineCosine(fineAngle);
  final y2 = source.y + (distance >> Fixed32.fracBits) * fineSine(fineAngle);

  _aimState
    ..shootThing = source
    ..shootZ = source.z + (source.height >> 1) + 8 * Fixed32.fracUnit
    ..attackRange = distance
    ..topSlope = _AimConstants.topSlope
    ..bottomSlope = _AimConstants.bottomSlope
    ..aimSlope = 0;

  map.pathTraverse(
    source.x,
    source.y,
    x2,
    y2,
    map.PathTraverseFlags.addLines | map.PathTraverseFlags.addThings,
    level,
    _aimTraverse,
  );

  if (lineTarget != null) {
    return _aimState.aimSlope;
  }

  return 0;
}

bool _aimTraverse(map.Intercept intercept) {
  if (intercept.isLine) {
    final line = intercept.line!;

    if ((line.flags & LineFlags.twoSided) == 0) {
      return false;
    }

    final opening = map.getLineOpening(line);
    if (opening.openBottom >= opening.openTop) {
      return false;
    }

    final dist = Fixed32.mul(_aimState.attackRange, intercept.frac);

    final front = line.frontSector;
    final back = line.backSector;

    if (front != null && back != null) {
      if (front.floorHeight != back.floorHeight) {
        final slope = Fixed32.div(opening.openBottom - _aimState.shootZ, dist);
        if (slope > _aimState.bottomSlope) {
          _aimState.bottomSlope = slope;
        }
      }

      if (front.ceilingHeight != back.ceilingHeight) {
        final slope = Fixed32.div(opening.openTop - _aimState.shootZ, dist);
        if (slope < _aimState.topSlope) {
          _aimState.topSlope = slope;
        }
      }
    }

    if (_aimState.topSlope <= _aimState.bottomSlope) {
      return false;
    }

    return true;
  }

  final th = intercept.thing!;
  if (th == _aimState.shootThing) {
    return true;
  }

  if ((th.flags & MobjFlag.shootable) == 0) {
    return true;
  }

  final dist = Fixed32.mul(_aimState.attackRange, intercept.frac);
  final thingTopSlope = Fixed32.div(th.z + th.height - _aimState.shootZ, dist);

  if (thingTopSlope < _aimState.bottomSlope) {
    return true;
  }

  final thingBottomSlope = Fixed32.div(th.z - _aimState.shootZ, dist);

  if (thingBottomSlope > _aimState.topSlope) {
    return true;
  }

  var adjustedTop = thingTopSlope;
  var adjustedBottom = thingBottomSlope;

  if (adjustedTop > _aimState.topSlope) {
    adjustedTop = _aimState.topSlope;
  }

  if (adjustedBottom < _aimState.bottomSlope) {
    adjustedBottom = _aimState.bottomSlope;
  }

  _aimState.aimSlope = (adjustedTop + adjustedBottom) ~/ 2;
  lineTarget = th;

  return false;
}

void _lineAttack(
  Mobj source,
  int angle,
  int distance,
  int slope,
  int damage,
  LevelLocals level,
) {
  final fineAngle = (angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
  final dx = (distance >> Fixed32.fracBits) * fineCosine(fineAngle);
  final dy = (distance >> Fixed32.fracBits) * fineSine(fineAngle);
  final x2 = source.x + dx;
  final y2 = source.y + dy;

  _shootState
    ..shootThing = source
    ..shootZ = source.z + (source.height >> 1) + 8 * Fixed32.fracUnit
    ..attackRange = distance
    ..aimSlope = slope
    ..damage = damage;

  map.pathTraverse(
    source.x,
    source.y,
    x2,
    y2,
    map.PathTraverseFlags.addLines | map.PathTraverseFlags.addThings,
    level,
    (intercept) => _shootTraverse(intercept, level),
  );
}

bool _shootTraverse(map.Intercept intercept, LevelLocals level) {
  if (intercept.isLine) {
    final line = intercept.line!;

    if (line.special != 0) {
      spec.shootSpecialLine(_shootState.shootThing!, line, level);
    }

    if ((line.flags & LineFlags.twoSided) == 0) {
      return _hitLine(intercept, line, level);
    }

    final opening = map.getLineOpening(line);
    final dist = Fixed32.mul(_shootState.attackRange, intercept.frac);

    final front = line.frontSector;
    final back = line.backSector;

    if (front != null && back != null) {
      if (front.floorHeight != back.floorHeight) {
        final slope = Fixed32.div(opening.openBottom - _shootState.shootZ, dist);
        if (slope > _shootState.aimSlope) {
          return _hitLine(intercept, line, level);
        }
      }

      if (front.ceilingHeight != back.ceilingHeight) {
        final slope = Fixed32.div(opening.openTop - _shootState.shootZ, dist);
        if (slope < _shootState.aimSlope) {
          return _hitLine(intercept, line, level);
        }
      }
    }

    return true;
  }

  final th = intercept.thing!;
  if (th == _shootState.shootThing) {
    return true;
  }

  if ((th.flags & MobjFlag.shootable) == 0) {
    return true;
  }

  final dist = Fixed32.mul(_shootState.attackRange, intercept.frac);
  final thingTopSlope = Fixed32.div(th.z + th.height - _shootState.shootZ, dist);

  if (thingTopSlope < _shootState.aimSlope) {
    return true;
  }

  final thingBottomSlope = Fixed32.div(th.z - _shootState.shootZ, dist);

  if (thingBottomSlope > _shootState.aimSlope) {
    return true;
  }

  final frac = intercept.frac - Fixed32.div(10 * Fixed32.fracUnit, _shootState.attackRange);
  final x = map.trace.x + Fixed32.mul(map.trace.dx, frac);
  final y = map.trace.y + Fixed32.mul(map.trace.dy, frac);
  final z = _shootState.shootZ +
      Fixed32.mul(_shootState.aimSlope, Fixed32.mul(frac, _shootState.attackRange));

  if ((th.flags & MobjFlag.noBlood) != 0) {
    mobj.spawnPuff(x, y, z, _shootState.attackRange, level.renderState, level);
  } else {
    mobj.spawnBlood(x, y, z, _shootState.damage, level.renderState, level);
  }

  if (_shootState.damage > 0) {
    spec.damageMobj(th, _shootState.shootThing, _shootState.shootThing, _shootState.damage, level);
  }

  return false;
}

bool _hitLine(map.Intercept intercept, Line line, LevelLocals level) {
  final frac = intercept.frac - Fixed32.div(4 * Fixed32.fracUnit, _shootState.attackRange);
  final x = map.trace.x + Fixed32.mul(map.trace.dx, frac);
  final y = map.trace.y + Fixed32.mul(map.trace.dy, frac);
  final z = _shootState.shootZ +
      Fixed32.mul(_shootState.aimSlope, Fixed32.mul(frac, _shootState.attackRange));

  final skyFlatNum = level.renderState.skyFlatNum;
  final front = line.frontSector;
  if (front != null && front.ceilingPic == skyFlatNum) {
    if (z > front.ceilingHeight) {
      return false;
    }

    final back = line.backSector;
    if (back != null && back.ceilingPic == skyFlatNum) {
      return false;
    }
  }

  mobj.spawnPuff(x, y, z, _shootState.attackRange, level.renderState, level);
  return false;
}

