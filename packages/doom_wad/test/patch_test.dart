import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

Uint8List _createPatch({
  required int width,
  required int height,
  int leftOffset = 0,
  int topOffset = 0,
  List<List<(int topDelta, List<int> pixels)>>? columns,
}) {
  final headerSize = 8 + width * 4;
  final columnData = <List<int>>[];
  final columnOffsets = <int>[];

  var currentOffset = headerSize;

  for (var x = 0; x < width; x++) {
    columnOffsets.add(currentOffset);
    final posts = columns != null && x < columns.length ? columns[x] : <(int, List<int>)>[];

    final colBytes = <int>[];
    for (final (topDelta, pixels) in posts) {
      colBytes
        ..add(topDelta)
        ..add(pixels.length)
        ..add(0)
        ..addAll(pixels)
        ..add(0);
    }
    colBytes.add(255);

    columnData.add(colBytes);
    currentOffset += colBytes.length;
  }

  final bytes = ByteData(currentOffset);
  bytes
    ..setInt16(0, width, Endian.little)
    ..setInt16(2, height, Endian.little)
    ..setInt16(4, leftOffset, Endian.little)
    ..setInt16(6, topOffset, Endian.little);

  for (var x = 0; x < width; x++) {
    bytes.setInt32(8 + x * 4, columnOffsets[x], Endian.little);
  }

  var offset = headerSize;
  for (final colBytes in columnData) {
    for (final b in colBytes) {
      bytes.setUint8(offset++, b);
    }
  }

  return Uint8List.view(bytes.buffer);
}

void main() {
  group('PatchHeader', () {
    test('stores dimensions and offsets', () {
      const header = PatchHeader(
        width: 64,
        height: 128,
        leftOffset: 32,
        topOffset: 100,
      );

      expect(header.width, 64);
      expect(header.height, 128);
      expect(header.leftOffset, 32);
      expect(header.topOffset, 100);
    });
  });

  group('PatchColumn', () {
    test('stores topDelta and pixels', () {
      final pixels = Uint8List.fromList([1, 2, 3, 4]);
      final column = PatchColumn(topDelta: 10, pixels: pixels);

      expect(column.topDelta, 10);
      expect(column.pixels, [1, 2, 3, 4]);
    });
  });

  group('Patch', () {
    test('parses minimal 1x1 patch', () {
      final data = _createPatch(
        width: 1,
        height: 1,
        columns: [
          [(0, [42])],
        ],
      );

      final patch = Patch.parse(data);

      expect(patch.width, 1);
      expect(patch.height, 1);
      expect(patch.leftOffset, 0);
      expect(patch.topOffset, 0);
      expect(patch.columns.length, 1);
      expect(patch.columns[0].length, 1);
      expect(patch.columns[0][0].topDelta, 0);
      expect(patch.columns[0][0].pixels, [42]);
    });

    test('parses header values', () {
      final data = _createPatch(
        width: 32,
        height: 64,
        leftOffset: 16,
        topOffset: 48,
      );

      final patch = Patch.parse(data);

      expect(patch.header.width, 32);
      expect(patch.header.height, 64);
      expect(patch.header.leftOffset, 16);
      expect(patch.header.topOffset, 48);
    });

    test('width getter returns header width', () {
      final data = _createPatch(width: 50, height: 100);
      final patch = Patch.parse(data);

      expect(patch.width, 50);
    });

    test('height getter returns header height', () {
      final data = _createPatch(width: 50, height: 100);
      final patch = Patch.parse(data);

      expect(patch.height, 100);
    });

    test('leftOffset getter returns header leftOffset', () {
      final data = _createPatch(width: 10, height: 10, leftOffset: 5);
      final patch = Patch.parse(data);

      expect(patch.leftOffset, 5);
    });

    test('topOffset getter returns header topOffset', () {
      final data = _createPatch(width: 10, height: 10, topOffset: 7);
      final patch = Patch.parse(data);

      expect(patch.topOffset, 7);
    });

    test('parses multiple columns', () {
      final data = _createPatch(
        width: 3,
        height: 10,
        columns: [
          [(0, [1])],
          [(0, [2])],
          [(0, [3])],
        ],
      );

      final patch = Patch.parse(data);

      expect(patch.columns.length, 3);
      expect(patch.columns[0][0].pixels[0], 1);
      expect(patch.columns[1][0].pixels[0], 2);
      expect(patch.columns[2][0].pixels[0], 3);
    });

    test('parses multiple posts per column', () {
      final data = _createPatch(
        width: 1,
        height: 20,
        columns: [
          [
            (0, [10, 11, 12]),
            (10, [20, 21]),
          ],
        ],
      );

      final patch = Patch.parse(data);

      expect(patch.columns[0].length, 2);
      expect(patch.columns[0][0].topDelta, 0);
      expect(patch.columns[0][0].pixels, [10, 11, 12]);
      expect(patch.columns[0][1].topDelta, 10);
      expect(patch.columns[0][1].pixels, [20, 21]);
    });

    test('parses empty columns', () {
      final data = _createPatch(
        width: 3,
        height: 10,
        columns: [
          [(0, [1])],
          [],
          [(0, [3])],
        ],
      );

      final patch = Patch.parse(data);

      expect(patch.columns[0].length, 1);
      expect(patch.columns[1].length, 0);
      expect(patch.columns[2].length, 1);
    });

    test('toIndexed creates indexed image', () {
      final data = _createPatch(
        width: 2,
        height: 3,
        columns: [
          [(0, [1, 2, 3])],
          [(0, [4, 5, 6])],
        ],
      );

      final patch = Patch.parse(data);
      final indexed = patch.toIndexed();

      expect(indexed.length, 6);
      expect(indexed[0], 1);
      expect(indexed[1], 4);
      expect(indexed[2], 2);
      expect(indexed[3], 5);
      expect(indexed[4], 3);
      expect(indexed[5], 6);
    });

    test('toIndexed handles sparse posts', () {
      final data = _createPatch(
        width: 1,
        height: 5,
        columns: [
          [(2, [100, 101])],
        ],
      );

      final patch = Patch.parse(data);
      final indexed = patch.toIndexed();

      expect(indexed[0], 0);
      expect(indexed[1], 0);
      expect(indexed[2], 100);
      expect(indexed[3], 101);
      expect(indexed[4], 0);
    });

    test('toIndexedWithTransparency fills with transparent index', () {
      final data = _createPatch(
        width: 1,
        height: 5,
        columns: [
          [(2, [100, 101])],
        ],
      );

      final patch = Patch.parse(data);
      final indexed = patch.toIndexedWithTransparency(255);

      expect(indexed[0], 255);
      expect(indexed[1], 255);
      expect(indexed[2], 100);
      expect(indexed[3], 101);
      expect(indexed[4], 255);
    });

    test('toIndexedWithTransparency uses custom transparent index', () {
      final data = _createPatch(
        width: 1,
        height: 3,
        columns: [
          [(1, [50])],
        ],
      );

      final patch = Patch.parse(data);
      final indexed = patch.toIndexedWithTransparency(247);

      expect(indexed[0], 247);
      expect(indexed[1], 50);
      expect(indexed[2], 247);
    });

    test('handles negative offsets', () {
      final data = _createPatch(
        width: 4,
        height: 8,
        leftOffset: -2,
        topOffset: -4,
      );

      final patch = Patch.parse(data);

      expect(patch.leftOffset, -2);
      expect(patch.topOffset, -4);
    });

    test('const constructor creates valid patch', () {
      const header = PatchHeader(
        width: 10,
        height: 20,
        leftOffset: 5,
        topOffset: 10,
      );
      final columns = <List<PatchColumn>>[
        [PatchColumn(topDelta: 0, pixels: Uint8List.fromList([1, 2, 3]))],
      ];

      final patch = Patch(header: header, columns: columns);

      expect(patch.width, 10);
      expect(patch.height, 20);
      expect(patch.columns.length, 1);
    });
  });
}
