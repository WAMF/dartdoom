import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_maputl.dart' as maputl;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

abstract final class _TeleportConstants {
  static const int teleportManType = 14;
  static const int teleportFreezeTime = 18;
  static const int teleportFogOffset = 20;
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
      destination.x + _TeleportConstants.teleportFogOffset * fineCosine(fineAngle),
      destination.y + _TeleportConstants.teleportFogOffset * fineSine(fineAngle),
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
  final subsector = maputl.pointInSubsector(x, y, level.renderState);

  maputl.unsetThingPosition(thing);

  thing
    ..floorZ = subsector.sector.floorHeight
    ..ceilingZ = subsector.sector.ceilingHeight
    ..x = x
    ..y = y;

  maputl.setThingPosition(thing, level.renderState);

  return true;
}

void _storeTeleportFog(int x, int y, int z, LevelLocals level) {
  level
    ..teleportFlashX = x
    ..teleportFlashY = y
    ..teleportFlashZ = z
    ..teleportTic = level.levelTime;
}
