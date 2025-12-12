import 'dart:io';
import 'dart:typed_data';

import 'package:doom_core/src/render/r_bsp.dart';
import 'package:doom_core/src/render/r_data.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_plane.dart';
import 'package:doom_core/src/render/r_segs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

abstract final class _ThingTypes {
  static const int player1Start = 1;
}

abstract final class _ViewHeight {
  static const int standing = 41;
}

void main() {
  group('E1M1 Integration', () {
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

    test('loads E1M1 map data', () {
      expect(mapData.vertices, isNotEmpty);
      expect(mapData.linedefs, isNotEmpty);
      expect(mapData.sidedefs, isNotEmpty);
      expect(mapData.sectors, isNotEmpty);
      expect(mapData.segs, isNotEmpty);
      expect(mapData.subsectors, isNotEmpty);
      expect(mapData.nodes, isNotEmpty);
      expect(mapData.things, isNotEmpty);
    });

    test('finds player 1 start position', () {
      final player1Start = mapData.things.firstWhere(
        (t) => t.type == _ThingTypes.player1Start,
      );

      expect(player1Start.x, isNot(0));
      expect(player1Start.y, isNot(0));
    });

    test('loads level into render state', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);

      expect(state.vertices, isNotEmpty);
      expect(state.lines, isNotEmpty);
      expect(state.sides, isNotEmpty);
      expect(state.sectors, isNotEmpty);
      expect(state.segs, isNotEmpty);
      expect(state.subsectors, isNotEmpty);
      expect(state.nodes, isNotEmpty);
    });

    test('initializes renderer with E1M1', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);

      RenderData(wadManager).initData(state);
      expect(state.colormaps, isNotNull);

      Renderer(state).init();
      expect(state.projection, isNot(0));
    });

    test('sets up view from player 1 start', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere(
        (t) => t.type == _ThingTypes.player1Start,
      );

      final viewX = player1Start.x.toFixed();
      final viewY = player1Start.y.toFixed();
      final viewZ = _ViewHeight.standing.toFixed();
      final viewAngle = (player1Start.angle * Angle.ang90 ~/ 90).u32.s32;

      renderer.setupFrame(viewX, viewY, viewZ, viewAngle);

      expect(state.viewX, viewX);
      expect(state.viewY, viewY);
      expect(state.viewZ, viewZ);
      expect(state.viewCos != 0 || state.viewSin != 0, isTrue);
    });

    test('BSP traversal visits subsectors', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final renderer = Renderer(state)..init();

      final player1Start = mapData.things.firstWhere(
        (t) => t.type == _ThingTypes.player1Start,
      );

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        _ViewHeight.standing.toFixed(),
        (player1Start.angle * Angle.ang90 ~/ 90).u32.s32,
      );

      final bsp = BspTraversal(state, renderer);

      var linesVisited = 0;
      bsp
        ..onAddLine = (seg, start, stop, rwAngle1) {
          linesVisited++;
        }
        ..clearClipSegs()
        ..renderBspNode(state.nodes.length - 1);

      expect(linesVisited, greaterThan(0));
    });

    test('seg renderer processes visible walls', () {
      final levelLoader = LevelLoader(textureManager);
      final state = levelLoader.loadLevel(mapData);
      RenderData(wadManager).initData(state);

      final renderer = Renderer(state)..init();
      final planeRenderer = PlaneRenderer(state, renderer.drawContext);
      final segRenderer = SegRenderer(state, renderer, renderer.drawContext)
        ..initClipArrays(ScreenDimensions.width)
        ..clearClips(ScreenDimensions.height);

      final player1Start = mapData.things.firstWhere(
        (t) => t.type == _ThingTypes.player1Start,
      );

      renderer.setupFrame(
        player1Start.x.toFixed(),
        player1Start.y.toFixed(),
        _ViewHeight.standing.toFixed(),
        (player1Start.angle * Angle.ang90 ~/ 90).u32.s32,
      );

      final frameBuffer = Uint8List(
        ScreenDimensions.width * ScreenDimensions.height,
      );
      renderer.renderPlayerView(frameBuffer);

      planeRenderer.clearPlanes();
      segRenderer.clearDrawSegs();

      var floorSpans = 0;
      var ceilingSpans = 0;

      segRenderer
        ..onFloorPlane = (x, top, bottom) {
          floorSpans++;
          planeRenderer.setFloorPlane(x, top, bottom);
        }
        ..onCeilingPlane = (x, top, bottom) {
          ceilingSpans++;
          planeRenderer.setCeilingPlane(x, top, bottom);
        };

      final bsp = BspTraversal(state, renderer)
        ..onAddLine = segRenderer.storeWallRange
        ..clearClipSegs()
        ..renderBspNode(state.nodes.length - 1);

      expect(floorSpans + ceilingSpans, greaterThan(0));
      expect(bsp, isNotNull);
    });
  });
}
