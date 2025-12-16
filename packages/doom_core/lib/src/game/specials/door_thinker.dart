import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/specials/move_plane.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class DoorConstants {
  static const int vdoorSpeed = 2 * Fixed32.fracUnit;
  static const int vdoorWait = 150;
}

abstract final class DoorDirection {
  static const int closing = -1;
  static const int waiting = 0;
  static const int opening = 1;
  static const int initialWait = 2;
}

enum DoorType {
  normal,
  close30ThenOpen,
  close,
  open,
  raiseIn5Mins,
  blazeRaise,
  blazeOpen,
  blazeClose,
}

class DoorThinker extends Thinker {
  DoorThinker(this.sector);

  final Sector sector;
  DoorType type = DoorType.normal;
  int topHeight = 0;
  int speed = DoorConstants.vdoorSpeed;
  int direction = DoorDirection.opening;
  int topWait = DoorConstants.vdoorWait;
  int topCountdown = 0;
}

void doorThink(DoorThinker door) {
  switch (door.direction) {
    case DoorDirection.waiting:
      door.topCountdown--;
      if (door.topCountdown <= 0) {
        switch (door.type) {
          case DoorType.blazeRaise:
          case DoorType.normal:
            door.direction = DoorDirection.closing;
          case DoorType.close30ThenOpen:
            door.direction = DoorDirection.opening;
          default:
            break;
        }
      }

    case DoorDirection.initialWait:
      door.topCountdown--;
      if (door.topCountdown <= 0) {
        if (door.type == DoorType.raiseIn5Mins) {
          door.direction = DoorDirection.opening;
          door.type = DoorType.normal;
        }
      }

    case DoorDirection.closing:
      final floorHeight = door.sector.floorHeight;
      final res = movePlane(
        door.sector,
        door.speed,
        floorHeight,
        false,
        1,
        door.direction,
      );

      if (res == MoveResult.pastDest) {
        switch (door.type) {
          case DoorType.blazeRaise:
          case DoorType.blazeClose:
          case DoorType.normal:
          case DoorType.close:
            door.sector.specialData = null;
            door.function = null;
          case DoorType.close30ThenOpen:
            door.direction = DoorDirection.waiting;
            door.topCountdown = 35 * 30;
          default:
            break;
        }
      } else if (res == MoveResult.crushed) {
        switch (door.type) {
          case DoorType.blazeClose:
          case DoorType.close:
            break;
          default:
            door.direction = DoorDirection.opening;
        }
      }

    case DoorDirection.opening:
      final res = movePlane(
        door.sector,
        door.speed,
        door.topHeight,
        false,
        1,
        door.direction,
      );

      if (res == MoveResult.pastDest) {
        switch (door.type) {
          case DoorType.blazeRaise:
          case DoorType.normal:
            door.direction = DoorDirection.waiting;
            door.topCountdown = door.topWait;
          case DoorType.close30ThenOpen:
          case DoorType.blazeOpen:
          case DoorType.open:
            door.sector.specialData = null;
            door.function = null;
          default:
            break;
        }
      }
  }
}

DoorThinker? evDoDoor(Line line, DoorType type, LevelLocals level) {
  final sectors = _findSectorsFromTag(line.tag, level);
  if (sectors.isEmpty) return null;

  DoorThinker? result;

  for (final sector in sectors) {
    if (sector.specialData != null) continue;

    final door = DoorThinker(sector)
      ..type = type
      ..topWait = DoorConstants.vdoorWait
      ..speed = DoorConstants.vdoorSpeed;

    level.thinkers.add(door);
    sector.specialData = door;
    door.function = (_) => doorThink(door);

    switch (type) {
      case DoorType.blazeClose:
      case DoorType.close:
        door.topHeight = findLowestCeilingSurrounding(sector);
        door.topHeight -= 4 << Fixed32.fracBits;
        door.direction = DoorDirection.closing;

      case DoorType.close30ThenOpen:
        door.topHeight = findLowestCeilingSurrounding(sector);
        door.topHeight -= 4 << Fixed32.fracBits;
        door.direction = DoorDirection.closing;

      case DoorType.blazeRaise:
      case DoorType.blazeOpen:
        door.direction = DoorDirection.opening;
        door.topHeight = findLowestCeilingSurrounding(sector);
        door.topHeight -= 4 << Fixed32.fracBits;
        door.speed = DoorConstants.vdoorSpeed * 4;

      case DoorType.normal:
      case DoorType.open:
        door.direction = DoorDirection.opening;
        door.topHeight = findLowestCeilingSurrounding(sector);
        door.topHeight -= 4 << Fixed32.fracBits;

      case DoorType.raiseIn5Mins:
        door.direction = DoorDirection.initialWait;
        door.topHeight = findLowestCeilingSurrounding(sector);
        door.topHeight -= 4 << Fixed32.fracBits;
        door.topCountdown = 35 * 60 * 5;
    }

    result ??= door;
  }

  return result;
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

abstract final class _LineFlags {
  static const int twoSided = 0x04;
}

int findLowestCeilingSurrounding(Sector sector) {
  var height = 0x7FFFFFFF;

  for (final line in sector.lines) {
    final other = getNextSector(line, sector);
    if (other != null) {
      final ceilHeight = other.ceilingHeight;
      if (ceilHeight < height) {
        height = ceilHeight;
      }
    }
  }

  return height;
}

Sector? getNextSector(Line line, Sector sector) {
  if ((line.flags & _LineFlags.twoSided) == 0) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}

void spawnDoorCloseIn30(Sector sector, LevelLocals level) {
  final door = DoorThinker(sector)
    ..type = DoorType.normal
    ..speed = DoorConstants.vdoorSpeed
    ..direction = DoorDirection.waiting
    ..topCountdown = 30 * 35;

  level.thinkers.add(door);
  sector
    ..specialData = door
    ..special = 0;
  door.function = (_) => doorThink(door);
}

void spawnDoorRaiseIn5Mins(Sector sector, LevelLocals level) {
  final door = DoorThinker(sector)
    ..type = DoorType.raiseIn5Mins
    ..speed = DoorConstants.vdoorSpeed
    ..direction = DoorDirection.initialWait
    ..topHeight = findLowestCeilingSurrounding(sector) - (4 << Fixed32.fracBits)
    ..topWait = DoorConstants.vdoorWait
    ..topCountdown = 5 * 60 * 35;

  level.thinkers.add(door);
  sector
    ..specialData = door
    ..special = 0;
  door.function = (_) => doorThink(door);
}
