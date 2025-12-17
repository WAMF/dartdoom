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
  static const int gor1 = 96;
  static const int pol5 = 98;
  static const int pol3 = 100;
  static const int pol6 = 102;
  static const int ceye = 118;
  static const int fsku = 119;
  static const int col5 = 120;
  static const int tlmp = 136;
  static const int tlp2 = 137;
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

  static const int blood1 = 248;
  static const int blood2 = 249;
  static const int blood3 = 250;

  static const int puff1 = 251;
  static const int puff2 = 252;
  static const int puff3 = 253;
  static const int puff4 = 254;

  static const int vileStnd = 255;
  static const int vileStnd2 = 256;
  static const int vileRun1 = 257;
  static const int vileRun2 = 258;
  static const int vileRun3 = 259;
  static const int vileRun4 = 260;
  static const int vileRun5 = 261;
  static const int vileRun6 = 262;
  static const int vileRun7 = 263;
  static const int vileRun8 = 264;
  static const int vileRun9 = 265;
  static const int vileRun10 = 266;
  static const int vileRun11 = 267;
  static const int vileRun12 = 268;
  static const int vileAtk1 = 269;
  static const int vileAtk2 = 270;
  static const int vileAtk3 = 271;
  static const int vileAtk4 = 272;
  static const int vileAtk5 = 273;
  static const int vileAtk6 = 274;
  static const int vileAtk7 = 275;
  static const int vileAtk8 = 276;
  static const int vileAtk9 = 277;
  static const int vileAtk10 = 278;
  static const int vileAtk11 = 279;
  static const int vileHeal1 = 280;
  static const int vileHeal2 = 281;
  static const int vileHeal3 = 282;
  static const int vilePain = 283;
  static const int vilePain2 = 284;
  static const int vileDie1 = 285;
  static const int vileDie2 = 286;
  static const int vileDie3 = 287;
  static const int vileDie4 = 288;
  static const int vileDie5 = 289;
  static const int vileDie6 = 290;
  static const int vileDie7 = 291;
  static const int vileDie8 = 292;
  static const int vileDie9 = 293;
  static const int vileDie10 = 294;

  static const int fire1 = 295;
  static const int fire2 = 296;
  static const int fire3 = 297;
  static const int fire4 = 298;
  static const int fire5 = 299;
  static const int fire6 = 300;
  static const int fire7 = 301;
  static const int fire8 = 302;
  static const int fire9 = 303;
  static const int fire10 = 304;
  static const int fire11 = 305;
  static const int fire12 = 306;
  static const int fire13 = 307;
  static const int fire14 = 308;
  static const int fire15 = 309;
  static const int fire16 = 310;
  static const int fire17 = 311;
  static const int fire18 = 312;
  static const int fire19 = 313;
  static const int fire20 = 314;
  static const int fire21 = 315;
  static const int fire22 = 316;
  static const int fire23 = 317;
  static const int fire24 = 318;
  static const int fire25 = 319;
  static const int fire26 = 320;
  static const int fire27 = 321;
  static const int fire28 = 322;
  static const int fire29 = 323;
  static const int fire30 = 324;

  static const int cyberStnd = 325;
  static const int cyberStnd2 = 326;
  static const int cyberRun1 = 327;
  static const int cyberRun2 = 328;
  static const int cyberRun3 = 329;
  static const int cyberRun4 = 330;
  static const int cyberRun5 = 331;
  static const int cyberRun6 = 332;
  static const int cyberRun7 = 333;
  static const int cyberRun8 = 334;
  static const int cyberAtk1 = 335;
  static const int cyberAtk2 = 336;
  static const int cyberAtk3 = 337;
  static const int cyberAtk4 = 338;
  static const int cyberAtk5 = 339;
  static const int cyberAtk6 = 340;
  static const int cyberPain = 341;
  static const int cyberDie1 = 342;
  static const int cyberDie2 = 343;
  static const int cyberDie3 = 344;
  static const int cyberDie4 = 345;
  static const int cyberDie5 = 346;
  static const int cyberDie6 = 347;
  static const int cyberDie7 = 348;
  static const int cyberDie8 = 349;
  static const int cyberDie9 = 350;
  static const int cyberDie10 = 351;

  static const int spidStnd = 352;
  static const int spidStnd2 = 353;
  static const int spidRun1 = 354;
  static const int spidRun2 = 355;
  static const int spidRun3 = 356;
  static const int spidRun4 = 357;
  static const int spidRun5 = 358;
  static const int spidRun6 = 359;
  static const int spidRun7 = 360;
  static const int spidRun8 = 361;
  static const int spidRun9 = 362;
  static const int spidRun10 = 363;
  static const int spidRun11 = 364;
  static const int spidRun12 = 365;
  static const int spidAtk1 = 366;
  static const int spidAtk2 = 367;
  static const int spidAtk3 = 368;
  static const int spidAtk4 = 369;
  static const int spidPain = 370;
  static const int spidPain2 = 371;
  static const int spidDie1 = 372;
  static const int spidDie2 = 373;
  static const int spidDie3 = 374;
  static const int spidDie4 = 375;
  static const int spidDie5 = 376;
  static const int spidDie6 = 377;
  static const int spidDie7 = 378;
  static const int spidDie8 = 379;
  static const int spidDie9 = 380;
  static const int spidDie10 = 381;
  static const int spidDie11 = 382;

  static const int painStnd = 383;
  static const int painRun1 = 384;
  static const int painRun2 = 385;
  static const int painRun3 = 386;
  static const int painRun4 = 387;
  static const int painRun5 = 388;
  static const int painRun6 = 389;
  static const int painAtk1 = 390;
  static const int painAtk2 = 391;
  static const int painAtk3 = 392;
  static const int painAtk4 = 393;
  static const int painPain = 394;
  static const int painPain2 = 395;
  static const int painDie1 = 396;
  static const int painDie2 = 397;
  static const int painDie3 = 398;
  static const int painDie4 = 399;
  static const int painDie5 = 400;
  static const int painDie6 = 401;
  static const int painRaise1 = 402;
  static const int painRaise2 = 403;
  static const int painRaise3 = 404;
  static const int painRaise4 = 405;
  static const int painRaise5 = 406;
  static const int painRaise6 = 407;

  static const int bloodyTwitch = 408;
  static const int bloodyTwitch2 = 409;
  static const int bloodyTwitch3 = 410;
  static const int bloodyTwitch4 = 411;
  static const int headCandles = 412;
  static const int headCandles2 = 413;
  static const int liveStick = 414;
  static const int liveStick2 = 415;
  static const int evilEye = 416;
  static const int evilEye2 = 417;
  static const int evilEye3 = 418;
  static const int evilEye4 = 419;
  static const int floatSkull = 420;
  static const int floatSkull2 = 421;
  static const int floatSkull3 = 422;
  static const int heartCol = 423;
  static const int heartCol2 = 424;
  static const int techLamp = 425;
  static const int techLamp2 = 426;
  static const int techLamp3 = 427;
  static const int techLamp4 = 428;
  static const int tech2Lamp = 429;
  static const int tech2Lamp2 = 430;
  static const int tech2Lamp3 = 431;
  static const int tech2Lamp4 = 432;

  static const int sGibs = 433;
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
  vileChase,
  vileStart,
  vileTarget,
  vileAttack,
  startFire,
  fire,
  fireCrackle,
  skelFist,
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

  MobjState(SpriteNum.blud, 2, 8, StateAction.none, StateNum.blood2),
  MobjState(SpriteNum.blud, 1, 8, StateAction.none, StateNum.blood3),
  MobjState(SpriteNum.blud, 0, 8, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.puff, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.puff2),
  MobjState(SpriteNum.puff, 1, 4, StateAction.none, StateNum.puff3),
  MobjState(SpriteNum.puff, 2, 4, StateAction.none, StateNum.puff4),
  MobjState(SpriteNum.puff, 3, 4, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.vile, 0, 10, StateAction.look, StateNum.vileStnd2),
  MobjState(SpriteNum.vile, 1, 10, StateAction.look, StateNum.vileStnd),
  MobjState(SpriteNum.vile, 0, 2, StateAction.vileChase, StateNum.vileRun2),
  MobjState(SpriteNum.vile, 0, 2, StateAction.vileChase, StateNum.vileRun3),
  MobjState(SpriteNum.vile, 1, 2, StateAction.vileChase, StateNum.vileRun4),
  MobjState(SpriteNum.vile, 1, 2, StateAction.vileChase, StateNum.vileRun5),
  MobjState(SpriteNum.vile, 2, 2, StateAction.vileChase, StateNum.vileRun6),
  MobjState(SpriteNum.vile, 2, 2, StateAction.vileChase, StateNum.vileRun7),
  MobjState(SpriteNum.vile, 3, 2, StateAction.vileChase, StateNum.vileRun8),
  MobjState(SpriteNum.vile, 3, 2, StateAction.vileChase, StateNum.vileRun9),
  MobjState(SpriteNum.vile, 4, 2, StateAction.vileChase, StateNum.vileRun10),
  MobjState(SpriteNum.vile, 4, 2, StateAction.vileChase, StateNum.vileRun11),
  MobjState(SpriteNum.vile, 5, 2, StateAction.vileChase, StateNum.vileRun12),
  MobjState(SpriteNum.vile, 5, 2, StateAction.vileChase, StateNum.vileRun1),
  MobjState(SpriteNum.vile, 6 | FrameFlag.fullBright, 0, StateAction.vileStart, StateNum.vileAtk2),
  MobjState(SpriteNum.vile, 6 | FrameFlag.fullBright, 10, StateAction.faceTarget, StateNum.vileAtk3),
  MobjState(SpriteNum.vile, 7 | FrameFlag.fullBright, 8, StateAction.vileTarget, StateNum.vileAtk4),
  MobjState(SpriteNum.vile, 8 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk5),
  MobjState(SpriteNum.vile, 9 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk6),
  MobjState(SpriteNum.vile, 10 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk7),
  MobjState(SpriteNum.vile, 11 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk8),
  MobjState(SpriteNum.vile, 12 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk9),
  MobjState(SpriteNum.vile, 13 | FrameFlag.fullBright, 8, StateAction.faceTarget, StateNum.vileAtk10),
  MobjState(SpriteNum.vile, 14 | FrameFlag.fullBright, 8, StateAction.vileAttack, StateNum.vileAtk11),
  MobjState(SpriteNum.vile, 15 | FrameFlag.fullBright, 20, StateAction.none, StateNum.vileRun1),
  MobjState(SpriteNum.vile, 26 | FrameFlag.fullBright, 10, StateAction.none, StateNum.vileHeal2),
  MobjState(SpriteNum.vile, 27 | FrameFlag.fullBright, 10, StateAction.none, StateNum.vileHeal3),
  MobjState(SpriteNum.vile, 28 | FrameFlag.fullBright, 10, StateAction.none, StateNum.vileRun1),
  MobjState(SpriteNum.vile, 16, 5, StateAction.none, StateNum.vilePain2),
  MobjState(SpriteNum.vile, 16, 5, StateAction.pain, StateNum.vileRun1),
  MobjState(SpriteNum.vile, 16, 7, StateAction.none, StateNum.vileDie2),
  MobjState(SpriteNum.vile, 17, 7, StateAction.scream, StateNum.vileDie3),
  MobjState(SpriteNum.vile, 18, 7, StateAction.fall, StateNum.vileDie4),
  MobjState(SpriteNum.vile, 19, 7, StateAction.none, StateNum.vileDie5),
  MobjState(SpriteNum.vile, 20, 7, StateAction.none, StateNum.vileDie6),
  MobjState(SpriteNum.vile, 21, 7, StateAction.none, StateNum.vileDie7),
  MobjState(SpriteNum.vile, 22, 7, StateAction.none, StateNum.vileDie8),
  MobjState(SpriteNum.vile, 23, 5, StateAction.none, StateNum.vileDie9),
  MobjState(SpriteNum.vile, 24, 5, StateAction.none, StateNum.vileDie10),
  MobjState(SpriteNum.vile, 25, -1, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.fire, 0 | FrameFlag.fullBright, 2, StateAction.startFire, StateNum.fire2),
  MobjState(SpriteNum.fire, 1 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire3),
  MobjState(SpriteNum.fire, 0 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire4),
  MobjState(SpriteNum.fire, 1 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire5),
  MobjState(SpriteNum.fire, 2 | FrameFlag.fullBright, 2, StateAction.fireCrackle, StateNum.fire6),
  MobjState(SpriteNum.fire, 1 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire7),
  MobjState(SpriteNum.fire, 2 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire8),
  MobjState(SpriteNum.fire, 1 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire9),
  MobjState(SpriteNum.fire, 2 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire10),
  MobjState(SpriteNum.fire, 3 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire11),
  MobjState(SpriteNum.fire, 2 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire12),
  MobjState(SpriteNum.fire, 3 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire13),
  MobjState(SpriteNum.fire, 2 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire14),
  MobjState(SpriteNum.fire, 3 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire15),
  MobjState(SpriteNum.fire, 4 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire16),
  MobjState(SpriteNum.fire, 3 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire17),
  MobjState(SpriteNum.fire, 4 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire18),
  MobjState(SpriteNum.fire, 3 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire19),
  MobjState(SpriteNum.fire, 4 | FrameFlag.fullBright, 2, StateAction.fireCrackle, StateNum.fire20),
  MobjState(SpriteNum.fire, 5 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire21),
  MobjState(SpriteNum.fire, 4 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire22),
  MobjState(SpriteNum.fire, 5 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire23),
  MobjState(SpriteNum.fire, 4 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire24),
  MobjState(SpriteNum.fire, 5 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire25),
  MobjState(SpriteNum.fire, 6 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire26),
  MobjState(SpriteNum.fire, 7 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire27),
  MobjState(SpriteNum.fire, 6 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire28),
  MobjState(SpriteNum.fire, 7 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire29),
  MobjState(SpriteNum.fire, 6 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.fire30),
  MobjState(SpriteNum.fire, 7 | FrameFlag.fullBright, 2, StateAction.fire, StateNum.sNull),

  MobjState(SpriteNum.cybr, 0, 10, StateAction.look, StateNum.cyberStnd2),
  MobjState(SpriteNum.cybr, 1, 10, StateAction.look, StateNum.cyberStnd),
  MobjState(SpriteNum.cybr, 0, 3, StateAction.none, StateNum.cyberRun2),
  MobjState(SpriteNum.cybr, 0, 3, StateAction.chase, StateNum.cyberRun3),
  MobjState(SpriteNum.cybr, 1, 3, StateAction.chase, StateNum.cyberRun4),
  MobjState(SpriteNum.cybr, 1, 3, StateAction.chase, StateNum.cyberRun5),
  MobjState(SpriteNum.cybr, 2, 3, StateAction.chase, StateNum.cyberRun6),
  MobjState(SpriteNum.cybr, 2, 3, StateAction.chase, StateNum.cyberRun7),
  MobjState(SpriteNum.cybr, 3, 3, StateAction.none, StateNum.cyberRun8),
  MobjState(SpriteNum.cybr, 3, 3, StateAction.chase, StateNum.cyberRun1),
  MobjState(SpriteNum.cybr, 4, 6, StateAction.faceTarget, StateNum.cyberAtk2),
  MobjState(SpriteNum.cybr, 5, 12, StateAction.cyberAttack, StateNum.cyberAtk3),
  MobjState(SpriteNum.cybr, 4, 12, StateAction.faceTarget, StateNum.cyberAtk4),
  MobjState(SpriteNum.cybr, 5, 12, StateAction.cyberAttack, StateNum.cyberAtk5),
  MobjState(SpriteNum.cybr, 4, 12, StateAction.faceTarget, StateNum.cyberAtk6),
  MobjState(SpriteNum.cybr, 5, 12, StateAction.cyberAttack, StateNum.cyberRun1),
  MobjState(SpriteNum.cybr, 6, 10, StateAction.pain, StateNum.cyberRun1),
  MobjState(SpriteNum.cybr, 7, 10, StateAction.none, StateNum.cyberDie2),
  MobjState(SpriteNum.cybr, 8, 10, StateAction.scream, StateNum.cyberDie3),
  MobjState(SpriteNum.cybr, 9, 10, StateAction.none, StateNum.cyberDie4),
  MobjState(SpriteNum.cybr, 10, 10, StateAction.none, StateNum.cyberDie5),
  MobjState(SpriteNum.cybr, 11, 10, StateAction.none, StateNum.cyberDie6),
  MobjState(SpriteNum.cybr, 12, 10, StateAction.fall, StateNum.cyberDie7),
  MobjState(SpriteNum.cybr, 13, 10, StateAction.none, StateNum.cyberDie8),
  MobjState(SpriteNum.cybr, 14, 10, StateAction.none, StateNum.cyberDie9),
  MobjState(SpriteNum.cybr, 15, 30, StateAction.none, StateNum.cyberDie10),
  MobjState(SpriteNum.cybr, 15, -1, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.spid, 0, 10, StateAction.look, StateNum.spidStnd2),
  MobjState(SpriteNum.spid, 1, 10, StateAction.look, StateNum.spidStnd),
  MobjState(SpriteNum.spid, 0, 3, StateAction.none, StateNum.spidRun2),
  MobjState(SpriteNum.spid, 0, 3, StateAction.chase, StateNum.spidRun3),
  MobjState(SpriteNum.spid, 1, 3, StateAction.chase, StateNum.spidRun4),
  MobjState(SpriteNum.spid, 1, 3, StateAction.chase, StateNum.spidRun5),
  MobjState(SpriteNum.spid, 2, 3, StateAction.none, StateNum.spidRun6),
  MobjState(SpriteNum.spid, 2, 3, StateAction.chase, StateNum.spidRun7),
  MobjState(SpriteNum.spid, 3, 3, StateAction.chase, StateNum.spidRun8),
  MobjState(SpriteNum.spid, 3, 3, StateAction.chase, StateNum.spidRun9),
  MobjState(SpriteNum.spid, 4, 3, StateAction.none, StateNum.spidRun10),
  MobjState(SpriteNum.spid, 4, 3, StateAction.chase, StateNum.spidRun11),
  MobjState(SpriteNum.spid, 5, 3, StateAction.chase, StateNum.spidRun12),
  MobjState(SpriteNum.spid, 5, 3, StateAction.chase, StateNum.spidRun1),
  MobjState(SpriteNum.spid, 0 | FrameFlag.fullBright, 20, StateAction.faceTarget, StateNum.spidAtk2),
  MobjState(SpriteNum.spid, 6 | FrameFlag.fullBright, 4, StateAction.sPosAttack, StateNum.spidAtk3),
  MobjState(SpriteNum.spid, 7 | FrameFlag.fullBright, 4, StateAction.sPosAttack, StateNum.spidAtk4),
  MobjState(SpriteNum.spid, 7 | FrameFlag.fullBright, 1, StateAction.spidRefire, StateNum.spidAtk2),
  MobjState(SpriteNum.spid, 8, 3, StateAction.none, StateNum.spidPain2),
  MobjState(SpriteNum.spid, 8, 3, StateAction.pain, StateNum.spidRun1),
  MobjState(SpriteNum.spid, 9, 20, StateAction.scream, StateNum.spidDie2),
  MobjState(SpriteNum.spid, 10, 10, StateAction.fall, StateNum.spidDie3),
  MobjState(SpriteNum.spid, 11, 10, StateAction.none, StateNum.spidDie4),
  MobjState(SpriteNum.spid, 12, 10, StateAction.none, StateNum.spidDie5),
  MobjState(SpriteNum.spid, 13, 10, StateAction.none, StateNum.spidDie6),
  MobjState(SpriteNum.spid, 14, 10, StateAction.none, StateNum.spidDie7),
  MobjState(SpriteNum.spid, 15, 10, StateAction.none, StateNum.spidDie8),
  MobjState(SpriteNum.spid, 16, 10, StateAction.none, StateNum.spidDie9),
  MobjState(SpriteNum.spid, 17, 10, StateAction.none, StateNum.spidDie10),
  MobjState(SpriteNum.spid, 18, 30, StateAction.none, StateNum.spidDie11),
  MobjState(SpriteNum.spid, 18, -1, StateAction.none, StateNum.sNull),

  MobjState(SpriteNum.pain, 0, 10, StateAction.look, StateNum.painStnd),
  MobjState(SpriteNum.pain, 0, 3, StateAction.chase, StateNum.painRun2),
  MobjState(SpriteNum.pain, 0, 3, StateAction.chase, StateNum.painRun3),
  MobjState(SpriteNum.pain, 1, 3, StateAction.chase, StateNum.painRun4),
  MobjState(SpriteNum.pain, 1, 3, StateAction.chase, StateNum.painRun5),
  MobjState(SpriteNum.pain, 2, 3, StateAction.chase, StateNum.painRun6),
  MobjState(SpriteNum.pain, 2, 3, StateAction.chase, StateNum.painRun1),
  MobjState(SpriteNum.pain, 3, 5, StateAction.faceTarget, StateNum.painAtk2),
  MobjState(SpriteNum.pain, 4, 5, StateAction.faceTarget, StateNum.painAtk3),
  MobjState(SpriteNum.pain, 5 | FrameFlag.fullBright, 5, StateAction.faceTarget, StateNum.painAtk4),
  MobjState(SpriteNum.pain, 5 | FrameFlag.fullBright, 0, StateAction.painAttack, StateNum.painRun1),
  MobjState(SpriteNum.pain, 6, 6, StateAction.none, StateNum.painPain2),
  MobjState(SpriteNum.pain, 6, 6, StateAction.pain, StateNum.painRun1),
  MobjState(SpriteNum.pain, 7 | FrameFlag.fullBright, 8, StateAction.none, StateNum.painDie2),
  MobjState(SpriteNum.pain, 8 | FrameFlag.fullBright, 8, StateAction.scream, StateNum.painDie3),
  MobjState(SpriteNum.pain, 9 | FrameFlag.fullBright, 8, StateAction.none, StateNum.painDie4),
  MobjState(SpriteNum.pain, 10 | FrameFlag.fullBright, 8, StateAction.none, StateNum.painDie5),
  MobjState(SpriteNum.pain, 11 | FrameFlag.fullBright, 8, StateAction.painDie, StateNum.painDie6),
  MobjState(SpriteNum.pain, 12 | FrameFlag.fullBright, 8, StateAction.none, StateNum.sNull),
  MobjState(SpriteNum.pain, 12, 8, StateAction.none, StateNum.painRaise2),
  MobjState(SpriteNum.pain, 11, 8, StateAction.none, StateNum.painRaise3),
  MobjState(SpriteNum.pain, 10, 8, StateAction.none, StateNum.painRaise4),
  MobjState(SpriteNum.pain, 9, 8, StateAction.none, StateNum.painRaise5),
  MobjState(SpriteNum.pain, 8, 8, StateAction.none, StateNum.painRaise6),
  MobjState(SpriteNum.pain, 7, 8, StateAction.none, StateNum.painRun1),

  MobjState(SpriteNum.gor1, 0, 10, StateAction.none, StateNum.bloodyTwitch2),
  MobjState(SpriteNum.gor1, 1, 15, StateAction.none, StateNum.bloodyTwitch3),
  MobjState(SpriteNum.gor1, 2, 8, StateAction.none, StateNum.bloodyTwitch4),
  MobjState(SpriteNum.gor1, 1, 6, StateAction.none, StateNum.bloodyTwitch),
  MobjState(SpriteNum.pol3, 0 | FrameFlag.fullBright, 6, StateAction.none, StateNum.headCandles2),
  MobjState(SpriteNum.pol3, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.headCandles),
  MobjState(SpriteNum.pol6, 0, 6, StateAction.none, StateNum.liveStick2),
  MobjState(SpriteNum.pol6, 1, 8, StateAction.none, StateNum.liveStick),

  MobjState(SpriteNum.ceye, 0 | FrameFlag.fullBright, 6, StateAction.none, StateNum.evilEye2),
  MobjState(SpriteNum.ceye, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.evilEye3),
  MobjState(SpriteNum.ceye, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.evilEye4),
  MobjState(SpriteNum.ceye, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.evilEye),
  MobjState(SpriteNum.fsku, 0 | FrameFlag.fullBright, 6, StateAction.none, StateNum.floatSkull2),
  MobjState(SpriteNum.fsku, 1 | FrameFlag.fullBright, 6, StateAction.none, StateNum.floatSkull3),
  MobjState(SpriteNum.fsku, 2 | FrameFlag.fullBright, 6, StateAction.none, StateNum.floatSkull),
  MobjState(SpriteNum.col5, 0, 14, StateAction.none, StateNum.heartCol2),
  MobjState(SpriteNum.col5, 1, 14, StateAction.none, StateNum.heartCol),
  MobjState(SpriteNum.tlmp, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.techLamp2),
  MobjState(SpriteNum.tlmp, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.techLamp3),
  MobjState(SpriteNum.tlmp, 2 | FrameFlag.fullBright, 4, StateAction.none, StateNum.techLamp4),
  MobjState(SpriteNum.tlmp, 3 | FrameFlag.fullBright, 4, StateAction.none, StateNum.techLamp),
  MobjState(SpriteNum.tlp2, 0 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tech2Lamp2),
  MobjState(SpriteNum.tlp2, 1 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tech2Lamp3),
  MobjState(SpriteNum.tlp2, 2 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tech2Lamp4),
  MobjState(SpriteNum.tlp2, 3 | FrameFlag.fullBright, 4, StateAction.none, StateNum.tech2Lamp),

  MobjState(SpriteNum.pol5, 0, -1, StateAction.none, StateNum.sNull),
];
