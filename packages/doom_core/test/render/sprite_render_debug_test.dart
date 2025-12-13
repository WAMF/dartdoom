import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:doom_core/src/game/blockmap.dart';
import 'package:doom_core/src/game/level_locals.dart';
import 'package:doom_core/src/game/mobj.dart';
import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

class _SpriteRendererAccess {
  _SpriteRendererAccess(this._state);

  final RenderState _state;
  final List<_DebugVissprite> vissprites = [];

  void renderForDebug(List<Sector> sectors) {
    vissprites.clear();

    for (final sector in sectors) {
      var thing = sector.thingList;
      while (thing != null) {
        _projectSpriteDebug(thing);
        thing = thing.sNext;
      }
    }
  }

  void _projectSpriteDebug(Mobj thing) {
    final trX = thing.x - _state.viewX;
    final trY = thing.y - _state.viewY;

    final gxt = Fixed32.mul(trX, _state.viewCos);
    final gyt = -Fixed32.mul(trY, _state.viewSin);

    final tz = gxt - gyt;

    const minZ = Fixed32.fracUnit * 4;
    if (tz < minZ) return;

    final xScale = Fixed32.div(_state.projection, tz);

    final gxtNeg = -Fixed32.mul(trX, _state.viewSin);
    final gytPos = Fixed32.mul(trY, _state.viewCos);
    var tx = -(gytPos + gxtNeg);

    if (tx.abs() > tz << 2) return;

    final spriteNum = thing.sprite;
    final frameNum = thing.frame & 0x7FFF;

    if (spriteNum >= _state.sprites.length) return;
    final sprdef = _state.sprites[spriteNum];
    if (frameNum >= sprdef.numFrames) return;
    final sprframe = sprdef.spriteFrames[frameNum];

    final lump = sprframe.lump[0];

    if (lump >= _state.spriteWidth.length) return;

    tx -= _state.spriteOffset[lump];
    final x1 = (_state.centerXFrac + Fixed32.mul(tx, xScale)) >> Fixed32.fracBits;

    if (x1 > _state.viewWidth) return;

    tx += _state.spriteWidth[lump];
    final x2 = ((_state.centerXFrac + Fixed32.mul(tx, xScale)) >> Fixed32.fracBits) - 1;

    if (x2 < 0) return;

    vissprites.add(_DebugVissprite(
      x1: x1 < 0 ? 0 : x1,
      x2: x2 >= _state.viewWidth ? _state.viewWidth - 1 : x2,
      scale: xScale,
      patch: lump,
      type: thing.type,
    ),);
  }
}

class _DebugVissprite {
  _DebugVissprite({
    required this.x1,
    required this.x2,
    required this.scale,
    required this.patch,
    required this.type,
  });

  final int x1;
  final int x2;
  final int scale;
  final int patch;
  final int type;
}

void main() {
  group('Sprite Render Debug', () {
    late Uint8List wadBytes;
    late WadManager wadManager;
    late TextureManager textureManager;
    late MapLoader mapLoader;
    late MapData mapData;

    setUpAll(() {
      final wadFile = File('../../assets/DOOM1.WAD');
      wadBytes = wadFile.readAsBytesSync();
    });

    setUp(() {
      wadManager = WadManager()..addWad(wadBytes);
      textureManager = TextureManager(wadManager)..init();
      mapLoader = MapLoader(wadManager);
      mapData = mapLoader.loadMap('E1M1');
    });

    test('check sprite visibility', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final level = LevelLocals(state)..init();
      if (mapData.blockmap != null) {
        level.blockmap = Blockmap.parse(mapData.blockmap!);
        level.initBlockLinks();
      }

      final thingSpawner = ThingSpawner(state, level)..spawnMapThings(mapData);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);

      stderr.writeln('=== Sprite Render Debug ===');
      stderr.writeln('Player start: (${player1Start.x}, ${player1Start.y})');
      stderr.writeln('Spawned mobjs: ${thingSpawner.mobjs.length}');
      stderr.writeln();

      stderr.writeln('Checking nearby mobjs:');
      for (final mobj in thingSpawner.mobjs) {
        final dx = (mobj.x >> 16) - player1Start.x;
        final dy = (mobj.y >> 16) - player1Start.y;
        final dist = dx * dx + dy * dy;
        if (dist < 500 * 500) {
          stderr.writeln('  type=${mobj.type}, sprite=${mobj.sprite}, pos=(${mobj.x >> 16}, ${mobj.y >> 16}), dist=${math.sqrt(dist.toDouble()).toInt()}');
        }
      }
      stderr.writeln();

      stderr.writeln('Sprite definitions check:');
      for (var i = 0; i < 5 && i < state.sprites.length; i++) {
        final sprdef = state.sprites[i];
        stderr.writeln('  sprite[$i]: numFrames=${sprdef.numFrames}');
        if (sprdef.numFrames > 0) {
          stderr.writeln('    frame[0]: rotate=${sprdef.spriteFrames[0].rotate}, lump[0]=${sprdef.spriteFrames[0].lump[0]}');
        }
      }
      stderr.writeln();

      stderr.writeln('Sprite width/offset arrays:');
      stderr.writeln('  spriteWidth.length: ${state.spriteWidth.length}');
      stderr.writeln('  spriteOffset.length: ${state.spriteOffset.length}');
      stderr.writeln('  spriteTopOffset.length: ${state.spriteTopOffset.length}');
      if (state.spriteWidth.isNotEmpty) {
        stderr.writeln('  spriteWidth[0]: ${state.spriteWidth[0]} (${state.spriteWidth[0] >> 16} pixels)');
        stderr.writeln('  spriteOffset[0]: ${state.spriteOffset[0]} (${state.spriteOffset[0] >> 16} pixels)');
        stderr.writeln('  spriteTopOffset[0]: ${state.spriteTopOffset[0]} (${state.spriteTopOffset[0] >> 16} pixels)');
      }
      stderr.writeln();

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        41.toFixed(),
        Angle.ang90,
      );

      stderr.writeln('View setup:');
      stderr.writeln('  viewX: ${state.viewX >> 16}');
      stderr.writeln('  viewY: ${state.viewY >> 16}');
      stderr.writeln('  viewZ: ${state.viewZ >> 16}');
      stderr.writeln('  viewAngle: ${state.viewAngle}');
      stderr.writeln('  viewCos: ${state.viewCos}');
      stderr.writeln('  viewSin: ${state.viewSin}');
      stderr.writeln('  projection: ${state.projection >> 16}');
      stderr.writeln();

      final frameBuffer = Uint8List(
        ScreenDimensions.width * ScreenDimensions.height,
      );
      renderer.renderPlayerView(frameBuffer);

      stderr.writeln('Render complete');

      expect(thingSpawner.mobjs.length, greaterThan(0));
    });

    test('find visible sprites', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final level = LevelLocals(state)..init();
      if (mapData.blockmap != null) {
        level.blockmap = Blockmap.parse(mapData.blockmap!);
        level.initBlockLinks();
      }

      final thingSpawner = ThingSpawner(state, level)..spawnMapThings(mapData);

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);
      final px = player1Start.x;
      final py = player1Start.y;

      stderr.writeln('=== Find Visible Sprites ===');
      stderr.writeln('Player at ($px, $py) facing north (ANG90)');
      stderr.writeln();

      stderr.writeln('Sprites in FOV (dy > 0 and |dx| < dy):');
      var count = 0;
      for (final mobj in thingSpawner.mobjs) {
        final mx = mobj.x >> 16;
        final my = mobj.y >> 16;
        final dx = mx - px;
        final dy = my - py;

        if (dy > 0 && dx.abs() < dy) {
          stderr.writeln('  type=${mobj.type}, pos=($mx, $my), dx=$dx, dy=$dy');
          count++;
        }
      }
      stderr.writeln('Total visible: $count');
    });

    test('check vissprite projection', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final level = LevelLocals(state)..init();
      if (mapData.blockmap != null) {
        level.blockmap = Blockmap.parse(mapData.blockmap!);
        level.initBlockLinks();
      }

      final thingSpawner = ThingSpawner(state, level)..spawnMapThings(mapData);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        41.toFixed(),
        Angle.ang90,
      );

      stderr.writeln('=== Vissprite Projection Check ===');

      final mobj = thingSpawner.mobjs.first;
      stderr.writeln('Testing mobj: type=${mobj.type}, sprite=${mobj.sprite}');
      stderr.writeln('  mobj pos: (${mobj.x >> 16}, ${mobj.y >> 16}, ${mobj.z >> 16})');
      stderr.writeln('  view pos: (${state.viewX >> 16}, ${state.viewY >> 16}, ${state.viewZ >> 16})');

      final trX = mobj.x - state.viewX;
      final trY = mobj.y - state.viewY;
      stderr.writeln('  trX: ${trX >> 16}, trY: ${trY >> 16}');

      final gxt = Fixed32.mul(trX, state.viewCos);
      final gyt = -Fixed32.mul(trY, state.viewSin);
      final tz = gxt - gyt;
      stderr.writeln('  gxt: ${gxt >> 16}, gyt: ${gyt >> 16}');
      stderr.writeln('  tz (depth): ${tz >> 16}');

      const minZ = Fixed32.fracUnit * 4;
      stderr.writeln('  minZ: ${minZ >> 16}');
      stderr.writeln('  tz < minZ: ${tz < minZ}');

      if (tz >= minZ) {
        final xScale = Fixed32.div(state.projection, tz);
        stderr.writeln('  xScale: $xScale (${xScale.toDouble() / Fixed32.fracUnit.toDouble()})');

        final gxtNeg = -Fixed32.mul(trX, state.viewSin);
        final gytPos = Fixed32.mul(trY, state.viewCos);
        final tx = -(gytPos + gxtNeg);
        stderr.writeln('  tx: ${tx >> 16}');

        final spriteNum = mobj.sprite;
        final frameNum = mobj.frame & 0x7FFF;
        stderr.writeln('  spriteNum: $spriteNum, frameNum: $frameNum');

        if (spriteNum < state.sprites.length) {
          final sprdef = state.sprites[spriteNum];
          stderr.writeln('  sprdef.numFrames: ${sprdef.numFrames}');
          if (frameNum < sprdef.numFrames) {
            final sprframe = sprdef.spriteFrames[frameNum];
            final lump = sprframe.lump[0];
            stderr.writeln('  lump: $lump');
            stderr.writeln('  spriteWidth[$lump]: ${state.spriteWidth[lump] >> 16}');
            stderr.writeln('  spriteOffset[$lump]: ${state.spriteOffset[lump] >> 16}');
            stderr.writeln('  spriteTopOffset[$lump]: ${state.spriteTopOffset[lump] >> 16}');
          }
        }
      }

      expect(thingSpawner.mobjs.length, greaterThan(0));
    });

    test('check vissprite count after render', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final level = LevelLocals(state)..init();
      if (mapData.blockmap != null) {
        level.blockmap = Blockmap.parse(mapData.blockmap!);
        level.initBlockLinks();
      }

      ThingSpawner(state, level).spawnMapThings(mapData);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        41.toFixed(),
        Angle.ang90,
      );

      final frameBuffer = Uint8List(
        ScreenDimensions.width * ScreenDimensions.height,
      );
      renderer.renderPlayerView(frameBuffer);

      stderr.writeln('=== Actual SpriteRenderer Stats ===');
      stderr.writeln('Total things processed: ${renderer.spriteRenderer.totalThingsProcessed}');
      stderr.writeln('Total vissprites: ${renderer.spriteRenderer.vissprites.length}');
      stderr.writeln('Draw calls: ${renderer.spriteRenderer.drawCallCount}');
      stderr.writeln('Columns drawn: ${renderer.spriteRenderer.columnsDrawn}');

      for (var i = 0; i < 5 && i < renderer.spriteRenderer.vissprites.length; i++) {
        final vis = renderer.spriteRenderer.vissprites[i];
        stderr.writeln('  vissprite[$i]: x1=${vis.x1}, x2=${vis.x2}, scale=${vis.scale}, patch=${vis.patch}');
        stderr.writeln('    textureMid=${vis.textureMid}, gz=${vis.gz}, gzt=${vis.gzt}');
      }

      stderr.writeln();
      stderr.writeln('=== Debug Renderer Stats ===');
      final spriteRenderer = _SpriteRendererAccess(state);
      spriteRenderer.renderForDebug(state.sectors);
      stderr.writeln('Total vissprites (debug): ${spriteRenderer.vissprites.length}');
    });

    test('verify sprites in framebuffer', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final level = LevelLocals(state)..init();
      if (mapData.blockmap != null) {
        level.blockmap = Blockmap.parse(mapData.blockmap!);
        level.initBlockLinks();
      }

      ThingSpawner(state, level).spawnMapThings(mapData);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        41.toFixed(),
        Angle.ang90,
      );

      final frameBuffer = Uint8List(
        ScreenDimensions.width * ScreenDimensions.height,
      );
      renderer.renderPlayerView(frameBuffer);

      stderr.writeln('=== Verify Sprites in Framebuffer ===');
      stderr.writeln('Columns drawn: ${renderer.spriteRenderer.columnsDrawn}');

      expect(
        renderer.spriteRenderer.columnsDrawn,
        greaterThan(0),
        reason: 'Expected sprite columns to be drawn',
      );
      expect(
        renderer.spriteRenderer.vissprites.length,
        greaterThan(0),
        reason: 'Expected vissprites to be created',
      );
    });

    test('examine sprite lump data', () {
      final firstSpriteLump = wadManager.getNumForName('S_START') + 1;

      stderr.writeln('First few sprite lumps:');
      for (var i = 0; i < 5; i++) {
        final lumpNum = firstSpriteLump + i;
        final lumpInfo = wadManager.getLumpInfo(lumpNum);
        final patchData = wadManager.cacheLumpNum(lumpNum);

        stderr.writeln('Sprite lump $i: ${lumpInfo.name}');
        if (patchData.length >= 8) {
          final byteData = ByteData.sublistView(patchData);
          final width = byteData.getInt16(0, Endian.little);
          final height = byteData.getInt16(2, Endian.little);
          final leftOffset = byteData.getInt16(4, Endian.little);
          final topOffset = byteData.getInt16(6, Endian.little);

          stderr.writeln('  width=$width, height=$height, leftOffset=$leftOffset, topOffset=$topOffset');

          stderr.writeln('  raw bytes: ${patchData.sublist(0, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')}');
        }
      }

      stderr.writeln();
      stderr.writeln('Looking for BAR1A0 (barrel sprite):');
      final lastSpriteLump = wadManager.getNumForName('S_END') - 1;
      for (var lumpNum = firstSpriteLump; lumpNum <= lastSpriteLump; lumpNum++) {
        final lumpInfo = wadManager.getLumpInfo(lumpNum);
        if (lumpInfo.name.startsWith('BAR1') ?? false) {
          final patchData = wadManager.cacheLumpNum(lumpNum);
          final byteData = ByteData.sublistView(patchData);
          final width = byteData.getInt16(0, Endian.little);
          final height = byteData.getInt16(2, Endian.little);
          final leftOffset = byteData.getInt16(4, Endian.little);
          final topOffset = byteData.getInt16(6, Endian.little);

          stderr.writeln('  ${lumpInfo.name}: width=$width, height=$height, leftOffset=$leftOffset, topOffset=$topOffset');
          break;
        }
      }

      stderr.writeln();
      stderr.writeln('Looking for POSS (zombie) sprites:');
      for (var lumpNum = firstSpriteLump; lumpNum <= lastSpriteLump; lumpNum++) {
        final lumpInfo = wadManager.getLumpInfo(lumpNum);
        if (lumpInfo.name.startsWith('POSS') ?? false) {
          final patchData = wadManager.cacheLumpNum(lumpNum);
          final byteData = ByteData.sublistView(patchData);
          final width = byteData.getInt16(0, Endian.little);
          final height = byteData.getInt16(2, Endian.little);
          final leftOffset = byteData.getInt16(4, Endian.little);
          final topOffset = byteData.getInt16(6, Endian.little);

          stderr.writeln('  ${lumpInfo.name}: width=$width, height=$height, leftOffset=$leftOffset, topOffset=$topOffset');
          break;
        }
      }

      stderr.writeln();
      stderr.writeln('Checking sprite lump indices for vissprite patches:');
      final patchIndices = [313, 437, 475];
      for (final idx in patchIndices) {
        final lumpNum = firstSpriteLump + idx;
        final lumpInfo = wadManager.getLumpInfo(lumpNum);
        final patchData = wadManager.cacheLumpNum(lumpNum);
        final byteData = ByteData.sublistView(patchData);
        final width = byteData.getInt16(0, Endian.little);
        final height = byteData.getInt16(2, Endian.little);
        final leftOffset = byteData.getInt16(4, Endian.little);
        final topOffset = byteData.getInt16(6, Endian.little);

        stderr.writeln('  patch[$idx]: ${lumpInfo.name} width=$width, height=$height, leftOffset=$leftOffset, topOffset=$topOffset');
      }
    });
  });
}
