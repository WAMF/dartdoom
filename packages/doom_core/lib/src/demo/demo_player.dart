import 'dart:typed_data';

import 'package:doom_core/src/demo/demo_format.dart';
import 'package:doom_core/src/events/tic_cmd.dart';

/// Plays back a recorded demo.
///
/// Original C (g_game.c):
/// ```c
/// void G_DoPlayDemo (void)
/// {
///     skill_t skill;
///     int i, episode, map;
///
///     gameaction = ga_nothing;
///     demobuffer = demo_p = W_CacheLumpName (defdemoname, PU_STATIC);
///     if (*demo_p++ != VERSION)
///     {
///         fprintf( stderr, "Demo is from a different game version!\n");
///         return;
///     }
///     skill = *demo_p++;
///     episode = *demo_p++;
///     map = *demo_p++;
///     deathmatch = *demo_p++;
///     respawnparm = *demo_p++;
///     fastparm = *demo_p++;
///     nomonsters = *demo_p++;
///     consoleplayer = *demo_p++;
///     for (i=0 ; i<MAXPLAYERS ; i++)
///         playeringame[i] = *demo_p++;
///     ...
///     usergame = false;
///     demoplayback = true;
/// }
/// ```
class DemoPlayer {
  DemoPlayer(Uint8List data) : _data = data {
    if (data.length < DemoHeader.headerSize) {
      throw ArgumentError('Demo data too short');
    }
    _header = DemoHeader.fromBytes(data);
    _position = DemoHeader.headerSize;
  }

  final Uint8List _data;
  late final DemoHeader _header;
  int _position = 0;
  bool _isFinished = false;

  /// The demo header containing game setup information.
  DemoHeader get header => _header;

  /// Whether the demo has finished playing.
  bool get isFinished => _isFinished;

  /// Current playback position in bytes.
  int get position => _position;

  /// Total demo size in bytes.
  int get totalSize => _data.length;

  /// Number of tics remaining to play.
  int get remainingTics {
    if (_isFinished) return 0;
    final remaining = _data.length - _position - 1; // -1 for marker
    return remaining ~/ DemoTic.ticSize;
  }

  /// Check if the demo version is compatible.
  bool get isCompatible => _header.isCompatible;

  /// Read the next tic command from the demo.
  ///
  /// Original C (g_game.c):
  /// ```c
  /// void G_ReadDemoTiccmd (ticcmd_t* cmd)
  /// {
  ///     if (*demo_p == DEMOMARKER)
  ///     {
  ///         // end of demo data stream
  ///         G_CheckDemoStatus ();
  ///         return;
  ///     }
  ///     cmd->forwardmove = ((signed char)*demo_p++);
  ///     cmd->sidemove = ((signed char)*demo_p++);
  ///     cmd->angleturn = ((unsigned char)*demo_p++)<<8;
  ///     cmd->buttons = (unsigned char)*demo_p++;
  /// }
  /// ```
  void readTic(TicCmd cmd) {
    if (_isFinished) {
      cmd.clear();
      return;
    }

    // Check for end marker
    if (_position >= _data.length ||
        _data[_position] == DemoConstants.demoMarker) {
      _isFinished = true;
      cmd.clear();
      return;
    }

    // Check if we have enough data for a full tic
    if (_position + DemoTic.ticSize > _data.length) {
      _isFinished = true;
      cmd.clear();
      return;
    }

    final tic = DemoTic.fromBytes(_data, _position);
    tic.applyTo(cmd);
    _position += DemoTic.ticSize;
  }

  /// Reset playback to the beginning.
  void reset() {
    _position = DemoHeader.headerSize;
    _isFinished = false;
  }

  /// Skip ahead by the specified number of tics.
  void skip(int tics) {
    final bytesToSkip = tics * DemoTic.ticSize;
    final newPosition = _position + bytesToSkip;

    if (newPosition >= _data.length ||
        _data[newPosition] == DemoConstants.demoMarker) {
      _isFinished = true;
      _position = _data.length;
    } else {
      _position = newPosition;
    }
  }

  /// Get the current tic number (0-based).
  int get currentTic {
    return (_position - DemoHeader.headerSize) ~/ DemoTic.ticSize;
  }

  /// Total number of tics in the demo.
  int get totalTics {
    // Find the demo marker
    for (var i = DemoHeader.headerSize; i < _data.length; i++) {
      if (_data[i] == DemoConstants.demoMarker) {
        return (i - DemoHeader.headerSize) ~/ DemoTic.ticSize;
      }
    }
    // No marker found, estimate from data length
    return (_data.length - DemoHeader.headerSize) ~/ DemoTic.ticSize;
  }
}
