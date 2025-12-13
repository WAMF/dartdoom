import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_draw.dart';
import 'package:doom_core/src/render/r_plane.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:doom_math/doom_math.dart';
import 'package:test/test.dart';

void main() {
  group('PlaneRenderer', () {
    late RenderState state;
    late DrawContext drawContext;
    late PlaneRenderer planeRenderer;

    setUp(() {
      state = RenderState();
      drawContext = DrawContext();
      planeRenderer = PlaneRenderer(state, drawContext);

      state
        ..centerX = ScreenDimensions.centerX
        ..centerY = ScreenDimensions.centerY
        ..centerXFrac = ScreenDimensions.centerX << Fixed32.fracBits
        ..centerYFrac = ScreenDimensions.centerY << Fixed32.fracBits
        ..viewWidth = ScreenDimensions.width
        ..viewHeight = ScreenDimensions.height
        ..projection = Fixed32.fracUnit
        ..viewAngle = 0
        ..viewZ = 41.toFixed()
        ..extraLight = 0
        ..skyFlatNum = -1;

      state.initBuffer();
      drawContext.setLookups(state.yLookup, state.columnOfs);

      for (var i = 0; i < RenderConstants.lightLevels; i++) {
        for (var j = 0; j < RenderConstants.maxLightZ; j++) {
          state.zLight[i][j] = Uint8List(256);
        }
      }
    });

    group('clearPlanes', () {
      test('creates floor and ceiling planes', () {
        planeRenderer.clearPlanes();

        expect(planeRenderer.floorPlane, isNotNull);
        expect(planeRenderer.ceilingPlane, isNotNull);
      });

      test('adds planes to visplanes list', () {
        planeRenderer.clearPlanes();

        expect(planeRenderer.visplanes.length, 2);
      });

      test('resets visplanes on subsequent calls', () {
        planeRenderer.clearPlanes();
        planeRenderer.clearPlanes();

        expect(planeRenderer.visplanes.length, 2);
      });
    });

    group('findPlane', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('returns existing plane with matching properties', () {
        final plane1 = planeRenderer.findPlane(100, 5, 160);
        final plane2 = planeRenderer.findPlane(100, 5, 160);

        expect(plane1, same(plane2));
      });

      test('creates new plane for different height', () {
        final plane1 = planeRenderer.findPlane(100, 5, 160);
        final plane2 = planeRenderer.findPlane(200, 5, 160);

        expect(plane1, isNot(same(plane2)));
      });

      test('creates new plane for different picNum', () {
        final plane1 = planeRenderer.findPlane(100, 5, 160);
        final plane2 = planeRenderer.findPlane(100, 10, 160);

        expect(plane1, isNot(same(plane2)));
      });

      test('creates new plane for different lightLevel', () {
        final plane1 = planeRenderer.findPlane(100, 5, 160);
        final plane2 = planeRenderer.findPlane(100, 5, 200);

        expect(plane1, isNot(same(plane2)));
      });

      test('normalizes sky planes to height 0 and lightLevel 0', () {
        state.skyFlatNum = 99;

        final plane = planeRenderer.findPlane(500, 99, 255);

        expect(plane.height, 0);
        expect(plane.lightLevel, 0);
      });

      test('throws when maxVisplanes exceeded', () {
        for (var i = 0; i < RenderConstants.maxVisplanes - 1; i++) {
          planeRenderer.findPlane(i, 0, 0);
        }

        expect(
          () => planeRenderer.findPlane(999, 999, 999),
          throwsStateError,
        );
      });
    });

    group('checkPlane', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('expands minX for start less than current minX', () {
        final plane = planeRenderer.findPlane(100, 5, 160)
          ..minX = 100
          ..maxX = 200;

        planeRenderer.checkPlane(plane, 50, 150);

        expect(plane.minX, 50);
      });

      test('expands maxX for stop greater than current maxX', () {
        final plane = planeRenderer.findPlane(100, 5, 160)
          ..minX = 100
          ..maxX = 200;

        planeRenderer.checkPlane(plane, 150, 250);

        expect(plane.maxX, 250);
      });
    });

    group('makeSpans', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('does not crash with valid parameters', () {
        planeRenderer.makeSpans(100, 50, 100, 55, 105);
      });

      test('handles edge case of equal t and b values', () {
        planeRenderer.makeSpans(100, 50, 50, 50, 50);
      });
    });

    group('enterSubsector', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('creates floor plane when floor below viewZ', () {
        final sector = Sector(
          floorHeight: 0,
          ceilingHeight: 128.toFixed(),
          floorPic: 5,
          ceilingPic: 10,
          lightLevel: 160,
          special: 0,
          tag: 0,
        );
        planeRenderer.enterSubsector(sector);

        expect(planeRenderer.floorPlane, isNotNull);
        expect(planeRenderer.floorPlane!.picNum, 5);
        expect(state.floorPlane, planeRenderer.floorPlane);
      });

      test('creates ceiling plane when ceiling above viewZ', () {
        final sector = Sector(
          floorHeight: 0,
          ceilingHeight: 128.toFixed(),
          floorPic: 5,
          ceilingPic: 10,
          lightLevel: 200,
          special: 0,
          tag: 0,
        );
        planeRenderer.enterSubsector(sector);

        expect(planeRenderer.ceilingPlane, isNotNull);
        expect(planeRenderer.ceilingPlane!.picNum, 10);
        expect(state.ceilingPlane, planeRenderer.ceilingPlane);
      });

      test('sets floor plane to null when floor at or above viewZ', () {
        final sector = Sector(
          floorHeight: 50.toFixed(),
          ceilingHeight: 128.toFixed(),
          floorPic: 5,
          ceilingPic: 10,
          lightLevel: 160,
          special: 0,
          tag: 0,
        );
        planeRenderer.enterSubsector(sector);

        expect(planeRenderer.floorPlane, isNull);
        expect(state.floorPlane, isNull);
      });

      test('sets ceiling plane to null when ceiling at or below viewZ', () {
        final sector = Sector(
          floorHeight: 0,
          ceilingHeight: 40.toFixed(),
          floorPic: 5,
          ceilingPic: 10,
          lightLevel: 160,
          special: 0,
          tag: 0,
        );
        planeRenderer.enterSubsector(sector);

        expect(planeRenderer.ceilingPlane, isNull);
        expect(state.ceilingPlane, isNull);
      });

      test('creates ceiling plane for sky even when below viewZ', () {
        state.skyFlatNum = 10;
        final sector = Sector(
          floorHeight: 0,
          ceilingHeight: 40.toFixed(),
          floorPic: 5,
          ceilingPic: 10,
          lightLevel: 160,
          special: 0,
          tag: 0,
        );
        planeRenderer.enterSubsector(sector);

        expect(planeRenderer.ceilingPlane, isNotNull);
        expect(state.ceilingPlane, planeRenderer.ceilingPlane);
      });
    });

    group('setFloorPlane and setCeilingPlane', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('setFloorPlane sets floor clip values', () {
        planeRenderer.setFloorPlane(100, 50, 100);

        expect(planeRenderer.floorPlane!.top[100], 50);
        expect(planeRenderer.floorPlane!.bottom[100], 100);
      });

      test('setCeilingPlane sets ceiling clip values', () {
        planeRenderer.setCeilingPlane(100, 20, 40);

        expect(planeRenderer.ceilingPlane!.top[100], 20);
        expect(planeRenderer.ceilingPlane!.bottom[100], 40);
      });

      test('setFloorPlane ignores invalid range', () {
        planeRenderer.setFloorPlane(100, 50, 100);
        final plane = planeRenderer.floorPlane!;
        final originalTop = plane.top[100];

        planeRenderer.setFloorPlane(100, 100, 50);

        expect(plane.top[100], originalTop);
      });

      test('setCeilingPlane ignores invalid range', () {
        planeRenderer.setCeilingPlane(100, 50, 100);
        final plane = planeRenderer.ceilingPlane!;
        final originalTop = plane.top[100];

        planeRenderer.setCeilingPlane(100, 100, 50);

        expect(plane.top[100], originalTop);
      });
    });

    group('drawPlanes', () {
      setUp(() {
        planeRenderer.clearPlanes();
      });

      test('does not crash with empty planes', () {
        final frameBuffer = Uint8List(
          ScreenDimensions.width * ScreenDimensions.height,
        );

        planeRenderer.drawPlanes(frameBuffer);
      });

      test('calls onDrawSky for sky planes', () {
        state.skyFlatNum = 99;

        final skyPlane = planeRenderer.findPlane(0, 99, 0)
          ..minX = 50
          ..maxX = 100;

        for (var x = 50; x <= 100; x++) {
          skyPlane
            ..top[x] = 0
            ..bottom[x] = 50;
        }

        var skyDrawn = false;
        planeRenderer.onDrawSky = (plane) {
          skyDrawn = true;
        };

        final frameBuffer = Uint8List(
          ScreenDimensions.width * ScreenDimensions.height,
        );
        planeRenderer.drawPlanes(frameBuffer);

        expect(skyDrawn, isTrue);
      });

      test('calls onGetFlat for non-sky planes', () {
        final plane = planeRenderer.findPlane(0, 5, 160)
          ..minX = 50
          ..maxX = 100;

        for (var x = 50; x <= 100; x++) {
          plane
            ..top[x] = 80
            ..bottom[x] = 90;
        }

        var flatRequested = false;
        planeRenderer.onGetFlat = (flatNum) {
          flatRequested = true;
          return Uint8List(64 * 64);
        };

        final frameBuffer = Uint8List(
          ScreenDimensions.width * ScreenDimensions.height,
        );

        drawContext.span.source = Uint8List(64 * 64);
        drawContext.span.colormap = Uint8List(256);

        planeRenderer.drawPlanes(frameBuffer);

        expect(flatRequested, isTrue);
      });
    });
  });
}
