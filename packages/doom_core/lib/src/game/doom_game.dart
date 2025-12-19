import 'dart:typed_data';

import 'package:doom_core/src/demo/demo_player.dart';
import 'package:doom_core/src/demo/demo_recorder.dart';
import 'package:doom_core/src/doomdef.dart';
import 'package:doom_core/src/events/doom_event.dart';
import 'package:doom_core/src/game/blockmap.dart';
import 'package:doom_core/src/game/g_game.dart';
import 'package:doom_core/src/game/g_input.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/game/p_pspr.dart';
import 'package:doom_core/src/game/p_spec.dart' as spec;
import 'package:doom_core/src/game/player.dart';
import 'package:doom_core/src/hud/hu_stuff.dart';
import 'package:doom_core/src/hud/st_stuff.dart';
import 'package:doom_core/src/intermission/wi_stuff.dart';
import 'package:doom_core/src/menu/m_menu.dart';
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/video/f_wipe.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/palette_converter.dart';
import 'package:doom_core/src/video/v_video.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

typedef VoidCallback = void Function();

abstract final class _PlayerStartType {
  static const int player1 = 1;
}

abstract final class _DemoConstants {
  static const int titleTics = 170;
  static const int pageTics = 200;
}

class DoomGame {
  late WadManager _wadManager;
  late TextureManager _textureManager;
  RenderState? _renderState;
  Renderer? _renderer;
  LevelLocals? _level;
  late GameTicker _ticker;
  late MenuSystem _menuSystem;
  late Intermission _intermission;
  final InputHandler input = InputHandler();

  final StatusBar _statusBar = StatusBar();
  final HudMessages _hudMessages = HudMessages();
  final PaletteConverter _paletteConverter = PaletteConverter();
  final ScreenBuffers _screenBuffers = ScreenBuffers();

  final int _consoleplayer = 0;
  bool _hudNeedsRefresh = true;

  GameMode _gameMode = GameMode.indetermined;

  GameState _gameState = GameState.demoScreen;
  GameAction _gameAction = GameAction.nothing;

  Skill _skill = Skill.hurtMePlenty;
  int _deferredEpisode = 1;
  int _deferredMap = 1;
  int _episode = 1;
  int _map = 1;
  bool _secretExit = false;
  int _nextMap = 1;

  // Game mode flags (from demo header or command line in original C)
  bool _noMonsters = false;
  bool _fastMonsters = false;
  bool _respawnMonsters = false;
  bool _deathmatch = false;

  int _demoSequence = -1;
  int _pageTic = 0;
  String _pageName = '';
  bool _advanceDemo = false;
  final Map<String, Patch> _pageCache = {};

  final ScreenWipe _wipe = ScreenWipe();
  GameState _wipeGameState = GameState.demoScreen;
  bool _forceWipe = false;
  final DoomRandom _menuRandom = DoomRandom();

  VoidCallback? onQuit;
  bool _shouldQuit = false;

  // Demo recording and playback
  DemoRecorder? _demoRecorder;
  DemoPlayer? _demoPlayer;
  bool _demoRecording = false;
  bool _demoPlayback = false;
  Uint8List? _pendingDemoData;

  /// Callback when demo recording finishes. Returns the recorded demo data.
  void Function(Uint8List demoData)? onDemoRecorded;

  bool get shouldQuit => _shouldQuit;
  RenderState? get renderState => _renderState;
  Renderer? get renderer => _renderer;
  LevelLocals? get level => _level;
  int get consoleplayer => _consoleplayer;
  PaletteConverter get paletteConverter => _paletteConverter;
  GameState get gameState => _gameState;
  MenuSystem get menuSystem => _menuSystem;
  Skill get skill => _skill;

  /// Whether a demo is currently being recorded.
  bool get isDemoRecording => _demoRecording;

  /// Whether a demo is currently being played back.
  bool get isDemoPlayback => _demoPlayback;

  Player? get player => _level?.players[_consoleplayer];

  void init(Uint8List wadBytes) {
    _wadManager = WadManager()..addWad(wadBytes);
    _textureManager = TextureManager(_wadManager)..init();
    _ticker = GameTicker();

    _gameMode = _identifyVersion();

    _menuSystem = MenuSystem(_wadManager, _screenBuffers, _gameMode)
      ..init()
      ..onNewGame = _deferedInitNew
      ..onQuitGame = _quitToTitle;

    _intermission = Intermission(_wadManager, _menuRandom)
      ..onWorldDone = _worldDone;

    _statusBar.loadGraphics(_wadManager);
    _hudMessages.loadFont(_wadManager);

    final playPalData = _wadManager.cacheLumpName('PLAYPAL');
    final playPal = PlayPal.parse(playPalData);
    _paletteConverter.loadPalettes(playPal);

    _startTitle();
  }

  GameMode _identifyVersion() {
    if (_wadManager.checkNumForName('MAP01') >= 0) {
      return GameMode.commercial;
    }

    if (_wadManager.checkNumForName('E4M1') >= 0) {
      return GameMode.retail;
    }

    if (_wadManager.checkNumForName('E3M1') >= 0) {
      return GameMode.registered;
    }

    if (_wadManager.checkNumForName('E1M1') >= 0) {
      return GameMode.shareware;
    }

    return GameMode.indetermined;
  }

  void _startTitle() {
    _gameState = GameState.demoScreen;
    _demoSequence = -1;
    _advanceDemo = false;
    _doAdvanceDemo();
  }

  void _advanceDemoFlag() {
    _advanceDemo = true;
  }

  /// Advance demo sequence.
  ///
  /// Original C (d_main.c):
  /// ```c
  /// void D_DoAdvanceDemo (void)
  /// {
  ///     players[consoleplayer].playerstate = PST_LIVE;
  ///     advancedemo = false;
  ///     usergame = false;
  ///     paused = false;
  ///     gameaction = ga_nothing;
  ///
  ///     if ( gamemode == retail )
  ///       demosequence = (demosequence+1)%7;
  ///     else
  ///       demosequence = (demosequence+1)%6;
  ///
  ///     switch (demosequence)
  ///     {
  ///       case 0:
  ///         pagetic = 170;
  ///         gamestate = GS_DEMOSCREEN;
  ///         pagename = "TITLEPIC";
  ///         break;
  ///       case 1:
  ///         G_DeferedPlayDemo ("demo1");
  ///         break;
  ///       case 2:
  ///         pagetic = 200;
  ///         gamestate = GS_DEMOSCREEN;
  ///         pagename = "CREDIT";
  ///         break;
  ///       case 3:
  ///         G_DeferedPlayDemo ("demo2");
  ///         break;
  ///       case 4:
  ///         gamestate = GS_DEMOSCREEN;
  ///         pagetic = 200;
  ///         if ( gamemode == retail )
  ///           pagename = "CREDIT";
  ///         else
  ///           pagename = "HELP2";
  ///         break;
  ///       case 5:
  ///         G_DeferedPlayDemo ("demo3");
  ///         break;
  ///       case 6:
  ///         G_DeferedPlayDemo ("demo4");
  ///         break;
  ///     }
  /// }
  /// ```
  void _doAdvanceDemo() {
    // Retail has 7 sequences (includes demo4), others have 6
    final maxSequence = _gameMode == GameMode.retail ? 7 : 6;
    _demoSequence = (_demoSequence + 1) % maxSequence;

    switch (_demoSequence) {
      case 0:
        // Title screen
        _pageTic = _gameMode == GameMode.commercial
            ? 35 * 11 // 11 seconds for commercial
            : _DemoConstants.titleTics; // 170 tics (~5 sec)
        _pageName = 'TITLEPIC';
        _gameState = GameState.demoScreen;
        // TODO: S_StartMusic for title music
      case 1:
        // Play demo1
        playDemoFromWad('DEMO1');
      case 2:
        // Credits screen
        _pageTic = _DemoConstants.pageTics; // 200 tics
        _pageName = 'CREDIT';
        _gameState = GameState.demoScreen;
      case 3:
        // Play demo2
        playDemoFromWad('DEMO2');
      case 4:
        // Title or credits/help depending on game mode
        _gameState = GameState.demoScreen;
        if (_gameMode == GameMode.commercial) {
          _pageTic = 35 * 11;
          _pageName = 'TITLEPIC';
          // TODO: S_StartMusic for title music
        } else {
          _pageTic = _DemoConstants.pageTics;
          _pageName = _gameMode == GameMode.retail ? 'CREDIT' : 'HELP2';
        }
      case 5:
        // Play demo3
        playDemoFromWad('DEMO3');
      case 6:
        // Play demo4 (retail only - The Definitive DOOM Special Edition)
        playDemoFromWad('DEMO4');
    }
  }

  void _pageTicker() {
    if (_advanceDemo) {
      _doAdvanceDemo();
      _advanceDemo = false;
    }

    if (--_pageTic < 0) {
      _advanceDemoFlag();
    }
  }

  void _drawPage() {
    if (_pageName.isEmpty) return;

    var patch = _pageCache[_pageName];
    if (patch == null) {
      final lumpNum = _wadManager.checkNumForName(_pageName);
      if (lumpNum >= 0) {
        final data = _wadManager.cacheLumpNum(lumpNum);
        patch = Patch.parse(data);
        _pageCache[_pageName] = patch;
      }
    }

    if (patch != null) {
      VVideo.drawPatchDirect(_screenBuffers.primary, 0, 0, patch);
    }
  }

  void _deferedInitNew(Skill skill, int episode, int map) {
    _skill = skill;
    _deferredEpisode = episode;
    _deferredMap = map;
    _gameAction = GameAction.newGame;
  }

  void _quitToTitle() {
    if (_gameState == GameState.demoScreen) {
      _shouldQuit = true;
      return;
    }

    _forceWipe = true;
    _level = null;
    _renderer = null;
    _renderState = null;
    _startTitle();
  }

  void _processGameAction() {
    switch (_gameAction) {
      case GameAction.newGame:
        _doNewGame();
        _gameAction = GameAction.nothing;
      case GameAction.completed:
        _doCompleted();
      case GameAction.worldDone:
        _doWorldDone();
        _gameAction = GameAction.nothing;
      case GameAction.playDemo:
        _doPlayDemo();
        _gameAction = GameAction.nothing;
      case GameAction.recordDemo:
        _doRecordDemo();
        _gameAction = GameAction.nothing;
      case GameAction.nothing:
      case GameAction.loadLevel:
      case GameAction.loadGame:
      case GameAction.saveGame:
      case GameAction.victory:
      case GameAction.screenshot:
        break;
    }
  }

  void _doNewGame() {
    // Stop any demo playback when starting a new game
    if (_demoPlayback) {
      _demoPlayback = false;
      _demoPlayer = null;
    }

    _forceWipe = true;
    _episode = _deferredEpisode;
    _map = _deferredMap;
    final mapName = _buildMapName(_episode, _map);
    loadLevel(mapName);
    _gameState = GameState.level;
  }

  String _buildMapName(int episode, int map) {
    if (_gameMode == GameMode.commercial) {
      return 'MAP${map.toString().padLeft(2, '0')}';
    }
    return 'E${episode}M$map';
  }

  void _doCompleted() {
    final level = _level;
    if (level == null) return;

    _secretExit = level.secretExit;

    if (_gameMode == GameMode.commercial) {
      _doCompletedCommercial();
    } else {
      _doCompletedEpisodic();
    }

    _intermission.start(
      episode: _episode,
      lastMap: _map,
      nextMap: _nextMap,
      kills: level.players[_consoleplayer].killCount,
      maxKills: level.totalKills,
      items: level.players[_consoleplayer].itemCount,
      maxItems: level.totalItems,
      secrets: level.players[_consoleplayer].secretCount,
      maxSecrets: level.totalSecrets,
      levelTime: level.levelTime,
      commercial: _gameMode == GameMode.commercial,
    );
    _gameState = GameState.intermission;
    _gameAction = GameAction.nothing;
  }

  void _doCompletedCommercial() {
    if (_map == 30) {
      _gameAction = GameAction.victory;
      return;
    }

    if (_secretExit) {
      _nextMap = _map == 15 ? 31 : 32;
    } else if (_map == 31) {
      _nextMap = 16;
    } else if (_map == 32) {
      _nextMap = 16;
    } else {
      _nextMap = _map + 1;
    }
  }

  void _doCompletedEpisodic() {
    if (_map == 8) {
      _gameAction = GameAction.victory;
      return;
    }

    if (_secretExit) {
      _nextMap = 9;
    } else if (_map == 9) {
      _nextMap = switch (_episode) {
        1 => 4,
        2 => 6,
        3 => 7,
        4 => 3,
        _ => _map + 1,
      };
    } else {
      _nextMap = _map + 1;
    }
  }

  void _worldDone() {
    _gameAction = GameAction.worldDone;
  }

  void _doWorldDone() {
    _forceWipe = true;
    _map = _nextMap;
    final mapName = _buildMapName(_episode, _map);
    loadLevel(mapName);
    _gameState = GameState.level;
  }

  void loadLevel(String mapName) {
    final mapLoader = MapLoader(_wadManager);
    final mapData = mapLoader.loadMap(mapName);

    final levelLoader = LevelLoader(_textureManager);
    final renderState = levelLoader.loadLevel(mapData);
    _renderState = renderState;

    RenderData(_wadManager).initData(renderState);

    final renderer = Renderer(renderState)..init();
    _renderer = renderer;

    final level = LevelLocals(renderState)
      ..init()
      ..skill = _skill
      ..noMonsters = _noMonsters
      ..fastMonsters = _fastMonsters
      ..respawnMonsters = _respawnMonsters
      ..deathmatch = _deathmatch;
    _level = level;

    if (mapData.blockmap != null) {
      level
        ..blockmap = Blockmap.parse(mapData.blockmap!)
        ..initBlockLinks();
      _computeSectorBlockBoxes(renderState.sectors, level.blockmap!);
    }

    level
      ..rejectMatrix = mapData.reject
      ..numSectors = renderState.sectors.length;

    ThingSpawner(renderState, level).spawnMapThings(mapData);

    _spawnPlayer(mapData);

    spec.spawnSpecials(level);
    spec.initPicAnims(level);

    final p = player;
    if (p != null) {
      _statusBar.init(p, _screenBuffers.screens);
      _hudMessages.init(p, _screenBuffers.primary, levelName: mapName);
    }
    _hudNeedsRefresh = true;
  }

  void _spawnPlayer(MapData mapData) {
    final level = _level;
    if (level == null) return;

    for (final thing in mapData.things) {
      if (thing.type == _PlayerStartType.player1 + _consoleplayer) {
        final x = thing.x << Fixed32.fracBits;
        final y = thing.y << Fixed32.fracBits;

        final mobj = Mobj()
          ..x = x
          ..y = y
          ..radius = PlayerConstants.playerRadius
          ..height = PlayerConstants.playerHeight
          ..flags = MobjFlag.solid | MobjFlag.shootable | MobjFlag.dropOff | MobjFlag.pickup | MobjFlag.slide
          ..angle = thing.angle * Angle.ang90 ~/ 90;

        _setPlayerMobjPosition(mobj);

        final ss = mobj.subsector;
        if (ss is! Subsector) continue;

        mobj
          ..floorZ = ss.sector.floorHeight
          ..ceilingZ = ss.sector.ceilingHeight
          ..z = ss.sector.floorHeight;

        final p = level.players[_consoleplayer]
          ..mobj = mobj
          ..playerState = PlayerState.live
          ..health = PlayerConstants.maxHealth
          ..viewHeight = PlayerConstants.viewHeight
          ..viewZ = mobj.z + PlayerConstants.viewHeight;
        mobj
          ..player = p
          ..spawnX = x
          ..spawnY = y
          ..spawnAngle = mobj.angle
          ..health = PlayerConstants.maxHealth;

        p
          ..weaponOwned[WeaponType.fist.index] = true
          ..weaponOwned[WeaponType.pistol.index] = true
          ..readyWeapon = WeaponType.pistol
          ..ammo[AmmoType.clip.index] = 50;

        setupPsprites(p);

        return;
      }
    }
  }

  void _setPlayerMobjPosition(Mobj mobj) {
    final renderState = _renderState;
    if (renderState == null) return;

    final nodes = renderState.nodes;
    final subsectors = renderState.subsectors;

    if (nodes.isEmpty) {
      if (subsectors.isNotEmpty) {
        mobj.subsector = subsectors[0];
        _linkToSector(mobj, subsectors[0].sector);
      }
      return;
    }

    var nodeNum = nodes.length - 1;

    while (!BspConstants.isSubsector(nodeNum)) {
      final node = nodes[nodeNum];
      final side = _pointOnSide(mobj.x, mobj.y, node);
      nodeNum = node.children[side];
    }

    final ss = subsectors[BspConstants.getIndex(nodeNum)];
    mobj.subsector = ss;
    _linkToSector(mobj, ss.sector);
    _linkToBlockmap(mobj);
  }

  void _linkToSector(Mobj mobj, Sector sector) {
    if ((mobj.flags & MobjFlag.noSector) != 0) return;

    mobj
      ..sPrev = null
      ..sNext = sector.thingList;

    if (sector.thingList != null) {
      sector.thingList!.sPrev = mobj;
    }

    sector.thingList = mobj;
  }

  void _linkToBlockmap(Mobj mobj) {
    if ((mobj.flags & MobjFlag.noBlockmap) != 0) return;

    final level = _level;
    if (level == null) return;

    final blockmap = level.blockmap;
    final blockLinks = level.blockLinks;
    if (blockmap == null || blockLinks == null) return;

    final (blockX, blockY) = blockmap.worldToBlock(mobj.x, mobj.y);
    if (blockmap.isValidBlock(blockX, blockY)) {
      final index = blockY * blockmap.columns + blockX;
      mobj
        ..bPrev = null
        ..bNext = blockLinks[index];
      if (blockLinks[index] != null) {
        blockLinks[index]!.bPrev = mobj;
      }
      blockLinks[index] = mobj;
    } else {
      mobj
        ..bNext = null
        ..bPrev = null;
    }
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

    return right < left ? 0 : 1;
  }

  void runTic() {
    // Don't run game tics during screen wipe - matches original C behavior
    // Original DOOM has a blocking loop during wipe where no G_Ticker runs
    if (_wipe.isActive) {
      return;
    }

    _processGameAction();

    _menuSystem.ticker();

    switch (_gameState) {
      case GameState.level:
        if (!_menuSystem.isActive) {
          final p = player;
          final l = _level;
          if (p != null && l != null) {
            final cmd = p.cmd;

            // Demo playback: read commands from demo
            if (_demoPlayback && _demoPlayer != null) {
              _demoPlayer!.readTic(cmd);
              if (_demoPlayer!.isFinished) {
                _stopDemoPlayback();
                return;
              }
            } else {
              // Normal gameplay: build commands from input
              input.buildTicCmd(cmd);
            }

            // Demo recording: write commands to demo
            if (_demoRecording && _demoRecorder != null) {
              _demoRecorder!.recordTic(cmd);
            }

            _ticker.tick(l);

            if (l.exitLevel || l.secretExit) {
              // If recording, stop the demo when level exits
              if (_demoRecording) {
                _stopDemoRecording();
              }
              _gameAction = GameAction.completed;
            }

            _statusBar.ticker();
            _hudMessages.ticker();
          }
        }
      case GameState.demoScreen:
        if (!_menuSystem.isActive) {
          _pageTicker();
        }
      case GameState.intermission:
        _intermission.ticker();
      case GameState.finale:
        break;
    }
  }

  void handleEvent(DoomEvent event) {
    if (_menuSystem.responder(event)) {
      return;
    }

    if (_gameState == GameState.intermission && event.type == DoomEventType.keyDown) {
      _intermission.accelerate();
      return;
    }

    if (event.type == DoomEventType.keyDown) {
      input.keyDown(event.data1);
    } else if (event.type == DoomEventType.keyUp) {
      input.keyUp(event.data1);
    }
  }

  void render(Uint8List frameBuffer) {
    final wipe = _gameState != _wipeGameState || _forceWipe;

    if (wipe && !_wipe.isActive) {
      _wipe.captureStartScreen(_screenBuffers.primary);
    }

    if (_gameState == GameState.level) {
      _renderLevel();
    } else if (_gameState == GameState.intermission) {
      _intermission.drawer(_screenBuffers.primary);
    } else {
      _drawPage();
    }

    _menuSystem.drawer();

    if (wipe && !_wipe.isActive) {
      _wipe
        ..captureEndScreen(_screenBuffers.primary)
        ..startWipe();
      _wipeGameState = _gameState;
      _forceWipe = false;
    }

    if (_wipe.isActive) {
      _wipe.doWipe(_screenBuffers.primary, 1);
    }

    final p = player;
    if (p != null) {
      _paletteConverter.updatePaletteForPlayer(p);
    }

    for (var i = 0; i < ScreenConstants.pixelCount; i++) {
      frameBuffer[i] = _screenBuffers.primary[i];
    }
  }

  void renderWithPalette(Uint8List rgbaBuffer) {
    final indexedBuffer = _screenBuffers.primary;
    final wipe = _gameState != _wipeGameState || _forceWipe;

    if (wipe && !_wipe.isActive) {
      _wipe.captureStartScreen(indexedBuffer);
    }

    if (_gameState == GameState.level) {
      _renderLevel();
    } else if (_gameState == GameState.intermission) {
      _intermission.drawer(indexedBuffer);
    } else {
      _drawPage();
    }

    _menuSystem.drawer();

    if (wipe && !_wipe.isActive) {
      _wipe
        ..captureEndScreen(indexedBuffer)
        ..startWipe();
      _wipeGameState = _gameState;
      _forceWipe = false;
    }

    if (_wipe.isActive) {
      _wipe.doWipe(indexedBuffer, 1);
    }

    final p = player;
    if (p != null) {
      _paletteConverter.updatePaletteForPlayer(p);
    }

    _paletteConverter.convertFrame(indexedBuffer, rgbaBuffer);
  }

  void _renderLevel() {
    final p = player;
    final r = _renderer;
    if (p == null || r == null) return;

    final mobj = p.mobj;
    if (mobj == null) return;

    r
      ..setupFrame(
        mobj.x,
        mobj.y,
        p.viewZ,
        mobj.angle,
      )
      ..renderPlayerView(_screenBuffers.primary, player: p);

    _statusBar.drawer(refresh: _hudNeedsRefresh);
    _hudMessages.drawer();
    _hudNeedsRefresh = false;
  }

  void keyDown(int keyCode) {
    input.keyDown(keyCode);
  }

  void keyUp(int keyCode) {
    input.keyUp(keyCode);
  }

  void _computeSectorBlockBoxes(List<Sector> sectors, Blockmap blockmap) {
    final originX = blockmap.originX << Fixed32.fracBits;
    final originY = blockmap.originY << Fixed32.fracBits;

    for (final sector in sectors) {
      if (sector.lines.isEmpty) continue;

      var minX = 0x7FFFFFFF;
      var maxX = -0x7FFFFFFF;
      var minY = 0x7FFFFFFF;
      var maxY = -0x7FFFFFFF;

      for (final line in sector.lines) {
        final v1 = line.v1;
        final v2 = line.v2;

        if (v1.x < minX) minX = v1.x;
        if (v1.x > maxX) maxX = v1.x;
        if (v1.y < minY) minY = v1.y;
        if (v1.y > maxY) maxY = v1.y;

        if (v2.x < minX) minX = v2.x;
        if (v2.x > maxX) maxX = v2.x;
        if (v2.y < minY) minY = v2.y;
        if (v2.y > maxY) maxY = v2.y;
      }

      var block = (maxY - originY + _BlockBoxConstants.maxRadius) >>
          (Fixed32.fracBits + BlockmapConstants.blockShift);
      if (block >= blockmap.rows) block = blockmap.rows - 1;
      sector.blockBox0 = block;

      block = (minY - originY - _BlockBoxConstants.maxRadius) >>
          (Fixed32.fracBits + BlockmapConstants.blockShift);
      if (block < 0) block = 0;
      sector.blockBox1 = block;

      block = (maxX - originX + _BlockBoxConstants.maxRadius) >>
          (Fixed32.fracBits + BlockmapConstants.blockShift);
      if (block >= blockmap.columns) block = blockmap.columns - 1;
      sector.blockBox3 = block;

      block = (minX - originX - _BlockBoxConstants.maxRadius) >>
          (Fixed32.fracBits + BlockmapConstants.blockShift);
      if (block < 0) block = 0;
      sector.blockBox2 = block;
    }
  }

  // ============================================================
  // Demo Recording and Playback
  // ============================================================

  /// Start recording a demo. The game will start a new level and record
  /// all player inputs.
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
  void startDemoRecording({
    required Skill skill,
    required int episode,
    required int map,
  }) {
    _skill = skill;
    _deferredEpisode = episode;
    _deferredMap = map;
    _gameAction = GameAction.recordDemo;
  }

  void _doRecordDemo() {
    _demoRecorder = DemoRecorder()
      ..startRecording(
        skill: _skill,
        episode: _deferredEpisode,
        map: _deferredMap,
        consolePlayer: _consoleplayer,
        playersInGame: [true, false, false, false],
      );
    _demoRecording = true;

    // Start the game
    _doNewGame();
  }

  void _stopDemoRecording() {
    if (!_demoRecording || _demoRecorder == null) return;

    final demoData = _demoRecorder!.stopRecording();
    _demoRecording = false;
    _demoRecorder = null;

    // Notify callback if set
    onDemoRecorded?.call(demoData);
  }

  /// Stop demo recording manually and return the recorded data.
  Uint8List? stopDemoRecording() {
    if (!_demoRecording || _demoRecorder == null) return null;

    final demoData = _demoRecorder!.stopRecording();
    _demoRecording = false;
    _demoRecorder = null;

    return demoData;
  }

  /// Start playing a demo from the provided data.
  ///
  /// Original C (g_game.c):
  /// ```c
  /// void G_DeferedPlayDemo (char* name)
  /// {
  ///     defdemoname = name;
  ///     gameaction = ga_playdemo;
  /// }
  /// ```
  void playDemo(Uint8List demoData) {
    _pendingDemoData = demoData;
    _gameAction = GameAction.playDemo;
  }

  void _doPlayDemo() {
    final data = _pendingDemoData;
    if (data == null) return;

    _pendingDemoData = null;

    // Validate demo data length
    if (data.length < 13) {
      return;
    }

    _demoPlayer = DemoPlayer(data);

    final header = _demoPlayer!.header;

    // Check version compatibility
    if (!header.isCompatible) {
      _demoPlayer = null;
      return;
    }

    // Set up game from demo header (matching C's G_DoPlayDemo)
    _skill = header.skill;
    _episode = header.episode;
    _map = header.map;

    // Apply game mode flags from demo header
    _deathmatch = header.deathmatch;
    _respawnMonsters = header.respawn;
    _fastMonsters = header.fast;
    _noMonsters = header.noMonsters;

    // Load the level
    _forceWipe = true;
    final mapName = _buildMapName(_episode, _map);
    loadLevel(mapName);
    _gameState = GameState.level;

    _demoPlayback = true;
  }

  void _stopDemoPlayback() {
    _demoPlayback = false;
    _demoPlayer = null;

    // Reset palette to normal (removes pain/bonus tint)
    _paletteConverter.setPaletteIndex(0);

    // Advance to next item in demo sequence (not restart)
    // This matches original DOOM behavior where demo end advances the sequence
    _advanceDemoFlag();
    _gameState = GameState.demoScreen;
  }

  /// Stop demo playback manually.
  void stopDemoPlayback() {
    if (_demoPlayback) {
      _stopDemoPlayback();
    }
  }

  /// Play a demo from the WAD file by lump name.
  ///
  /// If the demo lump is not found, advances to the next demo sequence item.
  void playDemoFromWad(String lumpName) {
    final lumpNum = _wadManager.checkNumForName(lumpName);
    if (lumpNum < 0) {
      // Demo not found in WAD - advance to next sequence item
      _advanceDemoFlag();
      return;
    }

    final demoData = _wadManager.cacheLumpNum(lumpNum);
    playDemo(demoData);
  }
}

abstract final class _BlockBoxConstants {
  static const int maxRadius = 32 << Fixed32.fracBits;
}
