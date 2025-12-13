import 'dart:typed_data';

import 'package:doom_core/src/doomdef.dart';
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
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_core/src/video/frame_buffer.dart';
import 'package:doom_core/src/video/palette_converter.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';

abstract final class _PlayerStartType {
  static const int player1 = 1;
}

class DoomGame {
  late WadManager _wadManager;
  late TextureManager _textureManager;
  late RenderState _renderState;
  late Renderer _renderer;
  late LevelLocals _level;
  late GameTicker _ticker;
  final InputHandler input = InputHandler();

  final StatusBar _statusBar = StatusBar();
  final HudMessages _hudMessages = HudMessages();
  final PaletteConverter _paletteConverter = PaletteConverter();
  final ScreenBuffers _screenBuffers = ScreenBuffers();

  final int _consoleplayer = 0;
  bool _hudNeedsRefresh = true;

  RenderState get renderState => _renderState;
  Renderer get renderer => _renderer;
  LevelLocals get level => _level;
  int get consoleplayer => _consoleplayer;
  PaletteConverter get paletteConverter => _paletteConverter;

  Player get player => _level.players[_consoleplayer];

  void init(Uint8List wadBytes) {
    _wadManager = WadManager()..addWad(wadBytes);
    _textureManager = TextureManager(_wadManager)..init();
    _ticker = GameTicker();

    _statusBar.loadGraphics(_wadManager);
    _hudMessages.loadFont(_wadManager);

    final playPalData = _wadManager.cacheLumpName('PLAYPAL');
    final playPal = PlayPal.parse(playPalData);
    _paletteConverter.loadPalettes(playPal);
  }

  void loadLevel(String mapName) {
    final mapLoader = MapLoader(_wadManager);
    final mapData = mapLoader.loadMap(mapName);

    final levelLoader = LevelLoader(_textureManager);
    _renderState = levelLoader.loadLevel(mapData);

    RenderData(_wadManager).initData(_renderState);

    _renderer = Renderer(_renderState)..init();

    _level = LevelLocals(_renderState)..init();

    if (mapData.blockmap != null) {
      _level.blockmap = Blockmap.parse(mapData.blockmap!);
      _level.initBlockLinks();
    }

    ThingSpawner(_renderState, _level).spawnMapThings(mapData);

    _spawnPlayer(mapData);

    spec.spawnSpecials(_level);
    spec.initPicAnims(_level);

    _statusBar.init(player, _screenBuffers.screens);
    _hudMessages.init(player, _screenBuffers.primary, levelName: mapName);
    _hudNeedsRefresh = true;
  }

  void _spawnPlayer(MapData mapData) {
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

        final player = _level.players[_consoleplayer]
          ..mobj = mobj
          ..playerState = PlayerState.live
          ..health = PlayerConstants.maxHealth
          ..viewHeight = PlayerConstants.viewHeight
          ..viewZ = mobj.z + PlayerConstants.viewHeight;
        mobj
          ..player = player
          ..spawnX = x
          ..spawnY = y
          ..spawnAngle = mobj.angle
          ..health = PlayerConstants.maxHealth;

        player
          ..weaponOwned[WeaponType.fist.index] = true
          ..weaponOwned[WeaponType.pistol.index] = true
          ..readyWeapon = WeaponType.pistol
          ..ammo[AmmoType.clip.index] = 50;

        setupPsprites(player);

        return;
      }
    }
  }

  void _setPlayerMobjPosition(Mobj mobj) {
    final nodes = _renderState.nodes;
    final subsectors = _renderState.subsectors;

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

    final blockmap = _level.blockmap;
    final blockLinks = _level.blockLinks;
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
    final cmd = player.cmd;
    input.buildTicCmd(cmd);
    _ticker.tick(_level);

    _statusBar.ticker();
    _hudMessages.ticker();
  }

  void render(Uint8List frameBuffer) {
    final mobj = player.mobj;
    if (mobj == null) return;

    _renderer
      ..setupFrame(
        mobj.x,
        mobj.y,
        player.viewZ,
        mobj.angle,
      )
      ..renderPlayerView(_screenBuffers.primary);

    _statusBar.drawer(refresh: _hudNeedsRefresh);
    _hudMessages.drawer();
    _hudNeedsRefresh = false;

    _paletteConverter.updatePaletteForPlayer(player);

    for (var i = 0; i < ScreenConstants.pixelCount; i++) {
      frameBuffer[i] = _screenBuffers.primary[i];
    }
  }

  void renderWithPalette(Uint8List rgbaBuffer) {
    final indexedBuffer = _screenBuffers.primary;
    final mobj = player.mobj;
    if (mobj == null) return;

    _renderer
      ..setupFrame(
        mobj.x,
        mobj.y,
        player.viewZ,
        mobj.angle,
      )
      ..renderPlayerView(indexedBuffer);

    _statusBar.drawer(refresh: _hudNeedsRefresh);
    _hudMessages.drawer();
    _hudNeedsRefresh = false;

    _paletteConverter
      ..updatePaletteForPlayer(player)
      ..convertFrame(indexedBuffer, rgbaBuffer);
  }

  void keyDown(int keyCode) {
    input.keyDown(keyCode);
  }

  void keyUp(int keyCode) {
    input.keyUp(keyCode);
  }
}
