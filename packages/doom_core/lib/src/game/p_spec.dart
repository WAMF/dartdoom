import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/specials/door_thinker.dart';
import 'package:doom_core/src/game/specials/plat_thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';

abstract final class _LineSpecial {
  static const int manualDoor = 1;
  static const int openDoor = 31;

  static const int switchDoor = 29;
  static const int switchDoorOpen = 103;
  static const int switchDoorClose = 50;
  static const int switchDoorBlazeRaise = 111;
  static const int switchDoorBlazeOpen = 112;
  static const int switchDoorBlazeClose = 113;

  static const int switchPlatDown = 21;
  static const int switchPlatRaise = 20;
  static const int switchPlatRaise24 = 15;
  static const int switchPlatRaise32 = 14;
}

void useSpecialLine(Mobj thing, Line line, int side, LevelLocals level) {
  if (side != 0) {
    return;
  }

  switch (line.special) {
    case _LineSpecial.manualDoor:
    case _LineSpecial.openDoor:
      evVerticalDoor(line, thing, level);

    case _LineSpecial.switchDoor:
      if (evDoDoor(line, DoorType.normal, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchDoorOpen:
      if (evDoDoor(line, DoorType.open, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchDoorClose:
      if (evDoDoor(line, DoorType.close, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchDoorBlazeRaise:
      if (evDoDoor(line, DoorType.blazeRaise, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchDoorBlazeOpen:
      if (evDoDoor(line, DoorType.blazeOpen, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchDoorBlazeClose:
      if (evDoDoor(line, DoorType.blazeClose, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchPlatDown:
      if (evDoPlat(line, PlatType.downWaitUpStay, 0, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchPlatRaise:
      if (evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchPlatRaise24:
      if (evDoPlat(line, PlatType.raiseAndChange, 24, level) != null) {
        changeSwitchTexture(line, false);
      }

    case _LineSpecial.switchPlatRaise32:
      if (evDoPlat(line, PlatType.raiseAndChange, 32, level) != null) {
        changeSwitchTexture(line, false);
      }
  }
}

void evVerticalDoor(Line line, Mobj thing, LevelLocals level) {
  final sector = line.backSector;
  if (sector == null) return;

  if (sector.specialData != null) {
    final door = sector.specialData;
    if (door is DoorThinker) {
      switch (line.special) {
        case _LineSpecial.manualDoor:
        case _LineSpecial.openDoor:
          if (door.direction == DoorDirection.closing) {
            door.direction = DoorDirection.opening;
          } else if (door.direction == DoorDirection.opening) {
            door.direction = DoorDirection.closing;
          }
      }
    }
    return;
  }

  final door = evDoDoor(line, DoorType.normal, level);
  if (door != null) {
    door.direction = DoorDirection.opening;
  }
}

void crossSpecialLine(Line line, Mobj thing, LevelLocals level) {
  // TODO: implement walk-over triggers
}

void changeSwitchTexture(Line line, bool useAgain) {
  // TODO: implement switch texture change
}

void spawnSpecials(LevelLocals level) {
  for (final sector in level.renderState.sectors) {
    switch (sector.special) {
      case 1:
      case 2:
      case 3:
      case 4:
      case 5:
      case 7:
      case 8:
      case 9:
      case 10:
      case 11:
      case 12:
      case 13:
      case 14:
      case 16:
      case 17:
        break;
    }
  }

  for (final line in level.renderState.lines) {
    switch (line.special) {
      case 48:
        break;
    }
  }
}
