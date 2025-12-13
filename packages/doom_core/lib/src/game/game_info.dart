import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_math/doom_math.dart';

abstract final class SpriteNum {
  static const int troo = 0;
  static const int shtg = 1;
  static const int pung = 2;
  static const int pisg = 3;
  static const int pisf = 4;
  static const int shtf = 5;
  static const int sht2 = 6;
  static const int chgg = 7;
  static const int chgf = 8;
  static const int misg = 9;
  static const int misf = 10;
  static const int sawg = 11;
  static const int plsg = 12;
  static const int plsf = 13;
  static const int bfgg = 14;
  static const int bfgf = 15;
  static const int blud = 16;
  static const int puff = 17;
  static const int bal1 = 18;
  static const int bal2 = 19;
  static const int plss = 20;
  static const int plse = 21;
  static const int misl = 22;
  static const int bfs1 = 23;
  static const int bfe1 = 24;
  static const int bfe2 = 25;
  static const int tfog = 26;
  static const int ifog = 27;
  static const int play = 28;
  static const int poss = 29;
  static const int spos = 30;
  static const int vile = 31;
  static const int fire = 32;
  static const int fatb = 33;
  static const int fbxp = 34;
  static const int skel = 35;
  static const int manf = 36;
  static const int fatt = 37;
  static const int cpos = 38;
  static const int sarg = 39;
  static const int head = 40;
  static const int bal7 = 41;
  static const int boss = 42;
  static const int bos2 = 43;
  static const int skul = 44;
  static const int spid = 45;
  static const int bspi = 46;
  static const int apls = 47;
  static const int apbx = 48;
  static const int cybr = 49;
  static const int pain = 50;
  static const int sswv = 51;
  static const int keen = 52;
  static const int bbrn = 53;
  static const int bosf = 54;
  static const int arm1 = 55;
  static const int arm2 = 56;
  static const int bar1 = 57;
  static const int bexp = 58;
  static const int fcan = 59;
  static const int bon1 = 60;
  static const int bon2 = 61;
  static const int bkey = 62;
  static const int rkey = 63;
  static const int ykey = 64;
  static const int bsku = 65;
  static const int rsku = 66;
  static const int ysku = 67;
  static const int stim = 68;
  static const int medi = 69;
  static const int soul = 70;
  static const int pinv = 71;
  static const int pstr = 72;
  static const int pins = 73;
  static const int mega = 74;
  static const int suit = 75;
  static const int pmap = 76;
  static const int pvis = 77;
  static const int clip = 78;
  static const int ammo = 79;
  static const int rock = 80;
  static const int brok = 81;
  static const int cell = 82;
  static const int celp = 83;
  static const int shel = 84;
  static const int sbox = 85;
  static const int bpak = 86;
  static const int bfug = 87;
  static const int mgun = 88;
  static const int csaw = 89;
  static const int laun = 90;
  static const int plas = 91;
  static const int shot = 92;
  static const int sgn2 = 93;
  static const int colu = 94;
  static const int smt2 = 95;
  static const int gor1 = 96;
  static const int pol2 = 97;
  static const int pol5 = 98;
  static const int pol4 = 99;
  static const int pol3 = 100;
  static const int pol1 = 101;
  static const int pol6 = 102;
  static const int gor2 = 103;
  static const int gor3 = 104;
  static const int gor4 = 105;
  static const int gor5 = 106;
  static const int smit = 107;
  static const int col1 = 108;
  static const int col2 = 109;
  static const int col3 = 110;
  static const int col4 = 111;
  static const int cand = 112;
  static const int cbra = 113;
  static const int col6 = 114;
  static const int tre1 = 115;
  static const int tre2 = 116;
  static const int elec = 117;
  static const int ceye = 118;
  static const int fsku = 119;
  static const int col5 = 120;
  static const int tblu = 121;
  static const int tgrn = 122;
  static const int tred = 123;
  static const int smbt = 124;
  static const int smgt = 125;
  static const int smrt = 126;
  static const int hdb1 = 127;
  static const int hdb2 = 128;
  static const int hdb3 = 129;
  static const int hdb4 = 130;
  static const int hdb5 = 131;
  static const int hdb6 = 132;
  static const int pob1 = 133;
  static const int pob2 = 134;
  static const int brs1 = 135;
  static const int tlmp = 136;
  static const int tlp2 = 137;

  static const int numSprites = 138;
}

const List<String> spriteNames = [
  'TROO', 'SHTG', 'PUNG', 'PISG', 'PISF', 'SHTF', 'SHT2', 'CHGG', 'CHGF', 'MISG',
  'MISF', 'SAWG', 'PLSG', 'PLSF', 'BFGG', 'BFGF', 'BLUD', 'PUFF', 'BAL1', 'BAL2',
  'PLSS', 'PLSE', 'MISL', 'BFS1', 'BFE1', 'BFE2', 'TFOG', 'IFOG', 'PLAY', 'POSS',
  'SPOS', 'VILE', 'FIRE', 'FATB', 'FBXP', 'SKEL', 'MANF', 'FATT', 'CPOS', 'SARG',
  'HEAD', 'BAL7', 'BOSS', 'BOS2', 'SKUL', 'SPID', 'BSPI', 'APLS', 'APBX', 'CYBR',
  'PAIN', 'SSWV', 'KEEN', 'BBRN', 'BOSF', 'ARM1', 'ARM2', 'BAR1', 'BEXP', 'FCAN',
  'BON1', 'BON2', 'BKEY', 'RKEY', 'YKEY', 'BSKU', 'RSKU', 'YSKU', 'STIM', 'MEDI',
  'SOUL', 'PINV', 'PSTR', 'PINS', 'MEGA', 'SUIT', 'PMAP', 'PVIS', 'CLIP', 'AMMO',
  'ROCK', 'BROK', 'CELL', 'CELP', 'SHEL', 'SBOX', 'BPAK', 'BFUG', 'MGUN', 'CSAW',
  'LAUN', 'PLAS', 'SHOT', 'SGN2', 'COLU', 'SMT2', 'GOR1', 'POL2', 'POL5', 'POL4',
  'POL3', 'POL1', 'POL6', 'GOR2', 'GOR3', 'GOR4', 'GOR5', 'SMIT', 'COL1', 'COL2',
  'COL3', 'COL4', 'CAND', 'CBRA', 'COL6', 'TRE1', 'TRE2', 'ELEC', 'CEYE', 'FSKU',
  'COL5', 'TBLU', 'TGRN', 'TRED', 'SMBT', 'SMGT', 'SMRT', 'HDB1', 'HDB2', 'HDB3',
  'HDB4', 'HDB5', 'HDB6', 'POB1', 'POB2', 'BRS1', 'TLMP', 'TLP2',
];

abstract final class _FU {
  static const int unit = Fixed32.fracUnit;
}

class ThingDef {
  const ThingDef({
    required this.sprite,
    required this.frame,
    required this.radius,
    required this.height,
    this.flags = 0,
    this.tics = -1,
  });

  final int sprite;
  final int frame;
  final int radius;
  final int height;
  final int flags;
  final int tics;
}

const Map<int, ThingDef> thingDefs = {
  1: ThingDef(sprite: SpriteNum.play, frame: 0, radius: 16 * _FU.unit, height: 56 * _FU.unit),
  2: ThingDef(sprite: SpriteNum.play, frame: 0, radius: 16 * _FU.unit, height: 56 * _FU.unit),
  3: ThingDef(sprite: SpriteNum.play, frame: 0, radius: 16 * _FU.unit, height: 56 * _FU.unit),
  4: ThingDef(sprite: SpriteNum.play, frame: 0, radius: 16 * _FU.unit, height: 56 * _FU.unit),

  2035: ThingDef(sprite: SpriteNum.bar1, frame: 0, radius: 10 * _FU.unit, height: 42 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.noBlood),

  2028: ThingDef(sprite: SpriteNum.colu, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  30: ThingDef(sprite: SpriteNum.col1, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  31: ThingDef(sprite: SpriteNum.col2, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  32: ThingDef(sprite: SpriteNum.col3, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  33: ThingDef(sprite: SpriteNum.col4, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  37: ThingDef(sprite: SpriteNum.col6, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  2001: ThingDef(sprite: SpriteNum.shot, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2002: ThingDef(sprite: SpriteNum.mgun, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2003: ThingDef(sprite: SpriteNum.laun, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2004: ThingDef(sprite: SpriteNum.plas, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2005: ThingDef(sprite: SpriteNum.csaw, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2006: ThingDef(sprite: SpriteNum.bfug, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),

  2007: ThingDef(sprite: SpriteNum.clip, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2008: ThingDef(sprite: SpriteNum.shel, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2010: ThingDef(sprite: SpriteNum.rock, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2046: ThingDef(sprite: SpriteNum.brok, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2047: ThingDef(sprite: SpriteNum.cell, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),

  2048: ThingDef(sprite: SpriteNum.ammo, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2049: ThingDef(sprite: SpriteNum.sbox, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  17: ThingDef(sprite: SpriteNum.celp, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),

  8: ThingDef(sprite: SpriteNum.bpak, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),

  2011: ThingDef(sprite: SpriteNum.stim, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2012: ThingDef(sprite: SpriteNum.medi, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2013: ThingDef(sprite: SpriteNum.soul, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  2014: ThingDef(sprite: SpriteNum.bon1, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  2015: ThingDef(sprite: SpriteNum.bon2, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),

  2018: ThingDef(sprite: SpriteNum.arm1, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2019: ThingDef(sprite: SpriteNum.arm2, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),

  5: ThingDef(sprite: SpriteNum.bkey, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),
  13: ThingDef(sprite: SpriteNum.rkey, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),
  6: ThingDef(sprite: SpriteNum.ykey, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),
  40: ThingDef(sprite: SpriteNum.bsku, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),
  38: ThingDef(sprite: SpriteNum.rsku, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),
  39: ThingDef(sprite: SpriteNum.ysku, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.notDmatch),

  2024: ThingDef(sprite: SpriteNum.pins, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  2025: ThingDef(sprite: SpriteNum.suit, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special),
  2026: ThingDef(sprite: SpriteNum.pmap, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  2045: ThingDef(sprite: SpriteNum.pvis, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),

  2022: ThingDef(sprite: SpriteNum.pinv, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  2023: ThingDef(sprite: SpriteNum.pstr, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),
  83: ThingDef(sprite: SpriteNum.mega, frame: 32768, radius: 20 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.special | MobjFlag.countItem),

  3004: ThingDef(sprite: SpriteNum.poss, frame: 0, radius: 20 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill),
  9: ThingDef(sprite: SpriteNum.spos, frame: 0, radius: 20 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill),

  3001: ThingDef(sprite: SpriteNum.troo, frame: 0, radius: 20 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill),
  3002: ThingDef(sprite: SpriteNum.sarg, frame: 0, radius: 30 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill),

  3003: ThingDef(sprite: SpriteNum.boss, frame: 0, radius: 24 * _FU.unit, height: 64 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.countKill),
  3005: ThingDef(sprite: SpriteNum.head, frame: 0, radius: 31 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.float | MobjFlag.noGravity | MobjFlag.countKill),
  3006: ThingDef(sprite: SpriteNum.skul, frame: 32768, radius: 16 * _FU.unit, height: 56 * _FU.unit, flags: MobjFlag.solid | MobjFlag.shootable | MobjFlag.float | MobjFlag.noGravity | MobjFlag.countKill),

  2044: ThingDef(sprite: SpriteNum.tblu, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  46: ThingDef(sprite: SpriteNum.tred, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  55: ThingDef(sprite: SpriteNum.smbt, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  56: ThingDef(sprite: SpriteNum.smgt, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  57: ThingDef(sprite: SpriteNum.smrt, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  47: ThingDef(sprite: SpriteNum.smit, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  48: ThingDef(sprite: SpriteNum.elec, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  35: ThingDef(sprite: SpriteNum.cand, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  34: ThingDef(sprite: SpriteNum.cbra, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  41: ThingDef(sprite: SpriteNum.ceye, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  42: ThingDef(sprite: SpriteNum.fsku, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  43: ThingDef(sprite: SpriteNum.tre1, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  44: ThingDef(sprite: SpriteNum.tblu, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  45: ThingDef(sprite: SpriteNum.tgrn, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  54: ThingDef(sprite: SpriteNum.tre2, frame: 0, radius: 32 * _FU.unit, height: 16 * _FU.unit),

  2038: ThingDef(sprite: SpriteNum.fcan, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  85: ThingDef(sprite: SpriteNum.tlmp, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit),
  86: ThingDef(sprite: SpriteNum.tlp2, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit),

  25: ThingDef(sprite: SpriteNum.pol1, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  26: ThingDef(sprite: SpriteNum.pol6, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  27: ThingDef(sprite: SpriteNum.pol4, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  28: ThingDef(sprite: SpriteNum.pol2, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),
  29: ThingDef(sprite: SpriteNum.pol3, frame: 32768, radius: 16 * _FU.unit, height: 16 * _FU.unit, flags: MobjFlag.solid),

  24: ThingDef(sprite: SpriteNum.pol5, frame: 0, radius: 16 * _FU.unit, height: 16 * _FU.unit),

  10: ThingDef(sprite: SpriteNum.play, frame: 13, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  12: ThingDef(sprite: SpriteNum.play, frame: 18, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  15: ThingDef(sprite: SpriteNum.play, frame: 13, radius: 20 * _FU.unit, height: 16 * _FU.unit),

  18: ThingDef(sprite: SpriteNum.poss, frame: 12, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  19: ThingDef(sprite: SpriteNum.spos, frame: 12, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  20: ThingDef(sprite: SpriteNum.troo, frame: 12, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  21: ThingDef(sprite: SpriteNum.sarg, frame: 13, radius: 30 * _FU.unit, height: 16 * _FU.unit),
  22: ThingDef(sprite: SpriteNum.head, frame: 12, radius: 31 * _FU.unit, height: 16 * _FU.unit),
  23: ThingDef(sprite: SpriteNum.skul, frame: 11, radius: 16 * _FU.unit, height: 16 * _FU.unit),

  49: ThingDef(sprite: SpriteNum.gor1, frame: 32768, radius: 16 * _FU.unit, height: 68 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  63: ThingDef(sprite: SpriteNum.gor1, frame: 32768, radius: 16 * _FU.unit, height: 68 * _FU.unit, flags: MobjFlag.spawnCeiling | MobjFlag.noGravity),
  50: ThingDef(sprite: SpriteNum.gor2, frame: 32768, radius: 16 * _FU.unit, height: 84 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  59: ThingDef(sprite: SpriteNum.gor2, frame: 32768, radius: 20 * _FU.unit, height: 84 * _FU.unit, flags: MobjFlag.spawnCeiling | MobjFlag.noGravity),
  52: ThingDef(sprite: SpriteNum.gor4, frame: 32768, radius: 16 * _FU.unit, height: 68 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  60: ThingDef(sprite: SpriteNum.gor4, frame: 32768, radius: 20 * _FU.unit, height: 68 * _FU.unit, flags: MobjFlag.spawnCeiling | MobjFlag.noGravity),
  51: ThingDef(sprite: SpriteNum.gor3, frame: 32768, radius: 16 * _FU.unit, height: 52 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  61: ThingDef(sprite: SpriteNum.gor3, frame: 32768, radius: 20 * _FU.unit, height: 52 * _FU.unit, flags: MobjFlag.spawnCeiling | MobjFlag.noGravity),
  53: ThingDef(sprite: SpriteNum.gor5, frame: 32768, radius: 16 * _FU.unit, height: 52 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  62: ThingDef(sprite: SpriteNum.gor5, frame: 32768, radius: 20 * _FU.unit, height: 52 * _FU.unit, flags: MobjFlag.spawnCeiling | MobjFlag.noGravity),

  73: ThingDef(sprite: SpriteNum.hdb1, frame: 32768, radius: 16 * _FU.unit, height: 88 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  74: ThingDef(sprite: SpriteNum.hdb2, frame: 32768, radius: 16 * _FU.unit, height: 88 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  75: ThingDef(sprite: SpriteNum.hdb3, frame: 32768, radius: 16 * _FU.unit, height: 64 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  76: ThingDef(sprite: SpriteNum.hdb4, frame: 32768, radius: 16 * _FU.unit, height: 64 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  77: ThingDef(sprite: SpriteNum.hdb5, frame: 32768, radius: 16 * _FU.unit, height: 64 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),
  78: ThingDef(sprite: SpriteNum.hdb6, frame: 32768, radius: 16 * _FU.unit, height: 64 * _FU.unit, flags: MobjFlag.solid | MobjFlag.spawnCeiling | MobjFlag.noGravity),

  79: ThingDef(sprite: SpriteNum.pob1, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  80: ThingDef(sprite: SpriteNum.pob2, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit),
  81: ThingDef(sprite: SpriteNum.brs1, frame: 0, radius: 20 * _FU.unit, height: 16 * _FU.unit),
};
