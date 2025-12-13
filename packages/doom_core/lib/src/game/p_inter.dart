import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/game_info.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_math/doom_math.dart';

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
