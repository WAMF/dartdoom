import 'dart:typed_data';

import 'package:doom_core/src/render/r_defs.dart';
import 'package:doom_core/src/render/r_state.dart';
import 'package:test/test.dart';

void main() {
  group('ScreenDimensions', () {
    test('has correct width', () {
      expect(ScreenDimensions.width, 320);
    });

    test('has correct height', () {
      expect(ScreenDimensions.height, 200);
    });

    test('centerX is half of width', () {
      expect(ScreenDimensions.centerX, ScreenDimensions.width ~/ 2);
    });

    test('centerY is half of height', () {
      expect(ScreenDimensions.centerY, ScreenDimensions.height ~/ 2);
    });
  });

  group('RenderState', () {
    late RenderState state;

    setUp(() {
      state = RenderState();
    });

    group('default values', () {
      test('has empty map data lists', () {
        expect(state.vertices, isEmpty);
        expect(state.segs, isEmpty);
        expect(state.sectors, isEmpty);
        expect(state.subsectors, isEmpty);
        expect(state.nodes, isEmpty);
        expect(state.lines, isEmpty);
        expect(state.sides, isEmpty);
      });

      test('has empty sprite data', () {
        expect(state.sprites, isEmpty);
        expect(state.firstSpriteLump, 0);
        expect(state.lastSpriteLump, 0);
        expect(state.numSpriteLumps, 0);
      });

      test('has empty texture data', () {
        expect(state.textureHeight, isEmpty);
        expect(state.spriteWidth, isEmpty);
        expect(state.spriteOffset, isEmpty);
        expect(state.spriteTopOffset, isEmpty);
      });

      test('has correct center values', () {
        expect(state.centerX, ScreenDimensions.centerX);
        expect(state.centerY, ScreenDimensions.centerY);
      });

      test('has correct view dimensions', () {
        expect(state.viewWidth, ScreenDimensions.width);
        expect(state.viewHeight, ScreenDimensions.height);
      });

      test('has zero view position', () {
        expect(state.viewX, 0);
        expect(state.viewY, 0);
        expect(state.viewZ, 0);
        expect(state.viewAngle, 0);
      });

      test('has null colormaps', () {
        expect(state.colormaps, isNull);
        expect(state.fixedColormap, isNull);
      });

      test('has zero frame tracking values', () {
        expect(state.validCount, 0);
        expect(state.frameCount, 0);
      });

      test('has zero lighting values', () {
        expect(state.extraLight, 0);
      });

      test('has allocated lookup arrays', () {
        expect(state.yLookup.length, ScreenDimensions.height);
        expect(state.columnOfs.length, ScreenDimensions.width);
        expect(state.viewAngleToX.length, 4096);
        expect(state.xToViewAngle.length, ScreenDimensions.width + 1);
      });
    });

    group('initBuffer', () {
      test('initializes yLookup for default view', () {
        state.initBuffer();

        for (var i = 0; i < state.viewHeight; i++) {
          expect(
            state.yLookup[i],
            (i + state.viewWindowY) * ScreenDimensions.width,
          );
        }
      });

      test('initializes columnOfs for default view', () {
        state.initBuffer();

        for (var i = 0; i < state.viewWidth; i++) {
          expect(state.columnOfs[i], state.viewWindowX + i);
        }
      });

      test('accounts for viewWindowX offset', () {
        state.viewWindowX = 10;
        state.initBuffer();

        for (var i = 0; i < state.viewWidth; i++) {
          expect(state.columnOfs[i], 10 + i);
        }
      });

      test('accounts for viewWindowY offset', () {
        state.viewWindowY = 20;
        state.initBuffer();

        for (var i = 0; i < state.viewHeight; i++) {
          expect(
            state.yLookup[i],
            (i + 20) * ScreenDimensions.width,
          );
        }
      });
    });

    group('scaleLight', () {
      test('has correct dimensions', () {
        expect(state.scaleLight.length, RenderConstants.lightLevels);
        for (final row in state.scaleLight) {
          expect(row.length, RenderConstants.maxLightScale);
        }
      });

      test('starts with null entries', () {
        for (final row in state.scaleLight) {
          for (final entry in row) {
            expect(entry, isNull);
          }
        }
      });

      test('can store colormap references', () {
        final colormap = Uint8List(256);
        state.scaleLight[0][0] = colormap;

        expect(state.scaleLight[0][0], colormap);
      });
    });

    group('zLight', () {
      test('has correct dimensions', () {
        expect(state.zLight.length, RenderConstants.lightLevels);
        for (final row in state.zLight) {
          expect(row.length, RenderConstants.maxLightZ);
        }
      });

      test('starts with null entries', () {
        for (final row in state.zLight) {
          for (final entry in row) {
            expect(entry, isNull);
          }
        }
      });
    });

    group('plane references', () {
      test('floorPlane starts null', () {
        expect(state.floorPlane, isNull);
      });

      test('ceilingPlane starts null', () {
        expect(state.ceilingPlane, isNull);
      });

      test('can set plane references', () {
        final plane = Visplane(height: 0, picNum: 0, lightLevel: 0);
        state.floorPlane = plane;
        state.ceilingPlane = plane;

        expect(state.floorPlane, plane);
        expect(state.ceilingPlane, plane);
      });
    });

    group('sky values', () {
      test('have default values', () {
        expect(state.skyFlatNum, 0);
        expect(state.skyTexture, 0);
        expect(state.skyColumnOffset, 0);
      });

      test('can be modified', () {
        state.skyFlatNum = 10;
        state.skyTexture = 5;
        state.skyColumnOffset = 1000;

        expect(state.skyFlatNum, 10);
        expect(state.skyTexture, 5);
        expect(state.skyColumnOffset, 1000);
      });
    });

    group('render wall state', () {
      test('has default values', () {
        expect(state.rwDistance, 0);
        expect(state.rwNormalAngle, 0);
        expect(state.rwAngle1, 0);
      });

      test('can be modified', () {
        state.rwDistance = 65536;
        state.rwNormalAngle = 16384;
        state.rwAngle1 = 32768;

        expect(state.rwDistance, 65536);
        expect(state.rwNormalAngle, 16384);
        expect(state.rwAngle1, 32768);
      });
    });
  });
}
