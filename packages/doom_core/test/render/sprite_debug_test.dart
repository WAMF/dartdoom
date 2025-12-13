import 'dart:io';
import 'dart:typed_data';

import 'package:doom_core/src/game/p_mobj.dart';
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

void main() {
  group('Sprite Debug', () {
    late Uint8List wadBytes;
    late WadManager wadManager;
    late TextureManager textureManager;
    late MapLoader mapLoader;
    late MapData mapData;

    setUpAll(() {
      final wadFile = File('../../assets/DOOM1.WAD');
      if (!wadFile.existsSync()) {
        fail('DOOM1.WAD not found at ${wadFile.absolute.path}');
      }
      wadBytes = wadFile.readAsBytesSync();
    });

    setUp(() {
      wadManager = WadManager()..addWad(wadBytes);
      textureManager = TextureManager(wadManager)..init();
      mapLoader = MapLoader(wadManager);
      mapData = mapLoader.loadMap('E1M1');
    });

    test('sprite count and distribution', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final thingSpawner = ThingSpawner(state)..spawnMapThings(mapData);

      stderr.writeln('=== Sprite Debug ===');
      stderr.writeln('Total map things: ${mapData.things.length}');
      stderr.writeln('Spawned mobjs: ${thingSpawner.mobjs.length}');
      stderr.writeln('');
      stderr.writeln('Sprite definitions loaded: ${state.sprites.length}');
      stderr.writeln('');

      var sectorsWithThings = 0;
      for (final sector in state.sectors) {
        if (sector.thingList != null) {
          sectorsWithThings++;
        }
      }
      stderr.writeln('Sectors with things: $sectorsWithThings');
      stderr.writeln('');

      stderr.writeln('First 10 spawned mobjs:');
      for (var i = 0; i < 10 && i < thingSpawner.mobjs.length; i++) {
        final mobj = thingSpawner.mobjs[i];
        stderr.writeln('  [$i] type=${mobj.type}, sprite=${mobj.sprite}, x=${mobj.x >> 16}, y=${mobj.y >> 16}');
      }

      expect(thingSpawner.mobjs.length, greaterThan(0));
      expect(sectorsWithThings, greaterThan(0));
    });

    test('render with sprites', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final thingSpawner = ThingSpawner(state)..spawnMapThings(mapData);

      final renderer = Renderer(state)..init();

      renderer.setupFrame(
        1056.toFixed(),
        (-3616).toFixed(),
        41.toFixed(),
        Angle.ang90,
      );

      final frameBuffer = Uint8List(
        ScreenDimensions.width * ScreenDimensions.height,
      );
      renderer.renderPlayerView(frameBuffer);

      stderr.writeln('Rendered with ${thingSpawner.mobjs.length} mobjs');
    });
  });
}
