import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/specials/move_plane.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class FloorConstants {
  static const int floorSpeed = Fixed32.fracUnit;
}

abstract final class FloorDirection {
  static const int down = -1;
  static const int up = 1;
}

enum FloorType {
  lowerFloor,
  lowerFloorToLowest,
  turboLower,
  raiseFloor,
  raiseFloorToNearest,
  raiseFloor24,
  raiseFloor512,
  raiseFloorCrush,
  raiseFloor24AndChange,
  raiseToTexture,
  lowerAndChange,
  raiseFloorTurbo,
  donutRaise,
}

enum StairType {
  build8,
  turbo16,
}

class FloorThinker extends Thinker {
  FloorThinker(this.sector);

  final Sector sector;
  FloorType type = FloorType.lowerFloor;
  bool crush = false;
  int direction = FloorDirection.down;
  int newSpecial = 0;
  int texture = 0;
  int floorDestHeight = 0;
  int speed = FloorConstants.floorSpeed;
}

void floorThink(FloorThinker floor, LevelLocals level) {
  final res = movePlane(
    floor.sector,
    floor.speed,
    floor.floorDestHeight,
    floor.crush,
    0,
    floor.direction,
  );

  if (res == MoveResult.pastDest) {
    floor.sector.specialData = null;

    if (floor.direction == FloorDirection.up) {
      if (floor.type == FloorType.donutRaise) {
        floor.sector
          ..special = floor.newSpecial
          ..floorPic = floor.texture;
      }
    } else if (floor.direction == FloorDirection.down) {
      if (floor.type == FloorType.lowerAndChange) {
        floor.sector
          ..special = floor.newSpecial
          ..floorPic = floor.texture;
      }
    }

    floor.function = null;
  }
}

bool evDoFloor(Line line, FloorType floorType, LevelLocals level) {
  final sectors = _findSectorsFromTag(line.tag, level);
  if (sectors.isEmpty) return false;

  var result = false;

  for (final sector in sectors) {
    if (sector.specialData != null) continue;

    result = true;
    final floor = FloorThinker(sector)
      ..type = floorType
      ..crush = false;

    level.thinkers.add(floor);
    sector.specialData = floor;
    floor.function = (_) => floorThink(floor, level);

    switch (floorType) {
      case FloorType.lowerFloor:
        floor
          ..direction = FloorDirection.down
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findHighestFloorSurrounding(sector);

      case FloorType.lowerFloorToLowest:
        floor
          ..direction = FloorDirection.down
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findLowestFloorSurrounding(sector);

      case FloorType.turboLower:
        floor
          ..direction = FloorDirection.down
          ..speed = FloorConstants.floorSpeed * 4
          ..floorDestHeight = _findHighestFloorSurrounding(sector);
        if (floor.floorDestHeight != sector.floorHeight) {
          floor.floorDestHeight += 8 * Fixed32.fracUnit;
        }

      case FloorType.raiseFloorCrush:
        floor
          ..crush = true
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findLowestCeilingSurrounding(sector);
        if (floor.floorDestHeight > sector.ceilingHeight) {
          floor.floorDestHeight = sector.ceilingHeight;
        }
        floor.floorDestHeight -= 8 * Fixed32.fracUnit;

      case FloorType.raiseFloor:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findLowestCeilingSurrounding(sector);
        if (floor.floorDestHeight > sector.ceilingHeight) {
          floor.floorDestHeight = sector.ceilingHeight;
        }

      case FloorType.raiseFloorTurbo:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed * 4
          ..floorDestHeight = _findNextHighestFloor(sector);

      case FloorType.raiseFloorToNearest:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findNextHighestFloor(sector);

      case FloorType.raiseFloor24:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = sector.floorHeight + 24 * Fixed32.fracUnit;

      case FloorType.raiseFloor512:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = sector.floorHeight + 512 * Fixed32.fracUnit;

      case FloorType.raiseFloor24AndChange:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = sector.floorHeight + 24 * Fixed32.fracUnit;
        final frontSector = line.frontSector;
        if (frontSector != null) {
          sector
            ..floorPic = frontSector.floorPic
            ..special = frontSector.special;
        }

      case FloorType.raiseToTexture:
        floor
          ..direction = FloorDirection.up
          ..speed = FloorConstants.floorSpeed;
        var minSize = 0x7FFFFFFF;
        for (final secLine in sector.lines) {
          if (_isTwoSided(secLine)) {
            final side0 = secLine.sideNum[0] >= 0
                ? level.renderState.sides[secLine.sideNum[0]]
                : null;
            final side1 = secLine.sideNum[1] >= 0
                ? level.renderState.sides[secLine.sideNum[1]]
                : null;

            if (side0 != null && side0.bottomTexture >= 0) {
              final texHeight =
                  _getTextureHeight(side0.bottomTexture, level);
              if (texHeight < minSize) {
                minSize = texHeight;
              }
            }
            if (side1 != null && side1.bottomTexture >= 0) {
              final texHeight =
                  _getTextureHeight(side1.bottomTexture, level);
              if (texHeight < minSize) {
                minSize = texHeight;
              }
            }
          }
        }
        floor.floorDestHeight = sector.floorHeight + minSize;

      case FloorType.lowerAndChange:
        floor
          ..direction = FloorDirection.down
          ..speed = FloorConstants.floorSpeed
          ..floorDestHeight = _findLowestFloorSurrounding(sector)
          ..texture = sector.floorPic;
        for (final secLine in sector.lines) {
          if (_isTwoSided(secLine)) {
            final otherSector = _getNextSector(secLine, sector);
            if (otherSector != null &&
                otherSector.floorHeight == floor.floorDestHeight) {
              floor
                ..texture = otherSector.floorPic
                ..newSpecial = otherSector.special;
              break;
            }
          }
        }

      case FloorType.donutRaise:
        break;
    }
  }

  return result;
}

bool evBuildStairs(Line line, StairType type, LevelLocals level) {
  final sectors = _findSectorsFromTag(line.tag, level);
  if (sectors.isEmpty) return false;

  var result = false;

  int speed;
  int stairSize;

  switch (type) {
    case StairType.build8:
      speed = FloorConstants.floorSpeed ~/ 4;
      stairSize = 8 * Fixed32.fracUnit;
    case StairType.turbo16:
      speed = FloorConstants.floorSpeed * 4;
      stairSize = 16 * Fixed32.fracUnit;
  }

  for (var sector in sectors) {
    if (sector.specialData != null) continue;

    result = true;
    final floor = FloorThinker(sector)
      ..direction = FloorDirection.up
      ..speed = speed;

    level.thinkers.add(floor);
    sector.specialData = floor;
    floor.function = (_) => floorThink(floor, level);

    var height = sector.floorHeight + stairSize;
    floor.floorDestHeight = height;

    final texture = sector.floorPic;

    var ok = true;
    while (ok) {
      ok = false;
      for (final secLine in sector.lines) {
        if (!_isTwoSided(secLine)) continue;

        final frontSector = secLine.frontSector;
        if (frontSector != sector) continue;

        final backSector = secLine.backSector;
        if (backSector == null) continue;
        if (backSector.floorPic != texture) continue;

        height += stairSize;

        if (backSector.specialData != null) continue;

        sector = backSector;
        final nextFloor = FloorThinker(sector)
          ..direction = FloorDirection.up
          ..speed = speed
          ..floorDestHeight = height;

        level.thinkers.add(nextFloor);
        sector.specialData = nextFloor;
        nextFloor.function = (_) => floorThink(nextFloor, level);

        ok = true;
        break;
      }
    }
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

int _findLowestFloorSurrounding(Sector sector) {
  var floor = sector.floorHeight;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null && other.floorHeight < floor) {
      floor = other.floorHeight;
    }
  }

  return floor;
}

int _findHighestFloorSurrounding(Sector sector) {
  var floor = -500 * Fixed32.fracUnit;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null && other.floorHeight > floor) {
      floor = other.floorHeight;
    }
  }

  return floor;
}

int _findLowestCeilingSurrounding(Sector sector) {
  var height = 0x7FFFFFFF;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null && other.ceilingHeight < height) {
      height = other.ceilingHeight;
    }
  }

  return height;
}

int _findNextHighestFloor(Sector sector) {
  final currentFloor = sector.floorHeight;
  var height = 0x7FFFFFFF;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null &&
        other.floorHeight > currentFloor &&
        other.floorHeight < height) {
      height = other.floorHeight;
    }
  }

  if (height == 0x7FFFFFFF) {
    return currentFloor;
  }

  return height;
}

bool _isTwoSided(Line line) {
  return (line.flags & _LineFlags.twoSided) != 0;
}

Sector? _getNextSector(Line line, Sector sector) {
  if (!_isTwoSided(line)) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}

int _getTextureHeight(int textureNum, LevelLocals level) {
  final textureHeight = level.renderState.textureHeight;
  if (textureNum < 0 || textureNum >= textureHeight.length) {
    return 0;
  }
  return textureHeight[textureNum];
}

abstract final class _LineFlags {
  static const int twoSided = 0x04;
}
