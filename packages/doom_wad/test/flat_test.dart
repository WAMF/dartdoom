import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

void main() {
  group('Flat', () {
    group('constants', () {
      test('size is 64', () {
        expect(Flat.size, 64);
      });

      test('dataSize is 4096', () {
        expect(Flat.dataSize, 4096);
      });
    });

    group('constructor', () {
      test('requires exactly 4096 bytes', () {
        expect(
          () => Flat(Uint8List(4095)),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Flat(Uint8List(4097)),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => Flat(Uint8List(4096)),
          returnsNormally,
        );
      });

      test('stores data', () {
        final data = Uint8List(4096);
        data[0] = 42;

        final flat = Flat(data);

        expect(flat.data[0], 42);
      });
    });

    group('getPixel', () {
      test('returns correct pixel value', () {
        final data = Uint8List(4096);
        data[0] = 10;
        data[1] = 20;
        data[64] = 30;

        final flat = Flat(data);

        expect(flat.getPixel(0, 0), 10);
        expect(flat.getPixel(1, 0), 20);
        expect(flat.getPixel(0, 1), 30);
      });

      test('wraps x coordinate with mask', () {
        final data = Uint8List(4096);
        data[0] = 100;

        final flat = Flat(data);

        expect(flat.getPixel(64, 0), 100);
        expect(flat.getPixel(128, 0), 100);
        expect(flat.getPixel(-64, 0), 100);
      });

      test('wraps y coordinate with mask', () {
        final data = Uint8List(4096);
        data[0] = 100;

        final flat = Flat(data);

        expect(flat.getPixel(0, 64), 100);
        expect(flat.getPixel(0, 128), 100);
        expect(flat.getPixel(0, -64), 100);
      });

      test('handles all corner pixels', () {
        final data = Uint8List(4096);
        data[0] = 1;
        data[63] = 2;
        data[64 * 63] = 3;
        data[64 * 63 + 63] = 4;

        final flat = Flat(data);

        expect(flat.getPixel(0, 0), 1);
        expect(flat.getPixel(63, 0), 2);
        expect(flat.getPixel(0, 63), 3);
        expect(flat.getPixel(63, 63), 4);
      });

      test('handles center pixel', () {
        final data = Uint8List(4096);
        data[32 * 64 + 32] = 128;

        final flat = Flat(data);

        expect(flat.getPixel(32, 32), 128);
      });
    });

    group('data', () {
      test('returns underlying data', () {
        final data = Uint8List(4096);
        for (var i = 0; i < 4096; i++) {
          data[i] = i & 0xFF;
        }

        final flat = Flat(data);

        expect(flat.data.length, 4096);
        expect(flat.data[0], 0);
        expect(flat.data[255], 255);
      });
    });
  });
}
