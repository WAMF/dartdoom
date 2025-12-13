import 'package:doom_core/src/game/mobj.dart';

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
}

abstract final class StateNum {
  static const int sNull = 0;

  static const int possStnd = 1;
  static const int possStnd2 = 2;
  static const int possRun1 = 3;
  static const int possRun2 = 4;
  static const int possRun3 = 5;
  static const int possRun4 = 6;
  static const int possRun5 = 7;
  static const int possRun6 = 8;
  static const int possRun7 = 9;
  static const int possRun8 = 10;
  static const int possAtk1 = 11;
  static const int possAtk2 = 12;
  static const int possAtk3 = 13;
  static const int possPain = 14;
  static const int possPain2 = 15;
  static const int possDie1 = 16;
  static const int possDie2 = 17;
  static const int possDie3 = 18;
  static const int possDie4 = 19;
  static const int possDie5 = 20;
  static const int possXdie1 = 21;
  static const int possXdie2 = 22;
  static const int possXdie3 = 23;
  static const int possXdie4 = 24;
  static const int possXdie5 = 25;
  static const int possXdie6 = 26;
  static const int possXdie7 = 27;
  static const int possXdie8 = 28;
  static const int possXdie9 = 29;
  static const int possRaise1 = 30;
  static const int possRaise2 = 31;
  static const int possRaise3 = 32;
  static const int possRaise4 = 33;

  static const int sposStnd = 34;
  static const int sposStnd2 = 35;
  static const int sposRun1 = 36;
  static const int sposRun2 = 37;
  static const int sposRun3 = 38;
  static const int sposRun4 = 39;
  static const int sposRun5 = 40;
  static const int sposRun6 = 41;
  static const int sposRun7 = 42;
  static const int sposRun8 = 43;
  static const int sposAtk1 = 44;
  static const int sposAtk2 = 45;
  static const int sposAtk3 = 46;
  static const int sposPain = 47;
  static const int sposPain2 = 48;
  static const int sposDie1 = 49;
  static const int sposDie2 = 50;
  static const int sposDie3 = 51;
  static const int sposDie4 = 52;
  static const int sposDie5 = 53;
  static const int sposXdie1 = 54;
  static const int sposXdie2 = 55;
  static const int sposXdie3 = 56;
  static const int sposXdie4 = 57;
  static const int sposXdie5 = 58;
  static const int sposXdie6 = 59;
  static const int sposXdie7 = 60;
  static const int sposXdie8 = 61;
  static const int sposXdie9 = 62;
  static const int sposRaise1 = 63;
  static const int sposRaise2 = 64;
  static const int sposRaise3 = 65;
  static const int sposRaise4 = 66;
  static const int sposRaise5 = 67;

  static const int troopStnd = 68;
  static const int troopStnd2 = 69;
  static const int troopRun1 = 70;
  static const int troopRun2 = 71;
  static const int troopRun3 = 72;
  static const int troopRun4 = 73;
  static const int troopRun5 = 74;
  static const int troopRun6 = 75;
  static const int troopRun7 = 76;
  static const int troopRun8 = 77;
  static const int troopAtk1 = 78;
  static const int troopAtk2 = 79;
  static const int troopAtk3 = 80;
  static const int troopPain = 81;
  static const int troopPain2 = 82;
  static const int troopDie1 = 83;
  static const int troopDie2 = 84;
  static const int troopDie3 = 85;
  static const int troopDie4 = 86;
  static const int troopDie5 = 87;
  static const int troopXdie1 = 88;
  static const int troopXdie2 = 89;
  static const int troopXdie3 = 90;
  static const int troopXdie4 = 91;
  static const int troopXdie5 = 92;
  static const int troopXdie6 = 93;
  static const int troopXdie7 = 94;
  static const int troopXdie8 = 95;
  static const int troopRaise1 = 96;
  static const int troopRaise2 = 97;

  static const int sargStnd = 98;
  static const int sargStnd2 = 99;
  static const int sargRun1 = 100;
  static const int sargRun2 = 101;
  static const int sargRun3 = 102;
  static const int sargRun4 = 103;
  static const int sargRun5 = 104;
  static const int sargRun6 = 105;
  static const int sargRun7 = 106;
  static const int sargRun8 = 107;
  static const int sargAtk1 = 108;
  static const int sargAtk2 = 109;
  static const int sargAtk3 = 110;
  static const int sargPain = 111;
  static const int sargPain2 = 112;
  static const int sargDie1 = 113;
  static const int sargDie2 = 114;
  static const int sargDie3 = 115;
  static const int sargDie4 = 116;
  static const int sargDie5 = 117;
  static const int sargDie6 = 118;
  static const int sargRaise1 = 119;
  static const int sargRaise2 = 120;
  static const int sargRaise3 = 121;
  static const int sargRaise4 = 122;
  static const int sargRaise5 = 123;
  static const int sargRaise6 = 124;

  static const int headStnd = 125;
  static const int headRun1 = 126;
  static const int headAtk1 = 127;
  static const int headAtk2 = 128;
  static const int headAtk3 = 129;
  static const int headPain = 130;
  static const int headPain2 = 131;
  static const int headPain3 = 132;
  static const int headDie1 = 133;
  static const int headDie2 = 134;
  static const int headDie3 = 135;
  static const int headDie4 = 136;
  static const int headDie5 = 137;
  static const int headDie6 = 138;
  static const int headRaise1 = 139;
  static const int headRaise2 = 140;
  static const int headRaise3 = 141;
  static const int headRaise4 = 142;
  static const int headRaise5 = 143;
  static const int headRaise6 = 144;

  static const int skulStnd = 145;
  static const int skulStnd2 = 146;
  static const int skulRun1 = 147;
  static const int skulRun2 = 148;
  static const int skulAtk1 = 149;
  static const int skulAtk2 = 150;
  static const int skulAtk3 = 151;
  static const int skulAtk4 = 152;
  static const int skulPain = 153;
  static const int skulPain2 = 154;
  static const int skulDie1 = 155;
  static const int skulDie2 = 156;
  static const int skulDie3 = 157;
  static const int skulDie4 = 158;
  static const int skulDie5 = 159;
  static const int skulDie6 = 160;

  static const int bossStnd = 161;
  static const int bossStnd2 = 162;
  static const int bossRun1 = 163;
  static const int bossRun2 = 164;
  static const int bossRun3 = 165;
  static const int bossRun4 = 166;
  static const int bossRun5 = 167;
  static const int bossRun6 = 168;
  static const int bossRun7 = 169;
  static const int bossRun8 = 170;
  static const int bossAtk1 = 171;
  static const int bossAtk2 = 172;
  static const int bossAtk3 = 173;
  static const int bossPain = 174;
  static const int bossPain2 = 175;
  static const int bossDie1 = 176;
  static const int bossDie2 = 177;
  static const int bossDie3 = 178;
  static const int bossDie4 = 179;
  static const int bossDie5 = 180;
  static const int bossDie6 = 181;
  static const int bossDie7 = 182;
  static const int bossRaise1 = 183;
  static const int bossRaise2 = 184;
  static const int bossRaise3 = 185;
  static const int bossRaise4 = 186;
  static const int bossRaise5 = 187;
  static const int bossRaise6 = 188;
  static const int bossRaise7 = 189;

  static const int tball1 = 190;
  static const int tball2 = 191;
  static const int tballx1 = 192;
  static const int tballx2 = 193;
  static const int tballx3 = 194;

  static const int rball1 = 195;
  static const int rball2 = 196;
  static const int rballx1 = 197;
  static const int rballx2 = 198;
  static const int rballx3 = 199;

  static const int brball1 = 200;
  static const int brball2 = 201;
  static const int brballx1 = 202;
  static const int brballx2 = 203;
  static const int brballx3 = 204;

  static const int rocket = 205;
  static const int explode1 = 206;
  static const int explode2 = 207;
  static const int explode3 = 208;

  static const int plasball1 = 209;
  static const int plasball2 = 210;
  static const int plasexp1 = 211;
  static const int plasexp2 = 212;
  static const int plasexp3 = 213;
  static const int plasexp4 = 214;
  static const int plasexp5 = 215;

  static const int bfgshot1 = 216;
  static const int bfgshot2 = 217;
  static const int bfgland1 = 218;
  static const int bfgland2 = 219;
  static const int bfgland3 = 220;
  static const int bfgland4 = 221;
  static const int bfgland5 = 222;
  static const int bfgland6 = 223;

  static const int tracer1 = 224;
  static const int tracer2 = 225;
  static const int traceexp1 = 226;
  static const int traceexp2 = 227;
  static const int traceexp3 = 228;

  static const int fatshot1 = 229;
  static const int fatshot2 = 230;
  static const int fatshotx1 = 231;
  static const int fatshotx2 = 232;
  static const int fatshotx3 = 233;

  static const int arachPlaz1 = 234;
  static const int arachPlaz2 = 235;
  static const int arachPlex1 = 236;
  static const int arachPlex2 = 237;
  static const int arachPlex3 = 238;
  static const int arachPlex4 = 239;
  static const int arachPlex5 = 240;

  static const int bar1 = 241;
  static const int bar2 = 242;
  static const int bexp = 243;
  static const int bexp2 = 244;
  static const int bexp3 = 245;
  static const int bexp4 = 246;
  static const int bexp5 = 247;
}

enum StateAction {
  none,
  look,
  chase,
  faceTarget,
  posAttack,
  sPosAttack,
  cPosAttack,
  cPosRefire,
  troopAttack,
  sargAttack,
  headAttack,
  bruisAttack,
  skullAttack,
  scream,
  xScream,
  pain,
  fall,
  explode,
  bfgSpray,
  tracer,
  cyberAttack,
  spidRefire,
  bspiAttack,
  fatAttack1,
  fatAttack2,
  fatAttack3,
  fatRaise,
  skelMissile,
  skelWhoosh,
  painAttack,
  painDie,
}

class MobjState {
  const MobjState(
    this.sprite,
    this.frame,
    this.tics,
    this.action,
    this.nextState,
  );

  final int sprite;
  final int frame;
  final int tics;
  final StateAction action;
  final int nextState;
}

const List<MobjState> states = [
  MobjState(0, 0, -1, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.poss, 0, 10, StateAction.look, StateNum.possStnd2),
  MobjState(SpriteNum.poss, 1, 10, StateAction.look, StateNum.possStnd),
  MobjState(SpriteNum.poss, 0, 4, StateAction.chase, StateNum.possRun2),
  MobjState(SpriteNum.poss, 0, 4, StateAction.chase, StateNum.possRun3),
  MobjState(SpriteNum.poss, 1, 4, StateAction.chase, StateNum.possRun4),
  MobjState(SpriteNum.poss, 1, 4, StateAction.chase, StateNum.possRun5),
  MobjState(SpriteNum.poss, 2, 4, StateAction.chase, StateNum.possRun6),
  MobjState(SpriteNum.poss, 2, 4, StateAction.chase, StateNum.possRun7),
  MobjState(SpriteNum.poss, 3, 4, StateAction.chase, StateNum.possRun8),
  MobjState(SpriteNum.poss, 3, 4, StateAction.chase, StateNum.possRun1),
  MobjState(SpriteNum.poss, 4, 10, StateAction.faceTarget, StateNum.possAtk2),
  MobjState(SpriteNum.poss, 5, 8, StateAction.posAttack, StateNum.possAtk3),
  MobjState(SpriteNum.poss, 4, 8, StateAction.none, StateNum.possRun1),
  MobjState(SpriteNum.poss, 6, 3, StateAction.none, StateNum.possPain2),
  MobjState(SpriteNum.poss, 6, 3, StateAction.pain, StateNum.possRun1),
  MobjState(SpriteNum.poss, 7, 5, StateAction.none, StateNum.possDie2),
  MobjState(SpriteNum.poss, 8, 5, StateAction.scream, StateNum.possDie3),
  MobjState(SpriteNum.poss, 9, 5, StateAction.fall, StateNum.possDie4),
  MobjState(SpriteNum.poss, 10, 5, StateAction.none, StateNum.possDie5),
  MobjState(SpriteNum.poss, 11, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.poss, 12, 5, StateAction.none, StateNum.possXdie2),
  MobjState(SpriteNum.poss, 13, 5, StateAction.xScream, StateNum.possXdie3),
  MobjState(SpriteNum.poss, 14, 5, StateAction.fall, StateNum.possXdie4),
  MobjState(SpriteNum.poss, 15, 5, StateAction.none, StateNum.possXdie5),
  MobjState(SpriteNum.poss, 16, 5, StateAction.none, StateNum.possXdie6),
  MobjState(SpriteNum.poss, 17, 5, StateAction.none, StateNum.possXdie7),
  MobjState(SpriteNum.poss, 18, 5, StateAction.none, StateNum.possXdie8),
  MobjState(SpriteNum.poss, 19, 5, StateAction.none, StateNum.possXdie9),
  MobjState(SpriteNum.poss, 20, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.poss, 10, 5, StateAction.none, StateNum.possRaise2),
  MobjState(SpriteNum.poss, 9, 5, StateAction.none, StateNum.possRaise3),
  MobjState(SpriteNum.poss, 8, 5, StateAction.none, StateNum.possRaise4),
  MobjState(SpriteNum.poss, 7, 5, StateAction.none, StateNum.possRun1),

  MobjState(SpriteNum.spos, 0, 10, StateAction.look, StateNum.sposStnd2),
  MobjState(SpriteNum.spos, 1, 10, StateAction.look, StateNum.sposStnd),
  MobjState(SpriteNum.spos, 0, 3, StateAction.chase, StateNum.sposRun2),
  MobjState(SpriteNum.spos, 0, 3, StateAction.chase, StateNum.sposRun3),
  MobjState(SpriteNum.spos, 1, 3, StateAction.chase, StateNum.sposRun4),
  MobjState(SpriteNum.spos, 1, 3, StateAction.chase, StateNum.sposRun5),
  MobjState(SpriteNum.spos, 2, 3, StateAction.chase, StateNum.sposRun6),
  MobjState(SpriteNum.spos, 2, 3, StateAction.chase, StateNum.sposRun7),
  MobjState(SpriteNum.spos, 3, 3, StateAction.chase, StateNum.sposRun8),
  MobjState(SpriteNum.spos, 3, 3, StateAction.chase, StateNum.sposRun1),
  MobjState(SpriteNum.spos, 4, 10, StateAction.faceTarget, StateNum.sposAtk2),
  MobjState(SpriteNum.spos, 5, 10, StateAction.sPosAttack, StateNum.sposAtk3),
  MobjState(SpriteNum.spos, 4, 10, StateAction.none, StateNum.sposRun1),
  MobjState(SpriteNum.spos, 6, 3, StateAction.none, StateNum.sposPain2),
  MobjState(SpriteNum.spos, 6, 3, StateAction.pain, StateNum.sposRun1),
  MobjState(SpriteNum.spos, 7, 5, StateAction.none, StateNum.sposDie2),
  MobjState(SpriteNum.spos, 8, 5, StateAction.scream, StateNum.sposDie3),
  MobjState(SpriteNum.spos, 9, 5, StateAction.fall, StateNum.sposDie4),
  MobjState(SpriteNum.spos, 10, 5, StateAction.none, StateNum.sposDie5),
  MobjState(SpriteNum.spos, 11, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.spos, 12, 5, StateAction.none, StateNum.sposXdie2),
  MobjState(SpriteNum.spos, 13, 5, StateAction.xScream, StateNum.sposXdie3),
  MobjState(SpriteNum.spos, 14, 5, StateAction.fall, StateNum.sposXdie4),
  MobjState(SpriteNum.spos, 15, 5, StateAction.none, StateNum.sposXdie5),
  MobjState(SpriteNum.spos, 16, 5, StateAction.none, StateNum.sposXdie6),
  MobjState(SpriteNum.spos, 17, 5, StateAction.none, StateNum.sposXdie7),
  MobjState(SpriteNum.spos, 18, 5, StateAction.none, StateNum.sposXdie8),
  MobjState(SpriteNum.spos, 19, 5, StateAction.none, StateNum.sposXdie9),
  MobjState(SpriteNum.spos, 20, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.spos, 11, 5, StateAction.none, StateNum.sposRaise2),
  MobjState(SpriteNum.spos, 10, 5, StateAction.none, StateNum.sposRaise3),
  MobjState(SpriteNum.spos, 9, 5, StateAction.none, StateNum.sposRaise4),
  MobjState(SpriteNum.spos, 8, 5, StateAction.none, StateNum.sposRaise5),
  MobjState(SpriteNum.spos, 7, 5, StateAction.none, StateNum.sposRun1),

  MobjState(SpriteNum.troo, 0, 10, StateAction.look, StateNum.troopStnd2),
  MobjState(SpriteNum.troo, 1, 10, StateAction.look, StateNum.troopStnd),
  MobjState(SpriteNum.troo, 0, 3, StateAction.chase, StateNum.troopRun2),
  MobjState(SpriteNum.troo, 0, 3, StateAction.chase, StateNum.troopRun3),
  MobjState(SpriteNum.troo, 1, 3, StateAction.chase, StateNum.troopRun4),
  MobjState(SpriteNum.troo, 1, 3, StateAction.chase, StateNum.troopRun5),
  MobjState(SpriteNum.troo, 2, 3, StateAction.chase, StateNum.troopRun6),
  MobjState(SpriteNum.troo, 2, 3, StateAction.chase, StateNum.troopRun7),
  MobjState(SpriteNum.troo, 3, 3, StateAction.chase, StateNum.troopRun8),
  MobjState(SpriteNum.troo, 3, 3, StateAction.chase, StateNum.troopRun1),
  MobjState(SpriteNum.troo, 4, 8, StateAction.faceTarget, StateNum.troopAtk2),
  MobjState(SpriteNum.troo, 5, 8, StateAction.faceTarget, StateNum.troopAtk3),
  MobjState(SpriteNum.troo, 6, 6, StateAction.troopAttack, StateNum.troopRun1),
  MobjState(SpriteNum.troo, 7, 2, StateAction.none, StateNum.troopPain2),
  MobjState(SpriteNum.troo, 7, 2, StateAction.pain, StateNum.troopRun1),
  MobjState(SpriteNum.troo, 8, 8, StateAction.none, StateNum.troopDie2),
  MobjState(SpriteNum.troo, 9, 8, StateAction.scream, StateNum.troopDie3),
  MobjState(SpriteNum.troo, 10, 6, StateAction.none, StateNum.troopDie4),
  MobjState(SpriteNum.troo, 11, 6, StateAction.fall, StateNum.troopDie5),
  MobjState(SpriteNum.troo, 12, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.troo, 13, 5, StateAction.none, StateNum.troopXdie2),
  MobjState(SpriteNum.troo, 14, 5, StateAction.xScream, StateNum.troopXdie3),
  MobjState(SpriteNum.troo, 15, 5, StateAction.none, StateNum.troopXdie4),
  MobjState(SpriteNum.troo, 16, 5, StateAction.fall, StateNum.troopXdie5),
  MobjState(SpriteNum.troo, 17, 5, StateAction.none, StateNum.troopXdie6),
  MobjState(SpriteNum.troo, 18, 5, StateAction.none, StateNum.troopXdie7),
  MobjState(SpriteNum.troo, 19, 5, StateAction.none, StateNum.troopXdie8),
  MobjState(SpriteNum.troo, 20, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.troo, 12, 8, StateAction.none, StateNum.troopRaise2),
  MobjState(SpriteNum.troo, 11, 8, StateAction.none, StateNum.troopRun1),

  MobjState(SpriteNum.sarg, 0, 10, StateAction.look, StateNum.sargStnd2),
  MobjState(SpriteNum.sarg, 1, 10, StateAction.look, StateNum.sargStnd),
  MobjState(SpriteNum.sarg, 0, 2, StateAction.chase, StateNum.sargRun2),
  MobjState(SpriteNum.sarg, 0, 2, StateAction.chase, StateNum.sargRun3),
  MobjState(SpriteNum.sarg, 1, 2, StateAction.chase, StateNum.sargRun4),
  MobjState(SpriteNum.sarg, 1, 2, StateAction.chase, StateNum.sargRun5),
  MobjState(SpriteNum.sarg, 2, 2, StateAction.chase, StateNum.sargRun6),
  MobjState(SpriteNum.sarg, 2, 2, StateAction.chase, StateNum.sargRun7),
  MobjState(SpriteNum.sarg, 3, 2, StateAction.chase, StateNum.sargRun8),
  MobjState(SpriteNum.sarg, 3, 2, StateAction.chase, StateNum.sargRun1),
  MobjState(SpriteNum.sarg, 4, 8, StateAction.faceTarget, StateNum.sargAtk2),
  MobjState(SpriteNum.sarg, 5, 8, StateAction.faceTarget, StateNum.sargAtk3),
  MobjState(SpriteNum.sarg, 6, 8, StateAction.sargAttack, StateNum.sargRun1),
  MobjState(SpriteNum.sarg, 7, 2, StateAction.none, StateNum.sargPain2),
  MobjState(SpriteNum.sarg, 7, 2, StateAction.pain, StateNum.sargRun1),
  MobjState(SpriteNum.sarg, 8, 8, StateAction.none, StateNum.sargDie2),
  MobjState(SpriteNum.sarg, 9, 8, StateAction.scream, StateNum.sargDie3),
  MobjState(SpriteNum.sarg, 10, 4, StateAction.none, StateNum.sargDie4),
  MobjState(SpriteNum.sarg, 11, 4, StateAction.fall, StateNum.sargDie5),
  MobjState(SpriteNum.sarg, 12, 4, StateAction.none, StateNum.sargDie6),
  MobjState(SpriteNum.sarg, 13, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.sarg, 13, 5, StateAction.none, StateNum.sargRaise2),
  MobjState(SpriteNum.sarg, 12, 5, StateAction.none, StateNum.sargRaise3),
  MobjState(SpriteNum.sarg, 11, 5, StateAction.none, StateNum.sargRaise4),
  MobjState(SpriteNum.sarg, 10, 5, StateAction.none, StateNum.sargRaise5),
  MobjState(SpriteNum.sarg, 9, 5, StateAction.none, StateNum.sargRaise6),
  MobjState(SpriteNum.sarg, 8, 5, StateAction.none, StateNum.sargRun1),

  MobjState(SpriteNum.head, 0, 10, StateAction.look, StateNum.headStnd),
  MobjState(SpriteNum.head, 0, 3, StateAction.chase, StateNum.headRun1),
  MobjState(SpriteNum.head, 1, 5, StateAction.faceTarget, StateNum.headAtk2),
  MobjState(SpriteNum.head, 2, 5, StateAction.faceTarget, StateNum.headAtk3),
  MobjState(SpriteNum.head, 3, 5, StateAction.headAttack, StateNum.headRun1),
  MobjState(SpriteNum.head, 4, 3, StateAction.none, StateNum.headPain2),
  MobjState(SpriteNum.head, 4, 3, StateAction.pain, StateNum.headPain3),
  MobjState(SpriteNum.head, 5, 6, StateAction.none, StateNum.headRun1),
  MobjState(SpriteNum.head, 6, 8, StateAction.none, StateNum.headDie2),
  MobjState(SpriteNum.head, 7, 8, StateAction.scream, StateNum.headDie3),
  MobjState(SpriteNum.head, 8, 8, StateAction.none, StateNum.headDie4),
  MobjState(SpriteNum.head, 9, 8, StateAction.none, StateNum.headDie5),
  MobjState(SpriteNum.head, 10, 8, StateAction.fall, StateNum.headDie6),
  MobjState(SpriteNum.head, 11, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.head, 11, 8, StateAction.none, StateNum.headRaise2),
  MobjState(SpriteNum.head, 10, 8, StateAction.none, StateNum.headRaise3),
  MobjState(SpriteNum.head, 9, 8, StateAction.none, StateNum.headRaise4),
  MobjState(SpriteNum.head, 8, 8, StateAction.none, StateNum.headRaise5),
  MobjState(SpriteNum.head, 7, 8, StateAction.none, StateNum.headRaise6),
  MobjState(SpriteNum.head, 6, 8, StateAction.none, StateNum.headRun1),

  MobjState(SpriteNum.skul, 0, 10, StateAction.look, StateNum.skulStnd2),
  MobjState(SpriteNum.skul, 1, 10, StateAction.look, StateNum.skulStnd),
  MobjState(SpriteNum.skul, 0, 6, StateAction.chase, StateNum.skulRun2),
  MobjState(SpriteNum.skul, 1, 6, StateAction.chase, StateNum.skulRun1),
  MobjState(SpriteNum.skul, 2, 10, StateAction.faceTarget, StateNum.skulAtk2),
  MobjState(SpriteNum.skul, 3, 4, StateAction.skullAttack, StateNum.skulAtk3),
  MobjState(SpriteNum.skul, 2, 4, StateAction.none, StateNum.skulAtk4),
  MobjState(SpriteNum.skul, 3, 4, StateAction.none, StateNum.skulAtk3),
  MobjState(SpriteNum.skul, 4, 3, StateAction.none, StateNum.skulPain2),
  MobjState(SpriteNum.skul, 4, 3, StateAction.pain, StateNum.skulRun1),
  MobjState(SpriteNum.skul, 5, 6, StateAction.none, StateNum.skulDie2),
  MobjState(SpriteNum.skul, 6, 6, StateAction.scream, StateNum.skulDie3),
  MobjState(SpriteNum.skul, 7, 6, StateAction.none, StateNum.skulDie4),
  MobjState(SpriteNum.skul, 8, 6, StateAction.fall, StateNum.skulDie5),
  MobjState(SpriteNum.skul, 9, 6, StateAction.none, StateNum.skulDie6),
  MobjState(SpriteNum.skul, 10, -1, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.boss, 0, 10, StateAction.look, StateNum.bossStnd2),
  MobjState(SpriteNum.boss, 1, 10, StateAction.look, StateNum.bossStnd),
  MobjState(SpriteNum.boss, 0, 3, StateAction.chase, StateNum.bossRun2),
  MobjState(SpriteNum.boss, 0, 3, StateAction.chase, StateNum.bossRun3),
  MobjState(SpriteNum.boss, 1, 3, StateAction.chase, StateNum.bossRun4),
  MobjState(SpriteNum.boss, 1, 3, StateAction.chase, StateNum.bossRun5),
  MobjState(SpriteNum.boss, 2, 3, StateAction.chase, StateNum.bossRun6),
  MobjState(SpriteNum.boss, 2, 3, StateAction.chase, StateNum.bossRun7),
  MobjState(SpriteNum.boss, 3, 3, StateAction.chase, StateNum.bossRun8),
  MobjState(SpriteNum.boss, 3, 3, StateAction.chase, StateNum.bossRun1),
  MobjState(SpriteNum.boss, 4, 8, StateAction.faceTarget, StateNum.bossAtk2),
  MobjState(SpriteNum.boss, 5, 8, StateAction.faceTarget, StateNum.bossAtk3),
  MobjState(SpriteNum.boss, 6, 8, StateAction.bruisAttack, StateNum.bossRun1),
  MobjState(SpriteNum.boss, 7, 2, StateAction.none, StateNum.bossPain2),
  MobjState(SpriteNum.boss, 7, 2, StateAction.pain, StateNum.bossRun1),
  MobjState(SpriteNum.boss, 8, 8, StateAction.none, StateNum.bossDie2),
  MobjState(SpriteNum.boss, 9, 8, StateAction.scream, StateNum.bossDie3),
  MobjState(SpriteNum.boss, 10, 8, StateAction.none, StateNum.bossDie4),
  MobjState(SpriteNum.boss, 11, 8, StateAction.fall, StateNum.bossDie5),
  MobjState(SpriteNum.boss, 12, 8, StateAction.none, StateNum.bossDie6),
  MobjState(SpriteNum.boss, 13, 8, StateAction.none, StateNum.bossDie7),
  MobjState(SpriteNum.boss, 14, -1, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.boss, 14, 8, StateAction.none, StateNum.bossRaise2),
  MobjState(SpriteNum.boss, 13, 8, StateAction.none, StateNum.bossRaise3),
  MobjState(SpriteNum.boss, 12, 8, StateAction.none, StateNum.bossRaise4),
  MobjState(SpriteNum.boss, 11, 8, StateAction.none, StateNum.bossRaise5),
  MobjState(SpriteNum.boss, 10, 8, StateAction.none, StateNum.bossRaise6),
  MobjState(SpriteNum.boss, 9, 8, StateAction.none, StateNum.bossRaise7),
  MobjState(SpriteNum.boss, 8, 8, StateAction.none, StateNum.bossRun1),

  MobjState(SpriteNum.bal1, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tball2),
  MobjState(SpriteNum.bal1, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tball1),
  MobjState(SpriteNum.bal1, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.tballx2),
  MobjState(SpriteNum.bal1, 3 | FrameFlag.fullBright, 6, StateAction.none, StateNum.tballx3),
  MobjState(SpriteNum.bal1, 4 | FrameFlag.fullBright, 6, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.bal7, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.rball2),
  MobjState(SpriteNum.bal7, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.rball1),
  MobjState(SpriteNum.bal7, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.rballx2),
  MobjState(SpriteNum.bal7, 3 | FrameFlag.fullBright, 6, StateAction.none, StateNum.rballx3),
  MobjState(SpriteNum.bal7, 4 | FrameFlag.fullBright, 6, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.bal2, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.brball2),
  MobjState(SpriteNum.bal2, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.brball1),
  MobjState(SpriteNum.bal2, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.brballx2),
  MobjState(SpriteNum.bal2, 3 | FrameFlag.fullBright, 6, StateAction.none, StateNum.brballx3),
  MobjState(SpriteNum.bal2, 4 | FrameFlag.fullBright, 6, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.misl, 0 | FrameFlag.fullBright, 1, StateAction.none, StateNum.rocket),
  MobjState(SpriteNum.misl, 1 | FrameFlag.fullBright, 8, StateAction.explode, StateNum.explode2),
  MobjState(SpriteNum.misl, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.explode3),
  MobjState(SpriteNum.misl, 3 | FrameFlag.fullBright, 4, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.plss, 0 | FrameFlag.fullBright, 6, StateAction.none, StateNum.plasball2),
  MobjState(SpriteNum.plss, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.plasball1),
  MobjState(SpriteNum.plse, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.plasexp2),
  MobjState(SpriteNum.plse, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.plasexp3),
  MobjState(SpriteNum.plse, 2 | FrameFlag.fullBright, 4, StateAction.none, StateNum.plasexp4),
  MobjState(SpriteNum.plse, 3 | FrameFlag.fullBright, 4, StateAction.none, StateNum.plasexp5),
  MobjState(SpriteNum.plse, 4 | FrameFlag.fullBright, 4, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.bfs1, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.bfgshot2),
  MobjState(SpriteNum.bfs1, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.bfgshot1),
  MobjState(SpriteNum.bfe1, 0 | FrameFlag.fullBright, 8, StateAction.bfgSpray, StateNum.bfgland2),
  MobjState(SpriteNum.bfe1, 1 | FrameFlag.fullBright, 8, StateAction.none, StateNum.bfgland3),
  MobjState(SpriteNum.bfe1, 2 | FrameFlag.fullBright, 8, StateAction.none, StateNum.bfgland4),
  MobjState(SpriteNum.bfe1, 3 | FrameFlag.fullBright, 8, StateAction.none, StateNum.bfgland5),
  MobjState(SpriteNum.bfe1, 4 | FrameFlag.fullBright, 8, StateAction.none, StateNum.bfgland6),
  MobjState(SpriteNum.bfe1, 5 | FrameFlag.fullBright, 8, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.fatb, 0 | FrameFlag.fullBright, 2, StateAction.tracer, StateNum.tracer2),
  MobjState(SpriteNum.fatb, 1 | FrameFlag.fullBright, 2, StateAction.tracer, StateNum.tracer1),
  MobjState(SpriteNum.fbxp, 0 | FrameFlag.fullBright, 8, StateAction.none, StateNum.traceexp2),
  MobjState(SpriteNum.fbxp, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.traceexp3),
  MobjState(SpriteNum.fbxp, 2 | FrameFlag.fullBright, 4, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.manf, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.fatshot2),
  MobjState(SpriteNum.manf, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.fatshot1),
  MobjState(SpriteNum.misl, 1 | FrameFlag.fullBright, 8, StateAction.none, StateNum.fatshotx2),
  MobjState(SpriteNum.misl, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.fatshotx3),
  MobjState(SpriteNum.misl, 3 | FrameFlag.fullBright, 4, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.apls, 0 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlaz2),
  MobjState(SpriteNum.apls, 1 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlaz1),
  MobjState(SpriteNum.apbx, 0 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlex2),
  MobjState(SpriteNum.apbx, 1 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlex3),
  MobjState(SpriteNum.apbx, 2 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlex4),
  MobjState(SpriteNum.apbx, 3 | FrameFlag.fullBright, 5, StateAction.none, StateNum.arachPlex5),
  MobjState(SpriteNum.apbx, 4 | FrameFlag.fullBright, 5, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.bar1, 0, 6, StateAction.none, StateNum.bar2),
  MobjState(SpriteNum.bar1, 1, 6, StateAction.none, StateNum.bar1),
  MobjState(SpriteNum.bexp, 0 | FrameFlag.fullBright, 5, StateAction.none, StateNum.bexp2),
  MobjState(SpriteNum.bexp, 1 | FrameFlag.fullBright, 5, StateAction.scream, StateNum.bexp3),
  MobjState(SpriteNum.bexp, 2 | FrameFlag.fullBright, 5, StateAction.none, StateNum.bexp4),
  MobjState(SpriteNum.bexp, 3 | FrameFlag.fullBright, 10, StateAction.explode, StateNum.bexp5),
  MobjState(SpriteNum.bexp, 4 | FrameFlag.fullBright, 10, StateAction.none, StateNum.sNull),
];
