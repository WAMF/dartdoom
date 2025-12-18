import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_enemy.dart' as enemy;
import 'package:doom_core/src/game/p_inter.dart' as inter;
import 'package:doom_core/src/game/p_pspr.dart' as pspr;
import 'package:doom_core/src/game/p_sight.dart' as sight;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/game/specials/ceiling_thinker.dart';
import 'package:doom_core/src/game/specials/door_thinker.dart';
import 'package:doom_core/src/game/specials/floor_thinker.dart';
import 'package:doom_core/src/game/specials/light_thinker.dart';
import 'package:doom_core/src/game/specials/plat_thinker.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _LineSpecial {
  static const int manualDoor = 1;
  static const int blueDoorManual = 26;
  static const int yellowDoorManual = 27;
  static const int redDoorManual = 28;
  static const int openDoor = 31;
  static const int blueDoorOpen = 32;
  static const int redDoorOpen = 33;
  static const int yellowDoorOpen = 34;
  static const int blazeDoorRaise = 117;
  static const int blazeDoorOpen = 118;

  static const int switchBuildStairs = 7;
  static const int switchDonut = 9;
  static const int switchExit = 11;
  static const int switchPlatRaise32 = 14;
  static const int switchPlatRaise24 = 15;
  static const int switchFloorRaiseNearest = 18;
  static const int switchPlatRaise = 20;
  static const int switchPlatDown = 21;
  static const int switchFloorLowerToLowest = 23;
  static const int switchDoor = 29;
  static const int switchLowerCeilingToFloor = 41;
  static const int switchCeilingCrush = 49;
  static const int switchDoorClose = 50;
  static const int switchSecretExit = 51;
  static const int switchRaiseFloorCrush = 55;
  static const int switchTurboLower = 71;
  static const int switchRaiseFloor = 101;
  static const int switchLowerFloor = 102;
  static const int switchDoorOpen = 103;
  static const int switchDoorBlazeRaise = 111;
  static const int switchDoorBlazeOpen = 112;
  static const int switchDoorBlazeClose = 113;
  static const int switchPlatBlaze = 122;
  static const int switchBuildStairsTurbo = 127;
  static const int switchRaiseFloorTurbo = 131;
  static const int switchRaiseFloor512 = 140;

  static const int buttonCloseDoor = 42;
  static const int buttonLowerCeilingToFloor = 43;
  static const int buttonLowerFloor = 45;
  static const int buttonLowerFloorToLowest = 60;
  static const int buttonOpenDoor = 61;
  static const int buttonPlatDown = 62;
  static const int buttonRaiseDoor = 63;
  static const int buttonRaiseFloor = 64;
  static const int buttonRaiseFloorCrush = 65;
  static const int buttonRaiseFloor24Change = 66;
  static const int buttonRaiseFloor32Change = 67;
  static const int buttonRaisePlatNearest = 68;
  static const int buttonRaiseFloorNearest = 69;
  static const int buttonTurboLower = 70;
  static const int buttonBlazeRaise = 114;
  static const int buttonBlazeOpen = 115;
  static const int buttonBlazeClose = 116;
  static const int buttonBlazePlatDown = 123;
  static const int buttonRaiseFloorTurbo = 132;
  static const int buttonLightOn = 138;
  static const int buttonLightOff = 139;

  static const int walkOpenDoor = 2;
  static const int walkCloseDoor = 3;
  static const int walkRaiseDoor = 4;
  static const int walkCloseDoor30 = 16;

  static const int walkPlatDownWaitUp = 10;
  static const int walkPlatRaiseNearest = 22;
  static const int walkPlatPerpetual = 53;

  static const int walkTeleport = 39;
  static const int walkTeleportRetrigger = 97;
  static const int walkTeleportMonster = 125;
  static const int walkTeleportMonsterRetrigger = 126;

  static const int walkExit = 52;
  static const int walkSecretExit = 124;

  static const int walkRaiseFloor = 5;
  static const int walkFastCrushAndRaise = 6;
  static const int walkBuildStairs = 8;
  static const int walkLightToBrightest = 12;
  static const int walkLightToMax = 13;
  static const int walkStartStrobe = 17;
  static const int walkLowerFloor = 19;
  static const int walkRaiseToTexture = 30;
  static const int walkLightToDark = 35;
  static const int walkTurboLower = 36;
  static const int walkLowerAndChange = 37;
  static const int walkLowerFloorToLowest = 38;
  static const int walkRaiseCeilingLowerFloor = 40;
  static const int walkLowerCeiling = 44;
  static const int walkCrushAndRaise = 25;
  static const int walkRaiseFloorCrush = 56;
  static const int walkRaiseFloor24 = 58;
  static const int walkRaiseFloor24Change = 59;
  static const int walkBuildStairsTurbo = 100;
  static const int walkLightOff = 104;
  static const int walkBlazePlatDown = 121;
  static const int walkRaiseFloorTurbo = 130;
  static const int walkSilentCrush = 141;

  static const int impactRaiseFloor = 24;
  static const int impactOpenDoor = 46;
  static const int impactRaiseFloorNearest = 47;

  static const int retriggerOpenDoor = 86;
  static const int retriggerPlatPerpetual = 87;
  static const int retriggerPlatDownWaitUp = 88;
  static const int retriggerPlatStop = 89;
  static const int retriggerRaiseDoor = 90;
  static const int retriggerCloseDoor = 75;
  static const int retriggerCloseDoor30 = 76;
  static const int retriggerBlazeRaise = 105;
  static const int retriggerBlazeOpen = 106;
  static const int retriggerBlazeClose = 107;
  static const int retriggerBlazePlatDown = 120;
  static const int retriggerLowerCeiling = 72;
  static const int retriggerCrushAndRaise = 73;
  static const int retriggerCeilingStop = 74;
  static const int retriggerFastCrush = 77;
  static const int retriggerLightToDark = 79;
  static const int retriggerLightToBrightest = 80;
  static const int retriggerLightToMax = 81;
  static const int retriggerLowerFloorToLowest = 82;
  static const int retriggerLowerFloor = 83;
  static const int retriggerLowerAndChange = 84;
  static const int retriggerRaiseFloor = 91;
  static const int retriggerRaiseFloor24 = 92;
  static const int retriggerRaiseFloor24Change = 93;
  static const int retriggerRaiseFloorCrush = 94;
  static const int retriggerRaiseToTexture = 96;
  static const int retriggerTurboLower = 98;
  static const int retriggerRaiseFloorToNearest = 128;
  static const int retriggerRaiseFloorTurbo = 129;
}

abstract final class _ThingType {
  static const int teleportDest = 14;
}

abstract final class _ExplodeDamage {
  static const int radius = 128;
}

abstract final class _RadiusAttack {
  // Note: In original C, MAXRADIUS is 32*FRACUNIT, but due to 32-bit overflow
  // in the calculation (damage+MAXRADIUS)<<FRACBITS, the MAXRADIUS contribution
  // is effectively lost. Using plain 32 here to match actual C behavior.
  static const int maxRadius = 32;
}

// Locked door messages
const _pdBlueK = 'You need a blue key to open this door';
const _pdRedK = 'You need a red key to open this door';
const _pdYellowK = 'You need a yellow key to open this door';

abstract final class _SectorSpecial {
  static const int lightRandom = 1;
  static const int lightBlink05 = 2;
  static const int lightBlink10 = 3;
  static const int damage20AndLightBlink = 4;
  static const int damage10 = 5;
  static const int damage5 = 7;
  static const int lightOscillate = 8;
  static const int secret = 9;
  static const int doorClose30 = 10;
  static const int endLevelDamage = 11;
  static const int lightBlink05Sync = 12;
  static const int lightBlink10Sync = 13;
  static const int doorOpen300 = 14;
  static const int damage20 = 16;
  static const int lightFlicker = 17;
}

void useSpecialLine(Mobj thing, Line line, int side, LevelLocals level) {
  if (side != 0) {
    return;
  }

  switch (line.special) {
    case _LineSpecial.manualDoor:
    case _LineSpecial.blueDoorManual:
    case _LineSpecial.yellowDoorManual:
    case _LineSpecial.redDoorManual:
    case _LineSpecial.openDoor:
    case _LineSpecial.blueDoorOpen:
    case _LineSpecial.redDoorOpen:
    case _LineSpecial.yellowDoorOpen:
    case _LineSpecial.blazeDoorRaise:
    case _LineSpecial.blazeDoorOpen:
      evVerticalDoor(line, thing, level);

    case _LineSpecial.switchBuildStairs:
      if (evBuildStairs(line, StairType.build8, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDonut:
      if (evDoDonut(line, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchExit:
      changeSwitchTexture(line, false, level);
      level.exitLevel = true;

    case _LineSpecial.switchPlatRaise32:
      if (evDoPlat(line, PlatType.raiseAndChange, 32, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatRaise24:
      if (evDoPlat(line, PlatType.raiseAndChange, 24, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchFloorRaiseNearest:
      if (evDoFloor(line, FloorType.raiseFloorToNearest, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatRaise:
      if (evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatDown:
      if (evDoPlat(line, PlatType.downWaitUpStay, 0, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchFloorLowerToLowest:
      if (evDoFloor(line, FloorType.lowerFloorToLowest, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoor:
      if (evDoDoor(line, DoorType.normal, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchLowerCeilingToFloor:
      if (evDoCeiling(line, CeilingType.lowerToFloor, level, _activeCeilings)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchCeilingCrush:
      if (evDoCeiling(line, CeilingType.crushAndRaise, level, _activeCeilings)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorClose:
      if (evDoDoor(line, DoorType.close, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchSecretExit:
      changeSwitchTexture(line, false, level);
      level.secretExit = true;

    case _LineSpecial.switchRaiseFloorCrush:
      if (evDoFloor(line, FloorType.raiseFloorCrush, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchTurboLower:
      if (evDoFloor(line, FloorType.turboLower, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchRaiseFloor:
      if (evDoFloor(line, FloorType.raiseFloor, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchLowerFloor:
      if (evDoFloor(line, FloorType.lowerFloor, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorOpen:
      if (evDoDoor(line, DoorType.open, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorBlazeRaise:
      if (evDoDoor(line, DoorType.blazeRaise, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorBlazeOpen:
      if (evDoDoor(line, DoorType.blazeOpen, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorBlazeClose:
      if (evDoDoor(line, DoorType.blazeClose, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatBlaze:
      if (evDoPlat(line, PlatType.blazeDWUS, 0, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchBuildStairsTurbo:
      if (evBuildStairs(line, StairType.turbo16, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchRaiseFloorTurbo:
      if (evDoFloor(line, FloorType.raiseFloorTurbo, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchRaiseFloor512:
      if (evDoFloor(line, FloorType.raiseFloor512, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.buttonCloseDoor:
      if (evDoDoor(line, DoorType.close, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonLowerCeilingToFloor:
      if (evDoCeiling(line, CeilingType.lowerToFloor, level, _activeCeilings)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonLowerFloor:
      if (evDoFloor(line, FloorType.lowerFloor, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonLowerFloorToLowest:
      if (evDoFloor(line, FloorType.lowerFloorToLowest, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonOpenDoor:
      if (evDoDoor(line, DoorType.open, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonPlatDown:
      if (evDoPlat(line, PlatType.downWaitUpStay, 0, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseDoor:
      if (evDoDoor(line, DoorType.normal, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloor:
      if (evDoFloor(line, FloorType.raiseFloor, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloorCrush:
      if (evDoFloor(line, FloorType.raiseFloorCrush, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloor24Change:
      if (evDoPlat(line, PlatType.raiseAndChange, 24, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloor32Change:
      if (evDoPlat(line, PlatType.raiseAndChange, 32, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaisePlatNearest:
      if (evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloorNearest:
      if (evDoFloor(line, FloorType.raiseFloorToNearest, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonTurboLower:
      if (evDoFloor(line, FloorType.turboLower, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonBlazeRaise:
      if (evDoDoor(line, DoorType.blazeRaise, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonBlazeOpen:
      if (evDoDoor(line, DoorType.blazeOpen, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonBlazeClose:
      if (evDoDoor(line, DoorType.blazeClose, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonBlazePlatDown:
      if (evDoPlat(line, PlatType.blazeDWUS, 0, level) != null) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonRaiseFloorTurbo:
      if (evDoFloor(line, FloorType.raiseFloorTurbo, level)) {
        changeSwitchTexture(line, true, level);
      }

    case _LineSpecial.buttonLightOn:
      evLightTurnOn(line, 255, level);
      changeSwitchTexture(line, true, level);

    case _LineSpecial.buttonLightOff:
      evLightTurnOn(line, 35, level);
      changeSwitchTexture(line, true, level);
  }
}

/// Check if player has the required key for a locked door line special.
/// Returns true if the door is not locked or the player has the key.
bool _playerHasKeyForDoor(Player? player, int lineSpecial) {
  if (player == null) return false;

  switch (lineSpecial) {
    case _LineSpecial.blueDoorManual:
    case _LineSpecial.blueDoorOpen:
      return player.cards[CardType.blueCard.index] ||
          player.cards[CardType.blueSkull.index];
    case _LineSpecial.redDoorManual:
    case _LineSpecial.redDoorOpen:
      return player.cards[CardType.redCard.index] ||
          player.cards[CardType.redSkull.index];
    case _LineSpecial.yellowDoorManual:
    case _LineSpecial.yellowDoorOpen:
      return player.cards[CardType.yellowCard.index] ||
          player.cards[CardType.yellowSkull.index];
    default:
      return true; // Not a locked door
  }
}

/// Get the message to display when a locked door cannot be opened.
String? _getLockedDoorMessage(int lineSpecial) {
  switch (lineSpecial) {
    case _LineSpecial.blueDoorManual:
    case _LineSpecial.blueDoorOpen:
      return _pdBlueK;
    case _LineSpecial.redDoorManual:
    case _LineSpecial.redDoorOpen:
      return _pdRedK;
    case _LineSpecial.yellowDoorManual:
    case _LineSpecial.yellowDoorOpen:
      return _pdYellowK;
    default:
      return null;
  }
}

/// Check if a line special is a locked door.
bool _isLockedDoor(int lineSpecial) {
  return lineSpecial == _LineSpecial.blueDoorManual ||
      lineSpecial == _LineSpecial.yellowDoorManual ||
      lineSpecial == _LineSpecial.redDoorManual ||
      lineSpecial == _LineSpecial.blueDoorOpen ||
      lineSpecial == _LineSpecial.redDoorOpen ||
      lineSpecial == _LineSpecial.yellowDoorOpen;
}

void evVerticalDoor(Line line, Mobj thing, LevelLocals level) {
  final sector = line.backSector;
  if (sector == null) return;

  // Check for locked doors - only players can open them
  if (_isLockedDoor(line.special)) {
    final player = thing.player as Player?;
    if (!_playerHasKeyForDoor(player, line.special)) {
      // Player doesn't have the key
      if (player != null) {
        player.message = _getLockedDoorMessage(line.special);
      }
      // TODO: S_StartSound(NULL, sfx_oof) - play denied sound
      return;
    }
  }

  if (sector.specialData != null) {
    final door = sector.specialData;
    if (door is DoorThinker) {
      switch (line.special) {
        case _LineSpecial.manualDoor:
        case _LineSpecial.blueDoorManual:
        case _LineSpecial.yellowDoorManual:
        case _LineSpecial.redDoorManual:
        case _LineSpecial.blazeDoorRaise:
          if (door.direction == DoorDirection.closing) {
            door.direction = DoorDirection.opening;
          } else {
            if (thing.player == null) return;
            door.direction = DoorDirection.closing;
          }
      }
    }
    return;
  }

  final door = DoorThinker(sector)
    ..topWait = DoorConstants.vdoorWait
    ..speed = DoorConstants.vdoorSpeed
    ..direction = DoorDirection.opening;

  level.thinkers.add(door);
  sector.specialData = door;
  door.function = (_) => doorThink(door, level);

  switch (line.special) {
    case _LineSpecial.manualDoor:
    case _LineSpecial.blueDoorManual:
    case _LineSpecial.yellowDoorManual:
    case _LineSpecial.redDoorManual:
      door.type = DoorType.normal;

    case _LineSpecial.openDoor:
    case _LineSpecial.blueDoorOpen:
    case _LineSpecial.redDoorOpen:
    case _LineSpecial.yellowDoorOpen:
      door.type = DoorType.open;
      line.special = 0;

    case _LineSpecial.blazeDoorRaise:
      door.type = DoorType.blazeRaise;
      door.speed = DoorConstants.vdoorSpeed * 4;

    case _LineSpecial.blazeDoorOpen:
      door.type = DoorType.blazeOpen;
      line.special = 0;
      door.speed = DoorConstants.vdoorSpeed * 4;
  }

  door
    ..topHeight = findLowestCeilingSurrounding(sector)
    ..topHeight -= 4 << Fixed32.fracBits;
}

void crossSpecialLine(Line line, int side, Mobj thing, LevelLocals level) {
  final isPlayer = thing.player != null;

  if (!isPlayer) {
    if ((thing.flags & MobjFlag.missile) != 0) {
      return;
    }

    final canActivate = switch (line.special) {
      _LineSpecial.walkTeleport ||
      _LineSpecial.walkTeleportRetrigger ||
      _LineSpecial.walkTeleportMonster ||
      _LineSpecial.walkTeleportMonsterRetrigger ||
      _LineSpecial.walkRaiseDoor ||
      _LineSpecial.walkPlatDownWaitUp ||
      _LineSpecial.retriggerPlatDownWaitUp =>
        true,
      _ => false,
    };

    if (!canActivate) return;
  }

  switch (line.special) {
    case _LineSpecial.walkOpenDoor:
      evDoDoor(line, DoorType.open, level);
      line.special = 0;

    case _LineSpecial.walkCloseDoor:
      evDoDoor(line, DoorType.close, level);
      line.special = 0;

    case _LineSpecial.walkRaiseDoor:
      evDoDoor(line, DoorType.normal, level);
      line.special = 0;

    case _LineSpecial.walkCloseDoor30:
      evDoDoor(line, DoorType.close30ThenOpen, level);
      line.special = 0;

    case _LineSpecial.walkPlatDownWaitUp:
      evDoPlat(line, PlatType.downWaitUpStay, 0, level);
      line.special = 0;

    case _LineSpecial.walkPlatRaiseNearest:
      evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level);
      line.special = 0;

    case _LineSpecial.walkPlatPerpetual:
      evDoPlat(line, PlatType.perpetualRaise, 0, level);
      line.special = 0;

    case _LineSpecial.walkTeleport:
      if (evTeleport(line, side, thing, level)) {
        line.special = 0;
      }

    case _LineSpecial.walkTeleportRetrigger:
      evTeleport(line, side, thing, level);

    case _LineSpecial.walkTeleportMonster:
      if (!isPlayer) {
        if (evTeleport(line, side, thing, level)) {
          line.special = 0;
        }
      }

    case _LineSpecial.walkTeleportMonsterRetrigger:
      if (!isPlayer) {
        evTeleport(line, side, thing, level);
      }

    case _LineSpecial.walkExit:
      level.exitLevel = true;

    case _LineSpecial.walkSecretExit:
      level.secretExit = true;

    case _LineSpecial.retriggerRaiseDoor:
      evDoDoor(line, DoorType.normal, level);

    case _LineSpecial.retriggerOpenDoor:
      evDoDoor(line, DoorType.open, level);

    case _LineSpecial.retriggerCloseDoor:
      evDoDoor(line, DoorType.close, level);

    case _LineSpecial.retriggerCloseDoor30:
      evDoDoor(line, DoorType.close30ThenOpen, level);

    case _LineSpecial.retriggerPlatDownWaitUp:
      evDoPlat(line, PlatType.downWaitUpStay, 0, level);

    case _LineSpecial.retriggerBlazeRaise:
      evDoDoor(line, DoorType.blazeRaise, level);

    case _LineSpecial.retriggerBlazeOpen:
      evDoDoor(line, DoorType.blazeOpen, level);

    case _LineSpecial.retriggerBlazeClose:
      evDoDoor(line, DoorType.blazeClose, level);

    case _LineSpecial.retriggerBlazePlatDown:
      evDoPlat(line, PlatType.blazeDWUS, 0, level);

    case _LineSpecial.walkRaiseFloor:
      evDoFloor(line, FloorType.raiseFloor, level);
      line.special = 0;

    case _LineSpecial.walkFastCrushAndRaise:
      evDoCeiling(line, CeilingType.fastCrushAndRaise, level, _activeCeilings);
      line.special = 0;

    case _LineSpecial.walkBuildStairs:
      evBuildStairs(line, StairType.build8, level);
      line.special = 0;

    case _LineSpecial.walkLightToBrightest:
      evLightTurnOn(line, 0, level);
      line.special = 0;

    case _LineSpecial.walkLightToMax:
      evLightTurnOn(line, 255, level);
      line.special = 0;

    case _LineSpecial.walkStartStrobe:
      evStartLightStrobing(line, level, level.random);
      line.special = 0;

    case _LineSpecial.walkLowerFloor:
      evDoFloor(line, FloorType.lowerFloor, level);
      line.special = 0;

    case _LineSpecial.walkRaiseToTexture:
      evDoFloor(line, FloorType.raiseToTexture, level);
      line.special = 0;

    case _LineSpecial.walkLightToDark:
      evLightTurnOn(line, 35, level);
      line.special = 0;

    case _LineSpecial.walkTurboLower:
      evDoFloor(line, FloorType.turboLower, level);
      line.special = 0;

    case _LineSpecial.walkLowerAndChange:
      evDoFloor(line, FloorType.lowerAndChange, level);
      line.special = 0;

    case _LineSpecial.walkLowerFloorToLowest:
      evDoFloor(line, FloorType.lowerFloorToLowest, level);
      line.special = 0;

    case _LineSpecial.walkRaiseCeilingLowerFloor:
      evDoCeiling(line, CeilingType.raiseToHighest, level, _activeCeilings);
      evDoFloor(line, FloorType.lowerFloorToLowest, level);
      line.special = 0;

    case _LineSpecial.walkLowerCeiling:
      evDoCeiling(line, CeilingType.lowerAndCrush, level, _activeCeilings);
      line.special = 0;

    case _LineSpecial.walkCrushAndRaise:
      evDoCeiling(line, CeilingType.crushAndRaise, level, _activeCeilings);
      line.special = 0;

    case _LineSpecial.walkRaiseFloorCrush:
      evDoFloor(line, FloorType.raiseFloorCrush, level);
      line.special = 0;

    case _LineSpecial.walkRaiseFloor24:
      evDoFloor(line, FloorType.raiseFloor24, level);
      line.special = 0;

    case _LineSpecial.walkRaiseFloor24Change:
      evDoFloor(line, FloorType.raiseFloor24AndChange, level);
      line.special = 0;

    case _LineSpecial.walkBuildStairsTurbo:
      evBuildStairs(line, StairType.turbo16, level);
      line.special = 0;

    case _LineSpecial.walkLightOff:
      evTurnTagLightsOff(line, level);
      line.special = 0;

    case _LineSpecial.walkBlazePlatDown:
      evDoPlat(line, PlatType.blazeDWUS, 0, level);
      line.special = 0;

    case _LineSpecial.walkRaiseFloorTurbo:
      evDoFloor(line, FloorType.raiseFloorTurbo, level);
      line.special = 0;

    case _LineSpecial.walkSilentCrush:
      evDoCeiling(line, CeilingType.silentCrushAndRaise, level, _activeCeilings);
      line.special = 0;

    case _LineSpecial.retriggerLowerCeiling:
      evDoCeiling(line, CeilingType.lowerAndCrush, level, _activeCeilings);

    case _LineSpecial.retriggerCrushAndRaise:
      evDoCeiling(line, CeilingType.crushAndRaise, level, _activeCeilings);

    case _LineSpecial.retriggerCeilingStop:
      evCeilingCrushStop(line, _activeCeilings);

    case _LineSpecial.retriggerFastCrush:
      evDoCeiling(line, CeilingType.fastCrushAndRaise, level, _activeCeilings);

    case _LineSpecial.retriggerLightToDark:
      evLightTurnOn(line, 35, level);

    case _LineSpecial.retriggerLightToBrightest:
      evLightTurnOn(line, 0, level);

    case _LineSpecial.retriggerLightToMax:
      evLightTurnOn(line, 255, level);

    case _LineSpecial.retriggerLowerFloorToLowest:
      evDoFloor(line, FloorType.lowerFloorToLowest, level);

    case _LineSpecial.retriggerLowerFloor:
      evDoFloor(line, FloorType.lowerFloor, level);

    case _LineSpecial.retriggerLowerAndChange:
      evDoFloor(line, FloorType.lowerAndChange, level);

    case _LineSpecial.retriggerPlatPerpetual:
      evDoPlat(line, PlatType.perpetualRaise, 0, level);

    case _LineSpecial.retriggerPlatStop:
      evStopPlat(line, level, _activePlatforms);

    case _LineSpecial.retriggerRaiseFloor:
      evDoFloor(line, FloorType.raiseFloor, level);

    case _LineSpecial.retriggerRaiseFloor24:
      evDoFloor(line, FloorType.raiseFloor24, level);

    case _LineSpecial.retriggerRaiseFloor24Change:
      evDoFloor(line, FloorType.raiseFloor24AndChange, level);

    case _LineSpecial.retriggerRaiseFloorCrush:
      evDoFloor(line, FloorType.raiseFloorCrush, level);

    case _LineSpecial.retriggerRaiseToTexture:
      evDoFloor(line, FloorType.raiseToTexture, level);

    case _LineSpecial.retriggerTurboLower:
      evDoFloor(line, FloorType.turboLower, level);

    case _LineSpecial.retriggerRaiseFloorToNearest:
      evDoFloor(line, FloorType.raiseFloorToNearest, level);

    case _LineSpecial.retriggerRaiseFloorTurbo:
      evDoFloor(line, FloorType.raiseFloorTurbo, level);
  }
}

void shootSpecialLine(Mobj thing, Line line, LevelLocals level) {
  if (thing.player == null) {
    final canActivate = switch (line.special) {
      _LineSpecial.impactOpenDoor => true,
      _ => false,
    };
    if (!canActivate) return;
  }

  switch (line.special) {
    case _LineSpecial.impactRaiseFloor:
      evDoFloor(line, FloorType.raiseFloor, level);
      changeSwitchTexture(line, false, level);

    case _LineSpecial.impactOpenDoor:
      evDoDoor(line, DoorType.open, level);
      changeSwitchTexture(line, true, level);

    case _LineSpecial.impactRaiseFloorNearest:
      evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level);
      changeSwitchTexture(line, false, level);
  }
}

bool evTeleport(Line line, int side, Mobj thing, LevelLocals level) {
  if ((thing.flags & MobjFlag.missile) != 0) {
    return false;
  }

  if (side == 1) {
    return false;
  }

  final tag = line.tag;

  for (var i = 0; i < level.renderState.sectors.length; i++) {
    final sector = level.renderState.sectors[i];
    if (sector.tag != tag) continue;

    for (final mobj in _iterateSectorThings(sector)) {
      if (mobj.type != _ThingType.teleportDest) continue;

      final subsector = mobj.subsector;
      if (subsector is! Subsector) continue;

      final sectorIndex = level.renderState.sectors.indexOf(subsector.sector);
      if (sectorIndex != i) continue;

      final oldX = thing.x;
      final oldY = thing.y;
      final oldZ = thing.z;

      thing.x = mobj.x;
      thing.y = mobj.y;
      thing.z = subsector.sector.floorHeight;

      thing.momX = 0;
      thing.momY = 0;
      thing.momZ = 0;

      thing.angle = mobj.angle;

      final thingPlayer = thing.player;
      if (thingPlayer is Player) {
        thingPlayer.viewZ = thing.z + thingPlayer.viewHeight;
        thingPlayer.deltaViewHeight = 0;
      }

      _setThingPosition(thing, level);

      thing.floorZ = subsector.sector.floorHeight;
      thing.ceilingZ = subsector.sector.ceilingHeight;

      level.teleportFlashX = oldX;
      level.teleportFlashY = oldY;
      level.teleportFlashZ = oldZ;
      level.teleportDestX = thing.x;
      level.teleportDestY = thing.y;
      level.teleportDestZ = thing.z;
      level.teleportTic = level.levelTime;

      return true;
    }
  }

  return false;
}

Iterable<Mobj> _iterateSectorThings(Sector sector) sync* {
  var mobj = sector.thingList;
  while (mobj != null) {
    yield mobj;
    mobj = mobj.sNext;
  }
}

void _setThingPosition(Mobj thing, LevelLocals level) {
  final state = level.renderState;

  if (state.nodes.isEmpty) {
    thing.subsector = state.subsectors.isNotEmpty ? state.subsectors[0] : null;
    return;
  }

  var nodeNum = state.nodes.length - 1;

  while (!BspConstants.isSubsector(nodeNum)) {
    final node = state.nodes[nodeNum];
    final side = _nodePointOnSide(thing.x, thing.y, node);
    nodeNum = node.children[side];
  }

  thing.subsector = state.subsectors[BspConstants.getIndex(nodeNum)];
}

int _nodePointOnSide(int x, int y, Node node) {
  if (node.dx == 0) {
    if (x <= node.x) {
      return node.dy > 0 ? 1 : 0;
    }
    return node.dy < 0 ? 1 : 0;
  }

  if (node.dy == 0) {
    if (y <= node.y) {
      return node.dx < 0 ? 1 : 0;
    }
    return node.dx > 0 ? 1 : 0;
  }

  final dx = x - node.x;
  final dy = y - node.y;

  final left = Fixed32.mul(node.dy >> Fixed32.fracBits, dx);
  final right = Fixed32.mul(dy, node.dx >> Fixed32.fracBits);

  return right < left ? 0 : 1;
}

void changeSwitchTexture(Line line, bool useAgain, LevelLocals level) {
  level.switchManager?.changeSwitchTexture(line, useAgain: useAgain, level: level);
}

void playerInSpecialSector(Mobj thing, LevelLocals level) {
  final subsector = thing.subsector;
  if (subsector is! Subsector) return;

  final sector = subsector.sector;

  if (thing.z != sector.floorHeight) {
    return;
  }

  final player = thing.player;
  if (player is! Player) return;

  switch (sector.special) {
    case _SectorSpecial.damage5:
      if ((level.levelTime & 0x1f) == 0) {
        damageMobj(thing, null, null, 5, level);
      }

    case _SectorSpecial.damage10:
      if ((level.levelTime & 0x1f) == 0) {
        damageMobj(thing, null, null, 10, level);
      }

    case _SectorSpecial.damage20:
    case _SectorSpecial.damage20AndLightBlink:
      if ((level.levelTime & 0x1f) == 0) {
        damageMobj(thing, null, null, 20, level);
      }

    case _SectorSpecial.secret:
      player.secretCount++;
      sector.special = 0;

    case _SectorSpecial.endLevelDamage:
      if ((level.levelTime & 0x1f) == 0) {
        damageMobj(thing, null, null, 20, level);
      }
      if (player.health <= 10) {
        level.exitLevel = true;
      }
  }
}

void damageMobj(
  Mobj target,
  Mobj? inflictor,
  Mobj? source,
  int damage,
  LevelLocals level,
) {
  inter.damageMobj(target, inflictor, source, damage, level);
}

bool setMobjState(Mobj mobj, int stateNum, LevelLocals level) {
  while (true) {
    if (stateNum == StateNum.sNull) {
      inter.removeMobj(mobj, level);
      return false;
    }

    if (stateNum < 0 || stateNum >= states.length) {
      mobj.tics = -1;
      return false;
    }

    final st = states[stateNum];
    mobj
      ..stateNum = stateNum
      ..tics = st.tics
      ..sprite = st.sprite
      ..frame = st.frame;

    _executeStateAction(mobj, st.action, level);

    stateNum = st.nextState;

    if (mobj.tics != 0) {
      break;
    }
  }

  return true;
}

void _executeStateAction(Mobj mobj, StateAction action, LevelLocals level) {
  switch (action) {
    case StateAction.none:
      break;
    case StateAction.look:
      enemy.aLook(mobj, level);
    case StateAction.chase:
      enemy.aChase(mobj, level, level.random);
    case StateAction.faceTarget:
      enemy.aFaceTarget(mobj, level.random);
    case StateAction.posAttack:
      enemy.aPosAttack(mobj, level.random, level);
    case StateAction.sPosAttack:
      enemy.aSPosAttack(mobj, level.random, level);
    case StateAction.cPosAttack:
      enemy.aCPosAttack(mobj, level.random, level);
    case StateAction.cPosRefire:
      enemy.aCPosRefire(mobj, level.random, level);
    case StateAction.troopAttack:
      enemy.aTroopAttack(mobj, level.random, level);
    case StateAction.sargAttack:
      enemy.aSargAttack(mobj, level.random, level);
    case StateAction.headAttack:
      enemy.aHeadAttack(mobj, level.random, level);
    case StateAction.bruisAttack:
      enemy.aBruisAttack(mobj, level.random, level);
    case StateAction.skullAttack:
      enemy.aSkullAttack(mobj);
    case StateAction.scream:
      enemy.aScream(mobj);
    case StateAction.xScream:
      enemy.aXScream(mobj);
    case StateAction.pain:
      enemy.aPain(mobj);
    case StateAction.fall:
      enemy.aFall(mobj);
    case StateAction.explode:
      _explode(mobj, level);
    case StateAction.bfgSpray:
      _bfgSpray(mobj, level);
    case StateAction.tracer:
      enemy.aTracer(mobj, level);
    case StateAction.cyberAttack:
      enemy.aCyberAttack(mobj, level);
    case StateAction.spidRefire:
      enemy.aSpidRefire(mobj, level.random, level);
    case StateAction.bspiAttack:
      enemy.aBspiAttack(mobj, level);
    case StateAction.fatAttack1:
      enemy.aFatAttack1(mobj, level);
    case StateAction.fatAttack2:
      enemy.aFatAttack2(mobj, level);
    case StateAction.fatAttack3:
      enemy.aFatAttack3(mobj, level);
    case StateAction.fatRaise:
      enemy.aFatRaise(mobj, level.random);
    case StateAction.skelMissile:
      enemy.aSkelMissile(mobj, level);
    case StateAction.skelWhoosh:
      enemy.aSkelWhoosh(mobj, level.random);
    case StateAction.painAttack:
      enemy.aPainAttack(mobj, level);
    case StateAction.painDie:
      enemy.aPainDie(mobj, level);
    case StateAction.vileChase:
      enemy.aVileChase(mobj, level, level.random);
    case StateAction.vileStart:
      enemy.aVileStart(mobj);
    case StateAction.vileTarget:
      enemy.aVileTarget(mobj, level, level.random);
    case StateAction.vileAttack:
      enemy.aVileAttack(mobj, level, level.random);
    case StateAction.startFire:
      enemy.aStartFire(mobj, level);
    case StateAction.fire:
      enemy.aFire(mobj, level);
    case StateAction.fireCrackle:
      enemy.aFireCrackle(mobj, level);
    case StateAction.skelFist:
      enemy.aSkelFist(mobj, level.random, level);
  }
}

void _explode(Mobj mobj, LevelLocals level) {
  radiusAttack(mobj, mobj.target, _ExplodeDamage.radius, level);
}

void _bfgSpray(Mobj mobj, LevelLocals level) {
  final source = mobj.target;
  if (source == null) return;

  const bfgRange = 16 * 64 * Fixed32.fracUnit;

  for (var i = 0; i < 40; i++) {
    final an = (mobj.angle - Angle.ang90 ~/ 2 + (Angle.ang90 ~/ 40) * i).u32.s32;
    pspr.aimLineAttack(source, an, bfgRange, level);

    final target = pspr.lineTarget;
    if (target == null) continue;

    var damage = 0;
    for (var j = 0; j < 15; j++) {
      damage += (level.random.pRandom() & 7) + 1;
    }

    inter.damageMobj(target, source, source, damage, level);
  }
}

void radiusAttack(Mobj spot, Mobj? source, int damage, LevelLocals level) {
  final blockmap = level.blockmap;
  final blockLinks = level.blockLinks;

  if (blockmap == null || blockLinks == null) return;

  final dist = (damage + _RadiusAttack.maxRadius) << Fixed32.fracBits;
  final (xl, yl) = blockmap.worldToBlock(spot.x - dist, spot.y - dist);
  final (xh, yh) = blockmap.worldToBlock(spot.x + dist, spot.y + dist);

  for (var by = yl; by <= yh; by++) {
    for (var bx = xl; bx <= xh; bx++) {
      if (!blockmap.isValidBlock(bx, by)) continue;

      final index = by * blockmap.columns + bx;
      var thing = blockLinks[index];

      while (thing != null) {
        final next = thing.bNext;
        _pitRadiusAttack(thing, spot, source, damage, level);
        thing = next;
      }
    }
  }
}

void _pitRadiusAttack(
  Mobj thing,
  Mobj spot,
  Mobj? source,
  int damage,
  LevelLocals level,
) {
  if ((thing.flags & MobjFlag.shootable) == 0) return;

  final dx = (thing.x - spot.x).abs();
  final dy = (thing.y - spot.y).abs();

  var dist = dx > dy ? dx : dy;
  dist = (dist - thing.radius) >> Fixed32.fracBits;

  if (dist < 0) dist = 0;
  if (dist >= damage) return;

  final canSee = sight.checkSight(
    thing,
    spot,
    level.renderState,
    rejectMatrix: level.rejectMatrix,
    numSectors: level.numSectors,
  );
  if (canSee) {
    inter.damageMobj(thing, spot, source, damage - dist, level);
  }
}

void setMobjStateNum(Mobj mobj, int stateNum, LevelLocals level) {
  setMobjState(mobj, stateNum, level);
}

void killMobj(Mobj? source, Mobj target, LevelLocals level) {
  inter.killMobj(source, target, level);
}

final ActiveCeilings _activeCeilings = ActiveCeilings();
final ActivePlatforms _activePlatforms = ActivePlatforms();

void spawnSpecials(LevelLocals level) {
  final random = level.random;

  for (final sector in level.renderState.sectors) {
    switch (sector.special) {
      case _SectorSpecial.lightRandom:
        spawnLightFlash(sector, level, random);

      case _SectorSpecial.lightBlink05:
        spawnStrobeFlash(
          sector,
          LightConstants.fastDark,
          level,
          random,
          inSync: false,
        );

      case _SectorSpecial.lightBlink10:
        spawnStrobeFlash(
          sector,
          LightConstants.slowDark,
          level,
          random,
          inSync: false,
        );

      case _SectorSpecial.lightOscillate:
        spawnGlowingLight(sector, level);

      case _SectorSpecial.lightBlink05Sync:
        spawnStrobeFlash(
          sector,
          LightConstants.fastDark,
          level,
          random,
          inSync: true,
        );

      case _SectorSpecial.lightBlink10Sync:
        spawnStrobeFlash(
          sector,
          LightConstants.slowDark,
          level,
          random,
          inSync: true,
        );

      case _SectorSpecial.lightFlicker:
        spawnFireFlicker(sector, level, random);

      case _SectorSpecial.secret:
        level.totalSecrets++;

      case _SectorSpecial.doorClose30:
        spawnDoorCloseIn30(sector, level);

      case _SectorSpecial.doorOpen300:
        spawnDoorRaiseIn5Mins(sector, level);
    }
  }

  _initScrollingLines(level);
}

abstract final class _ScrollingLineSpecial {
  static const int scrollLeft = 48;
}

void _initScrollingLines(LevelLocals level) {
  level.scrollingLines.clear();
  for (final line in level.renderState.lines) {
    if (line.special == _ScrollingLineSpecial.scrollLeft) {
      level.scrollingLines.add(line);
    }
  }
}

void updateScrollingLines(LevelLocals level) {
  final sides = level.renderState.sides;
  for (final line in level.scrollingLines) {
    final sideNum = line.sideNum[0];
    if (sideNum >= 0 && sideNum < sides.length) {
      sides[sideNum].textureOffset += Fixed32.fracUnit;
    }
  }
}

void respawnPlayer(Player player, LevelLocals level) {
  player.playerState = PlayerState.reborn;

  player
    ..health = PlayerConstants.maxHealth
    ..armorPoints = 0
    ..armorType = 0
    ..damageCount = 0
    ..bonusCount = 0
    ..extraLight = 0
    ..fixedColormap = 0
    ..readyWeapon = WeaponType.pistol
    ..pendingWeapon = WeaponType.noChange
    ..attackDown = false
    ..useDown = false;

  for (var i = 0; i < player.powers.length; i++) {
    player.powers[i] = 0;
  }

  for (var i = 0; i < player.cards.length; i++) {
    player.cards[i] = false;
  }

  for (var i = 0; i < player.weaponOwned.length; i++) {
    player.weaponOwned[i] = false;
  }
  player.weaponOwned[WeaponType.fist.index] = true;
  player.weaponOwned[WeaponType.pistol.index] = true;

  for (var i = 0; i < player.ammo.length; i++) {
    player.ammo[i] = 0;
  }
  player.ammo[AmmoType.clip.index] = 50;

  final mobj = player.mobj;
  if (mobj != null) {
    mobj
      ..x = mobj.spawnX
      ..y = mobj.spawnY
      ..angle = mobj.spawnAngle
      ..health = PlayerConstants.maxHealth
      ..flags = MobjFlag.solid | MobjFlag.shootable | MobjFlag.dropOff | MobjFlag.pickup;

    _setThingPosition(mobj, level);
  }

  player.playerState = PlayerState.live;
}

class _AnimDef {
  const _AnimDef({
    required this.isTexture,
    required this.endName,
    required this.startName,
    required this.speed,
  });

  final bool isTexture;
  final String endName;
  final String startName;
  final int speed;
}

class _Anim {
  _Anim({
    required this.isTexture,
    required this.picNum,
    required this.basePic,
    required this.numPics,
    required this.speed,
  });

  final bool isTexture;
  final int picNum;
  final int basePic;
  final int numPics;
  final int speed;
}

abstract final class _AnimSpeed {
  static const int standard = 8;
}

const List<_AnimDef> _animDefs = [
  _AnimDef(isTexture: false, endName: 'NUKAGE3', startName: 'NUKAGE1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'FWATER4', startName: 'FWATER1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'SWATER4', startName: 'SWATER1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'LAVA4', startName: 'LAVA1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'BLOOD3', startName: 'BLOOD1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'RROCK08', startName: 'RROCK05', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'SLIME04', startName: 'SLIME01', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'SLIME08', startName: 'SLIME05', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: false, endName: 'SLIME12', startName: 'SLIME09', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'BLODGR4', startName: 'BLODGR1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'SLADRIP3', startName: 'SLADRIP1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'BLODRIP4', startName: 'BLODRIP1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'FIREWALL', startName: 'FIREWALA', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'GSTFONT3', startName: 'GSTFONT1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'FIRELAVA', startName: 'FIRELAV3', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'FIREMAG3', startName: 'FIREMAG1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'FIREBLU2', startName: 'FIREBLU1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'ROCKRED3', startName: 'ROCKRED1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'BFALL4', startName: 'BFALL1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'SFALL4', startName: 'SFALL1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'WFALL4', startName: 'WFALL1', speed: _AnimSpeed.standard),
  _AnimDef(isTexture: true, endName: 'DBRAIN4', startName: 'DBRAIN1', speed: _AnimSpeed.standard),
];

List<_Anim> _anims = [];

void initPicAnims(LevelLocals level) {
  final textureManager = level.renderState.textureManager;
  if (textureManager == null) return;

  _anims = [];

  for (final def in _animDefs) {
    if (def.isTexture) {
      final startNum = textureManager.checkTextureNumForName(def.startName);
      if (startNum == -1) continue;

      final endNum = textureManager.checkTextureNumForName(def.endName);
      if (endNum == -1) continue;

      final numPics = endNum - startNum + 1;
      if (numPics < 2) continue;

      _anims.add(_Anim(
        isTexture: true,
        picNum: endNum,
        basePic: startNum,
        numPics: numPics,
        speed: def.speed,
      ),);
    } else {
      final startNum = textureManager.checkFlatNumForName(def.startName);
      if (startNum == -1) continue;

      final endNum = textureManager.checkFlatNumForName(def.endName);
      if (endNum == -1) continue;

      final numPics = endNum - startNum + 1;
      if (numPics < 2) continue;

      _anims.add(_Anim(
        isTexture: false,
        picNum: endNum,
        basePic: startNum,
        numPics: numPics,
        speed: def.speed,
      ),);
    }
  }
}

void updateAnimations(LevelLocals level) {
  final state = level.renderState;
  final levelTime = level.levelTime;

  for (final anim in _anims) {
    for (var i = anim.basePic; i < anim.basePic + anim.numPics; i++) {
      final pic = anim.basePic + ((levelTime ~/ anim.speed + i) % anim.numPics);
      if (anim.isTexture) {
        if (i < state.textureTranslation.length) {
          state.textureTranslation[i] = pic;
        }
      } else {
        if (i < state.flatTranslation.length) {
          state.flatTranslation[i] = pic;
        }
      }
    }
  }
}
