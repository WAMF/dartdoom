import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_main.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('Renderer', () {
    late RenderState state;
    late Renderer renderer;

    setUp(() {
      state = RenderState();
      renderer = Renderer(state);
    });

    group('initialization', () {
      test('has draw context', () {
        expect(renderer.drawContext, isNotNull);
      });

      test('init sets up projection tables', () {
        state
          ..centerX = ScreenDimensions.centerX
          ..centerY = ScreenDimensions.centerY;

        renderer.init();

        expect(state.projection, isNot(0));
        expect(state.clipAngle, isNot(0));
      });

      test('init configures lookups in draw context', () {
        renderer.init();

        expect(renderer.drawContext.column.yLookup, state.yLookup);
        expect(renderer.drawContext.column.columnOfs, state.columnOfs);
      });
    });

    group('setupFrame', () {
      setUp(() {
        renderer.init();
      });

      test('sets view position', () {
        renderer.setupFrame(100.toFixed(), 200.toFixed(), 50.toFixed(), 0);

        expect(state.viewX, 100.toFixed());
        expect(state.viewY, 200.toFixed());
        expect(state.viewZ, 50.toFixed());
        expect(state.viewAngle, 0);
      });

      test('calculates view sine and cosine', () {
        renderer.setupFrame(0, 0, 0, 0);

        expect(state.viewCos, isNot(0));
      });

      test('increments frame and valid counts', () {
        final initialFrame = state.frameCount;
        final initialValid = state.validCount;

        renderer.setupFrame(0, 0, 0, 0);

        expect(state.frameCount, initialFrame + 1);
        expect(state.validCount, initialValid + 1);
      });

      test('resets extraLight and fixedColormap', () {
        state.extraLight = 10;
        state.fixedColormap = Uint8List(256);

        renderer.setupFrame(0, 0, 0, 0);

        expect(state.extraLight, 0);
        expect(state.fixedColormap, isNull);
      });
    });

    group('pointOnSide', () {
      setUp(() {
        renderer.init();
      });

      test('returns 0 for point on right of vertical partition', () {
        final node = Node(
          x: 0,
          y: 0,
          dx: 0,
          dy: Fixed32.fracUnit,
          bbox: [Int32List(4), Int32List(4)],
          children: Int32List.fromList([0, 0]),
        );

        state.viewX = Fixed32.fracUnit;
        state.viewY = 0;

        final side = renderer.pointOnSide(Fixed32.fracUnit, 0, node);
        expect(side, 0);
      });

      test('returns 1 for point on left of vertical partition', () {
        final node = Node(
          x: 0,
          y: 0,
          dx: 0,
          dy: Fixed32.fracUnit,
          bbox: [Int32List(4), Int32List(4)],
          children: Int32List.fromList([0, 0]),
        );

        final side = renderer.pointOnSide(-Fixed32.fracUnit, 0, node);
        expect(side, 1);
      });

      test('returns 0 for point below horizontal partition', () {
        final node = Node(
          x: 0,
          y: 0,
          dx: Fixed32.fracUnit,
          dy: 0,
          bbox: [Int32List(4), Int32List(4)],
          children: Int32List.fromList([0, 0]),
        );

        final side = renderer.pointOnSide(0, -Fixed32.fracUnit, node);
        expect(side, 0);
      });

      test('returns 1 for point above horizontal partition', () {
        final node = Node(
          x: 0,
          y: 0,
          dx: Fixed32.fracUnit,
          dy: 0,
          bbox: [Int32List(4), Int32List(4)],
          children: Int32List.fromList([0, 0]),
        );

        final side = renderer.pointOnSide(0, Fixed32.fracUnit, node);
        expect(side, 1);
      });
    });

    group('pointToAngle', () {
      setUp(() {
        renderer.init();
        state.viewX = 0;
        state.viewY = 0;
      });

      test('returns 0 for point at view position', () {
        final angle = renderer.pointToAngleXY(0, 0);
        expect(angle, 0);
      });

      test('returns angle for point to the right', () {
        final angle = renderer.pointToAngleXY(Fixed32.fracUnit, 0);
        expect(angle, 0);
      });

      test('returns ANG90 for point directly above', () {
        final angle = renderer.pointToAngleXY(0, Fixed32.fracUnit);
        expect(angle, closeTo(Angle.ang90, Angle.ang90 ~/ 16));
      });

      test('returns ANG180 for point to the left', () {
        final angle = renderer.pointToAngleXY(-Fixed32.fracUnit, 0);
        final normalized = angle.u32.s32;
        expect(normalized.abs(), closeTo(Angle.ang180.abs(), Angle.ang90 ~/ 8));
      });

      test('returns ANG270 for point directly below', () {
        final angle = renderer.pointToAngleXY(0, -Fixed32.fracUnit);
        final normalized = angle.u32;
        expect(normalized, closeTo(Angle.ang270.u32, Angle.ang90 ~/ 8));
      });
    });

    group('angleToX and xToAngle', () {
      setUp(() {
        renderer.init();
      });

      test('angleToX returns center for ANG90', () {
        final x = renderer.angleToX(Angle.ang90);
        expect(x, closeTo(state.centerX, 10));
      });

      test('angleToX clamps to view bounds', () {
        final x1 = renderer.angleToX(Angle.ang90);
        final x2 = renderer.angleToX(-Angle.ang90);

        expect(x1, greaterThanOrEqualTo(0));
        expect(x1, lessThanOrEqualTo(state.viewWidth));
        expect(x2, greaterThanOrEqualTo(0));
        expect(x2, lessThanOrEqualTo(state.viewWidth));
      });

      test('xToAngle returns angle for center', () {
        final angle = renderer.xToAngle(state.centerX);
        expect(angle.abs(), lessThan(Angle.ang45));
      });
    });

    group('pointInSubsector', () {
      setUp(() {
        renderer.init();

        final sector = Sector(
          floorHeight: 0,
          ceilingHeight: 128,
          floorPic: 0,
          ceilingPic: 0,
          lightLevel: 128,
          special: 0,
          tag: 0,
        );

        state.subsectors = [
          Subsector(sector: sector, numLines: 1, firstLine: 0),
        ];
        state.nodes = [];
      });

      test('returns first subsector when no nodes exist', () {
        final sub = renderer.pointInSubsector(0, 0);
        expect(sub, state.subsectors[0]);
      });
    });

    group('scaleFromGlobalAngle', () {
      setUp(() {
        renderer.init();
        state.viewAngle = 0;
        state.rwNormalAngle = 0;
        state.rwDistance = Fixed32.fracUnit * 100;
      });

      test('returns valid scale for visible angle', () {
        final scale = renderer.scaleFromGlobalAngle(0);
        expect(scale, greaterThan(0));
      });

      test('clamps scale to maximum', () {
        state.rwDistance = 1;
        final scale = renderer.scaleFromGlobalAngle(0);
        expect(scale, lessThanOrEqualTo(64 * Fixed32.fracUnit));
      });

      test('clamps scale to minimum', () {
        state.rwDistance = Fixed32.fracUnit * 10000;
        final scale = renderer.scaleFromGlobalAngle(0);
        expect(scale, greaterThanOrEqualTo(256));
      });
    });

    group('renderPlayerView', () {
      test('sets frame buffer', () {
        renderer.init();
        final frameBuffer = Uint8List(
          ScreenDimensions.width * ScreenDimensions.height,
        );

        renderer.renderPlayerView(frameBuffer);

        expect(renderer.frameBuffer, frameBuffer);
      });

      test('clears planes before rendering', () {
        renderer.init();
        state.floorPlane = Visplane(height: 99, picNum: 99, lightLevel: 99);
        state.ceilingPlane = Visplane(height: 99, picNum: 99, lightLevel: 99);

        renderer.renderPlayerView(Uint8List(
          ScreenDimensions.width * ScreenDimensions.height,
        ),);

        expect(state.floorPlane, isNotNull);
        expect(state.ceilingPlane, isNotNull);
      });
    });
  });
}
