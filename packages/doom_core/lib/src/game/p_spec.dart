import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_enemy.dart' as enemy;
import 'package:doom_core/src/game/p_inter.dart' as inter;
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

  static const int switchFloorLower = 23;
  static const int switchFloorRaise = 18;
  static const int switchFloorRaiseNearest = 119;
  static const int switchCeilingCrush = 49;
  static const int switchCeilingStop = 57;

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

  static const int retriggerRaiseDoor = 86;
  static const int retriggerOpenDoor = 87;
  static const int retriggerPlatDownWaitUp = 88;
  static const int retriggerCloseDoor = 75;
  static const int retriggerCloseDoor30 = 76;
  static const int retriggerBlazeRaise = 105;
  static const int retriggerBlazeOpen = 106;
  static const int retriggerBlazeClose = 107;
  static const int retriggerBlazePlatDown = 120;
}

abstract final class _ThingType {
  static const int teleportDest = 14;
}

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

    case _LineSpecial.switchDoor:
      if (evDoDoor(line, DoorType.normal, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorOpen:
      if (evDoDoor(line, DoorType.open, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchDoorClose:
      if (evDoDoor(line, DoorType.close, level) != null) {
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

    case _LineSpecial.switchPlatDown:
      if (evDoPlat(line, PlatType.downWaitUpStay, 0, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatRaise:
      if (evDoPlat(line, PlatType.raiseToNearestAndChange, 0, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatRaise24:
      if (evDoPlat(line, PlatType.raiseAndChange, 24, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchPlatRaise32:
      if (evDoPlat(line, PlatType.raiseAndChange, 32, level) != null) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchFloorLower:
      if (evDoFloor(line, FloorType.lowerFloorToLowest, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchFloorRaise:
      if (evDoFloor(line, FloorType.raiseFloor, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchFloorRaiseNearest:
      if (evDoFloor(line, FloorType.raiseFloorToNearest, level)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchCeilingCrush:
      if (evDoCeiling(line, CeilingType.crushAndRaise, level, _activeCeilings)) {
        changeSwitchTexture(line, false, level);
      }

    case _LineSpecial.switchCeilingStop:
      if (evCeilingCrushStop(line, _activeCeilings)) {
        changeSwitchTexture(line, false, level);
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
  door.function = (_) => doorThink(door);

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
      mobj
        ..stateNum = StateNum.sNull
        ..tics = -1;
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
  }
}

void setMobjStateNum(Mobj mobj, int stateNum, LevelLocals level) {
  setMobjState(mobj, stateNum, level);
}

void killMobj(Mobj? source, Mobj target, LevelLocals level) {
  inter.killMobj(source, target, level);
}

final ActiveCeilings _activeCeilings = ActiveCeilings();

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
