import 'dart:math' as math;

import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_math/doom_math.dart';

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
  static const int numDirs = 9;
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

void lookForPlayers(Mobj actor, LevelLocals level) {
  if (level.players.isEmpty) return;

  final player = level.players[0];
  final playerMobj = player.mobj;
  if (playerMobj == null) return;

  if (player.health <= 0) return;

  if (!_checkSight(actor, playerMobj, level)) return;

  actor.target = playerMobj;
  actor.threshold = 60;
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

  if (!_checkMeleeRange(actor, target)) {
    if (actor.reactionTime == 0) {
      _newChaseDir(actor, target, level);
    }
  }

  _move(actor, level);
}

bool _checkMeleeRange(Mobj actor, Mobj target) {
  final dist = _approxDistance(target.x - actor.x, target.y - actor.y);
  return dist < (64 * Fixed32.fracUnit) + actor.info!.radius;
}

bool _checkSight(Mobj actor, Mobj target, LevelLocals level) {
  final dx = (target.x - actor.x).abs();
  final dy = (target.y - actor.y).abs();
  final dist = math.max(dx, dy);

  if (dist > 2048 * Fixed32.fracUnit) {
    return false;
  }

  return true;
}

void _newChaseDir(Mobj actor, Mobj target, LevelLocals level) {
  final oldDir = actor.moveDir;
  final turnaround = _opposite[oldDir];

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
    if (actor.moveDir != turnaround && _tryWalk(actor, level)) {
      return;
    }
  }

  if (dx.abs() > dy.abs()) {
    final swap = d1;
    d1 = d2;
    d2 = swap;
  }

  if (d1 != _MoveDir.noDir && d1 != turnaround) {
    actor.moveDir = d1;
    if (_tryWalk(actor, level)) return;
  }

  if (d2 != _MoveDir.noDir && d2 != turnaround) {
    actor.moveDir = d2;
    if (_tryWalk(actor, level)) return;
  }

  if (oldDir != _MoveDir.noDir) {
    actor.moveDir = oldDir;
    if (_tryWalk(actor, level)) return;
  }

  for (var dir = _MoveDir.east; dir <= _MoveDir.southeast; dir++) {
    if (dir != turnaround) {
      actor.moveDir = dir;
      if (_tryWalk(actor, level)) return;
    }
  }

  if (turnaround != _MoveDir.noDir) {
    actor.moveDir = turnaround;
    if (_tryWalk(actor, level)) return;
  }

  actor.moveDir = _MoveDir.noDir;
}

bool _tryWalk(Mobj actor, LevelLocals level) {
  if (actor.moveDir == _MoveDir.noDir) return false;

  return true;
}

void _move(Mobj actor, LevelLocals level) {
  if (actor.moveDir == _MoveDir.noDir) return;

  final speed = actor.info?.speed ?? 0;
  actor.momX = Fixed32.mul(speed, _xSpeed[actor.moveDir]);
  actor.momY = Fixed32.mul(speed, _ySpeed[actor.moveDir]);
}

int _approxDistance(int dx, int dy) {
  final adx = dx.abs();
  final ady = dy.abs();
  return adx + ady - (math.min(adx, ady) >> 1);
}

void attackMelee(Mobj actor, int damage, LevelLocals level) {
  final target = actor.target;
  if (target == null) return;

  if (!_checkMeleeRange(actor, target)) return;

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

int _pointToAngle(int x1, int y1, int x2, int y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;

  if (dx == 0 && dy == 0) return 0;

  final angle = (math.atan2(dy.toDouble(), dx.toDouble()) * (0x80000000 / math.pi)).toInt();
  return angle;
}
