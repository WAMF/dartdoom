import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';

/// Constants for demo format.
abstract final class DemoConstants {
  /// Current demo version (matches linuxdoom-1.10).
  static const int version = 110;

  /// Minimum compatible demo version (DOOM 1.4+).
  /// Demos from versions 104-110 share the same 13-byte header format.
  static const int minVersion = 104;

  /// Marker byte indicating end of demo data.
  static const int demoMarker = 0x80;

  /// Default demo buffer size (128KB).
  static const int defaultBufferSize = 0x20000;

  /// Maximum number of players in a demo.
  static const int maxPlayers = 4;
}

/// Demo file header containing game setup information.
///
/// Original C (g_game.c):
/// ```c
/// *demo_p++ = VERSION;
/// *demo_p++ = gameskill;
/// *demo_p++ = gameepisode;
/// *demo_p++ = gamemap;
/// *demo_p++ = deathmatch;
/// *demo_p++ = respawnparm;
/// *demo_p++ = fastparm;
/// *demo_p++ = nomonsters;
/// *demo_p++ = consoleplayer;
/// for (i=0 ; i<MAXPLAYERS ; i++)
///     *demo_p++ = playeringame[i];
/// ```
class DemoHeader {
  DemoHeader({
    required this.version,
    required this.skill,
    required this.episode,
    required this.map,
    this.deathmatch = false,
    this.respawn = false,
    this.fast = false,
    this.noMonsters = false,
    this.consolePlayer = 0,
    List<bool>? playersInGame,
  }) : playersInGame = playersInGame ??
            List.filled(DemoConstants.maxPlayers, false);

  /// Parse a demo header from bytes.
  factory DemoHeader.fromBytes(Uint8List data) {
    if (data.length < headerSize) {
      throw ArgumentError('Demo data too short for header');
    }

    var offset = 0;
    final ver = data[offset++];
    final skillIndex = data[offset++];
    final ep = data[offset++];
    final m = data[offset++];
    final dm = data[offset++] != 0;
    final resp = data[offset++] != 0;
    final f = data[offset++] != 0;
    final noMon = data[offset++] != 0;
    final consolePl = data[offset++];

    final pig = <bool>[];
    for (var i = 0; i < DemoConstants.maxPlayers; i++) {
      pig.add(data[offset++] != 0);
    }

    return DemoHeader(
      version: ver,
      skill: Skill.values[skillIndex.clamp(0, Skill.values.length - 1)],
      episode: ep,
      map: m,
      deathmatch: dm,
      respawn: resp,
      fast: f,
      noMonsters: noMon,
      consolePlayer: consolePl,
      playersInGame: pig,
    );
  }

  /// Total header size in bytes.
  static const int headerSize = 13; // 9 bytes + 4 player flags

  /// Demo format version.
  final int version;

  /// Skill level (0-4).
  final Skill skill;

  /// Episode number (1-4 for Doom, 1 for Doom 2).
  final int episode;

  /// Map number.
  final int map;

  /// Deathmatch mode flag.
  final bool deathmatch;

  /// Respawn monsters flag.
  final bool respawn;

  /// Fast monsters flag.
  final bool fast;

  /// No monsters flag.
  final bool noMonsters;

  /// Player number being recorded (0-3).
  final int consolePlayer;

  /// Which players are active in the game.
  final List<bool> playersInGame;

  /// Serialize the header to bytes.
  Uint8List toBytes() {
    final data = Uint8List(headerSize);
    var offset = 0;

    data[offset++] = version;
    data[offset++] = skill.index;
    data[offset++] = episode;
    data[offset++] = map;
    data[offset++] = deathmatch ? 1 : 0;
    data[offset++] = respawn ? 1 : 0;
    data[offset++] = fast ? 1 : 0;
    data[offset++] = noMonsters ? 1 : 0;
    data[offset++] = consolePlayer;

    for (var i = 0; i < DemoConstants.maxPlayers; i++) {
      data[offset++] = (i < playersInGame.length && playersInGame[i]) ? 1 : 0;
    }

    return data;
  }

  /// Check if this header is compatible with current game version.
  /// Accepts demos from versions 104-110 (DOOM 1.4 through linuxdoom-1.10).
  bool get isCompatible =>
      version >= DemoConstants.minVersion && version <= DemoConstants.version;

  /// Number of active players in this demo.
  int get playerCount => playersInGame.where((bool p) => p).length;

  @override
  String toString() =>
      'DemoHeader(v$version, skill=${skill.name}, E${episode}M$map, '
      'players=$playerCount)';
}

/// A single tic command as stored in a demo file.
///
/// Original C (g_game.c):
/// ```c
/// *demo_p++ = cmd->forwardmove;
/// *demo_p++ = cmd->sidemove;
/// *demo_p++ = (cmd->angleturn+128)>>8;
/// *demo_p++ = cmd->buttons;
/// ```
class DemoTic {
  DemoTic({
    required this.forwardMove,
    required this.sideMove,
    required this.angleTurn,
    required this.buttons,
  });

  /// Create from a TicCmd.
  factory DemoTic.fromTicCmd(TicCmd cmd) {
    return DemoTic(
      forwardMove: cmd.forwardMove.clamp(-127, 127),
      sideMove: cmd.sideMove.clamp(-127, 127),
      // Original: (cmd->angleturn+128)>>8
      angleTurn: ((cmd.angleTurn + 128) >> 8) & 0xFF,
      buttons: cmd.buttons & 0xFF,
    );
  }

  /// Parse from bytes at offset.
  factory DemoTic.fromBytes(Uint8List data, int offset) {
    return DemoTic(
      forwardMove: data[offset],
      sideMove: data[offset + 1],
      angleTurn: data[offset + 2],
      buttons: data[offset + 3],
    );
  }

  /// Size of a tic in bytes.
  static const int ticSize = 4;

  /// Forward/backward movement (-127 to 127).
  final int forwardMove;

  /// Strafe left/right movement (-127 to 127).
  final int sideMove;

  /// Turn angle, compressed from 16-bit to 8-bit.
  final int angleTurn;

  /// Button state (attack, use, weapon change).
  final int buttons;

  /// Apply this tic to a TicCmd.
  void applyTo(TicCmd cmd) {
    // Original C: cmd->angleturn = ((unsigned char)*demo_p++)<<8;
    // angleturn is a signed short (16-bit), so 0x80<<8 = 0x8000 = -32768
    final shiftedAngle = angleTurn << 8;
    // Convert to signed 16-bit: if >= 0x8000, subtract 0x10000
    final signedAngle = shiftedAngle >= 0x8000 ? shiftedAngle - 0x10000 : shiftedAngle;

    cmd
      ..forwardMove = forwardMove < 128 ? forwardMove : forwardMove - 256
      ..sideMove = sideMove < 128 ? sideMove : sideMove - 256
      ..angleTurn = signedAngle
      ..buttons = buttons;
  }

  /// Write to bytes at offset.
  void writeToBytes(Uint8List data, int offset) {
    // Store forwardMove as signed byte
    data[offset] = forwardMove & 0xFF;
    data[offset + 1] = sideMove & 0xFF;
    data[offset + 2] = angleTurn & 0xFF;
    data[offset + 3] = buttons & 0xFF;
  }
}
