import 'dart:typed_data';

class PatchHeader {

  const PatchHeader({
    required this.width,
    required this.height,
    required this.leftOffset,
    required this.topOffset,
  });
  final int width;
  final int height;
  final int leftOffset;
  final int topOffset;
}

class PatchColumn {

  const PatchColumn({
    required this.topDelta,
    required this.pixels,
  });
  final int topDelta;
  final Uint8List pixels;
}

class Patch {

  const Patch({
    required this.header,
    required this.columns,
  });

  factory Patch.parse(Uint8List data) {
    final byteData = ByteData.sublistView(data);

    final width = byteData.getInt16(0, Endian.little);
    final height = byteData.getInt16(2, Endian.little);
    final leftOffset = byteData.getInt16(4, Endian.little);
    final topOffset = byteData.getInt16(6, Endian.little);

    final header = PatchHeader(
      width: width,
      height: height,
      leftOffset: leftOffset,
      topOffset: topOffset,
    );

    final columnOffsets = <int>[];
    for (var i = 0; i < width; i++) {
      columnOffsets.add(byteData.getInt32(8 + i * 4, Endian.little));
    }

    final columns = <List<PatchColumn>>[];
    for (var x = 0; x < width; x++) {
      final columnPosts = <PatchColumn>[];
      var offset = columnOffsets[x];

      while (true) {
        final topDelta = data[offset];
        if (topDelta == 255) break;

        final length = data[offset + 1];
        final pixels = Uint8List.sublistView(data, offset + 3, offset + 3 + length);

        columnPosts.add(PatchColumn(
          topDelta: topDelta,
          pixels: pixels,
        ),);

        offset += length + 4;
      }

      columns.add(columnPosts);
    }

    return Patch(header: header, columns: columns);
  }
  final PatchHeader header;
  final List<List<PatchColumn>> columns;

  int get width => header.width;
  int get height => header.height;
  int get leftOffset => header.leftOffset;
  int get topOffset => header.topOffset;

  Uint8List toIndexed() {
    final result = Uint8List(width * height);

    for (var x = 0; x < width; x++) {
      for (final post in columns[x]) {
        var y = post.topDelta;
        for (final pixel in post.pixels) {
          if (y < height) {
            result[y * width + x] = pixel;
          }
          y++;
        }
      }
    }

    return result;
  }

  Uint8List toIndexedWithTransparency(int transparentIndex) {
    final result = Uint8List(width * height);
    result.fillRange(0, result.length, transparentIndex);

    for (var x = 0; x < width; x++) {
      for (final post in columns[x]) {
        var y = post.topDelta;
        for (final pixel in post.pixels) {
          if (y < height) {
            result[y * width + x] = pixel;
          }
          y++;
        }
      }
    }

    return result;
  }
}

class Flat {

  Flat(this.data) {
    if (data.length != dataSize) {
      throw ArgumentError('Flat must have $dataSize bytes');
    }
  }
  static const int size = 64;
  static const int dataSize = size * size;

  final Uint8List data;

  int getPixel(int x, int y) => data[(y & 63) * size + (x & 63)];
}
