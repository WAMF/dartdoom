import 'dart:typed_data';

import 'package:doom_core/src/demo/demo_format.dart';
import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/tic_cmd.dart';

/// Records gameplay to a demo file.
///
/// Original C (g_game.c):
/// ```c
/// void G_RecordDemo (char* name)
/// {
///     usergame = false;
///     strcpy (demoname, name);
///     strcat (demoname, ".lmp");
///     demobuffer = demo_p = Z_Malloc (0x20000,PU_STATIC,NULL);
///     demoend = demobuffer + 0x20000;
///     demorecording = true;
/// }
/// ```
class DemoRecorder {
  DemoRecorder({
    int bufferSize = DemoConstants.defaultBufferSize,
  }) : _buffer = Uint8List(bufferSize);

  final Uint8List _buffer;
  int _position = 0;
  bool _isRecording = false;
  DemoHeader? _header;

  /// Whether recording is currently active.
  bool get isRecording => _isRecording;

  /// Current recording position (number of bytes written).
  int get position => _position;

  /// Remaining buffer space in bytes.
  int get remainingSpace => _buffer.length - _position;

  /// Start recording a demo.
  ///
  /// Original C (g_game.c):
  /// ```c
  /// void G_BeginRecording (void)
  /// {
  ///     *demo_p++ = VERSION;
  ///     *demo_p++ = gameskill;
  ///     *demo_p++ = gameepisode;
  ///     *demo_p++ = gamemap;
  ///     *demo_p++ = deathmatch;
  ///     *demo_p++ = respawnparm;
  ///     *demo_p++ = fastparm;
  ///     *demo_p++ = nomonsters;
  ///     *demo_p++ = consoleplayer;
  ///     for (i=0 ; i<MAXPLAYERS ; i++)
  ///         *demo_p++ = playeringame[i];
  /// }
  /// ```
  void startRecording({
    required Skill skill,
    required int episode,
    required int map,
    bool deathmatch = false,
    bool respawn = false,
    bool fast = false,
    bool noMonsters = false,
    int consolePlayer = 0,
    List<bool>? playersInGame,
  }) {
    if (_isRecording) {
      throw StateError('Already recording');
    }

    _header = DemoHeader(
      version: DemoConstants.version,
      skill: skill,
      episode: episode,
      map: map,
      deathmatch: deathmatch,
      respawn: respawn,
      fast: fast,
      noMonsters: noMonsters,
      consolePlayer: consolePlayer,
      playersInGame: playersInGame,
    );

    // Write header to buffer
    final headerBytes = _header!.toBytes();
    _buffer.setRange(0, headerBytes.length, headerBytes);
    _position = headerBytes.length;
    _isRecording = true;
  }

  /// Record a single tic command.
  ///
  /// Original C (g_game.c):
  /// ```c
  /// void G_WriteDemoTiccmd (ticcmd_t* cmd)
  /// {
  ///     *demo_p++ = cmd->forwardmove;
  ///     *demo_p++ = cmd->sidemove;
  ///     *demo_p++ = (cmd->angleturn+128)>>8;
  ///     *demo_p++ = cmd->buttons;
  ///     demo_p -= 4;
  ///     G_ReadDemoTiccmd (cmd);     // make SURE it is exactly the same
  ///     if (demo_p > demoend - 16)
  ///     {
  ///         G_CheckDemoStatus ();
  ///     }
  /// }
  /// ```
  void recordTic(TicCmd cmd) {
    if (!_isRecording) {
      throw StateError('Not recording');
    }

    // Check if buffer is nearly full (leave space for marker + safety margin)
    if (_position + DemoTic.ticSize + 16 > _buffer.length) {
      // Buffer full - stop recording
      stopRecording();
      return;
    }

    final tic = DemoTic.fromTicCmd(cmd);
    tic.writeToBytes(_buffer, _position);
    _position += DemoTic.ticSize;
  }

  /// Stop recording and return the demo data.
  ///
  /// Original C (g_game.c):
  /// ```c
  /// // end of recording
  /// *demo_p++ = DEMOMARKER;
  /// M_WriteFile (demoname, demobuffer, demo_p - demobuffer);
  /// Z_Free (demobuffer);
  /// demorecording = false;
  /// ```
  Uint8List stopRecording() {
    if (!_isRecording) {
      throw StateError('Not recording');
    }

    // Write demo marker
    _buffer[_position++] = DemoConstants.demoMarker;

    // Extract recorded data
    final result = Uint8List.fromList(_buffer.sublist(0, _position));

    // Reset state
    _isRecording = false;
    _position = 0;
    _header = null;

    return result;
  }

  /// Get the header of the current recording.
  DemoHeader? get header => _header;

  /// Number of tics recorded so far.
  int get ticCount {
    if (_position <= DemoHeader.headerSize) return 0;
    return (_position - DemoHeader.headerSize) ~/ DemoTic.ticSize;
  }
}
