import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/p_pspr.dart';
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/serialization/game_serializer.dart';

/// Archive all players to the writer.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_ArchivePlayers (void)
/// {
///     int i, j;
///     for (i=0 ; i<MAXPLAYERS ; i++)
///     {
///         if (!playeringame[i])
///             continue;
///         PADSAVEP();
///         memcpy (save_p, &players[i], sizeof(player_t));
///         save_p += sizeof(player_t);
///         for (j=0 ; j<NUMPSPRITES ; j++)
///         {
///             if (players[i].psprites[j].state)
///                 players[i].psprites[j].state =
///                     (state_t *)(players[i].psprites[j].state-states);
///         }
///     }
/// }
/// ```
void archivePlayers(
  LevelLocals level,
  GameDataWriter writer,
  List<bool> playersInGame,
) {
  for (var i = 0; i < MaxPlayers.count; i++) {
    if (!playersInGame[i]) continue;

    writer.pad();

    final player = level.players[i];
    _writePlayer(player, writer);
  }
}

void _writePlayer(Player player, GameDataWriter writer) {
  // mobj reference is restored during unarchive via player number
  // Write player number as reference marker
  writer
    ..writeInt(player.playerNum)

    // View state
    ..writeFixed(player.viewZ)
    ..writeFixed(player.viewHeight)
    ..writeFixed(player.deltaViewHeight)
    ..writeFixed(player.bob)

    // Health and armor
    ..writeInt(player.health)
    ..writeInt(player.armorPoints)
    ..writeInt(player.armorType);

  // Powers (6 ints)
  for (final power in player.powers) {
    writer.writeInt(power);
  }

  // Cards (6 bools)
  for (final card in player.cards) {
    writer.writeBool(value: card);
  }

  // Backpack
  writer.writeBool(value: player.backpack);

  // Frags (4 ints)
  for (final frag in player.frags) {
    writer.writeInt(frag);
  }

  // Weapons
  writer
    ..writeInt(player.readyWeapon.index)
    ..writeInt(player.pendingWeapon.index);

  // Weapon ownership (9 bools)
  for (final owned in player.weaponOwned) {
    writer.writeBool(value: owned);
  }

  // Ammo (4 ints each)
  for (final ammo in player.ammo) {
    writer.writeInt(ammo);
  }
  for (final maxAmmo in player.maxAmmo) {
    writer.writeInt(maxAmmo);
  }

  // Input state
  writer
    ..writeBool(value: player.attackDown)
    ..writeBool(value: player.useDown)

    // Cheat/refire
    ..writeInt(player.cheats)
    ..writeInt(player.refire)

    // Stats
    ..writeInt(player.killCount)
    ..writeInt(player.itemCount)
    ..writeInt(player.secretCount)

    // Damage/bonus counters
    ..writeInt(player.damageCount)
    ..writeInt(player.bonusCount)

    // Extra light/colormap
    ..writeInt(player.extraLight)
    ..writeInt(player.fixedColormap)
    ..writeInt(player.colorMap)

    // Player state
    ..writeInt(player.playerState.index)

    // Didsecret flag
    ..writeBool(value: player.didsecret)

    // Psprites - save count
    ..writeInt(player.psprites.length);

  for (final psp in player.psprites) {
    writer
      ..writeInt(psp.state)
      ..writeInt(psp.tics)
      ..writeFixed(psp.sx)
      ..writeFixed(psp.sy)
      ..writeInt(psp.psprState.index)
      ..writeInt(psp.sprite)
      ..writeInt(psp.frame)
      ..writeInt(psp.attackFrameIndex)
      ..writeInt(psp.attackFrameTics);
  }
}

/// Unarchive all players from the reader.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_UnArchivePlayers (void)
/// {
///     int i, j;
///     for (i=0 ; i<MAXPLAYERS ; i++)
///     {
///         if (!playeringame[i])
///             continue;
///         PADSAVEP();
///         memcpy (&players[i], save_p, sizeof(player_t));
///         save_p += sizeof(player_t);
///         players[i].mo = NULL;
///         players[i].message = NULL;
///         players[i].attacker = NULL;
///         for (j=0 ; j<NUMPSPRITES ; j++)
///         {
///             if (players[i].psprites[j].state)
///                 players[i].psprites[j].state =
///                     &states[(int)players[i].psprites[j].state];
///         }
///     }
/// }
/// ```
void unarchivePlayers(
  LevelLocals level,
  GameDataReader reader,
  List<bool> playersInGame,
) {
  for (var i = 0; i < MaxPlayers.count; i++) {
    if (!playersInGame[i]) continue;

    reader.skipPadding();

    final player = level.players[i];
    _readPlayer(player, reader);

    // Clear runtime pointers
    player
      ..mobj = null
      ..message = null
      ..attacker = null;
  }
}

void _readPlayer(Player player, GameDataReader reader) {
  // Read player number (for verification)
  player
    ..playerNum = reader.readInt()

    // View state
    ..viewZ = reader.readFixed()
    ..viewHeight = reader.readFixed()
    ..deltaViewHeight = reader.readFixed()
    ..bob = reader.readFixed()

    // Health and armor
    ..health = reader.readInt()
    ..armorPoints = reader.readInt()
    ..armorType = reader.readInt();

  // Powers (6 ints)
  for (var i = 0; i < player.powers.length; i++) {
    player.powers[i] = reader.readInt();
  }

  // Cards (6 bools)
  for (var i = 0; i < player.cards.length; i++) {
    player.cards[i] = reader.readBool();
  }

  // Backpack
  player.backpack = reader.readBool();

  // Frags (4 ints)
  for (var i = 0; i < player.frags.length; i++) {
    player.frags[i] = reader.readInt();
  }

  // Weapons
  final readyIndex = reader.readInt();
  final pendingIndex = reader.readInt();
  player
    ..readyWeapon = _weaponFromIndex(readyIndex)
    ..pendingWeapon = _weaponFromIndex(pendingIndex);

  // Weapon ownership (9 bools)
  for (var i = 0; i < player.weaponOwned.length; i++) {
    player.weaponOwned[i] = reader.readBool();
  }

  // Ammo (4 ints each)
  for (var i = 0; i < player.ammo.length; i++) {
    player.ammo[i] = reader.readInt();
  }
  for (var i = 0; i < player.maxAmmo.length; i++) {
    player.maxAmmo[i] = reader.readInt();
  }

  // Input state
  player
    ..attackDown = reader.readBool()
    ..useDown = reader.readBool()

    // Cheat/refire
    ..cheats = reader.readInt()
    ..refire = reader.readInt()

    // Stats
    ..killCount = reader.readInt()
    ..itemCount = reader.readInt()
    ..secretCount = reader.readInt()

    // Damage/bonus counters
    ..damageCount = reader.readInt()
    ..bonusCount = reader.readInt()

    // Extra light/colormap
    ..extraLight = reader.readInt()
    ..fixedColormap = reader.readInt()
    ..colorMap = reader.readInt();

  // Player state
  final stateIndex = reader.readInt();
  player.playerState = _playerStateFromIndex(stateIndex);

  // Didsecret flag
  player.didsecret = reader.readBool();

  // Psprites
  final pspCount = reader.readInt();
  player.psprites.clear();
  for (var i = 0; i < pspCount; i++) {
    final psp = PspriteDef()
      ..state = reader.readInt()
      ..tics = reader.readInt()
      ..sx = reader.readFixed()
      ..sy = reader.readFixed()
      ..psprState = _psprStateFromIndex(reader.readInt())
      ..sprite = reader.readInt()
      ..frame = reader.readInt()
      ..attackFrameIndex = reader.readInt()
      ..attackFrameTics = reader.readInt();
    player.psprites.add(psp);
  }
}

WeaponType _weaponFromIndex(int index) {
  if (index < 0 || index >= WeaponType.values.length) {
    return WeaponType.noChange;
  }
  return WeaponType.values[index];
}

PlayerState _playerStateFromIndex(int index) {
  if (index < 0 || index >= PlayerState.values.length) {
    return PlayerState.live;
  }
  return PlayerState.values[index];
}

PsprState _psprStateFromIndex(int index) {
  if (index < 0 || index >= PsprState.values.length) {
    return PsprState.none;
  }
  return PsprState.values[index];
}
