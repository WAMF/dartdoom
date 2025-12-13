import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/game/info.dart' hide SpriteNum;
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';

abstract final class CheatFlag {
  static const int godMode = 1;
  static const int noClip = 2;
}

abstract final class _DamageConstants {
  static const int baseThreshold = 100;
  static const int maxDamageCount = 100;
}

abstract final class _AmmoValues {
  static const List<int> maxAmmo = [200, 50, 300, 50];
  static const List<int> clipAmmo = [10, 4, 20, 1];
}

abstract final class _InterConstants {
  static const int bonusAdd = 6;
  static const int maxHealth = 100;
  static const int maxSuperHealth = 200;
  static const int invulnTics = 30 * 35;
  static const int invisTics = 60 * 35;
  static const int infraTics = 120 * 35;
  static const int ironTics = 60 * 35;
}

abstract final class _WeaponInfo {
  static const List<AmmoType> weaponAmmo = [
    AmmoType.noAmmo,
    AmmoType.clip,
    AmmoType.shell,
    AmmoType.clip,
    AmmoType.missile,
    AmmoType.cell,
    AmmoType.cell,
    AmmoType.noAmmo,
    AmmoType.shell,
  ];
}

bool giveAmmo(Player player, AmmoType ammo, int num) {
  if (ammo == AmmoType.noAmmo) {
    return false;
  }

  final ammoIndex = ammo.index;
  if (ammoIndex < 0 || ammoIndex >= player.ammo.length) {
    return false;
  }

  if (player.ammo[ammoIndex] >= player.maxAmmo[ammoIndex]) {
    return false;
  }

  var amount = num;
  if (amount > 0) {
    amount *= _AmmoValues.clipAmmo[ammoIndex];
  } else {
    amount = _AmmoValues.clipAmmo[ammoIndex] ~/ 2;
  }

  final oldAmmo = player.ammo[ammoIndex];
  player.ammo[ammoIndex] += amount;

  if (player.ammo[ammoIndex] > player.maxAmmo[ammoIndex]) {
    player.ammo[ammoIndex] = player.maxAmmo[ammoIndex];
  }

  if (oldAmmo > 0) {
    return true;
  }

  switch (ammo) {
    case AmmoType.clip:
      if (player.readyWeapon == WeaponType.fist) {
        if (player.weaponOwned[WeaponType.chaingun.index]) {
          player.pendingWeapon = WeaponType.chaingun;
        } else {
          player.pendingWeapon = WeaponType.pistol;
        }
      }

    case AmmoType.shell:
      if (player.readyWeapon == WeaponType.fist ||
          player.readyWeapon == WeaponType.pistol) {
        if (player.weaponOwned[WeaponType.shotgun.index]) {
          player.pendingWeapon = WeaponType.shotgun;
        }
      }

    case AmmoType.cell:
      if (player.readyWeapon == WeaponType.fist ||
          player.readyWeapon == WeaponType.pistol) {
        if (player.weaponOwned[WeaponType.plasma.index]) {
          player.pendingWeapon = WeaponType.plasma;
        }
      }

    case AmmoType.missile:
      if (player.readyWeapon == WeaponType.fist) {
        if (player.weaponOwned[WeaponType.missile.index]) {
          player.pendingWeapon = WeaponType.missile;
        }
      }

    case AmmoType.noAmmo:
      break;
  }

  return true;
}

bool giveWeapon(Player player, WeaponType weapon, {required bool dropped}) {
  var gaveAmmo = false;
  var gaveWeapon = false;

  final weaponIndex = weapon.index;
  if (weaponIndex < 0 || weaponIndex >= _WeaponInfo.weaponAmmo.length) {
    return false;
  }

  final ammoType = _WeaponInfo.weaponAmmo[weaponIndex];
  if (ammoType != AmmoType.noAmmo) {
    gaveAmmo = giveAmmo(player, ammoType, dropped ? 1 : 2);
  }

  if (!player.weaponOwned[weaponIndex]) {
    gaveWeapon = true;
    player.weaponOwned[weaponIndex] = true;
    player.pendingWeapon = weapon;
  }

  return gaveWeapon || gaveAmmo;
}

bool giveBody(Player player, int num) {
  if (player.health >= _InterConstants.maxHealth) {
    return false;
  }

  player.health += num;
  if (player.health > _InterConstants.maxHealth) {
    player.health = _InterConstants.maxHealth;
  }

  final mobj = player.mobj;
  if (mobj != null) {
    mobj.health = player.health;
  }

  return true;
}

bool giveArmor(Player player, int armorType) {
  final hits = armorType * 100;
  if (player.armorPoints >= hits) {
    return false;
  }

  player
    ..armorType = armorType
    ..armorPoints = hits;

  return true;
}

void giveCard(Player player, CardType card) {
  if (player.cards[card.index]) {
    return;
  }

  player.bonusCount = _InterConstants.bonusAdd;
  player.cards[card.index] = true;
}

bool givePower(Player player, PowerType power) {
  final powerIndex = power.index;

  switch (power) {
    case PowerType.invulnerability:
      player.powers[powerIndex] = _InterConstants.invulnTics;
      return true;

    case PowerType.invisibility:
      player.powers[powerIndex] = _InterConstants.invisTics;
      final mobj = player.mobj;
      if (mobj != null) {
        mobj.flags |= MobjFlag.shadow;
      }
      return true;

    case PowerType.infrared:
      player.powers[powerIndex] = _InterConstants.infraTics;
      return true;

    case PowerType.ironFeet:
      player.powers[powerIndex] = _InterConstants.ironTics;
      return true;

    case PowerType.strength:
      giveBody(player, 100);
      player.powers[powerIndex] = 1;
      return true;

    case PowerType.allMap:
      if (player.powers[powerIndex] != 0) {
        return false;
      }
      player.powers[powerIndex] = 1;
      return true;

    case PowerType.numPowers:
      return false;
  }
}

void touchSpecialThing(Mobj special, Mobj toucher, LevelLocals level) {
  final delta = special.z - toucher.z;

  if (delta > toucher.height || delta < -8 * Fixed32.fracUnit) {
    return;
  }

  final player = toucher.player;
  if (player is! Player) {
    return;
  }

  if (toucher.health <= 0) {
    return;
  }

  var pickedUp = false;

  switch (special.sprite) {
    case SpriteNum.arm1:
      pickedUp = giveArmor(player, 1);

    case SpriteNum.arm2:
      pickedUp = giveArmor(player, 2);

    case SpriteNum.bon1:
      player.health++;
      if (player.health > _InterConstants.maxSuperHealth) {
        player.health = _InterConstants.maxSuperHealth;
      }
      toucher.health = player.health;
      pickedUp = true;

    case SpriteNum.bon2:
      player.armorPoints++;
      if (player.armorPoints > _InterConstants.maxSuperHealth) {
        player.armorPoints = _InterConstants.maxSuperHealth;
      }
      if (player.armorType == 0) {
        player.armorType = 1;
      }
      pickedUp = true;

    case SpriteNum.soul:
      player.health += 100;
      if (player.health > _InterConstants.maxSuperHealth) {
        player.health = _InterConstants.maxSuperHealth;
      }
      toucher.health = player.health;
      pickedUp = true;

    case SpriteNum.mega:
      player.health = _InterConstants.maxSuperHealth;
      toucher.health = player.health;
      giveArmor(player, 2);
      pickedUp = true;

    case SpriteNum.bkey:
      giveCard(player, CardType.blueCard);
      pickedUp = true;

    case SpriteNum.ykey:
      giveCard(player, CardType.yellowCard);
      pickedUp = true;

    case SpriteNum.rkey:
      giveCard(player, CardType.redCard);
      pickedUp = true;

    case SpriteNum.bsku:
      giveCard(player, CardType.blueSkull);
      pickedUp = true;

    case SpriteNum.ysku:
      giveCard(player, CardType.yellowSkull);
      pickedUp = true;

    case SpriteNum.rsku:
      giveCard(player, CardType.redSkull);
      pickedUp = true;

    case SpriteNum.stim:
      pickedUp = giveBody(player, 10);

    case SpriteNum.medi:
      pickedUp = giveBody(player, 25);

    case SpriteNum.pinv:
      pickedUp = givePower(player, PowerType.invulnerability);

    case SpriteNum.pstr:
      pickedUp = givePower(player, PowerType.strength);
      if (pickedUp && player.readyWeapon != WeaponType.fist) {
        player.pendingWeapon = WeaponType.fist;
      }

    case SpriteNum.pins:
      pickedUp = givePower(player, PowerType.invisibility);

    case SpriteNum.suit:
      pickedUp = givePower(player, PowerType.ironFeet);

    case SpriteNum.pmap:
      pickedUp = givePower(player, PowerType.allMap);

    case SpriteNum.pvis:
      pickedUp = givePower(player, PowerType.infrared);

    case SpriteNum.clip:
      if ((special.flags & MobjFlag.dropped) != 0) {
        pickedUp = giveAmmo(player, AmmoType.clip, 0);
      } else {
        pickedUp = giveAmmo(player, AmmoType.clip, 1);
      }

    case SpriteNum.ammo:
      pickedUp = giveAmmo(player, AmmoType.clip, 5);

    case SpriteNum.rock:
      pickedUp = giveAmmo(player, AmmoType.missile, 1);

    case SpriteNum.brok:
      pickedUp = giveAmmo(player, AmmoType.missile, 5);

    case SpriteNum.cell:
      pickedUp = giveAmmo(player, AmmoType.cell, 1);

    case SpriteNum.celp:
      pickedUp = giveAmmo(player, AmmoType.cell, 5);

    case SpriteNum.shel:
      pickedUp = giveAmmo(player, AmmoType.shell, 1);

    case SpriteNum.sbox:
      pickedUp = giveAmmo(player, AmmoType.shell, 5);

    case SpriteNum.bpak:
      if (!player.backpack) {
        for (var i = 0; i < player.maxAmmo.length; i++) {
          player.maxAmmo[i] *= 2;
        }
        player.backpack = true;
      }
      for (var i = 0; i < _AmmoValues.maxAmmo.length; i++) {
        giveAmmo(player, AmmoType.values[i], 1);
      }
      pickedUp = true;

    case SpriteNum.bfug:
      pickedUp = giveWeapon(player, WeaponType.bfg, dropped: false);

    case SpriteNum.mgun:
      pickedUp = giveWeapon(
        player,
        WeaponType.chaingun,
        dropped: (special.flags & MobjFlag.dropped) != 0,
      );

    case SpriteNum.csaw:
      pickedUp = giveWeapon(player, WeaponType.chainsaw, dropped: false);

    case SpriteNum.laun:
      pickedUp = giveWeapon(player, WeaponType.missile, dropped: false);

    case SpriteNum.plas:
      pickedUp = giveWeapon(player, WeaponType.plasma, dropped: false);

    case SpriteNum.shot:
      pickedUp = giveWeapon(
        player,
        WeaponType.shotgun,
        dropped: (special.flags & MobjFlag.dropped) != 0,
      );

    case SpriteNum.sgn2:
      pickedUp = giveWeapon(
        player,
        WeaponType.superShotgun,
        dropped: (special.flags & MobjFlag.dropped) != 0,
      );
  }

  if (!pickedUp) {
    return;
  }

  if ((special.flags & MobjFlag.countItem) != 0) {
    player.itemCount++;
  }

  _removeMobj(special, level);
  player.bonusCount += _InterConstants.bonusAdd;
}

void _removeMobj(Mobj mobj, LevelLocals level) {
  _unlinkFromSector(mobj);
  mobj
    ..flags &= ~(MobjFlag.special | MobjFlag.solid | MobjFlag.shootable)
    ..health = 0;
}

void _unlinkFromSector(Mobj mobj) {
  if (mobj.sNext != null) {
    mobj.sNext!.sPrev = mobj.sPrev;
  }

  if (mobj.sPrev != null) {
    mobj.sPrev!.sNext = mobj.sNext;
  } else {
    final subsector = mobj.subsector;
    if (subsector is Subsector) {
      if (subsector.sector.thingList == mobj) {
        subsector.sector.thingList = mobj.sNext;
      }
    }
  }

  mobj
    ..sNext = null
    ..sPrev = null;
}

void damageMobj(
  Mobj target,
  Mobj? inflictor,
  Mobj? source,
  int damage,
  LevelLocals level,
) {
  if ((target.flags & MobjFlag.shootable) == 0) {
    return;
  }

  if (target.health <= 0) {
    return;
  }

  if ((target.flags & MobjFlag.skullFly) != 0) {
    target
      ..momX = 0
      ..momY = 0
      ..momZ = 0;
  }

  final player = target.player;
  var actualDamage = damage;

  final sourcePlayer = source?.player;
  if (inflictor != null &&
      (target.flags & MobjFlag.noClip) == 0 &&
      (sourcePlayer is! Player ||
          sourcePlayer.readyWeapon != WeaponType.chainsaw)) {
    var ang = pointToAngle(target.x - inflictor.x, target.y - inflictor.y);
    final mass = target.info?.mass ?? 100;
    var thrust = actualDamage * (Fixed32.fracUnit >> 3) * 100 ~/ mass;

    if (actualDamage < 40 &&
        actualDamage > target.health &&
        target.z - inflictor.z > 64 * Fixed32.fracUnit &&
        (level.random.pRandom() & 1) != 0) {
      ang = (ang + Angle.ang180).u32;
      thrust *= 4;
    }

    final fineAngle = (ang.u32 >> Angle.angleToFineShift) & Angle.fineMask;
    target
      ..momX += Fixed32.mul(thrust, fineCosine(fineAngle))
      ..momY += Fixed32.mul(thrust, fineSine(fineAngle));
  }

  if (player is Player) {
    if (actualDamage < 1000 &&
        ((player.cheats & CheatFlag.godMode) != 0 ||
            player.powers[PowerType.invulnerability.index] > 0)) {
      return;
    }

    if (player.armorType > 0) {
      int saved;
      if (player.armorType == 1) {
        saved = actualDamage ~/ 3;
      } else {
        saved = actualDamage ~/ 2;
      }

      if (player.armorPoints <= saved) {
        saved = player.armorPoints;
        player.armorType = 0;
      }

      player.armorPoints -= saved;
      actualDamage -= saved;
    }

    player.health -= actualDamage;
    if (player.health < 0) {
      player.health = 0;
    }

    player
      ..attacker = source
      ..damageCount += actualDamage;

    if (player.damageCount > _DamageConstants.maxDamageCount) {
      player.damageCount = _DamageConstants.maxDamageCount;
    }
  }

  target.health -= actualDamage;
  if (target.health <= 0) {
    killMobj(source, target, level);
    return;
  }

  final info = target.info;
  if (info != null &&
      (level.random.pRandom() < info.painChance) &&
      (target.flags & MobjFlag.skullFly) == 0) {
    target.flags |= MobjFlag.justHit;
    spec.setMobjState(target, info.painState, level);
  }

  target.reactionTime = 0;

  if ((target.threshold == 0 || target.type == _MobjType.vile) &&
      source != null &&
      source != target &&
      source.type != _MobjType.vile) {
    target
      ..target = source
      ..threshold = _DamageConstants.baseThreshold;

    final info = target.info;
    if (info != null &&
        target.stateNum == info.spawnState &&
        info.seeState != StateNum.sNull) {
      spec.setMobjState(target, info.seeState, level);
    }
  }
}

void killMobj(Mobj? source, Mobj target, LevelLocals level) {
  target.flags &= ~(MobjFlag.shootable | MobjFlag.float | MobjFlag.skullFly);

  if (target.type != _MobjType.skull) {
    target.flags &= ~MobjFlag.noGravity;
  }

  target
    ..flags |= MobjFlag.corpse | MobjFlag.dropOff
    ..height >>= 2;

  if (source != null && source.player is Player) {
    final player = source.player! as Player;
    if ((target.flags & MobjFlag.countKill) != 0) {
      player.killCount++;
    }
  } else if ((target.flags & MobjFlag.countKill) != 0) {
    if (level.players.isNotEmpty) {
      level.players[0].killCount++;
    }
  }

  if (target.player is Player) {
    final player = target.player! as Player;
    target.flags &= ~MobjFlag.solid;
    player.playerState = PlayerState.dead;
  }

  final info = target.info;
  if (info != null) {
    if (target.health < -info.spawnHealth && info.xDeathState != 0) {
      spec.setMobjState(target, info.xDeathState, level);
    } else {
      spec.setMobjState(target, info.deathState, level);
    }

    target.tics -= level.random.pRandom() & 3;
    if (target.tics < 1) {
      target.tics = 1;
    }
  }

  _dropItem(target, level);
}

void _dropItem(Mobj target, LevelLocals level) {
  final int itemSprite;
  switch (target.type) {
    case _MobjType.possessed:
    case _MobjType.wolfSs:
      itemSprite = SpriteNum.clip;
    case _MobjType.shotGuy:
      itemSprite = SpriteNum.shot;
    case _MobjType.chainGuy:
      itemSprite = SpriteNum.mgun;
    default:
      return;
  }

  _spawnDroppedItem(target.x, target.y, target.floorZ, itemSprite, level);
}

void _spawnDroppedItem(
  int x,
  int y,
  int z,
  int sprite,
  LevelLocals level,
) {
  final mobj = Mobj()
    ..x = x
    ..y = y
    ..z = z
    ..sprite = sprite
    ..frame = 0
    ..flags = MobjFlag.special | MobjFlag.dropped;

  _setThingPosition(mobj, level);
}

void _setThingPosition(Mobj mobj, LevelLocals level) {
  final ss = _pointInSubsector(mobj.x, mobj.y, level.renderState);
  if (ss == null) return;

  mobj
    ..subsector = ss
    ..floorZ = ss.sector.floorHeight
    ..ceilingZ = ss.sector.ceilingHeight;

  if ((mobj.flags & MobjFlag.noSector) == 0) {
    final sector = ss.sector;
    mobj
      ..sPrev = null
      ..sNext = sector.thingList;

    if (sector.thingList != null) {
      sector.thingList!.sPrev = mobj;
    }
    sector.thingList = mobj;
  }
}

Subsector? _pointInSubsector(int x, int y, RenderState state) {
  if (state.nodes.isEmpty) {
    return state.subsectors.isNotEmpty ? state.subsectors[0] : null;
  }

  var nodeNum = state.nodes.length - 1;

  while (!BspConstants.isSubsector(nodeNum)) {
    final node = state.nodes[nodeNum];
    final side = _pointOnSide(x, y, node);
    nodeNum = node.children[side];
  }

  return state.subsectors[BspConstants.getIndex(nodeNum)];
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

abstract final class _MobjType {
  static const int possessed = 3004;
  static const int shotGuy = 9;
  static const int chainGuy = 65;
  static const int skull = 3006;
  static const int vile = 64;
  static const int wolfSs = 84;
}
