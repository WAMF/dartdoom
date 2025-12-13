import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/specials/move_plane.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class CeilingConstants {
  static const int ceilingSpeed = Fixed32.fracUnit;
  static const int maxCeilings = 30;
}

abstract final class CeilingDirection {
  static const int down = -1;
  static const int stasis = 0;
  static const int up = 1;
}

enum CeilingType {
  lowerToFloor,
  raiseToHighest,
  lowerAndCrush,
  crushAndRaise,
  fastCrushAndRaise,
  silentCrushAndRaise,
}

class CeilingThinker extends Thinker {
  CeilingThinker(this.sector);

  final Sector sector;
  CeilingType type = CeilingType.lowerToFloor;
  int bottomHeight = 0;
  int topHeight = 0;
  int speed = CeilingConstants.ceilingSpeed;
  int direction = CeilingDirection.down;
  int oldDirection = CeilingDirection.down;
  bool crush = false;
  int tag = 0;
}

class ActiveCeilings {
  final List<CeilingThinker?> _ceilings =
      List.filled(CeilingConstants.maxCeilings, null);

  void add(CeilingThinker ceiling) {
    for (var i = 0; i < CeilingConstants.maxCeilings; i++) {
      if (_ceilings[i] == null) {
        _ceilings[i] = ceiling;
        return;
      }
    }
  }

  void remove(CeilingThinker ceiling) {
    for (var i = 0; i < CeilingConstants.maxCeilings; i++) {
      if (_ceilings[i] == ceiling) {
        _ceilings[i]?.sector.specialData = null;
        _ceilings[i]?.function = null;
        _ceilings[i] = null;
        break;
      }
    }
  }

  void activateInStasis(int tag) {
    for (var i = 0; i < CeilingConstants.maxCeilings; i++) {
      final ceiling = _ceilings[i];
      if (ceiling != null &&
          ceiling.tag == tag &&
          ceiling.direction == CeilingDirection.stasis) {
        ceiling.direction = ceiling.oldDirection;
      }
    }
  }

  bool stopCrush(int tag) {
    var result = false;
    for (var i = 0; i < CeilingConstants.maxCeilings; i++) {
      final ceiling = _ceilings[i];
      if (ceiling != null &&
          ceiling.tag == tag &&
          ceiling.direction != CeilingDirection.stasis) {
        ceiling
          ..oldDirection = ceiling.direction
          ..direction = CeilingDirection.stasis
          ..function = null;
        result = true;
      }
    }
    return result;
  }
}

void ceilingThink(CeilingThinker ceiling, ActiveCeilings activeCeilings) {
  switch (ceiling.direction) {
    case CeilingDirection.stasis:
      break;

    case CeilingDirection.up:
      final res = movePlane(
        ceiling.sector,
        ceiling.speed,
        ceiling.topHeight,
        false,
        1,
        ceiling.direction,
      );

      if (res == MoveResult.pastDest) {
        switch (ceiling.type) {
          case CeilingType.raiseToHighest:
            activeCeilings.remove(ceiling);

          case CeilingType.silentCrushAndRaise:
          case CeilingType.fastCrushAndRaise:
          case CeilingType.crushAndRaise:
            ceiling.direction = CeilingDirection.down;

          case CeilingType.lowerToFloor:
          case CeilingType.lowerAndCrush:
            break;
        }
      }

    case CeilingDirection.down:
      final res = movePlane(
        ceiling.sector,
        ceiling.speed,
        ceiling.bottomHeight,
        ceiling.crush,
        1,
        ceiling.direction,
      );

      if (res == MoveResult.pastDest) {
        switch (ceiling.type) {
          case CeilingType.silentCrushAndRaise:
          case CeilingType.crushAndRaise:
            ceiling
              ..speed = CeilingConstants.ceilingSpeed
              ..direction = CeilingDirection.up;

          case CeilingType.fastCrushAndRaise:
            ceiling.direction = CeilingDirection.up;

          case CeilingType.lowerAndCrush:
          case CeilingType.lowerToFloor:
            activeCeilings.remove(ceiling);

          case CeilingType.raiseToHighest:
            break;
        }
      } else if (res == MoveResult.crushed) {
        switch (ceiling.type) {
          case CeilingType.silentCrushAndRaise:
          case CeilingType.crushAndRaise:
          case CeilingType.lowerAndCrush:
            ceiling.speed = CeilingConstants.ceilingSpeed ~/ 8;

          case CeilingType.fastCrushAndRaise:
          case CeilingType.lowerToFloor:
          case CeilingType.raiseToHighest:
            break;
        }
      }
  }
}

bool evDoCeiling(
  Line line,
  CeilingType type,
  LevelLocals level,
  ActiveCeilings activeCeilings,
) {
  switch (type) {
    case CeilingType.fastCrushAndRaise:
    case CeilingType.silentCrushAndRaise:
    case CeilingType.crushAndRaise:
      activeCeilings.activateInStasis(line.tag);
    case CeilingType.lowerToFloor:
    case CeilingType.lowerAndCrush:
    case CeilingType.raiseToHighest:
      break;
  }

  final sectors = _findSectorsFromTag(line.tag, level);
  if (sectors.isEmpty) return false;

  var result = false;

  for (final sector in sectors) {
    if (sector.specialData != null) continue;

    result = true;
    final ceiling = CeilingThinker(sector)..crush = false;

    level.thinkers.add(ceiling);
    sector.specialData = ceiling;
    ceiling.function =
        (_) => ceilingThink(ceiling, activeCeilings);

    switch (type) {
      case CeilingType.fastCrushAndRaise:
        ceiling
          ..crush = true
          ..topHeight = sector.ceilingHeight
          ..bottomHeight = sector.floorHeight + 8 * Fixed32.fracUnit
          ..direction = CeilingDirection.down
          ..speed = CeilingConstants.ceilingSpeed * 2;

      case CeilingType.silentCrushAndRaise:
      case CeilingType.crushAndRaise:
        ceiling
          ..crush = true
          ..topHeight = sector.ceilingHeight
          ..bottomHeight = sector.floorHeight + 8 * Fixed32.fracUnit
          ..direction = CeilingDirection.down
          ..speed = CeilingConstants.ceilingSpeed;

      case CeilingType.lowerAndCrush:
        ceiling
          ..bottomHeight = sector.floorHeight + 8 * Fixed32.fracUnit
          ..direction = CeilingDirection.down
          ..speed = CeilingConstants.ceilingSpeed;

      case CeilingType.lowerToFloor:
        ceiling
          ..bottomHeight = sector.floorHeight
          ..direction = CeilingDirection.down
          ..speed = CeilingConstants.ceilingSpeed;

      case CeilingType.raiseToHighest:
        ceiling
          ..topHeight = _findHighestCeilingSurrounding(sector)
          ..direction = CeilingDirection.up
          ..speed = CeilingConstants.ceilingSpeed;
    }

    ceiling
      ..tag = sector.tag
      ..type = type;
    activeCeilings.add(ceiling);
  }

  return result;
}

bool evCeilingCrushStop(Line line, ActiveCeilings activeCeilings) {
  return activeCeilings.stopCrush(line.tag);
}

List<Sector> _findSectorsFromTag(int tag, LevelLocals level) {
  final result = <Sector>[];
  for (final sector in level.renderState.sectors) {
    if (sector.tag == tag) {
      result.add(sector);
    }
  }
  return result;
}

int _findHighestCeilingSurrounding(Sector sector) {
  var height = -500 * Fixed32.fracUnit;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null && other.ceilingHeight > height) {
      height = other.ceilingHeight;
    }
  }

  return height;
}

Sector? _getNextSector(Line line, Sector sector) {
  if ((line.flags & _LineFlags.twoSided) == 0) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}

abstract final class _LineFlags {
  static const int twoSided = 0x04;
}
