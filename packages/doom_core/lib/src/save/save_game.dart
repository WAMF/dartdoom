import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/specials/ceiling_thinker.dart';
import 'package:doom_core/src/game/specials/plat_thinker.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/save/archive_players.dart';
import 'package:doom_core/src/save/archive_specials.dart';
import 'package:doom_core/src/save/archive_thinkers.dart';
import 'package:doom_core/src/save/archive_world.dart';
import 'package:doom_core/src/serialization/binary_serializer.dart';
import 'package:doom_core/src/serialization/game_serializer.dart';

/// Save game header constants matching original DOOM.
abstract final class SaveGameConstants {
  static const int descriptionSize = 24;
  static const int versionStringSize = 16;
  static const String versionString = 'DartDOOM 1.0';
  static const int saveMarker = 0x1d;
  static const int maxSaveSlots = 6;
}

/// Save game header data.
class SaveGameHeader {
  SaveGameHeader({
    required this.description,
    required this.versionString,
    required this.skill,
    required this.episode,
    required this.map,
    required this.playersInGame,
    required this.levelTime,
  });

  final String description;
  final String versionString;
  final Skill skill;
  final int episode;
  final int map;
  final List<bool> playersInGame;
  final int levelTime;

  /// Create header from current game state.
  factory SaveGameHeader.fromGameState({
    required String description,
    required Skill skill,
    required int episode,
    required int map,
    required List<bool> playersInGame,
    required int levelTime,
  }) {
    return SaveGameHeader(
      description: description,
      versionString: SaveGameConstants.versionString,
      skill: skill,
      episode: episode,
      map: map,
      playersInGame: playersInGame,
      levelTime: levelTime,
    );
  }
}

/// Manager for save/load game operations.
///
/// Original C (p_saveg.c):
/// ```c
/// void P_SaveGame (char* description)
/// {
///     byte* save_p;
///     memcpy(save_p, description, SAVESTRINGSIZE);
///     save_p += SAVESTRINGSIZE;
///     memset(save_p, 0, VERSIONSIZE);
///     save_p += VERSIONSIZE;
///     *save_p++ = gameskill;
///     *save_p++ = gameepisode;
///     *save_p++ = gamemap;
///     for (i=0 ; i<MAXPLAYERS ; i++)
///         *save_p++ = playeringame[i];
///     *save_p++ = leveltime>>16;
///     *save_p++ = leveltime>>8;
///     *save_p++ = leveltime;
///     P_ArchivePlayers ();
///     P_ArchiveWorld ();
///     P_ArchiveThinkers ();
///     P_ArchiveSpecials ();
///     *save_p++ = 0x1d;
/// }
/// ```
class SaveGameManager {
  SaveGameManager({
    GameSerializer? serializer,
  }) : _serializer = serializer ?? BinarySerializer();

  final GameSerializer _serializer;

  /// Save the current game state.
  ///
  /// Returns the save data as bytes.
  Uint8List saveGame({
    required String description,
    required LevelLocals level,
    required RenderState renderState,
    required Skill skill,
    required int episode,
    required int map,
    required List<bool> playersInGame,
  }) {
    final writer = _serializer.createWriter();

    // Write header
    _writeHeader(
      writer,
      description: description,
      skill: skill,
      episode: episode,
      map: map,
      playersInGame: playersInGame,
      levelTime: level.levelTime,
    );

    // Archive game state
    archivePlayers(level, writer, playersInGame);
    archiveWorld(renderState, writer);
    archiveThinkers(level, renderState, writer);
    archiveSpecials(level, renderState, writer);

    // Write save marker
    writer.writeByte(SaveGameConstants.saveMarker);

    return writer.toBytes();
  }

  void _writeHeader(
    GameDataWriter writer, {
    required String description,
    required Skill skill,
    required int episode,
    required int map,
    required List<bool> playersInGame,
    required int levelTime,
  }) {
    // Description (24 bytes, null-padded)
    writer.writeString(description, SaveGameConstants.descriptionSize);

    // Version string (16 bytes, null-padded)
    writer.writeString(
      SaveGameConstants.versionString,
      SaveGameConstants.versionStringSize,
    );

    // Game parameters
    writer
      ..writeByte(skill.index)
      ..writeByte(episode)
      ..writeByte(map);

    // Players in game
    for (var i = 0; i < 4; i++) {
      writer.writeBool(value: i < playersInGame.length && playersInGame[i]);
    }

    // Level time (3 bytes: high, mid, low)
    writer
      ..writeByte((levelTime >> 16) & 0xff)
      ..writeByte((levelTime >> 8) & 0xff)
      ..writeByte(levelTime & 0xff);
  }

  /// Load a saved game.
  ///
  /// Returns the save game header. The caller is responsible for
  /// setting up the level before calling [restoreGameState].
  SaveGameHeader loadGameHeader(Uint8List data) {
    final reader = _serializer.createReader(data);
    return _readHeader(reader);
  }

  SaveGameHeader _readHeader(GameDataReader reader) {
    // Description
    final description = reader.readString(SaveGameConstants.descriptionSize);

    // Version string
    final versionString = reader.readString(SaveGameConstants.versionStringSize);

    // Game parameters
    final skillIndex = reader.readByte();
    final episode = reader.readByte();
    final map = reader.readByte();

    // Players in game
    final playersInGame = <bool>[];
    for (var i = 0; i < 4; i++) {
      playersInGame.add(reader.readBool());
    }

    // Level time
    final levelTimeHigh = reader.readByte();
    final levelTimeMid = reader.readByte();
    final levelTimeLow = reader.readByte();
    final levelTime =
        (levelTimeHigh << 16) | (levelTimeMid << 8) | levelTimeLow;

    return SaveGameHeader(
      description: description,
      versionString: versionString,
      skill: Skill.values[skillIndex.clamp(0, Skill.values.length - 1)],
      episode: episode,
      map: map,
      playersInGame: playersInGame,
      levelTime: levelTime,
    );
  }

  /// Restore game state from save data after the level has been set up.
  ///
  /// Original C (p_saveg.c):
  /// ```c
  /// void P_LoadGame (void)
  /// {
  ///     // ... read header ...
  ///     P_UnArchivePlayers ();
  ///     P_UnArchiveWorld ();
  ///     P_UnArchiveThinkers ();
  ///     P_UnArchiveSpecials ();
  ///     if (*save_p != 0x1d)
  ///         I_Error ("Bad savegame");
  /// }
  /// ```
  void restoreGameState({
    required Uint8List data,
    required LevelLocals level,
    required RenderState renderState,
    required List<bool> playersInGame,
    required void Function(Mobj mobj) setThingPosition,
    required ActiveCeilings activeCeilings,
    required ActivePlatforms activePlatforms,
  }) {
    final reader = _serializer.createReader(data);

    // Skip header (already read by loadGameHeader)
    _readHeader(reader);

    // Restore game state
    unarchivePlayers(level, reader, playersInGame);
    unarchiveWorld(renderState, reader);
    unarchiveThinkers(level, renderState, reader, setThingPosition);
    unarchiveSpecials(
      level,
      renderState,
      reader,
      activeCeilings: activeCeilings,
      activePlatforms: activePlatforms,
    );

    // Verify save marker
    final marker = reader.readByte();
    if (marker != SaveGameConstants.saveMarker) {
      throw StateError(
        'Bad save game: expected marker 0x${SaveGameConstants.saveMarker.toRadixString(16)}, '
        'got 0x${marker.toRadixString(16)}',
      );
    }

    // Restore level time
    // Note: This is already read in the header, but LevelLocals needs it
    // The caller should set level.levelTime from the header
  }

  /// Get a list of save game descriptions from a list of save data.
  List<String?> getSaveDescriptions(List<Uint8List?> saveFiles) {
    return saveFiles.map((data) {
      if (data == null || data.length < SaveGameConstants.descriptionSize) {
        return null;
      }
      try {
        final reader = _serializer.createReader(data);
        return reader.readString(SaveGameConstants.descriptionSize);
      } catch (_) {
        return null;
      }
    }).toList();
  }
}
