import 'dart:io';
import 'dart:typed_data';

import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

void main() {
  group('Sky Debug', () {
    late Uint8List wadBytes;
    late WadManager wadManager;
    late TextureManager textureManager;

    setUpAll(() {
      final wadFile = File('../../assets/DOOM1.WAD');
      if (!wadFile.existsSync()) {
        fail('DOOM1.WAD not found');
      }
      wadBytes = wadFile.readAsBytesSync();
    });

    setUp(() {
      wadManager = WadManager()..addWad(wadBytes);
      textureManager = TextureManager(wadManager)..init();
    });

    test('finds F_SKY1 flat', () {
      final skyFlatNum = textureManager.flatNumForName('F_SKY1');
      print('F_SKY1 flat number: $skyFlatNum');
      expect(skyFlatNum, greaterThanOrEqualTo(0));
    });

    test('finds SKY1 texture', () {
      final skyTexNum = textureManager.checkTextureNumForName('SKY1');
      print('SKY1 texture number: $skyTexNum');
      expect(skyTexNum, greaterThanOrEqualTo(0));

      if (skyTexNum >= 0) {
        final texDef = textureManager.getTextureDef(skyTexNum);
        print('SKY1 size: ${texDef.width}x${texDef.height}');

        final col = textureManager.getTextureColumn(skyTexNum, 0);
        print('Column 0 length: ${col.length}');
        print('First 10 pixels: ${col.take(10).toList()}');

        expect(col.length, texDef.height);
        expect(col.any((p) => p != 0), isTrue);
      }
    });

    test('level setup initializes sky correctly', () {
      final mapLoader = MapLoader(wadManager);
      final mapData = mapLoader.loadMap('E1M1');
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);

      print('state.skyFlatNum: ${state.skyFlatNum}');
      print('state.skyTexture: ${state.skyTexture}');

      expect(state.skyFlatNum, greaterThanOrEqualTo(0));
      expect(state.skyTexture, greaterThanOrEqualTo(0));
    });

    test('E1M1 starting sector has sky ceiling', () {
      final mapLoader = MapLoader(wadManager);
      final mapData = mapLoader.loadMap('E1M1');
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);

      final player1Start = mapData.things.firstWhere((t) => t.type == 1);
      print('Player start: (${player1Start.x}, ${player1Start.y})');

      RenderData(wadManager).initData(state);
      final renderer = Renderer(state)..init();

      final subsector = renderer.pointInSubsector(
        player1Start.x << 16,
        player1Start.y << 16,
      );

      print('Subsector sector floor: ${subsector.sector.floorHeight >> 16}');
      print('Subsector sector ceiling: ${subsector.sector.ceilingHeight >> 16}');
      print('Subsector sector floorPic: ${subsector.sector.floorPic}');
      print('Subsector sector ceilingPic: ${subsector.sector.ceilingPic}');
      print('state.skyFlatNum: ${state.skyFlatNum}');
      print('Is ceiling sky? ${subsector.sector.ceilingPic == state.skyFlatNum}');
    });

    test('visplanes after render', () {
      final mapLoader = MapLoader(wadManager);
      final mapData = mapLoader.loadMap('E1M1');
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

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

      print('Floor flat data exists: ${textureManager.getFlat(10).isNotEmpty}');
      print('Ceiling flat data exists: ${textureManager.getFlat(32).isNotEmpty}');
      print('Ceiling flat first bytes: ${textureManager.getFlat(32).take(10).toList()}');

      print('zLight[0][0] is null: ${state.zLight[0][0] == null}');
      print('colormaps length: ${state.colormaps?.length ?? 0}');

      var nonZeroTopHalf = 0;
      var nonZeroBottomHalf = 0;
      for (var y = 0; y < 100; y++) {
        for (var x = 0; x < 320; x++) {
          if (frameBuffer[y * 320 + x] != 0) nonZeroTopHalf++;
        }
      }
      for (var y = 100; y < 200; y++) {
        for (var x = 0; x < 320; x++) {
          if (frameBuffer[y * 320 + x] != 0) nonZeroBottomHalf++;
        }
      }
      print('Non-zero pixels in top half (ceiling): $nonZeroTopHalf');
      print('Non-zero pixels in bottom half (floor): $nonZeroBottomHalf');

      final playpalIndex = wadManager.getNumForName('PLAYPAL');
      final playpalData = wadManager.readLump(playpalIndex);
      final palette = PlayPal.parse(playpalData).palettes.first;

      print('Palette index 6 RGB: (${palette.getRed(6)}, ${palette.getGreen(6)}, ${palette.getBlue(6)})');
      print('Palette index 7 RGB: (${palette.getRed(7)}, ${palette.getGreen(7)}, ${palette.getBlue(7)})');
      print('Palette index 107 RGB: (${palette.getRed(107)}, ${palette.getGreen(107)}, ${palette.getBlue(107)})');
      print('Palette index 108 RGB: (${palette.getRed(108)}, ${palette.getGreen(108)}, ${palette.getBlue(108)})');
      print('Palette index 109 RGB: (${palette.getRed(109)}, ${palette.getGreen(109)}, ${palette.getBlue(109)})');

      final ceilPixels = <int>{};
      for (var y = 0; y < 50; y++) {
        for (var x = 0; x < 320; x++) {
          final p = frameBuffer[y * 320 + x];
          if (p != 0) ceilPixels.add(p);
        }
      }
      print('Unique ceiling pixel values (top 50 rows): $ceilPixels');
    });
  });
}
