import 'dart:typed_data';

import 'package:doom_core/src/render/r_bsp.dart';
import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('BspTraversal', () {
    late RenderState state;
    late Renderer renderer;
    late BspTraversal bsp;

    setUp(() {
      state = RenderState();
      renderer = Renderer(state);
      renderer.init();
      bsp = BspTraversal(state, renderer);
    });

    group('clearClipSegs', () {
      test('initializes solid segs with sentinel values', () {
        bsp.clearClipSegs();
      });

      test('can be called multiple times', () {
        bsp.clearClipSegs();
        bsp.clearClipSegs();
        bsp.clearClipSegs();
      });
    });

    group('renderBspNode', () {
      late Sector sector;
      late Side side;
      late Vertex v1;
      late Vertex v2;

      setUp(() {
        sector = Sector(
          index: 0,
          floorHeight: 0,
          ceilingHeight: 128.toFixed(),
          floorPic: 0,
          ceilingPic: 0,
          lightLevel: 128,
          special: 0,
          tag: 0,
        );

        side = Side(
          textureOffset: 0,
          rowOffset: 0,
          topTexture: 0,
          bottomTexture: 0,
          midTexture: 1,
          sector: sector,
        );

        v1 = Vertex(0, 0);
        v2 = Vertex(64.toFixed(), 0);

        final line = Line(
          v1: v1,
          v2: v2,
          dx: 64.toFixed(),
          dy: 0,
          flags: 1,
          special: 0,
          tag: 0,
          sideNum: [0, -1],
          slopeType: SlopeType.horizontal,
          bbox: Int32List.fromList([0, 0, 64.toFixed(), 0]),
          frontSide: side,
          frontSector: sector,
        );

        final seg = Seg(
          v1: v1,
          v2: v2,
          offset: 0,
          angle: 0,
          sidedef: side,
          linedef: line,
          frontSector: sector,
        );

        state.subsectors = [
          Subsector(sector: sector, numLines: 1, firstLine: 0),
        ];
        state.segs = [seg];
        state.nodes = [];

        state.viewX = 32.toFixed();
        state.viewY = (-64).toFixed();
        state.viewZ = 41.toFixed();
        state.viewAngle = Angle.ang90;
        state.clipAngle = Angle.ang45;

        renderer.setupFrame(
          state.viewX,
          state.viewY,
          state.viewZ,
          state.viewAngle,
        );
      });

      test('renders subsector when nodeNum is -1', () {
        bsp.clearClipSegs();
        bsp.renderBspNode(-1);
      });

      test('renders subsector when subsector flag is set', () {
        bsp.clearClipSegs();
        bsp.renderBspNode(BspConstants.subsectorFlag);
      });

      test('calls onAddLine callback when line is visible', () {
        var callbackCalled = false;
        bsp.onAddLine = (seg, start, stop, rwAngle1) {
          callbackCalled = true;
        };

        bsp.clearClipSegs();
        bsp.renderBspNode(BspConstants.subsectorFlag);

        expect(callbackCalled, isTrue);
      });

      test('traverses BSP tree with nodes', () {
        final node = Node(
          x: 32.toFixed(),
          y: 0,
          dx: 0,
          dy: 64.toFixed(),
          bbox: [
            Int32List.fromList([
              64.toFixed(),
              0,
              0,
              32.toFixed(),
            ]),
            Int32List.fromList([
              64.toFixed(),
              0,
              32.toFixed(),
              64.toFixed(),
            ]),
          ],
          children: Int32List.fromList([
            BspConstants.subsectorFlag,
            BspConstants.subsectorFlag | 1,
          ]),
        );

        state.nodes = [node];
        state.subsectors = [
          Subsector(sector: sector, numLines: 1, firstLine: 0),
          Subsector(sector: sector, numLines: 0, firstLine: 0),
        ];

        bsp.clearClipSegs();
        bsp.renderBspNode(0);
      });
    });

    group('solid wall clipping', () {
      late Sector sector;
      late Side side;
      late Vertex v1;
      late Vertex v2;

      setUp(() {
        sector = Sector(
          index: 0,
          floorHeight: 0,
          ceilingHeight: 128.toFixed(),
          floorPic: 0,
          ceilingPic: 0,
          lightLevel: 128,
          special: 0,
          tag: 0,
        );

        side = Side(
          textureOffset: 0,
          rowOffset: 0,
          topTexture: 0,
          bottomTexture: 0,
          midTexture: 1,
          sector: sector,
        );

        v1 = Vertex(0, 0);
        v2 = Vertex(64.toFixed(), 0);

        state.viewX = 32.toFixed();
        state.viewY = (-64).toFixed();
        state.viewZ = 41.toFixed();
        state.viewAngle = Angle.ang90;
        state.clipAngle = Angle.ang45;

        renderer.setupFrame(
          state.viewX,
          state.viewY,
          state.viewZ,
          state.viewAngle,
        );
      });

      test('clips solid walls correctly', () {
        final line = Line(
          v1: v1,
          v2: v2,
          dx: 64.toFixed(),
          dy: 0,
          flags: 1,
          special: 0,
          tag: 0,
          sideNum: [0, -1],
          slopeType: SlopeType.horizontal,
          bbox: Int32List.fromList([0, 0, 64.toFixed(), 0]),
          frontSide: side,
          frontSector: sector,
        );

        final seg = Seg(
          v1: v1,
          v2: v2,
          offset: 0,
          angle: 0,
          sidedef: side,
          linedef: line,
          frontSector: sector,
        );

        state.segs = [seg];
        state.subsectors = [
          Subsector(sector: sector, numLines: 1, firstLine: 0),
        ];
        state.nodes = [];

        final visibleRanges = <List<int>>[];
        bsp.onAddLine = (s, start, stop, rwAngle1) {
          visibleRanges.add([start, stop]);
        };

        bsp.clearClipSegs();
        bsp.renderBspNode(-1);

        expect(visibleRanges, isNotEmpty);
      });
    });
  });
}
