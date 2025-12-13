import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/game/info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_map.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class PhysicsConstants {
  static const int gravity = Fixed32.fracUnit;
  static const int friction = 0xe800;
  static const int maxMove = 30 * Fixed32.fracUnit;
  static const int stopSpeed = 0x1000;
}

abstract final class _SpawnConstants {
  static const int onFloorZ = -0x7FFFFFFF;
  static const int onCeilingZ = 0x7FFFFFFF;
}

abstract final class _MonsterSpeed {
  static const int slow = 8;
  static const int normal = 10;
  static const int fast = 15;
}

const Map<int, MobjInfo> _monsterInfo = {
  3004: MobjInfo(
    doomEdNum: 3004,
    spawnState: StateNum.possStnd,
    spawnHealth: 20,
    seeState: StateNum.possRun1,
    reactionTime: 8,
    painState: StateNum.possPain,
    painChance: 200,
    meleeState: 0,
    missileState: StateNum.possAtk1,
    deathState: StateNum.possDie1,
    xDeathState: StateNum.possXdie1,
    speed: _MonsterSpeed.slow,
    radius: 20 << 16,
    height: 56 << 16,
    mass: 100,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: StateNum.possRaise1,
  ),
  9: MobjInfo(
    doomEdNum: 9,
    spawnState: StateNum.sposStnd,
    spawnHealth: 30,
    seeState: StateNum.sposRun1,
    reactionTime: 8,
    painState: StateNum.sposPain,
    painChance: 170,
    meleeState: 0,
    missileState: StateNum.sposAtk1,
    deathState: StateNum.sposDie1,
    xDeathState: StateNum.sposXdie1,
    speed: _MonsterSpeed.slow,
    radius: 20 << 16,
    height: 56 << 16,
    mass: 100,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: StateNum.sposRaise1,
  ),
  3001: MobjInfo(
    doomEdNum: 3001,
    spawnState: StateNum.troopStnd,
    spawnHealth: 60,
    seeState: StateNum.troopRun1,
    reactionTime: 8,
    painState: StateNum.troopPain,
    painChance: 200,
    meleeState: StateNum.troopAtk1,
    missileState: StateNum.troopAtk1,
    deathState: StateNum.troopDie1,
    xDeathState: StateNum.troopXdie1,
    speed: _MonsterSpeed.slow,
    radius: 20 << 16,
    height: 56 << 16,
    mass: 100,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: StateNum.troopRaise1,
  ),
  3002: MobjInfo(
    doomEdNum: 3002,
    spawnState: StateNum.sargStnd,
    spawnHealth: 150,
    seeState: StateNum.sargRun1,
    reactionTime: 8,
    painState: StateNum.sargPain,
    painChance: 180,
    meleeState: StateNum.sargAtk1,
    missileState: 0,
    deathState: StateNum.sargDie1,
    xDeathState: 0,
    speed: _MonsterSpeed.normal,
    radius: 30 << 16,
    height: 56 << 16,
    mass: 400,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: StateNum.sargRaise1,
  ),
  3005: MobjInfo(
    doomEdNum: 3005,
    spawnState: StateNum.headStnd,
    spawnHealth: 400,
    seeState: StateNum.headRun1,
    reactionTime: 8,
    painState: StateNum.headPain,
    painChance: 128,
    meleeState: 0,
    missileState: StateNum.headAtk1,
    deathState: StateNum.headDie1,
    xDeathState: 0,
    speed: _MonsterSpeed.slow,
    radius: 31 << 16,
    height: 56 << 16,
    mass: 400,
    flags: MobjFlag.solid |
        MobjFlag.shootable |
        MobjFlag.float |
        MobjFlag.noGravity |
        MobjFlag.countKill,
    raiseState: StateNum.headRaise1,
  ),
  3006: MobjInfo(
    doomEdNum: 3006,
    spawnState: StateNum.skulStnd,
    spawnHealth: 100,
    seeState: StateNum.skulRun1,
    reactionTime: 8,
    painState: StateNum.skulPain,
    painChance: 256,
    meleeState: StateNum.skulAtk1,
    missileState: 0,
    deathState: StateNum.skulDie1,
    xDeathState: 0,
    speed: _MonsterSpeed.fast,
    radius: 16 << 16,
    height: 56 << 16,
    mass: 50,
    flags: MobjFlag.solid |
        MobjFlag.shootable |
        MobjFlag.float |
        MobjFlag.noGravity |
        MobjFlag.countKill,
    raiseState: 0,
  ),
  3003: MobjInfo(
    doomEdNum: 3003,
    spawnState: StateNum.bossStnd,
    spawnHealth: 1000,
    seeState: StateNum.bossRun1,
    reactionTime: 8,
    painState: StateNum.bossPain,
    painChance: 50,
    meleeState: StateNum.bossAtk1,
    missileState: StateNum.bossAtk1,
    deathState: StateNum.bossDie1,
    xDeathState: 0,
    speed: _MonsterSpeed.slow,
    radius: 24 << 16,
    height: 64 << 16,
    mass: 1000,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: StateNum.bossRaise1,
  ),
};

MobjInfo? _getMonsterInfo(int thingType) => _monsterInfo[thingType];

class ThingSpawner {
  ThingSpawner(this._state, this._level);

  final RenderState _state;
  final LevelLocals _level;
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
    final info = _getMonsterInfo(thingType);

    final mobj = Mobj()
      ..x = x
      ..y = y
      ..radius = def.radius
      ..height = def.height
      ..flags = def.flags
      ..sprite = def.sprite
      ..frame = def.frame
      ..type = thingType
      ..info = info
      ..health = info?.spawnHealth ?? 1000
      ..reactionTime = info?.reactionTime ?? 8;

    final spawnState = info?.spawnState ?? 0;
    if (spawnState > 0 && spawnState < states.length) {
      final st = states[spawnState];
      mobj
        ..stateNum = spawnState
        ..tics = st.tics
        ..sprite = st.sprite
        ..frame = st.frame;
    }

    _setThingPosition(mobj);

    final ss = mobj.subsector;
    if (ss == null || ss is! Subsector) return null;

    mobj.floorZ = ss.sector.floorHeight;
    mobj.ceilingZ = ss.sector.ceilingHeight;

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

    if ((mobj.flags & MobjFlag.noBlockmap) == 0) {
      final blockmap = _level.blockmap;
      final blockLinks = _level.blockLinks;
      if (blockmap != null && blockLinks != null) {
        final (blockX, blockY) = blockmap.worldToBlock(mobj.x, mobj.y);
        if (blockmap.isValidBlock(blockX, blockY)) {
          final index = blockY * blockmap.columns + blockX;
          mobj.bPrev = null;
          mobj.bNext = blockLinks[index];
          if (blockLinks[index] != null) {
            blockLinks[index]!.bPrev = mobj;
          }
          blockLinks[index] = mobj;
        } else {
          mobj
            ..bNext = null
            ..bPrev = null;
        }
      }
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
    _level.clearBlockLinks();
    _mobjs.clear();
  }
}

void mobjThinker(Mobj mobj, LevelLocals level) {
  if (mobj.momX != 0 ||
      mobj.momY != 0 ||
      (mobj.flags & MobjFlag.skullFly) != 0) {
    xyMovement(mobj, level);
  }

  if (mobj.z != mobj.floorZ || mobj.momZ != 0) {
    zMovement(mobj, level);
  }

  if (mobj.tics != -1) {
    mobj.tics--;

    if (mobj.tics == 0) {
      final st = states[mobj.stateNum];
      spec.setMobjState(mobj, st.nextState, level);
    }
  }
}

void xyMovement(Mobj mo, LevelLocals level) {
  if (mo.momX == 0 && mo.momY == 0) {
    return;
  }

  var xMove = mo.momX;
  var yMove = mo.momY;

  if (xMove > PhysicsConstants.maxMove) {
    xMove = PhysicsConstants.maxMove;
  } else if (xMove < -PhysicsConstants.maxMove) {
    xMove = -PhysicsConstants.maxMove;
  }

  if (yMove > PhysicsConstants.maxMove) {
    yMove = PhysicsConstants.maxMove;
  } else if (yMove < -PhysicsConstants.maxMove) {
    yMove = -PhysicsConstants.maxMove;
  }

  final pTryX = mo.x + xMove;
  final pTryY = mo.y + yMove;

  if (!tryMove(mo, pTryX, pTryY, level)) {
    if (mo.player != null) {
      slideMove(mo, level);
    } else if ((mo.flags & MobjFlag.missile) != 0) {
      mo.momX = mo.momY = mo.momZ = 0;
    } else {
      mo.momX = mo.momY = 0;
    }
  }

  if ((mo.flags & (MobjFlag.missile | MobjFlag.skullFly)) != 0) {
    return;
  }

  if (mo.z > mo.floorZ) {
    return;
  }

  mo.momX = Fixed32.mul(mo.momX, PhysicsConstants.friction);
  mo.momY = Fixed32.mul(mo.momY, PhysicsConstants.friction);

  if (mo.momX.abs() < PhysicsConstants.stopSpeed &&
      mo.momY.abs() < PhysicsConstants.stopSpeed) {
    mo.momX = 0;
    mo.momY = 0;
  }
}

void zMovement(Mobj mo, LevelLocals level) {
  if (mo.player != null && mo.z < mo.floorZ) {
    final player = mo.player! as Player;
    player.viewHeight -= mo.floorZ - mo.z;
    player.deltaViewHeight = (PlayerConstants.viewHeight - player.viewHeight) >> 3;
  }

  mo.z += mo.momZ;

  if ((mo.flags & MobjFlag.float) != 0 && mo.target != null) {
    final dist = _approxDist(mo.x - mo.target!.x, mo.y - mo.target!.y);
    final delta = mo.target!.z + (mo.height >> 1) - mo.z;

    if (delta < 0 && dist < -(delta * 3)) {
      mo.z -= Fixed32.fracUnit;
    } else if (delta > 0 && dist < (delta * 3)) {
      mo.z += Fixed32.fracUnit;
    }
  }

  if (mo.z <= mo.floorZ) {
    if ((mo.flags & MobjFlag.skullFly) != 0) {
      mo.momZ = -mo.momZ;
    }

    if (mo.momZ < 0) {
      if (mo.player != null && mo.momZ < -PhysicsConstants.gravity * 8) {
        final player = mo.player! as Player;
        player.deltaViewHeight = mo.momZ >> 3;
      }
      mo.momZ = 0;
    }

    mo.z = mo.floorZ;

    if ((mo.flags & MobjFlag.missile) != 0 && (mo.flags & MobjFlag.noClip) == 0) {
      return;
    }
  } else if ((mo.flags & MobjFlag.noGravity) == 0) {
    if (mo.momZ == 0) {
      mo.momZ = -PhysicsConstants.gravity * 2;
    } else {
      mo.momZ -= PhysicsConstants.gravity;
    }
  }

  if (mo.z + mo.height > mo.ceilingZ) {
    mo.z = mo.ceilingZ - mo.height;

    if (mo.momZ > 0) {
      mo.momZ = 0;
    }

    if ((mo.flags & MobjFlag.skullFly) != 0) {
      mo.momZ = -mo.momZ;
    }
  }
}

int _approxDist(int dx, int dy) {
  dx = dx.abs();
  dy = dy.abs();
  if (dx < dy) {
    return dx + dy - (dx >> 1);
  }
  return dx + dy - (dy >> 1);
}
