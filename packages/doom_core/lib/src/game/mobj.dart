abstract final class MobjFlag {
  static const int special = 0x1;
  static const int solid = 0x2;
  static const int shootable = 0x4;
  static const int noSector = 0x8;
  static const int noBlockmap = 0x10;
  static const int ambush = 0x20;
  static const int justHit = 0x40;
  static const int justAttacked = 0x80;
  static const int spawnCeiling = 0x100;
  static const int noGravity = 0x200;
  static const int dropOff = 0x400;
  static const int pickup = 0x800;
  static const int noClip = 0x1000;
  static const int slide = 0x2000;
  static const int float = 0x4000;
  static const int teleport = 0x8000;
  static const int missile = 0x10000;
  static const int dropped = 0x20000;
  static const int shadow = 0x40000;
  static const int noBlood = 0x80000;
  static const int corpse = 0x100000;
  static const int inFloat = 0x200000;
  static const int countKill = 0x400000;
  static const int countItem = 0x800000;
  static const int skullFly = 0x1000000;
  static const int notDmatch = 0x2000000;
  static const int translation = 0xc000000;
  static const int transShift = 26;
}

abstract final class FrameFlag {
  static const int frameMask = 0x7FFF;
  static const int fullBright = 0x8000;
}

class MobjInfo {
  const MobjInfo({
    required this.doomEdNum,
    required this.spawnState,
    required this.spawnHealth,
    required this.seeState,
    required this.reactionTime, required this.painState, required this.painChance, required this.meleeState, required this.missileState, required this.deathState, required this.xDeathState, required this.speed, required this.radius, required this.height, required this.mass, required this.flags, required this.raiseState, this.seeSound = 0,
    this.attackSound = 0,
    this.painSound = 0,
    this.deathSound = 0,
    this.damage = 0,
    this.activeSound = 0,
  });

  final int doomEdNum;
  final int spawnState;
  final int spawnHealth;
  final int seeState;
  final int seeSound;
  final int reactionTime;
  final int attackSound;
  final int painState;
  final int painChance;
  final int painSound;
  final int meleeState;
  final int missileState;
  final int deathState;
  final int xDeathState;
  final int deathSound;
  final int speed;
  final int radius;
  final int height;
  final int mass;
  final int damage;
  final int activeSound;
  final int flags;
  final int raiseState;
}

class StateInfo {
  const StateInfo({
    required this.sprite,
    required this.frame,
    required this.tics,
    required this.nextState,
  });

  final int sprite;
  final int frame;
  final int tics;
  final int nextState;
}

class Mobj {
  int x = 0;
  int y = 0;
  int z = 0;

  Mobj? sNext;
  Mobj? sPrev;

  int angle = 0;
  int sprite = 0;
  int frame = 0;

  Mobj? bNext;
  Mobj? bPrev;

  Object? subsector;

  int floorZ = 0;
  int ceilingZ = 0;

  int radius = 0;
  int height = 0;

  int momX = 0;
  int momY = 0;
  int momZ = 0;

  int validCount = 0;

  int type = 0;
  MobjInfo? info;

  int tics = 0;
  int stateNum = 0;
  int flags = 0;
  int health = 0;

  int moveDir = 0;
  int moveCount = 0;

  Mobj? target;
  Object? player;

  int reactionTime = 0;
  int threshold = 0;

  int lastLook = 0;

  int spawnX = 0;
  int spawnY = 0;
  int spawnAngle = 0;
  int spawnType = 0;
  int spawnOptions = 0;

  Mobj? tracer;
}
