import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _TeleportConstants {
  static const int teleportManType = 14;
  static const int teleportFreezeTime = 18;
  static const int teleportFogOffset = 20 * Fixed32.fracUnit;
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

    final destination = _findTeleportDestination(sector, level);
    if (destination == null) continue;

    final oldX = thing.x;
    final oldY = thing.y;
    final oldZ = thing.z;

    if (!_teleportMove(thing, destination.x, destination.y, level)) {
      return false;
    }

    thing.z = thing.floorZ;

    final playerObj = thing.player;
    if (playerObj is Player) {
      playerObj.viewZ = thing.z + playerObj.viewHeight;
    }

    _storeTeleportFog(oldX, oldY, oldZ, level);

    final fineAngle = (destination.angle.u32 >> Angle.angleToFineShift) & Angle.fineMask;
    _storeTeleportFog(
      destination.x + Fixed32.mul(_TeleportConstants.teleportFogOffset, fineCosine(fineAngle)),
      destination.y + Fixed32.mul(_TeleportConstants.teleportFogOffset, fineSine(fineAngle)),
      thing.z,
      level,
    );

    if (playerObj != null) {
      thing.reactionTime = _TeleportConstants.teleportFreezeTime;
    }

    thing
      ..angle = destination.angle
      ..momX = 0
      ..momY = 0
      ..momZ = 0;

    return true;
  }

  return false;
}

Mobj? _findTeleportDestination(Sector sector, LevelLocals level) {
  var mobj = sector.thingList;
  while (mobj != null) {
    if (mobj.type == _TeleportConstants.teleportManType) {
      return mobj;
    }
    mobj = mobj.sNext;
  }
  return null;
}

bool _teleportMove(Mobj thing, int x, int y, LevelLocals level) {
  final subsector = _findSubsector(x, y, level);
  if (subsector == null) return false;

  thing
    ..floorZ = subsector.sector.floorHeight
    ..ceilingZ = subsector.sector.ceilingHeight
    ..x = x
    ..y = y;

  _setThingPosition(thing, subsector, level);

  return true;
}

Subsector? _findSubsector(int x, int y, LevelLocals level) {
  final nodes = level.renderState.nodes;
  final subsectors = level.renderState.subsectors;

  if (nodes.isEmpty || subsectors.isEmpty) return null;

  var nodeNum = nodes.length - 1;

  while ((nodeNum & _SubsectorFlag.nfSubsector) == 0) {
    final node = nodes[nodeNum];
    final side = _pointOnSide(x, y, node);
    nodeNum = node.children[side];
  }

  final subsectorIndex = nodeNum & ~_SubsectorFlag.nfSubsector;
  if (subsectorIndex >= subsectors.length) return null;

  return subsectors[subsectorIndex];
}

int _pointOnSide(int x, int y, Node node) {
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

  if (right < left) {
    return 0;
  }
  return 1;
}

void _setThingPosition(Mobj thing, Subsector subsector, LevelLocals level) {
  thing.subsector = subsector;

  if ((thing.flags & MobjFlag.noSector) == 0) {
    final sector = subsector.sector;
    thing
      ..sPrev = null
      ..sNext = sector.thingList;
    if (sector.thingList != null) {
      sector.thingList!.sPrev = thing;
    }
    sector.thingList = thing;
  }
}

void _storeTeleportFog(int x, int y, int z, LevelLocals level) {
  level
    ..teleportFlashX = x
    ..teleportFlashY = y
    ..teleportFlashZ = z
    ..teleportTic = level.levelTime;
}

abstract final class _SubsectorFlag {
  static const int nfSubsector = 0x8000;
}
