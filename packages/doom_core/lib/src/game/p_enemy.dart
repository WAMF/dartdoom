import 'dart:math' as math;

import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_map.dart' as map;
import 'package:doom_core/src/game/p_sight.dart' as sight;
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

const int _floatSpeed = Fixed32.fracUnit;

abstract final class _MoveDir {
  static const int east = 0;
  static const int northeast = 1;
  static const int north = 2;
  static const int northwest = 3;
  static const int west = 4;
  static const int southwest = 5;
  static const int south = 6;
  static const int southeast = 7;
  static const int noDir = 8;
}

abstract final class _EnemyConstants {
  static const int meleeRange = 64 * Fixed32.fracUnit;
  static const int skullSpeed = 20 * Fixed32.fracUnit;
  static const int ang90 = 0x40000000;
  static const int ang270 = 0xC0000000;
}

const List<int> _opposite = [
  _MoveDir.west,
  _MoveDir.southwest,
  _MoveDir.south,
  _MoveDir.southeast,
  _MoveDir.east,
  _MoveDir.northeast,
  _MoveDir.north,
  _MoveDir.northwest,
  _MoveDir.noDir,
];

const List<int> _xSpeed = [
  Fixed32.fracUnit,
  47000,
  0,
  -47000,
  -Fixed32.fracUnit,
  -47000,
  0,
  47000,
];

const List<int> _ySpeed = [
  0,
  47000,
  Fixed32.fracUnit,
  47000,
  0,
  -47000,
  -Fixed32.fracUnit,
  -47000,
];

bool lookForPlayers(Mobj actor, LevelLocals level, {bool allAround = false}) {
  if (level.players.isEmpty) return false;

  final player = level.players[0];
  final playerMobj = player.mobj;
  if (playerMobj == null) return false;

  if (player.health <= 0) return false;

  if (!_checkSight(actor, playerMobj, level)) return false;

  if (!allAround) {
    final an = (_pointToAngle(actor.x, actor.y, playerMobj.x, playerMobj.y) -
            actor.angle)
        .u32;

    if (an > _EnemyConstants.ang90 && an < _EnemyConstants.ang270) {
      final dist = _approxDistance(
        playerMobj.x - actor.x,
        playerMobj.y - actor.y,
      );
      if (dist > _EnemyConstants.meleeRange) {
        return false;
      }
    }
  }

  actor
    ..target = playerMobj
    ..threshold = 60;
  return true;
}

void aLook(Mobj actor, LevelLocals level) {
  actor.threshold = 0;

  final ss = actor.subsector;
  if (ss is Subsector) {
    final soundTarget = ss.sector.soundTarget;
    if (soundTarget != null && (soundTarget.flags & MobjFlag.shootable) != 0) {
      actor.target = soundTarget;

      if ((actor.flags & MobjFlag.ambush) != 0) {
        if (!_checkSight(actor, soundTarget, level)) {
          if (!lookForPlayers(actor, level)) {
            return;
          }
        }
      }
      _goToSeeState(actor, level);
      return;
    }
  }

  if (!lookForPlayers(actor, level)) {
    return;
  }

  _goToSeeState(actor, level);
}

void _goToSeeState(Mobj actor, LevelLocals level) {
  final info = actor.info;
  if (info == null) return;

  final seeState = info.seeState;
  if (seeState != 0) {
    spec.setMobjStateNum(actor, seeState, level);
  }
}

void aChase(Mobj actor, LevelLocals level, DoomRandom random) {
  if (actor.reactionTime > 0) {
    actor.reactionTime--;
  }

  if (actor.threshold > 0) {
    final target = actor.target;
    if (target == null || target.health <= 0) {
      actor.threshold = 0;
    } else {
      actor.threshold--;
    }
  }

  if (actor.moveDir < 8) {
    actor.angle = actor.angle & (7 << 29);
    final delta = actor.angle - (actor.moveDir << 29);

    if (delta > 0) {
      actor.angle -= 0x40000000 ~/ 2;
    } else if (delta < 0) {
      actor.angle += 0x40000000 ~/ 2;
    }
  }

  final target = actor.target;
  if (target == null || (target.flags & MobjFlag.shootable) == 0) {
    if (!lookForPlayers(actor, level, allAround: true)) {
      final spawnState = actor.info?.spawnState ?? 0;
      if (spawnState != 0) {
        spec.setMobjStateNum(actor, spawnState, level);
      }
    }
    return;
  }

  if ((actor.flags & MobjFlag.justAttacked) != 0) {
    actor.flags &= ~MobjFlag.justAttacked;
    _newChaseDir(actor, target, level, random);
    return;
  }

  final info = actor.info;
  if (info != null) {
    if (info.meleeState != 0 && checkMeleeRange(actor, target)) {
      spec.setMobjStateNum(actor, info.meleeState, level);
      return;
    }

    if (info.missileState != 0) {
      if (actor.moveCount == 0 && checkMissileRange(actor, random, level)) {
        spec.setMobjStateNum(actor, info.missileState, level);
        actor.flags |= MobjFlag.justAttacked;
        return;
      }
    }
  }

  actor.moveCount--;
  if (actor.moveCount < 0 || !_move(actor, level)) {
    _newChaseDir(actor, target, level, random);
  }
}

void chase(Mobj actor, LevelLocals level) {
  if (actor.reactionTime > 0) {
    actor.reactionTime--;
  }

  if (actor.threshold > 0) {
    final target = actor.target;
    if (target == null || target.health <= 0) {
      actor.threshold = 0;
    } else {
      actor.threshold--;
    }
  }

  if (actor.moveDir != _MoveDir.noDir) {
    actor.moveDir = _MoveDir.noDir;
  }

  final target = actor.target;
  if (target == null || (target.flags & MobjFlag.shootable) == 0) {
    lookForPlayers(actor, level);
    return;
  }

  if (!checkMeleeRange(actor, target)) {
    if (actor.reactionTime == 0) {
      _newChaseDir(actor, target, level, level.random);
    }
  }

  _moveSimple(actor);
}

bool checkMeleeRange(Mobj actor, Mobj target) {
  final dist = _approxDistance(target.x - actor.x, target.y - actor.y);
  const meleeRange = _EnemyConstants.meleeRange - 20 * Fixed32.fracUnit;
  final radius = actor.info?.radius ?? 0;
  return dist < meleeRange + radius;
}

bool checkMissileRange(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return false;

  if (!_checkSight(actor, target, level)) return false;

  if ((actor.flags & MobjFlag.justHit) != 0) {
    actor.flags &= ~MobjFlag.justHit;
    return true;
  }

  if (actor.reactionTime > 0) return false;

  var dist = _approxDistance(
        actor.x - target.x,
        actor.y - target.y,
      ) -
      64 * Fixed32.fracUnit;

  final info = actor.info;
  if (info != null && info.meleeState == 0) {
    dist -= 128 * Fixed32.fracUnit;
  }

  dist >>= 16;

  if (dist > 200) dist = 200;

  return random.pRandom() >= dist;
}

bool _checkSight(Mobj actor, Mobj target, LevelLocals level) {
  return sight.checkSight(actor, target, level.renderState);
}

bool _tryWalk(Mobj actor, LevelLocals level, DoomRandom random) {
  if (!_move(actor, level)) {
    return false;
  }
  actor.moveCount = random.pRandom() & 15;
  return true;
}

void _newChaseDir(
  Mobj actor,
  Mobj target,
  LevelLocals level,
  DoomRandom random,
) {
  final oldDir = actor.moveDir;
  final turnaround = oldDir < 9 ? _opposite[oldDir] : _MoveDir.noDir;

  final dx = target.x - actor.x;
  final dy = target.y - actor.y;

  int d1;
  int d2;

  if (dx > 10 * Fixed32.fracUnit) {
    d1 = _MoveDir.east;
  } else if (dx < -10 * Fixed32.fracUnit) {
    d1 = _MoveDir.west;
  } else {
    d1 = _MoveDir.noDir;
  }

  if (dy < -10 * Fixed32.fracUnit) {
    d2 = _MoveDir.south;
  } else if (dy > 10 * Fixed32.fracUnit) {
    d2 = _MoveDir.north;
  } else {
    d2 = _MoveDir.noDir;
  }

  if (d1 != _MoveDir.noDir && d2 != _MoveDir.noDir) {
    final diag = (d1 == _MoveDir.east) == (d2 == _MoveDir.south);
    actor.moveDir = diag
        ? (d2 == _MoveDir.south ? _MoveDir.southeast : _MoveDir.northeast)
        : (d2 == _MoveDir.south ? _MoveDir.southwest : _MoveDir.northwest);
    if (actor.moveDir != turnaround && _tryWalk(actor, level, random)) {
      return;
    }
  }

  if (random.pRandom() > 200 || dy.abs() > dx.abs()) {
    final swap = d1;
    d1 = d2;
    d2 = swap;
  }

  if (d1 == turnaround) d1 = _MoveDir.noDir;
  if (d2 == turnaround) d2 = _MoveDir.noDir;

  if (d1 != _MoveDir.noDir) {
    actor.moveDir = d1;
    if (_tryWalk(actor, level, random)) {
      return;
    }
  }

  if (d2 != _MoveDir.noDir) {
    actor.moveDir = d2;
    if (_tryWalk(actor, level, random)) {
      return;
    }
  }

  if (oldDir != _MoveDir.noDir) {
    actor.moveDir = oldDir;
    if (_tryWalk(actor, level, random)) {
      return;
    }
  }

  if (random.pRandom() & 1 != 0) {
    for (var dir = _MoveDir.east; dir <= _MoveDir.southeast; dir++) {
      if (dir != turnaround) {
        actor.moveDir = dir;
        if (_tryWalk(actor, level, random)) {
          return;
        }
      }
    }
  } else {
    for (var dir = _MoveDir.southeast; dir >= _MoveDir.east; dir--) {
      if (dir != turnaround) {
        actor.moveDir = dir;
        if (_tryWalk(actor, level, random)) {
          return;
        }
      }
    }
  }

  if (turnaround != _MoveDir.noDir) {
    actor.moveDir = turnaround;
    if (_tryWalk(actor, level, random)) {
      return;
    }
  }

  actor.moveDir = _MoveDir.noDir;
}

bool _move(Mobj actor, LevelLocals level) {
  if (actor.moveDir == _MoveDir.noDir) return false;

  if (actor.moveDir >= 8) return false;

  final info = actor.info;
  final speed = info?.speed ?? 0;

  final tryX = actor.x + speed * _xSpeed[actor.moveDir];
  final tryY = actor.y + speed * _ySpeed[actor.moveDir];

  if (!map.tryMove(actor, tryX, tryY, level)) {
    if ((actor.flags & MobjFlag.float) != 0 && level.floatOk) {
      if (actor.z < level.tmFloorZ) {
        actor.z += _floatSpeed;
      } else {
        actor.z -= _floatSpeed;
      }
      actor.flags |= MobjFlag.inFloat;
      return true;
    }
    return false;
  }

  actor.flags &= ~MobjFlag.inFloat;

  if ((actor.flags & MobjFlag.float) == 0) {
    actor.z = actor.floorZ;
  }

  return true;
}

void _moveSimple(Mobj actor) {
  if (actor.moveDir == _MoveDir.noDir) return;

  final speed = actor.info?.speed ?? 0;
  actor
    ..momX = Fixed32.mul(speed, _xSpeed[actor.moveDir])
    ..momY = Fixed32.mul(speed, _ySpeed[actor.moveDir]);
}

int _approxDistance(int dx, int dy) {
  final adx = dx.abs();
  final ady = dy.abs();
  return adx + ady - (math.min(adx, ady) >> 1);
}

void attackMelee(Mobj actor, int damage, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  if (!checkMeleeRange(actor, target)) return;

  spec.damageMobj(target, actor, actor, damage, level);
}

void faceTarget(Mobj actor) {
  final target = actor.target;
  if (target == null) return;

  actor.flags &= ~MobjFlag.ambush;

  final dx = target.x - actor.x;
  final dy = target.y - actor.y;

  if (dx == 0 && dy == 0) return;

  actor.angle = _pointToAngle(actor.x, actor.y, target.x, target.y);
}

void aFaceTarget(Mobj actor, DoomRandom random) {
  final target = actor.target;
  if (target == null) return;

  actor
    ..flags &= ~MobjFlag.ambush
    ..angle = _pointToAngle(actor.x, actor.y, target.x, target.y);

  if ((target.flags & MobjFlag.shadow) != 0) {
    actor.angle += (random.pRandom() - random.pRandom()) << 21;
  }
}

void aPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  final damage = ((random.pRandom() % 5) + 1) * 3;
  _hitscanAttack(actor, damage, level);
}

void aSPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  for (var i = 0; i < 3; i++) {
    final damage = ((random.pRandom() % 5) + 1) * 3;
    _hitscanAttack(actor, damage, level);
  }
}

void aCPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  final damage = ((random.pRandom() % 5) + 1) * 3;
  _hitscanAttack(actor, damage, level);
}

void aCPosRefire(
  Mobj actor,
  DoomRandom random,
  LevelLocals level,
) {
  aFaceTarget(actor, random);

  if (random.pRandom() < 40) return;

  final target = actor.target;
  if (target == null ||
      target.health <= 0 ||
      !_checkSight(actor, target, level)) {
    final seeState = actor.info?.seeState ?? 0;
    if (seeState != 0) {
      spec.setMobjStateNum(actor, seeState, level);
    }
  }
}

void aTroopAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  if (checkMeleeRange(actor, target)) {
    final damage = (random.pRandom() % 8 + 1) * 3;
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

void aSargAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  if (checkMeleeRange(actor, target)) {
    final damage = ((random.pRandom() % 10) + 1) * 4;
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

void aHeadAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  if (checkMeleeRange(actor, target)) {
    final damage = (random.pRandom() % 6 + 1) * 10;
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

void aBruisAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  if (checkMeleeRange(actor, target)) {
    final damage = (random.pRandom() % 8 + 1) * 10;
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

void aSkelFist(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  if (checkMeleeRange(actor, target)) {
    final damage = ((random.pRandom() % 10) + 1) * 6;
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

void aSkullAttack(Mobj actor) {
  final target = actor.target;
  if (target == null) return;

  actor.flags |= MobjFlag.skullFly;

  faceTarget(actor);
  final an = actor.angle >> Angle.angleToFineShift;
  actor
    ..momX = Fixed32.mul(_EnemyConstants.skullSpeed, fineCosine(an))
    ..momY = Fixed32.mul(_EnemyConstants.skullSpeed, fineSine(an));

  final dist = _approxDistance(target.x - actor.x, target.y - actor.y);
  final distDenom = dist ~/ _EnemyConstants.skullSpeed;
  final divisor = distDenom < 1 ? 1 : distDenom;

  actor.momZ = (target.z + (target.height >> 1) - actor.z) ~/ divisor;
}

void aFall(Mobj actor) {
  actor.flags &= ~MobjFlag.solid;
}

void aScream(Mobj actor) {
  final deathSound = actor.info?.deathSound ?? 0;
  if (deathSound == 0) return;
}

void aXScream(Mobj actor) {}

void aPain(Mobj actor) {
  final painSound = actor.info?.painSound ?? 0;
  if (painSound == 0) return;
}

void _hitscanAttack(Mobj actor, int damage, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  if (_checkSight(actor, target, level)) {
    spec.damageMobj(target, actor, actor, damage, level);
  }
}

int _pointToAngle(int x1, int y1, int x2, int y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  if (dx == 0 && dy == 0) return 0;

  final angle =
      (math.atan2(dy.toDouble(), dx.toDouble()) * (0x80000000 / math.pi))
          .toInt();
  return angle;
}
