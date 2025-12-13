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
  int direction,
) {
  switch (floorOrCeiling) {
    case 0:
      return _moveFloor(sector, speed, dest, crush, direction);
    case 1:
      return _moveCeiling(sector, speed, dest, crush, direction);
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
) {
  switch (direction) {
    case -1:
      if (sector.floorHeight - speed < dest) {
        sector.floorHeight = dest;
        return MoveResult.pastDest;
      }
      sector.floorHeight -= speed;
      return MoveResult.ok;

    case 1:
      if (sector.floorHeight + speed > dest) {
        sector.floorHeight = dest;
        return MoveResult.pastDest;
      }
      sector.floorHeight += speed;
      return MoveResult.ok;
  }

  return MoveResult.ok;
}

MoveResult _moveCeiling(
  Sector sector,
  int speed,
  int dest,
  bool crush,
  int direction,
) {
  switch (direction) {
    case -1:
      if (sector.ceilingHeight - speed < dest) {
        sector.ceilingHeight = dest;
        return MoveResult.pastDest;
      }
      sector.ceilingHeight -= speed;
      return MoveResult.ok;

    case 1:
      if (sector.ceilingHeight + speed > dest) {
        sector.ceilingHeight = dest;
        return MoveResult.pastDest;
      }
      sector.ceilingHeight += speed;
      return MoveResult.ok;
  }

  return MoveResult.ok;
}
