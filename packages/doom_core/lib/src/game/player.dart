import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_pspr.dart';
import 'package:doom_math/doom_math.dart';

abstract final class PlayerConstants {
  static const int viewHeight = 41 * Fixed32.fracUnit;
  static const int maxBob = 16 * Fixed32.fracUnit;
  static const int forwardMove = 25;
  static const int sideMove = 24;
  static const int angleUnit = 128;
  static const int playerRadius = 16 * Fixed32.fracUnit;
  static const int playerHeight = 56 * Fixed32.fracUnit;
  static const int maxHealth = 100;
  static const int runMultiplier = 2;
}

abstract final class _NumTypes {
  static const int numPowers = 6;
  static const int numCards = 6;
  static const int numWeapons = 9;
  static const int numAmmo = 4;
}

class Player {
  Mobj? mobj;
  int playerNum = 0;

  int viewZ = 0;
  int viewHeight = PlayerConstants.viewHeight;
  int deltaViewHeight = 0;
  int bob = 0;

  int health = PlayerConstants.maxHealth;
  int armorPoints = 0;
  int armorType = 0;

  final List<int> powers = List.filled(_NumTypes.numPowers, 0);
  final List<bool> cards = List.filled(_NumTypes.numCards, false);
  bool backpack = false;

  final List<int> frags = List.filled(4, 0);
  WeaponType readyWeapon = WeaponType.pistol;
  WeaponType pendingWeapon = WeaponType.noChange;

  final List<bool> weaponOwned = List.filled(_NumTypes.numWeapons, false);
  final List<int> ammo = List.filled(_NumTypes.numAmmo, 0);
  final List<int> maxAmmo = [200, 50, 300, 50];

  bool attackDown = false;
  bool useDown = false;

  int cheats = 0;
  int refire = 0;

  int killCount = 0;
  int itemCount = 0;
  int secretCount = 0;

  String? message;
  int damageCount = 0;
  int bonusCount = 0;

  Mobj? attacker;

  int extraLight = 0;
  int fixedColormap = 0;

  int colorMap = 0;

  PlayerState playerState = PlayerState.live;
  TicCmd cmd = TicCmd();

  bool didsecret = false;

  final List<PspriteDef> psprites = [];
}
