import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/game/info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_map.dart';
import 'package:doom_core/src/game/p_pspr.dart' show aimLineAttack, lineTarget;
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

abstract final class _ThingFlags {
  static const int easy = 1;
  static const int normal = 2;
  static const int hard = 4;
}

abstract final class _BarrelConstants {
  static const int thingType = 2035;
  static const int health = 20;
  static const int radius = 10 << 16;
  static const int height = 42 << 16;
}

const Map<int, MobjInfo> _monsterInfo = {
  _BarrelConstants.thingType: MobjInfo(
    doomEdNum: _BarrelConstants.thingType,
    spawnState: StateNum.bar1,
    spawnHealth: _BarrelConstants.health,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.bexp,
    xDeathState: 0,
    speed: 0,
    radius: _BarrelConstants.radius,
    height: _BarrelConstants.height,
    mass: 100,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.noBlood,
    raiseState: 0,
  ),
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
  64: MobjInfo(
    doomEdNum: 64,
    spawnState: StateNum.vileStnd,
    spawnHealth: 700,
    seeState: StateNum.vileRun1,
    reactionTime: 8,
    painState: StateNum.vilePain,
    painChance: 10,
    meleeState: 0,
    missileState: StateNum.vileAtk1,
    deathState: StateNum.vileDie1,
    xDeathState: 0,
    speed: 15,
    radius: 20 << 16,
    height: 56 << 16,
    mass: 500,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: 0,
  ),
  MobjType.fire: MobjInfo(
    doomEdNum: MobjType.fire,
    spawnState: StateNum.fire1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 20 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.noBlockmap | MobjFlag.noGravity,
    raiseState: 0,
  ),
  16: MobjInfo(
    doomEdNum: 16,
    spawnState: StateNum.cyberStnd,
    spawnHealth: 4000,
    seeState: StateNum.cyberRun1,
    reactionTime: 8,
    painState: StateNum.cyberPain,
    painChance: 20,
    meleeState: 0,
    missileState: StateNum.cyberAtk1,
    deathState: StateNum.cyberDie1,
    xDeathState: 0,
    speed: 16,
    radius: 40 << 16,
    height: 110 << 16,
    mass: 1000,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: 0,
  ),
  7: MobjInfo(
    doomEdNum: 7,
    spawnState: StateNum.spidStnd,
    spawnHealth: 3000,
    seeState: StateNum.spidRun1,
    reactionTime: 8,
    painState: StateNum.spidPain,
    painChance: 40,
    meleeState: 0,
    missileState: StateNum.spidAtk1,
    deathState: StateNum.spidDie1,
    xDeathState: 0,
    speed: 12,
    radius: 128 << 16,
    height: 100 << 16,
    mass: 1000,
    flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill,
    raiseState: 0,
  ),
  71: MobjInfo(
    doomEdNum: 71,
    spawnState: StateNum.painStnd,
    spawnHealth: 400,
    seeState: StateNum.painRun1,
    reactionTime: 8,
    painState: StateNum.painPain,
    painChance: 128,
    meleeState: 0,
    missileState: StateNum.painAtk1,
    deathState: StateNum.painDie1,
    xDeathState: 0,
    speed: 8,
    radius: 31 << 16,
    height: 56 << 16,
    mass: 400,
    flags: MobjFlag.solid |
        MobjFlag.shootable |
        MobjFlag.float |
        MobjFlag.noGravity |
        MobjFlag.countKill,
    raiseState: StateNum.painRaise1,
  ),
  49: MobjInfo(
    doomEdNum: 49,
    spawnState: StateNum.bloodyTwitch,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 68 << 16,
    mass: 100,
    flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity,
    raiseState: 0,
  ),
  63: MobjInfo(
    doomEdNum: 63,
    spawnState: StateNum.bloodyTwitch,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 20 << 16,
    height: 68 << 16,
    mass: 100,
    flags: MobjFlag.spawnCeiling | MobjFlag.noGravity,
    raiseState: 0,
  ),
  29: MobjInfo(
    doomEdNum: 29,
    spawnState: StateNum.headCandles,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  26: MobjInfo(
    doomEdNum: 26,
    spawnState: StateNum.liveStick,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  41: MobjInfo(
    doomEdNum: 41,
    spawnState: StateNum.evilEye,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  42: MobjInfo(
    doomEdNum: 42,
    spawnState: StateNum.floatSkull,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  36: MobjInfo(
    doomEdNum: 36,
    spawnState: StateNum.heartCol,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  85: MobjInfo(
    doomEdNum: 85,
    spawnState: StateNum.techLamp,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
  86: MobjInfo(
    doomEdNum: 86,
    spawnState: StateNum.tech2Lamp,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 16 << 16,
    height: 16 << 16,
    mass: 100,
    flags: MobjFlag.solid,
    raiseState: 0,
  ),
};

MobjInfo? _getMonsterInfo(int thingType) => _monsterInfo[thingType];

abstract final class MobjType {
  static const int troopShot = -1;
  static const int headShot = -2;
  static const int bruiserShot = -3;
  static const int rocket = -4;
  static const int plasma = -5;
  static const int bfg = -6;
  static const int arachPlaz = -7;
  static const int tracer = -8;
  static const int fatShot = -9;
  static const int puff = -10;
  static const int blood = -11;
  static const int fire = -12;
  static const int skull = 3006;
  static const int vile = 64;
  static const int pain = 71;
}

const _missileFlags = MobjFlag.noBlockmap |
    MobjFlag.missile |
    MobjFlag.dropOff |
    MobjFlag.noGravity;

const Map<int, MobjInfo> _projectileInfo = {
  MobjType.troopShot: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.tball1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.tballx1,
    xDeathState: 0,
    speed: 10 * Fixed32.fracUnit,
    radius: 6 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 3,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.headShot: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.rball1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.rballx1,
    xDeathState: 0,
    speed: 10 * Fixed32.fracUnit,
    radius: 6 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 5,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.bruiserShot: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.brball1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.brballx1,
    xDeathState: 0,
    speed: 15 * Fixed32.fracUnit,
    radius: 6 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 8,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.rocket: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.rocket,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.explode1,
    xDeathState: 0,
    speed: 20 * Fixed32.fracUnit,
    radius: 11 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 20,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.plasma: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.plasball1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.plasexp1,
    xDeathState: 0,
    speed: 25 * Fixed32.fracUnit,
    radius: 13 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 5,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.bfg: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.bfgshot1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.bfgland1,
    xDeathState: 0,
    speed: 25 * Fixed32.fracUnit,
    radius: 13 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 100,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.arachPlaz: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.arachPlaz1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.arachPlex1,
    xDeathState: 0,
    speed: 25 * Fixed32.fracUnit,
    radius: 13 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 5,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.tracer: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.tracer1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.traceexp1,
    xDeathState: 0,
    speed: 10 * Fixed32.fracUnit,
    radius: 11 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 10,
    flags: _missileFlags,
    raiseState: 0,
  ),
  MobjType.fatShot: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.fatshot1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: StateNum.fatshotx1,
    xDeathState: 0,
    speed: 20 * Fixed32.fracUnit,
    radius: 6 * Fixed32.fracUnit,
    height: 8 * Fixed32.fracUnit,
    mass: 100,
    damage: 8,
    flags: _missileFlags,
    raiseState: 0,
  ),
};

const Map<int, MobjInfo> _effectInfo = {
  MobjType.puff: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.puff1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 20 * Fixed32.fracUnit,
    height: 16 * Fixed32.fracUnit,
    mass: 100,
    flags: MobjFlag.noBlockmap | MobjFlag.noGravity,
    raiseState: 0,
  ),
  MobjType.blood: MobjInfo(
    doomEdNum: -1,
    spawnState: StateNum.blood1,
    spawnHealth: 1000,
    seeState: 0,
    reactionTime: 8,
    painState: 0,
    painChance: 0,
    meleeState: 0,
    missileState: 0,
    deathState: 0,
    xDeathState: 0,
    speed: 0,
    radius: 20 * Fixed32.fracUnit,
    height: 16 * Fixed32.fracUnit,
    mass: 100,
    flags: MobjFlag.noBlockmap | MobjFlag.noGravity,
    raiseState: 0,
  ),
};

MobjInfo? getEffectInfo(int mobjType) => _effectInfo[mobjType];

MobjInfo? getProjectileInfo(int mobjType) => _projectileInfo[mobjType];

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

    if (!_shouldSpawnForSkill(thing.options)) {
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

    if (mobj.tics > 0) {
      mobj.tics = 1 + (_level.random.pRandom() % mobj.tics);
    }

    if ((mobj.flags & MobjFlag.countKill) != 0) {
      _level.totalKills++;
    }

    if ((mobj.flags & MobjFlag.countItem) != 0) {
      _level.totalItems++;
    }

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

  bool _shouldSpawnForSkill(int options) {
    final skill = _level.skill;
    int bit;

    switch (skill) {
      case Skill.imTooYoungToDie:
      case Skill.heyNotTooRough:
        bit = _ThingFlags.easy;
      case Skill.hurtMePlenty:
        bit = _ThingFlags.normal;
      case Skill.ultraViolence:
      case Skill.nightmare:
        bit = _ThingFlags.hard;
    }

    return (options & bit) != 0;
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
      ..reactionTime = _level.skill == Skill.nightmare
          ? 0
          : (info?.reactionTime ?? 8)
      // Original C: mobj->lastlook = P_Random() % MAXPLAYERS;
      ..lastLook = _level.random.pRandom() % 4;

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

// Original C (p_mobj.c):
// ```c
// void P_XYMovement (mobj_t* mo)
// {
//     fixed_t ptryx, ptryy;
//     player_t* player;
//     fixed_t xmove, ymove;
//
//     if (!mo->momx && !mo->momy)
//     {
//         if (mo->flags & MF_SKULLFLY)
//         {
//             // the skull slammed into something
//             mo->flags &= ~MF_SKULLFLY;
//             mo->momx = mo->momy = mo->momz = 0;
//             P_SetMobjState (mo, mo->info->spawnstate);
//         }
//         return;
//     }
//
//     player = mo->player;
//
//     if (mo->momx > MAXMOVE) mo->momx = MAXMOVE;
//     else if (mo->momx < -MAXMOVE) mo->momx = -MAXMOVE;
//     if (mo->momy > MAXMOVE) mo->momy = MAXMOVE;
//     else if (mo->momy < -MAXMOVE) mo->momy = -MAXMOVE;
//
//     xmove = mo->momx;
//     ymove = mo->momy;
//
//     do
//     {
//         if (xmove > MAXMOVE/2 || ymove > MAXMOVE/2)
//         {
//             ptryx = mo->x + xmove/2;
//             ptryy = mo->y + ymove/2;
//             xmove >>= 1;
//             ymove >>= 1;
//         }
//         else
//         {
//             ptryx = mo->x + xmove;
//             ptryy = mo->y + ymove;
//             xmove = ymove = 0;
//         }
//
//         if (!P_TryMove (mo, ptryx, ptryy))
//         {
//             if (mo->player) P_SlideMove (mo);
//             else if (mo->flags & MF_MISSILE)
//             {
//                 // ... sky check omitted ...
//                 P_ExplodeMissile (mo);
//             }
//             else
//                 mo->momx = mo->momy = 0;
//         }
//     } while (xmove || ymove);
//
//     // slow down
//     if (player && player->cheats & CF_NOMOMENTUM)
//     {
//         mo->momx = mo->momy = 0;
//         return;
//     }
//
//     if (mo->flags & (MF_MISSILE | MF_SKULLFLY))
//         return; // no friction for missiles ever
//
//     if (mo->z > mo->floorz)
//         return; // no friction when airborne
//
//     if (mo->flags & MF_CORPSE)
//     {
//         // do not stop sliding if halfway off a step with some momentum
//         if (mo->momx > FRACUNIT/4 || mo->momx < -FRACUNIT/4
//             || mo->momy > FRACUNIT/4 || mo->momy < -FRACUNIT/4)
//         {
//             if (mo->floorz != mo->subsector->sector->floorheight)
//                 return;
//         }
//     }
//
//     if (mo->momx > -STOPSPEED && mo->momx < STOPSPEED
//         && mo->momy > -STOPSPEED && mo->momy < STOPSPEED
//         && (!player || (player->cmd.forwardmove==0 && player->cmd.sidemove==0)))
//     {
//         // if in a walking frame, stop moving
//         if (player && ...)
//             P_SetMobjState (player->mo, S_PLAY);
//         mo->momx = 0;
//         mo->momy = 0;
//     }
//     else
//     {
//         mo->momx = FixedMul (mo->momx, FRICTION);
//         mo->momy = FixedMul (mo->momy, FRICTION);
//     }
// }
// ```
void xyMovement(Mobj mo, LevelLocals level) {
  if (mo.momX == 0 && mo.momY == 0) {
    // Original C: skull slammed into something
    if ((mo.flags & MobjFlag.skullFly) != 0) {
      mo.flags &= ~MobjFlag.skullFly;
      mo.momX = mo.momY = mo.momZ = 0;
      final info = mo.info;
      if (info != null && info.spawnState > 0) {
        spec.setMobjStateNum(mo, info.spawnState, level);
      }
    }
    return;
  }

  final player = mo.player;

  if (mo.momX > PhysicsConstants.maxMove) {
    mo.momX = PhysicsConstants.maxMove;
  } else if (mo.momX < -PhysicsConstants.maxMove) {
    mo.momX = -PhysicsConstants.maxMove;
  }

  if (mo.momY > PhysicsConstants.maxMove) {
    mo.momY = PhysicsConstants.maxMove;
  } else if (mo.momY < -PhysicsConstants.maxMove) {
    mo.momY = -PhysicsConstants.maxMove;
  }

  var xMove = mo.momX;
  var yMove = mo.momY;

  // Original C: do-while loop to split large movements
  do {
    int pTryX;
    int pTryY;

    if (xMove > PhysicsConstants.maxMove ~/ 2 ||
        yMove > PhysicsConstants.maxMove ~/ 2 ||
        xMove < -PhysicsConstants.maxMove ~/ 2 ||
        yMove < -PhysicsConstants.maxMove ~/ 2) {
      pTryX = mo.x + xMove ~/ 2;
      pTryY = mo.y + yMove ~/ 2;
      xMove >>= 1;
      yMove >>= 1;
    } else {
      pTryX = mo.x + xMove;
      pTryY = mo.y + yMove;
      xMove = yMove = 0;
    }

    if (!tryMove(mo, pTryX, pTryY, level)) {
      if (mo.player != null) {
        slideMove(mo, level);
      } else if ((mo.flags & MobjFlag.missile) != 0) {
        explodeMissile(mo, level);
        return;
      } else {
        mo.momX = mo.momY = 0;
      }
    }
  } while (xMove != 0 || yMove != 0);

  // slow down
  if ((mo.flags & (MobjFlag.missile | MobjFlag.skullFly)) != 0) {
    return; // no friction for missiles ever
  }

  if (mo.z > mo.floorZ) {
    return; // no friction when airborne
  }

  // Original C: corpse sliding check
  if ((mo.flags & MobjFlag.corpse) != 0) {
    // do not stop sliding if halfway off a step with some momentum
    const quarterUnit = Fixed32.fracUnit ~/ 4;
    if (mo.momX > quarterUnit ||
        mo.momX < -quarterUnit ||
        mo.momY > quarterUnit ||
        mo.momY < -quarterUnit) {
      final ss = mo.subsector;
      if (ss != null && ss is Subsector) {
        if (mo.floorZ != ss.sector.floorHeight) {
          return;
        }
      }
    }
  }

  // Original C: stop check includes player command check
  final p = player is Player ? player : null;
  if (mo.momX > -PhysicsConstants.stopSpeed &&
      mo.momX < PhysicsConstants.stopSpeed &&
      mo.momY > -PhysicsConstants.stopSpeed &&
      mo.momY < PhysicsConstants.stopSpeed &&
      (p == null || (p.cmd.forwardMove == 0 && p.cmd.sideMove == 0))) {
    mo.momX = 0;
    mo.momY = 0;
  } else {
    mo.momX = Fixed32.mul(mo.momX, PhysicsConstants.friction);
    mo.momY = Fixed32.mul(mo.momY, PhysicsConstants.friction);
  }
}

void zMovement(Mobj mo, LevelLocals level) {
  if (mo.player != null && mo.z < mo.floorZ) {
    final player = mo.player! as Player;
    player.viewHeight -= mo.floorZ - mo.z;
    player.deltaViewHeight = (PlayerConstants.viewHeight - player.viewHeight) >> 3;
  }

  mo.z += mo.momZ;

  // Original C: float down towards target if too close
  // if ( mo->flags & MF_FLOAT && mo->target)
  // {
  //     if ( !(mo->flags & MF_SKULLFLY) && !(mo->flags & MF_INFLOAT) )
  //     { ... }
  // }
  if ((mo.flags & MobjFlag.float) != 0 && mo.target != null) {
    if ((mo.flags & MobjFlag.skullFly) == 0 &&
        (mo.flags & MobjFlag.inFloat) == 0) {
      final dist = approxDistance(mo.x - mo.target!.x, mo.y - mo.target!.y);
      final delta = mo.target!.z + (mo.height >> 1) - mo.z;

      if (delta < 0 && dist < -(delta * 3)) {
        mo.z -= Fixed32.fracUnit;
      } else if (delta > 0 && dist < (delta * 3)) {
        mo.z += Fixed32.fracUnit;
      }
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
      explodeMissile(mo, level);
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

    if ((mo.flags & MobjFlag.missile) != 0 && (mo.flags & MobjFlag.noClip) == 0) {
      explodeMissile(mo, level);
      return;
    }
  }
}

abstract final class _MissileConstants {
  static const int spawnZOffset = 32 * Fixed32.fracUnit;
}

Mobj? spawnMobj(
  int x,
  int y,
  int z,
  int mobjType,
  RenderState state,
  LevelLocals level,
) {
  final info = getProjectileInfo(mobjType);
  if (info == null) return null;

  final mobj = Mobj()
    ..x = x
    ..y = y
    ..type = mobjType
    ..info = info
    ..radius = info.radius
    ..height = info.height
    ..flags = info.flags
    ..health = info.spawnHealth
    ..reactionTime = info.reactionTime
    // Original C: mobj->lastlook = P_Random () % MAXPLAYERS;
    ..lastLook = level.random.pRandom() % 4;

  final spawnState = info.spawnState;
  if (spawnState > 0 && spawnState < states.length) {
    final st = states[spawnState];
    mobj
      ..stateNum = spawnState
      ..tics = st.tics
      ..sprite = st.sprite
      ..frame = st.frame;
  }

  _setMobjPosition(mobj, state, level);

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

  return mobj;
}

void _setMobjPosition(Mobj mobj, RenderState state, LevelLocals level) {
  final ss = _pointInSubsectorGlobal(mobj.x, mobj.y, state);
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
    final blockmap = level.blockmap;
    final blockLinks = level.blockLinks;
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
      }
    }
  }
}

Subsector? _pointInSubsectorGlobal(int x, int y, RenderState state) {
  if (state.nodes.isEmpty) {
    return state.subsectors.isNotEmpty ? state.subsectors[0] : null;
  }

  var nodeNum = state.nodes.length - 1;

  while (!BspConstants.isSubsector(nodeNum)) {
    final node = state.nodes[nodeNum];
    final side = _pointOnSideGlobal(x, y, node);
    nodeNum = node.children[side];
  }

  return state.subsectors[BspConstants.getIndex(nodeNum)];
}

int _pointOnSideGlobal(int x, int y, Node node) {
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

Mobj? spawnMissile(
  Mobj source,
  Mobj dest,
  int mobjType,
  RenderState state,
  LevelLocals level,
) {
  final z = source.z + _MissileConstants.spawnZOffset;
  final th = spawnMobj(source.x, source.y, z, mobjType, state, level);
  if (th == null) return null;

  th.target = source;

  var an = pointToAngle(dest.x - source.x, dest.y - source.y);

  if ((dest.flags & MobjFlag.shadow) != 0) {
    an += (level.random.pRandom() - level.random.pRandom()) << 20;
  }

  th.angle = an;
  final fineAngle = an.u32 >> Angle.angleToFineShift;
  final speed = th.info!.speed;
  th
    ..momX = Fixed32.mul(speed, fineCosine(fineAngle))
    ..momY = Fixed32.mul(speed, fineSine(fineAngle));

  final dist = approxDistance(dest.x - source.x, dest.y - source.y);
  var numDist = dist ~/ speed;
  if (numDist < 1) numDist = 1;

  th.momZ = (dest.z - source.z) ~/ numDist;

  _checkMissileSpawn(th, level);

  return th;
}

Mobj? spawnPlayerMissile(
  Mobj source,
  int mobjType,
  RenderState state,
  LevelLocals level,
) {
  var an = source.angle;
  var slope = aimLineAttack(source, an, _bulletRange, level);

  if (lineTarget == null) {
    an += 1 << 26;
    slope = aimLineAttack(source, an, _bulletRange, level);

    if (lineTarget == null) {
      an -= 2 << 26;
      slope = aimLineAttack(source, an, _bulletRange, level);
    }

    if (lineTarget == null) {
      an = source.angle;
      slope = 0;
    }
  }

  final x = source.x;
  final y = source.y;
  final z = source.z + _MissileConstants.spawnZOffset;

  final th = spawnMobj(x, y, z, mobjType, state, level);
  if (th == null) return null;

  th.target = source;
  th.angle = an;

  final fineAngle = an.u32 >> Angle.angleToFineShift;
  final speed = th.info!.speed;
  th
    ..momX = Fixed32.mul(speed, fineCosine(fineAngle))
    ..momY = Fixed32.mul(speed, fineSine(fineAngle))
    ..momZ = Fixed32.mul(speed, slope);

  _checkMissileSpawn(th, level);

  return th;
}

const _bulletRange = 16 * 64 * Fixed32.fracUnit;

void _checkMissileSpawn(Mobj th, LevelLocals level) {
  th.tics -= level.random.pRandom() & 3;
  if (th.tics < 1) th.tics = 1;

  th
    ..x += th.momX >> 1
    ..y += th.momY >> 1
    ..z += th.momZ >> 1;

  if (!tryMove(th, th.x, th.y, level)) {
    explodeMissile(th, level);
  }
}

void explodeMissile(Mobj mo, LevelLocals level) {
  mo
    ..momX = 0
    ..momY = 0
    ..momZ = 0;

  final info = mo.info;
  if (info != null && info.deathState > 0) {
    spec.setMobjStateNum(mo, info.deathState, level);
  }

  mo.tics -= level.random.pRandom() & 3;
  if (mo.tics < 1) mo.tics = 1;

  mo.flags &= ~MobjFlag.missile;
}

Mobj? spawnEffect(
  int x,
  int y,
  int z,
  int mobjType,
  RenderState state,
  LevelLocals level,
) {
  final info = getEffectInfo(mobjType);
  if (info == null) return null;

  final mobj = Mobj()
    ..x = x
    ..y = y
    ..type = mobjType
    ..info = info
    ..radius = info.radius
    ..height = info.height
    ..flags = info.flags
    ..health = info.spawnHealth
    ..reactionTime = info.reactionTime;

  final spawnState = info.spawnState;
  if (spawnState > 0 && spawnState < states.length) {
    final st = states[spawnState];
    mobj
      ..stateNum = spawnState
      ..tics = st.tics
      ..sprite = st.sprite
      ..frame = st.frame;
  }

  _setMobjPosition(mobj, state, level);

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

  return mobj;
}

Mobj? spawnPuff(
  int x,
  int y,
  int z,
  int attackRange,
  RenderState state,
  LevelLocals level,
) {
  final zOffset = (level.random.pRandom() - level.random.pRandom()) << 10;
  final th = spawnEffect(x, y, z + zOffset, MobjType.puff, state, level);
  if (th == null) return null;

  th.momZ = Fixed32.fracUnit;
  th.tics -= level.random.pRandom() & 3;
  if (th.tics < 1) th.tics = 1;

  if (attackRange == GameConstants.meleeRange) {
    spec.setMobjStateNum(th, StateNum.puff3, level);
  }

  return th;
}

Mobj? spawnBlood(
  int x,
  int y,
  int z,
  int damage,
  RenderState state,
  LevelLocals level,
) {
  final zOffset = (level.random.pRandom() - level.random.pRandom()) << 10;
  final th = spawnEffect(x, y, z + zOffset, MobjType.blood, state, level);
  if (th == null) return null;

  th.momZ = 2 * Fixed32.fracUnit;
  th.tics -= level.random.pRandom() & 3;
  if (th.tics < 1) th.tics = 1;

  if (damage <= 12 && damage >= 9) {
    spec.setMobjStateNum(th, StateNum.blood2, level);
  } else if (damage < 9) {
    spec.setMobjStateNum(th, StateNum.blood3, level);
  }

  return th;
}

Mobj? spawnSkull(
  int x,
  int y,
  int z,
  RenderState state,
  LevelLocals level,
) {
  final info = _getMonsterInfo(MobjType.skull);
  if (info == null) return null;

  final mobj = Mobj()
    ..x = x
    ..y = y
    ..type = MobjType.skull
    ..info = info
    ..radius = info.radius
    ..height = info.height
    ..flags = info.flags
    ..health = info.spawnHealth
    ..reactionTime = level.skill == Skill.nightmare ? 0 : info.reactionTime;

  final spawnState = info.spawnState;
  if (spawnState > 0 && spawnState < states.length) {
    final st = states[spawnState];
    mobj
      ..stateNum = spawnState
      ..tics = st.tics
      ..sprite = st.sprite
      ..frame = st.frame;
  }

  _setMobjPosition(mobj, state, level);

  final ss = mobj.subsector;
  if (ss == null || ss is! Subsector) return null;

  mobj
    ..floorZ = ss.sector.floorHeight
    ..ceilingZ = ss.sector.ceilingHeight
    ..z = z;

  return mobj;
}

int countSkulls(RenderState state) {
  var count = 0;
  for (final sector in state.sectors) {
    var thing = sector.thingList;
    while (thing != null) {
      if (thing.type == MobjType.skull && thing.health > 0) {
        count++;
      }
      thing = thing.sNext;
    }
  }
  return count;
}
