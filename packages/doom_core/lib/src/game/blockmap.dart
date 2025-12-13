import 'dart:typed_data';

import 'package:doom_math/doom_math.dart';

abstract final class BlockmapConstants {
  static const int blockSize = 128;
  static const int blockShift = 7;
  static const int blockMask = 127;
  static const int blockFrac = blockSize * Fixed32.fracUnit;
}

class Blockmap {

  factory Blockmap.parse(Uint8List data) {
    final view = ByteData.sublistView(data);
    final originX = view.getInt16(0, Endian.little);
    final originY = view.getInt16(2, Endian.little);
    final columns = view.getUint16(4, Endian.little);
    final rows = view.getUint16(6, Endian.little);

    final blockCount = columns * rows;
    final offsets = <int>[];
    for (var i = 0; i < blockCount; i++) {
      offsets.add(view.getUint16(8 + i * 2, Endian.little));
    }

    final blockLists = <List<int>>[];
    for (var i = 0; i < blockCount; i++) {
      final listStart = offsets[i] * 2;
      final lines = <int>[];

      var pos = listStart;
      if (pos >= data.length) {
        blockLists.add(lines);
        continue;
      }

      final first = view.getInt16(pos, Endian.little);
      if (first == 0) {
        pos += 2;
      }

      while (pos < data.length - 1) {
        final lineNum = view.getInt16(pos, Endian.little);
        if (lineNum == -1) break;
        lines.add(lineNum);
        pos += 2;
      }

      blockLists.add(lines);
    }

    return Blockmap._(
      originX: originX,
      originY: originY,
      columns: columns,
      rows: rows,
      offsets: offsets,
      blockLists: blockLists,
    );
  }
  Blockmap._({
    required this.originX,
    required this.originY,
    required this.columns,
    required this.rows,
    required this.offsets,
    required this.blockLists,
  });

  final int originX;
  final int originY;
  final int columns;
  final int rows;
  final List<int> offsets;
  final List<List<int>> blockLists;

  (int, int) worldToBlock(int x, int y) {
    final blockX = (x - (originX << Fixed32.fracBits)) >> (Fixed32.fracBits + BlockmapConstants.blockShift);
    final blockY = (y - (originY << Fixed32.fracBits)) >> (Fixed32.fracBits + BlockmapConstants.blockShift);
    return (blockX, blockY);
  }

  bool isValidBlock(int blockX, int blockY) {
    return blockX >= 0 && blockX < columns && blockY >= 0 && blockY < rows;
  }

  List<int> getLinesInBlock(int blockX, int blockY) {
    if (!isValidBlock(blockX, blockY)) return const [];
    final index = blockY * columns + blockX;
    return blockLists[index];
  }

  Iterable<int> iterateLines(int x1, int y1, int x2, int y2) sync* {
    final (bx1, by1) = worldToBlock(x1, y1);
    final (bx2, by2) = worldToBlock(x2, y2);

    final minX = bx1 < bx2 ? bx1 : bx2;
    final maxX = bx1 > bx2 ? bx1 : bx2;
    final minY = by1 < by2 ? by1 : by2;
    final maxY = by1 > by2 ? by1 : by2;

    final seen = <int>{};

    for (var by = minY; by <= maxY; by++) {
      for (var bx = minX; bx <= maxX; bx++) {
        if (!isValidBlock(bx, by)) continue;
        for (final lineNum in getLinesInBlock(bx, by)) {
          if (seen.add(lineNum)) {
            yield lineNum;
          }
        }
      }
    }
  }
}
