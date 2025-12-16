import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/specials/move_plane.dart';
import 'package:doom_core/src/game/thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class PlatConstants {
  static const int platSpeed = Fixed32.fracUnit;
  static const int platWait = 3;
  static const int maxPlatforms = 30;
}

enum PlatStatus {
  up,
  down,
  waiting,
  inStasis,
}

enum PlatType {
  raiseToNearestAndChange,
  raiseAndChange,
  downWaitUpStay,
  blazeDWUS,
  perpetualRaise,
}

class PlatThinker extends Thinker {
  PlatThinker(this.sector);

  final Sector sector;
  int speed = PlatConstants.platSpeed;
  int low = 0;
  int high = 0;
  int wait = 0;
  int count = 0;
  PlatStatus status = PlatStatus.up;
  PlatStatus oldStatus = PlatStatus.up;
  PlatType type = PlatType.downWaitUpStay;
  bool crush = false;
  int tag = 0;
}

class ActivePlatforms {
  final List<PlatThinker?> _platforms =
      List.filled(PlatConstants.maxPlatforms, null);

  void add(PlatThinker plat) {
    for (var i = 0; i < PlatConstants.maxPlatforms; i++) {
      if (_platforms[i] == null) {
        _platforms[i] = plat;
        return;
      }
    }
  }

  void remove(PlatThinker plat) {
    for (var i = 0; i < PlatConstants.maxPlatforms; i++) {
      if (_platforms[i] == plat) {
        _platforms[i]?.sector.specialData = null;
        _platforms[i]?.function = null;
        _platforms[i] = null;
        break;
      }
    }
  }

  void activateInStasis(int tag, LevelLocals level) {
    for (var i = 0; i < PlatConstants.maxPlatforms; i++) {
      final plat = _platforms[i];
      if (plat != null &&
          plat.tag == tag &&
          plat.status == PlatStatus.inStasis) {
        plat.status = plat.oldStatus;
        plat.function = (_) => platThink(plat, level);
      }
    }
  }

  bool stopPlat(int tag) {
    var result = false;
    for (var i = 0; i < PlatConstants.maxPlatforms; i++) {
      final plat = _platforms[i];
      if (plat != null &&
          plat.tag == tag &&
          plat.status != PlatStatus.inStasis) {
        plat
          ..oldStatus = plat.status
          ..status = PlatStatus.inStasis
          ..function = null;
        result = true;
      }
    }
    return result;
  }
}

void platThink(PlatThinker plat, LevelLocals level) {
  switch (plat.status) {
    case PlatStatus.up:
      final res = movePlane(
        plat.sector,
        plat.speed,
        plat.high,
        plat.crush,
        0,
        1,
        level: level,
      );

      if (res == MoveResult.crushed && !plat.crush) {
        plat.count = plat.wait;
        plat.status = PlatStatus.down;
      } else if (res == MoveResult.pastDest) {
        plat.count = plat.wait;
        plat.status = PlatStatus.waiting;

        switch (plat.type) {
          case PlatType.blazeDWUS:
          case PlatType.downWaitUpStay:
          case PlatType.raiseAndChange:
          case PlatType.raiseToNearestAndChange:
            plat.sector.specialData = null;
            plat.function = null;
          default:
            break;
        }
      }

    case PlatStatus.down:
      final res = movePlane(
        plat.sector,
        plat.speed,
        plat.low,
        false,
        0,
        -1,
        level: level,
      );

      if (res == MoveResult.pastDest) {
        plat.count = plat.wait;
        plat.status = PlatStatus.waiting;
      }

    case PlatStatus.waiting:
      plat.count--;
      if (plat.count <= 0) {
        if (plat.sector.floorHeight == plat.low) {
          plat.status = PlatStatus.up;
        } else {
          plat.status = PlatStatus.down;
        }
      }

    case PlatStatus.inStasis:
      break;
  }
}

PlatThinker? evDoPlat(
  Line line,
  PlatType type,
  int amount,
  LevelLocals level,
) {
  final sectors = _findSectorsFromTag(line.tag, level);
  if (sectors.isEmpty) return null;

  PlatThinker? result;

  for (final sector in sectors) {
    if (sector.specialData != null) continue;

    final plat = PlatThinker(sector)
      ..type = type
      ..crush = false
      ..tag = line.tag;

    level.thinkers.add(plat);
    sector.specialData = plat;
    plat.function = (_) => platThink(plat, level);

    switch (type) {
      case PlatType.raiseToNearestAndChange:
        plat.speed = PlatConstants.platSpeed ~/ 2;
        plat.high = _findNextHighestFloor(sector);
        plat.wait = 0;
        plat.status = PlatStatus.up;
        sector.special = 0;

      case PlatType.raiseAndChange:
        plat.speed = PlatConstants.platSpeed ~/ 2;
        plat.high = sector.floorHeight + amount * Fixed32.fracUnit;
        plat.wait = 0;
        plat.status = PlatStatus.up;

      case PlatType.downWaitUpStay:
        plat.speed = PlatConstants.platSpeed * 4;
        plat.low = _findLowestFloorSurrounding(sector);
        if (plat.low > sector.floorHeight) {
          plat.low = sector.floorHeight;
        }
        plat.high = sector.floorHeight;
        plat.wait = 35 * PlatConstants.platWait;
        plat.status = PlatStatus.down;

      case PlatType.blazeDWUS:
        plat.speed = PlatConstants.platSpeed * 8;
        plat.low = _findLowestFloorSurrounding(sector);
        if (plat.low > sector.floorHeight) {
          plat.low = sector.floorHeight;
        }
        plat.high = sector.floorHeight;
        plat.wait = 35 * PlatConstants.platWait;
        plat.status = PlatStatus.down;

      case PlatType.perpetualRaise:
        plat.speed = PlatConstants.platSpeed;
        plat.low = _findLowestFloorSurrounding(sector);
        if (plat.low > sector.floorHeight) {
          plat.low = sector.floorHeight;
        }
        plat.high = _findHighestFloorSurrounding(sector);
        if (plat.high < sector.floorHeight) {
          plat.high = sector.floorHeight;
        }
        plat.wait = 35 * PlatConstants.platWait;
        plat.status = PlatStatus.down;
    }

    result ??= plat;
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
    if (other != null) {
      if (other.floorHeight < floor) {
        floor = other.floorHeight;
      }
    }
  }

  return floor;
}

int _findHighestFloorSurrounding(Sector sector) {
  var floor = -500 * Fixed32.fracUnit;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null) {
      if (other.floorHeight > floor) {
        floor = other.floorHeight;
      }
    }
  }

  return floor;
}

int _findNextHighestFloor(Sector sector) {
  final currentFloor = sector.floorHeight;
  var height = 0x7FFFFFFF;

  for (final line in sector.lines) {
    final other = _getNextSector(line, sector);
    if (other != null) {
      if (other.floorHeight > currentFloor && other.floorHeight < height) {
        height = other.floorHeight;
      }
    }
  }

  return height;
}

Sector? _getNextSector(Line line, Sector sector) {
  if ((line.flags & 0x04) == 0) return null;

  if (line.frontSector == sector) {
    return line.backSector;
  }
  return line.frontSector;
}

bool evStopPlat(Line line, LevelLocals level, ActivePlatforms activePlatforms) {
  return activePlatforms.stopPlat(line.tag);
}
