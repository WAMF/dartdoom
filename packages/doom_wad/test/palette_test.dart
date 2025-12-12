import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

void main() {
  group('DoomPalette', () {
    test('requires exactly 768 bytes', () {
      expect(
        () => DoomPalette(Uint8List(767)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => DoomPalette(Uint8List(769)),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => DoomPalette(Uint8List(768)),
        returnsNormally,
      );
    });

    test('getRed returns correct value', () {
      final data = Uint8List(768);
      data[0] = 255;
      data[3] = 128;

      final palette = DoomPalette(data);

      expect(palette.getRed(0), 255);
      expect(palette.getRed(1), 128);
    });

    test('getGreen returns correct value', () {
      final data = Uint8List(768);
      data[1] = 200;
      data[4] = 100;

      final palette = DoomPalette(data);

      expect(palette.getGreen(0), 200);
      expect(palette.getGreen(1), 100);
    });

    test('getBlue returns correct value', () {
      final data = Uint8List(768);
      data[2] = 150;
      data[5] = 75;

      final palette = DoomPalette(data);

      expect(palette.getBlue(0), 150);
      expect(palette.getBlue(1), 75);
    });

    test('getRgba returns correct RGBA value', () {
      final data = Uint8List(768);
      data[0] = 255;
      data[1] = 128;
      data[2] = 64;

      final palette = DoomPalette(data);
      final rgba = palette.getRgba(0);

      expect(rgba & 0xFF, 255);
      expect((rgba >> 8) & 0xFF, 128);
      expect((rgba >> 16) & 0xFF, 64);
      expect((rgba >> 24) & 0xFF, 255);
    });

    test('toRgba32 converts all colors', () {
      final data = Uint8List(768);
      for (var i = 0; i < 256; i++) {
        data[i * 3] = i;
        data[i * 3 + 1] = 255 - i;
        data[i * 3 + 2] = i ~/ 2;
      }

      final palette = DoomPalette(data);
      final rgba32 = palette.toRgba32();

      expect(rgba32.length, 256);

      expect(rgba32[0] & 0xFF, 0);
      expect((rgba32[0] >> 8) & 0xFF, 255);
      expect((rgba32[0] >> 16) & 0xFF, 0);

      expect(rgba32[100] & 0xFF, 100);
      expect((rgba32[100] >> 8) & 0xFF, 155);
      expect((rgba32[100] >> 16) & 0xFF, 50);
    });

    test('handles edge color indices', () {
      final data = Uint8List(768);
      data[0] = 10;
      data[1] = 20;
      data[2] = 30;
      data[765] = 250;
      data[766] = 251;
      data[767] = 252;

      final palette = DoomPalette(data);

      expect(palette.getRed(0), 10);
      expect(palette.getGreen(0), 20);
      expect(palette.getBlue(0), 30);
      expect(palette.getRed(255), 250);
      expect(palette.getGreen(255), 251);
      expect(palette.getBlue(255), 252);
    });
  });

  group('PlayPal', () {
    test('parses single palette', () {
      final data = Uint8List(768);
      data[0] = 100;
      data[1] = 101;
      data[2] = 102;

      final playpal = PlayPal.parse(data);

      expect(playpal.length, 1);
      expect(playpal[0].getRed(0), 100);
      expect(playpal[0].getGreen(0), 101);
      expect(playpal[0].getBlue(0), 102);
    });

    test('parses multiple palettes', () {
      final data = Uint8List(768 * 3);
      for (var p = 0; p < 3; p++) {
        final offset = p * 768;
        data[offset] = p * 50;
        data[offset + 1] = p * 50 + 10;
        data[offset + 2] = p * 50 + 20;
      }

      final playpal = PlayPal.parse(data);

      expect(playpal.length, 3);
      expect(playpal[0].getRed(0), 0);
      expect(playpal[1].getRed(0), 50);
      expect(playpal[2].getRed(0), 100);
    });

    test('operator [] returns correct palette', () {
      final data = Uint8List(768 * 2);
      data[0] = 10;
      data[768] = 20;

      final playpal = PlayPal.parse(data);

      expect(playpal[0].getRed(0), 10);
      expect(playpal[1].getRed(0), 20);
    });

    test('handles standard DOOM 14 palettes', () {
      final data = Uint8List(768 * 14);

      final playpal = PlayPal.parse(data);

      expect(playpal.length, 14);
    });

    test('palettes list is accessible', () {
      final data = Uint8List(768 * 2);
      final playpal = PlayPal.parse(data);

      expect(playpal.palettes.length, 2);
    });
  });

  group('Colormap', () {
    test('maps color indices', () {
      final data = Uint8List(256);
      for (var i = 0; i < 256; i++) {
        data[i] = 255 - i;
      }

      final colormap = Colormap(data);

      expect(colormap.map(0), 255);
      expect(colormap.map(128), 127);
      expect(colormap.map(255), 0);
    });

    test('data getter returns underlying data', () {
      final data = Uint8List(256);
      data[0] = 42;

      final colormap = Colormap(data);

      expect(colormap.data[0], 42);
      expect(colormap.data.length, 256);
    });

    test('handles identity mapping', () {
      final data = Uint8List(256);
      for (var i = 0; i < 256; i++) {
        data[i] = i;
      }

      final colormap = Colormap(data);

      for (var i = 0; i < 256; i++) {
        expect(colormap.map(i), i);
      }
    });
  });

  group('ColormapSet', () {
    test('parses single colormap', () {
      final data = Uint8List(256);
      for (var i = 0; i < 256; i++) {
        data[i] = i;
      }

      final set = ColormapSet.parse(data);

      expect(set.length, 1);
      expect(set[0].map(100), 100);
    });

    test('parses multiple colormaps', () {
      final data = Uint8List(256 * 3);
      for (var m = 0; m < 3; m++) {
        for (var i = 0; i < 256; i++) {
          data[m * 256 + i] = (i + m * 10) & 0xFF;
        }
      }

      final set = ColormapSet.parse(data);

      expect(set.length, 3);
      expect(set[0].map(0), 0);
      expect(set[1].map(0), 10);
      expect(set[2].map(0), 20);
    });

    test('operator [] returns correct colormap', () {
      final data = Uint8List(256 * 2);
      data[0] = 5;
      data[256] = 10;

      final set = ColormapSet.parse(data);

      expect(set[0].map(0), 5);
      expect(set[1].map(0), 10);
    });

    test('handles standard DOOM 34 colormaps', () {
      final data = Uint8List(256 * 34);

      final set = ColormapSet.parse(data);

      expect(set.length, 34);
    });

    test('colormaps list is accessible', () {
      final data = Uint8List(256 * 2);
      final set = ColormapSet.parse(data);

      expect(set.colormaps.length, 2);
    });
  });
}
