import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/p_map.dart' as map;
import 'package:doom_core/src/render/r_defs.dart';

enum MoveResult {
  ok,
  crushed,
  pastDest,
}

MoveResult movePlane(
  Sector sector,
  int speed,
  int dest,
  bool crush,
  int floorOrCeiling,
  int direction, {
  LevelLocals? level,
}) {
  switch (floorOrCeiling) {
    case 0:
      return _moveFloor(sector, speed, dest, crush, direction, level);
    case 1:
      return _moveCeiling(sector, speed, dest, crush, direction, level);
    default:
      return MoveResult.ok;
  }
}

MoveResult _moveFloor(
  Sector sector,
  int speed,
  int dest,
  bool crush,
  int direction,
  LevelLocals? level,
) {
  switch (direction) {
    case -1:
      if (sector.floorHeight - speed < dest) {
        final lastPos = sector.floorHeight;
        sector.floorHeight = dest;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.floorHeight = lastPos;
          map.changeSector(sector, crush, level);
        }
        return MoveResult.pastDest;
      } else {
        final lastPos = sector.floorHeight;
        sector.floorHeight -= speed;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.floorHeight = lastPos;
          map.changeSector(sector, crush, level);
          return MoveResult.crushed;
        }
      }

    case 1:
      if (sector.floorHeight + speed > dest) {
        final lastPos = sector.floorHeight;
        sector.floorHeight = dest;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.floorHeight = lastPos;
          map.changeSector(sector, crush, level);
        }
        return MoveResult.pastDest;
      } else {
        final lastPos = sector.floorHeight;
        sector.floorHeight += speed;
        if (level != null && map.changeSector(sector, crush, level)) {
          if (crush) {
            return MoveResult.crushed;
          }
          sector.floorHeight = lastPos;
          map.changeSector(sector, crush, level);
          return MoveResult.crushed;
        }
      }
  }

  return MoveResult.ok;
}

MoveResult _moveCeiling(
  Sector sector,
  int speed,
  int dest,
  bool crush,
  int direction,
  LevelLocals? level,
) {
  switch (direction) {
    case -1:
      if (sector.ceilingHeight - speed < dest) {
        final lastPos = sector.ceilingHeight;
        sector.ceilingHeight = dest;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.ceilingHeight = lastPos;
          map.changeSector(sector, crush, level);
        }
        return MoveResult.pastDest;
      } else {
        final lastPos = sector.ceilingHeight;
        sector.ceilingHeight -= speed;
        if (level != null && map.changeSector(sector, crush, level)) {
          if (crush) {
            return MoveResult.crushed;
          }
          sector.ceilingHeight = lastPos;
          map.changeSector(sector, crush, level);
          return MoveResult.crushed;
        }
      }

    case 1:
      if (sector.ceilingHeight + speed > dest) {
        final lastPos = sector.ceilingHeight;
        sector.ceilingHeight = dest;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.ceilingHeight = lastPos;
          map.changeSector(sector, crush, level);
        }
        return MoveResult.pastDest;
      } else {
        final lastPos = sector.ceilingHeight;
        sector.ceilingHeight += speed;
        if (level != null && map.changeSector(sector, crush, level)) {
          sector.ceilingHeight = lastPos;
          map.changeSector(sector, crush, level);
          return MoveResult.crushed;
        }
      }
  }

  return MoveResult.ok;
}
