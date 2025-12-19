import 'package:doom_core/src/game/info.dart' show StateNum;
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_inter.dart' as inter;
import 'package:doom_core/src/game/p_map.dart' as map;
import 'package:doom_core/src/game/p_maputl.dart' as maputl;
import 'package:doom_core/src/game/p_mobj.dart'
    show MobjType, countSkulls, spawnMissile, spawnMobj, spawnSkull;
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
  static const int maxSkullCount = 20;
  static const int skullSpawnZ = 8 * Fixed32.fracUnit;
}

abstract final class _MonsterType {
  static const int vile = 64;
  static const int undead = 66;
  static const int skull = 3006;
  static const int spider = 7;
  static const int cyborg = 16;
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
    final an =
        (pointToAngle(playerMobj.x - actor.x, playerMobj.y - actor.y) -
                actor.angle)
            .u32;

    if (an > _EnemyConstants.ang90 && an < _EnemyConstants.ang270) {
      final dist = approxDistance(
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

  // make active sound
  // Original C: if (actor->info->activesound && P_Random () < 3)
  if (actor.info?.activeSound != null && random.pRandom() < 3) {
    // Sound would be played here
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
  final dist = approxDistance(target.x - actor.x, target.y - actor.y);
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

  var dist = approxDistance(
        actor.x - target.x,
        actor.y - target.y,
      ) -
      64 * Fixed32.fracUnit;

  final info = actor.info;
  if (info != null && info.meleeState == 0) {
    dist -= 128 * Fixed32.fracUnit;
  }

  dist >>= 16;

  final actorType = actor.type;

  if (actorType == _MonsterType.vile) {
    if (dist > 14 * 64) return false;
  }

  if (actorType == _MonsterType.undead) {
    if (dist < 196) return false;
    dist >>= 1;
  }

  if (actorType == _MonsterType.cyborg ||
      actorType == _MonsterType.spider ||
      actorType == _MonsterType.skull) {
    dist >>= 1;
  }

  if (dist > 200) dist = 200;

  if (actorType == _MonsterType.cyborg && dist > 160) {
    dist = 160;
  }

  return random.pRandom() >= dist;
}

bool _checkSight(Mobj actor, Mobj target, LevelLocals level) {
  return sight.checkSight(
    actor,
    target,
    level.renderState,
    rejectMatrix: level.rejectMatrix,
    numSectors: level.numSectors,
  );
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

  actor.angle = pointToAngle(target.x - actor.x, target.y - actor.y);
}

void aFaceTarget(Mobj actor, DoomRandom random) {
  final target = actor.target;
  if (target == null) return;

  actor
    ..flags &= ~MobjFlag.ambush
    ..angle = pointToAngle(target.x - actor.x, target.y - actor.y);

  if ((target.flags & MobjFlag.shadow) != 0) {
    actor.angle += (random.pRandom() - random.pRandom()) << 21;
  }
}

void aPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  // Original C: angle += (P_Random()-P_Random())<<20;
  // Must call P_Random twice for angle spread even if not used for actual aiming
  random.pRandom();
  random.pRandom();
  final damage = ((random.pRandom() % 5) + 1) * 3;
  _hitscanAttack(actor, damage, level);
}

void aSPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  for (var i = 0; i < 3; i++) {
    // Original C: angle = bangle + ((P_Random()-P_Random())<<20);
    random.pRandom();
    random.pRandom();
    final damage = ((random.pRandom() % 5) + 1) * 3;
    _hitscanAttack(actor, damage, level);
  }
}

void aCPosAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  // Original C: angle = bangle + ((P_Random()-P_Random())<<20);
  random.pRandom();
  random.pRandom();
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
    return;
  }

  spawnMissile(actor, target, MobjType.troopShot, level.renderState, level);
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
    return;
  }

  spawnMissile(actor, target, MobjType.headShot, level.renderState, level);
}

void aBruisAttack(Mobj actor, DoomRandom random, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  if (checkMeleeRange(actor, target)) {
    final damage = (random.pRandom() % 8 + 1) * 10;
    spec.damageMobj(target, actor, actor, damage, level);
    return;
  }

  spawnMissile(actor, target, MobjType.bruiserShot, level.renderState, level);
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

  final dist = approxDistance(target.x - actor.x, target.y - actor.y);
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


void aCyberAttack(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  spawnMissile(actor, target, MobjType.rocket, level.renderState, level);
}

void aSpidRefire(Mobj actor, DoomRandom random, LevelLocals level) {
  aFaceTarget(actor, random);

  if (random.pRandom() < 10) return;

  final target = actor.target;
  if (target == null || target.health <= 0 || !_checkSight(actor, target, level)) {
    final info = actor.info;
    if (info != null && info.seeState > 0) {
      spec.setMobjStateNum(actor, info.seeState, level);
    }
  }
}

void aBspiAttack(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  spawnMissile(actor, target, MobjType.arachPlaz, level.renderState, level);
}

void aSkelMissile(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  actor.z += 16 * Fixed32.fracUnit;
  final mo = spawnMissile(actor, target, MobjType.tracer, level.renderState, level);
  actor.z -= 16 * Fixed32.fracUnit;

  if (mo != null) {
    mo
      ..x += mo.momX
      ..y += mo.momY
      ..tracer = target;
  }
}

void aSkelWhoosh(Mobj actor, DoomRandom random) {
  final target = actor.target;
  if (target == null) return;
  faceTarget(actor);
}

void aTracer(Mobj actor, LevelLocals level) {
  // Original C: if (gametic & 3) return;
  // Only adjust direction every 4 tics
  if ((level.levelTime & 3) != 0) return;

  // Spawn puff and smoke - these call P_Random for various effects
  // P_SpawnPuff does:
  //   z += ((P_Random()-P_Random())<<10)  - 2 calls
  //   P_SpawnMobj (puff) -> lastlook      - 1 call
  //   th->tics -= P_Random()&3            - 1 call
  // Then A_Tracer spawns smoke:
  //   P_SpawnMobj (smoke) -> lastlook     - 1 call
  //   th->tics -= P_Random()&3            - 1 call
  // Total: 6 P_Random calls
  level.random
    ..pRandom() // P_SpawnPuff z adjustment 1
    ..pRandom() // P_SpawnPuff z adjustment 2
    ..pRandom() // P_SpawnMobj (puff) lastlook
    ..pRandom() // puff tics adjustment
    ..pRandom() // P_SpawnMobj (smoke) lastlook
    ..pRandom(); // smoke tics adjustment

  final dest = actor.tracer;
  if (dest == null || dest.health <= 0) return;

  final exact = pointToAngle(dest.x - actor.x, dest.y - actor.y);

  if (exact != actor.angle) {
    const traceAngle = 0xc000000;
    final diff = (exact - actor.angle).u32.s32;
    if (diff < 0) {
      actor.angle = (actor.angle - traceAngle).u32.s32;
      if (((exact - actor.angle).u32.s32) > 0) {
        actor.angle = exact;
      }
    } else {
      actor.angle = (actor.angle + traceAngle).u32.s32;
      if (((exact - actor.angle).u32.s32) < 0) {
        actor.angle = exact;
      }
    }
  }

  final an = actor.angle >> Angle.angleToFineShift;
  final info = actor.info;
  final speed = info?.speed ?? (10 * Fixed32.fracUnit);
  actor
    ..momX = Fixed32.mul(speed, fineCosine(an))
    ..momY = Fixed32.mul(speed, fineSine(an));

  final dist = approxDistance(dest.x - actor.x, dest.y - actor.y);
  var distDenom = dist ~/ speed;
  if (distDenom < 1) distDenom = 1;

  final slope = (dest.z + 40 * Fixed32.fracUnit - actor.z) ~/ distDenom;
  if (slope < actor.momZ) {
    actor.momZ -= Fixed32.fracUnit ~/ 8;
  } else {
    actor.momZ += Fixed32.fracUnit ~/ 8;
  }
}

void aFatRaise(Mobj actor, DoomRandom random) {
  faceTarget(actor);
}

void aFatAttack1(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  const fatSpread = Angle.ang90 ~/ 8;
  actor.angle = (actor.angle + fatSpread).u32.s32;
  spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);

  final mo = spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);
  if (mo != null) {
    mo.angle = (mo.angle + fatSpread).u32.s32;
    final an = mo.angle >> Angle.angleToFineShift;
    final info = mo.info;
    final speed = info?.speed ?? (20 * Fixed32.fracUnit);
    mo
      ..momX = Fixed32.mul(speed, fineCosine(an))
      ..momY = Fixed32.mul(speed, fineSine(an));
  }
}

void aFatAttack2(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  const fatSpread = Angle.ang90 ~/ 8;
  actor.angle = (actor.angle - fatSpread).u32.s32;
  spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);

  final mo = spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);
  if (mo != null) {
    mo.angle = (mo.angle - fatSpread * 2).u32.s32;
    final an = mo.angle >> Angle.angleToFineShift;
    final info = mo.info;
    final speed = info?.speed ?? (20 * Fixed32.fracUnit);
    mo
      ..momX = Fixed32.mul(speed, fineCosine(an))
      ..momY = Fixed32.mul(speed, fineSine(an));
  }
}

void aFatAttack3(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  const fatSpread = Angle.ang90 ~/ 8;

  var mo = spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);
  if (mo != null) {
    mo.angle = (mo.angle - fatSpread ~/ 2).u32.s32;
    final an = mo.angle >> Angle.angleToFineShift;
    final info = mo.info;
    final speed = info?.speed ?? (20 * Fixed32.fracUnit);
    mo
      ..momX = Fixed32.mul(speed, fineCosine(an))
      ..momY = Fixed32.mul(speed, fineSine(an));
  }

  mo = spawnMissile(actor, target, MobjType.fatShot, level.renderState, level);
  if (mo != null) {
    mo.angle = (mo.angle + fatSpread ~/ 2).u32.s32;
    final an = mo.angle >> Angle.angleToFineShift;
    final info = mo.info;
    final speed = info?.speed ?? (20 * Fixed32.fracUnit);
    mo
      ..momX = Fixed32.mul(speed, fineCosine(an))
      ..momY = Fixed32.mul(speed, fineSine(an));
  }
}

void aPainAttack(Mobj actor, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, level.random);
  _painShootSkull(actor, actor.angle, level);
}

void aPainDie(Mobj actor, LevelLocals level) {
  aFall(actor);
  _painShootSkull(actor, (actor.angle + Angle.ang90).u32.s32, level);
  _painShootSkull(actor, (actor.angle + Angle.ang180).u32.s32, level);
  _painShootSkull(actor, (actor.angle + Angle.ang270).u32.s32, level);
}

void _painShootSkull(Mobj actor, int angle, LevelLocals level) {
  if (countSkulls(level.renderState) > _EnemyConstants.maxSkullCount) {
    return;
  }

  final actorInfo = actor.info;
  final actorRadius = actorInfo?.radius ?? (31 << 16);
  const skullRadius = 16 << 16;

  final prestep = 4 * Fixed32.fracUnit + 3 * (actorRadius + skullRadius) ~/ 2;

  final an = angle.u32 >> Angle.angleToFineShift;
  final x = actor.x + Fixed32.mul(prestep, fineCosine(an));
  final y = actor.y + Fixed32.mul(prestep, fineSine(an));
  final z = actor.z + _EnemyConstants.skullSpawnZ;

  final newMobj = spawnSkull(x, y, z, level.renderState, level);
  if (newMobj == null) return;

  if (!map.tryMove(newMobj, newMobj.x, newMobj.y, level)) {
    inter.damageMobj(newMobj, actor, actor, 10000, level);
    return;
  }

  newMobj.target = actor.target;
  aSkullAttack(newMobj);
}

abstract final class _VileConstants {
  static const int maxRadius = 128 * Fixed32.fracUnit;
  static const int vileRadius = 20 * Fixed32.fracUnit;
  static const int fireDist = 24 * Fixed32.fracUnit;
  static const int vileDamage = 20;
  static const int radiusDamage = 70;
  static const int thrustFactor = 1000 * Fixed32.fracUnit;
}

Mobj? _corpsehit;
LevelLocals? _pitVileCheckLevel;
int _viletryx = 0;
int _viletryy = 0;

bool _pitVileCheck(Mobj thing) {
  if ((thing.flags & MobjFlag.corpse) == 0) return true;
  if (thing.tics != -1) return true;

  final info = thing.info;
  if (info == null || info.raiseState == 0) return true;

  final maxdist = info.radius + _VileConstants.vileRadius;

  if ((thing.x - _viletryx).abs() > maxdist ||
      (thing.y - _viletryy).abs() > maxdist) {
    return true;
  }

  _corpsehit = thing;
  thing
    ..momX = 0
    ..momY = 0;

  final oldHeight = thing.height;
  thing.height = thing.height << 2;
  final check = map.checkPosition(thing, thing.x, thing.y, _pitVileCheckLevel!);
  thing.height = oldHeight;

  if (!check) return true;

  return false;
}

void aVileChase(Mobj actor, LevelLocals level, DoomRandom random) {
  if (actor.moveDir != _MoveDir.noDir) {
    final info = actor.info;
    final speed = info?.speed ?? 15;
    _viletryx = actor.x + speed * _xSpeed[actor.moveDir];
    _viletryy = actor.y + speed * _ySpeed[actor.moveDir];
    _pitVileCheckLevel = level;

    final bm = level.blockmap;
    if (bm != null) {
      final xl = ((_viletryx - bm.originX - _VileConstants.maxRadius * 2) >>
              _mapBlockShift)
          .clamp(0, bm.columns - 1);
      final xh = ((_viletryx - bm.originX + _VileConstants.maxRadius * 2) >>
              _mapBlockShift)
          .clamp(0, bm.columns - 1);
      final yl = ((_viletryy - bm.originY - _VileConstants.maxRadius * 2) >>
              _mapBlockShift)
          .clamp(0, bm.rows - 1);
      final yh = ((_viletryy - bm.originY + _VileConstants.maxRadius * 2) >>
              _mapBlockShift)
          .clamp(0, bm.rows - 1);

      for (var bx = xl; bx <= xh; bx++) {
        for (var by = yl; by <= yh; by++) {
          if (!_blockThingsIterator(bx, by, _pitVileCheck, level)) {
            final corpse = _corpsehit;
            if (corpse != null) {
              final temp = actor.target;
              actor.target = corpse;
              aFaceTarget(actor, random);
              actor.target = temp;

              spec.setMobjStateNum(actor, StateNum.vileHeal1, level);

              final corpseInfo = corpse.info;
              if (corpseInfo != null) {
                spec.setMobjStateNum(corpse, corpseInfo.raiseState, level);
                corpse
                  ..height = corpse.height << 2
                  ..flags = corpseInfo.flags
                  ..health = corpseInfo.spawnHealth
                  ..target = null;
              }
              return;
            }
          }
        }
      }
    }
  }

  aChase(actor, level, random);
}

void aVileStart(Mobj actor) {}

void aVileTarget(Mobj actor, LevelLocals level, DoomRandom random) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  final fog = spawnMobj(
    target.x,
    target.y,
    target.z,
    MobjType.fire,
    level.renderState,
    level,
  );

  if (fog != null) {
    actor.tracer = fog;
    fog
      ..target = actor
      ..tracer = target;
    aFire(fog, level);
  }
}

void aVileAttack(Mobj actor, LevelLocals level, DoomRandom random) {
  final target = actor.target;
  if (target == null) return;

  aFaceTarget(actor, random);

  if (!_checkSight(actor, target, level)) return;

  inter.damageMobj(target, actor, actor, _VileConstants.vileDamage, level);

  final targetInfo = target.info;
  final mass = targetInfo?.mass ?? 100;
  target.momZ = _VileConstants.thrustFactor ~/ mass;

  final an = actor.angle.u32 >> Angle.angleToFineShift;

  final fire = actor.tracer;
  if (fire == null) return;

  fire
    ..x = target.x - Fixed32.mul(_VileConstants.fireDist, fineCosine(an))
    ..y = target.y - Fixed32.mul(_VileConstants.fireDist, fineSine(an));

  spec.radiusAttack(fire, actor, _VileConstants.radiusDamage, level);
}

void aStartFire(Mobj actor, LevelLocals level) {
  aFire(actor, level);
}

void aFireCrackle(Mobj actor, LevelLocals level) {
  aFire(actor, level);
}

void aFire(Mobj actor, LevelLocals level) {
  final dest = actor.tracer;
  if (dest == null) return;

  final vile = actor.target;
  if (vile == null) return;

  if (!_checkSight(vile, dest, level)) return;

  final an = dest.angle.u32 >> Angle.angleToFineShift;

  maputl.unsetThingPosition(actor);
  actor
    ..x = dest.x + Fixed32.mul(_VileConstants.fireDist, fineCosine(an))
    ..y = dest.y + Fixed32.mul(_VileConstants.fireDist, fineSine(an))
    ..z = dest.z;
  maputl.setThingPosition(actor, level.renderState);
}

bool _blockThingsIterator(
  int x,
  int y,
  bool Function(Mobj) func,
  LevelLocals level,
) {
  final bm = level.blockmap;
  final links = level.blockLinks;
  if (bm == null || links == null) return true;

  if (x < 0 || y < 0 || x >= bm.columns || y >= bm.rows) return true;

  final offset = y * bm.columns + x;
  var mobj = links[offset];

  while (mobj != null) {
    if (!func(mobj)) return false;
    mobj = mobj.bNext;
  }

  return true;
}

const int _mapBlockShift = 7;
