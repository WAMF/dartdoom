import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _SpawnConstants {
  static const int onFloorZ = -0x7FFFFFFF;
  static const int onCeilingZ = 0x7FFFFFFF;
}

class ThingSpawner {
  ThingSpawner(this._state);

  final RenderState _state;
  final List<Mobj> _mobjs = [];

  List<Mobj> get mobjs => _mobjs;

  void spawnMapThings(MapData mapData) {
    for (final thing in mapData.things) {
      _spawnMapThing(thing);
    }
  }

  void _spawnMapThing(MapThing thing) {
    if (thing.type <= 4) {
      return;
    }

    if (thing.type == 11) {
      return;
    }

    final def = thingDefs[thing.type];
    if (def == null) {
      return;
    }

    final x = thing.x << Fixed32.fracBits;
    final y = thing.y << Fixed32.fracBits;

    int z;
    if ((def.flags & MobjFlag.spawnCeiling) != 0) {
      z = _SpawnConstants.onCeilingZ;
    } else {
      z = _SpawnConstants.onFloorZ;
    }

    final mobj = _spawnMobj(x, y, z, def, thing.type);
    if (mobj == null) return;

    mobj.angle = _bamAngle(thing.angle);
    mobj.spawnX = thing.x;
    mobj.spawnY = thing.y;
    mobj.spawnAngle = thing.angle;
    mobj.spawnType = thing.type;
    mobj.spawnOptions = thing.options;

    if ((thing.options & 0x08) != 0) {
      mobj.flags |= MobjFlag.ambush;
    }
  }

  Mobj? _spawnMobj(int x, int y, int z, ThingDef def, int thingType) {
    final mobj = Mobj()
      ..x = x
      ..y = y
      ..radius = def.radius
      ..height = def.height
      ..flags = def.flags
      ..sprite = def.sprite
      ..frame = def.frame
      ..type = thingType;

    _setThingPosition(mobj);

    final ss = mobj.subsector;
    if (ss == null || ss is! Subsector) return null;

    mobj.floorZ = ss.sector.floorHeight << Fixed32.fracBits;
    mobj.ceilingZ = ss.sector.ceilingHeight << Fixed32.fracBits;

    if (z == _SpawnConstants.onFloorZ) {
      mobj.z = mobj.floorZ;
    } else if (z == _SpawnConstants.onCeilingZ) {
      mobj.z = mobj.ceilingZ - mobj.height;
    } else {
      mobj.z = z;
    }

    _mobjs.add(mobj);
    return mobj;
  }

  void _setThingPosition(Mobj mobj) {
    final ss = _pointInSubsector(mobj.x, mobj.y);
    if (ss == null) return;

    mobj.subsector = ss;

    if ((mobj.flags & MobjFlag.noSector) == 0) {
      final sector = ss.sector;

      mobj.sPrev = null;
      mobj.sNext = sector.thingList;

      if (sector.thingList != null) {
        sector.thingList!.sPrev = mobj;
      }

      sector.thingList = mobj;
    }
  }

  Subsector? _pointInSubsector(int x, int y) {
    if (_state.nodes.isEmpty) {
      return _state.subsectors.isNotEmpty ? _state.subsectors[0] : null;
    }

    var nodeNum = _state.nodes.length - 1;

    while (!BspConstants.isSubsector(nodeNum)) {
      final node = _state.nodes[nodeNum];
      final side = _pointOnSide(x, y, node);
      nodeNum = node.children[side];
    }

    return _state.subsectors[BspConstants.getIndex(nodeNum)];
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

  int _bamAngle(int degrees) {
    return degrees * Angle.ang90 ~/ 90;
  }

  void clear() {
    for (final sector in _state.sectors) {
      sector.thingList = null;
    }
    _mobjs.clear();
  }
}
