import 'dart:typed_data';

import 'package:doom_wad/doom_wad.dart';
import 'package:test/test.dart';

Uint8List _createMinimalWad({
  String type = 'IWAD',
  List<(String name, Uint8List data)> lumps = const [],
}) {
  final lumpData = <int>[];
  final lumpOffsets = <int>[];
  const headerSize = 12;

  var currentOffset = headerSize;
  for (final (_, data) in lumps) {
    lumpOffsets.add(currentOffset);
    lumpData.addAll(data);
    currentOffset += data.length;
  }

  final directoryOffset = currentOffset;
  final directory = <int>[];

  for (var i = 0; i < lumps.length; i++) {
    final (name, data) = lumps[i];
    directory
      ..addAll(_int32ToBytes(lumpOffsets[i]))
      ..addAll(_int32ToBytes(data.length));
    final nameBytes = name.codeUnits;
    for (var j = 0; j < 8; j++) {
      directory.add(j < nameBytes.length ? nameBytes[j] : 0);
    }
  }

  final wadBytes = <int>[
    ...type.codeUnits,
    ..._int32ToBytes(lumps.length),
    ..._int32ToBytes(directoryOffset),
    ...lumpData,
    ...directory,
  ];

  return Uint8List.fromList(wadBytes);
}

List<int> _int32ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}

void main() {
  group('WadType', () {
    test('has iwad and pwad values', () {
      expect(WadType.values, contains(WadType.iwad));
      expect(WadType.values, contains(WadType.pwad));
    });
  });

  group('WadHeader', () {
    test('parses IWAD header', () {
      final data = ByteData(12)
        ..setUint8(0, 73) // I
        ..setUint8(1, 87) // W
        ..setUint8(2, 65) // A
        ..setUint8(3, 68) // D
        ..setInt32(4, 100, Endian.little)
        ..setInt32(8, 1000, Endian.little);

      final header = WadHeader.parse(data);

      expect(header.type, WadType.iwad);
      expect(header.numLumps, 100);
      expect(header.infoTableOffset, 1000);
    });

    test('parses PWAD header', () {
      final data = ByteData(12)
        ..setUint8(0, 80) // P
        ..setUint8(1, 87) // W
        ..setUint8(2, 65) // A
        ..setUint8(3, 68) // D
        ..setInt32(4, 50, Endian.little)
        ..setInt32(8, 500, Endian.little);

      final header = WadHeader.parse(data);

      expect(header.type, WadType.pwad);
      expect(header.numLumps, 50);
      expect(header.infoTableOffset, 500);
    });

    test('throws on invalid WAD identification', () {
      final data = ByteData(12)
        ..setUint8(0, 88) // X
        ..setUint8(1, 87) // W
        ..setUint8(2, 65) // A
        ..setUint8(3, 68); // D

      expect(
        () => WadHeader.parse(data),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('WadReader', () {
    late WadReader reader;
    late ByteData data;

    setUp(() {
      data = ByteData(32);
      reader = WadReader(data);
    });

    test('starts at position 0', () {
      expect(reader.position, 0);
    });

    test('reports correct length', () {
      expect(reader.length, 32);
    });

    test('readInt8 reads signed byte and advances position', () {
      data.setInt8(0, -42);
      expect(reader.readInt8(), -42);
      expect(reader.position, 1);
    });

    test('readUint8 reads unsigned byte and advances position', () {
      data.setUint8(0, 200);
      expect(reader.readUint8(), 200);
      expect(reader.position, 1);
    });

    test('readInt16 reads signed 16-bit little-endian', () {
      data.setInt16(0, -1000, Endian.little);
      expect(reader.readInt16(), -1000);
      expect(reader.position, 2);
    });

    test('readUint16 reads unsigned 16-bit little-endian', () {
      data.setUint16(0, 50000, Endian.little);
      expect(reader.readUint16(), 50000);
      expect(reader.position, 2);
    });

    test('readInt32 reads signed 32-bit little-endian', () {
      data.setInt32(0, -100000, Endian.little);
      expect(reader.readInt32(), -100000);
      expect(reader.position, 4);
    });

    test('readUint32 reads unsigned 32-bit little-endian', () {
      data.setUint32(0, 3000000000, Endian.little);
      expect(reader.readUint32(), 3000000000);
      expect(reader.position, 4);
    });

    test('readString reads null-terminated string', () {
      data
        ..setUint8(0, 84) // T
        ..setUint8(1, 69) // E
        ..setUint8(2, 83) // S
        ..setUint8(3, 84) // T
        ..setUint8(4, 0); // null

      expect(reader.readString(8), 'TEST');
      expect(reader.position, 8);
    });

    test('readString converts to uppercase', () {
      data
        ..setUint8(0, 116) // t
        ..setUint8(1, 101) // e
        ..setUint8(2, 115) // s
        ..setUint8(3, 116); // t

      expect(reader.readString(4), 'TEST');
    });

    test('readBytes reads specified number of bytes', () {
      data
        ..setUint8(0, 1)
        ..setUint8(1, 2)
        ..setUint8(2, 3)
        ..setUint8(3, 4);

      final bytes = reader.readBytes(4);
      expect(bytes, [1, 2, 3, 4]);
      expect(reader.position, 4);
    });

    test('skip advances position', () {
      reader.skip(10);
      expect(reader.position, 10);
    });
  });

  group('LumpInfo', () {
    test('stores lump metadata', () {
      const info = LumpInfo(
        name: 'TESTLUMP',
        position: 1000,
        size: 500,
        fileIndex: 0,
      );

      expect(info.name, 'TESTLUMP');
      expect(info.position, 1000);
      expect(info.size, 500);
      expect(info.fileIndex, 0);
    });
  });

  group('WadFile', () {
    test('parses minimal IWAD with no lumps', () {
      final bytes = _createMinimalWad();

      final wad = WadFile.parse(bytes);

      expect(wad.header.type, WadType.iwad);
      expect(wad.numLumps, 0);
      expect(wad.lumps, isEmpty);
    });

    test('parses IWAD with lumps', () {
      final lumpData = Uint8List.fromList([1, 2, 3, 4, 5]);
      final bytes = _createMinimalWad(
        lumps: [('TESTLUMP', lumpData)],
      );

      final wad = WadFile.parse(bytes);

      expect(wad.numLumps, 1);
      expect(wad.lumps[0].name, 'TESTLUMP');
      expect(wad.lumps[0].size, 5);
    });

    test('readLump returns correct data', () {
      final lumpData = Uint8List.fromList([10, 20, 30, 40, 50]);
      final bytes = _createMinimalWad(
        lumps: [('DATA', lumpData)],
      );

      final wad = WadFile.parse(bytes);
      final result = wad.readLump(0);

      expect(result, [10, 20, 30, 40, 50]);
    });

    test('readLump throws on invalid index', () {
      final bytes = _createMinimalWad();
      final wad = WadFile.parse(bytes);

      expect(() => wad.readLump(0), throwsA(isA<RangeError>()));
      expect(() => wad.readLump(-1), throwsA(isA<RangeError>()));
    });

    test('readLumpByName returns correct data', () {
      final lumpData = Uint8List.fromList([1, 2, 3]);
      final bytes = _createMinimalWad(
        lumps: [('MYLUMP', lumpData)],
      );

      final wad = WadFile.parse(bytes);
      final result = wad.readLumpByName('MYLUMP');

      expect(result, [1, 2, 3]);
    });

    test('readLumpByName throws on missing lump', () {
      final bytes = _createMinimalWad();
      final wad = WadFile.parse(bytes);

      expect(
        () => wad.readLumpByName('MISSING'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('getLumpIndex returns last occurrence', () {
      final bytes = _createMinimalWad(
        lumps: [
          ('DUPE', Uint8List.fromList([1])),
          ('OTHER', Uint8List.fromList([2])),
          ('DUPE', Uint8List.fromList([3])),
        ],
      );

      final wad = WadFile.parse(bytes);

      expect(wad.getLumpIndex('DUPE'), 2);
    });

    test('getLumpIndex is case-insensitive', () {
      final bytes = _createMinimalWad(
        lumps: [('TESTLUMP', Uint8List.fromList([1]))],
      );

      final wad = WadFile.parse(bytes);

      expect(wad.getLumpIndex('testlump'), 0);
      expect(wad.getLumpIndex('TESTLUMP'), 0);
      expect(wad.getLumpIndex('TestLump'), 0);
    });

    test('getLumpIndex returns -1 for missing lump', () {
      final bytes = _createMinimalWad();
      final wad = WadFile.parse(bytes);

      expect(wad.getLumpIndex('MISSING'), -1);
    });

    test('hasLump returns correct result', () {
      final bytes = _createMinimalWad(
        lumps: [('EXISTS', Uint8List.fromList([1]))],
      );

      final wad = WadFile.parse(bytes);

      expect(wad.hasLump('EXISTS'), isTrue);
      expect(wad.hasLump('MISSING'), isFalse);
    });

    test('parses PWAD', () {
      final bytes = _createMinimalWad(type: 'PWAD');

      final wad = WadFile.parse(bytes);

      expect(wad.header.type, WadType.pwad);
    });

    test('fileIndex is stored correctly', () {
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([1]))],
      );

      final wad = WadFile.parse(bytes, fileIndex: 5);

      expect(wad.fileIndex, 5);
      expect(wad.lumps[0].fileIndex, 5);
    });
  });

  group('WadManager', () {
    test('starts with no lumps', () {
      final manager = WadManager();
      expect(manager.numLumps, 0);
    });

    test('addWad adds lumps', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [
          ('LUMP1', Uint8List.fromList([1])),
          ('LUMP2', Uint8List.fromList([2])),
        ],
      );

      manager.addWad(bytes);

      expect(manager.numLumps, 2);
    });

    test('addWad handles multiple WADs', () {
      final manager = WadManager();
      final wad1 = _createMinimalWad(
        lumps: [('LUMP1', Uint8List.fromList([1]))],
      );
      final wad2 = _createMinimalWad(
        type: 'PWAD',
        lumps: [('LUMP2', Uint8List.fromList([2]))],
      );

      manager
        ..addWad(wad1)
        ..addWad(wad2);

      expect(manager.numLumps, 2);
    });

    test('checkNumForName returns index', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [
          ('FIRST', Uint8List.fromList([1])),
          ('SECOND', Uint8List.fromList([2])),
        ],
      );

      manager.addWad(bytes);

      expect(manager.checkNumForName('FIRST'), 0);
      expect(manager.checkNumForName('SECOND'), 1);
    });

    test('checkNumForName returns -1 for missing', () {
      final manager = WadManager();
      expect(manager.checkNumForName('MISSING'), -1);
    });

    test('checkNumForName returns last occurrence', () {
      final manager = WadManager();
      final wad1 = _createMinimalWad(
        lumps: [('DUPE', Uint8List.fromList([1]))],
      );
      final wad2 = _createMinimalWad(
        type: 'PWAD',
        lumps: [('DUPE', Uint8List.fromList([2]))],
      );

      manager
        ..addWad(wad1)
        ..addWad(wad2);

      expect(manager.checkNumForName('DUPE'), 1);
    });

    test('getNumForName returns index', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([1]))],
      );

      manager.addWad(bytes);

      expect(manager.getNumForName('LUMP'), 0);
    });

    test('getNumForName throws on missing lump', () {
      final manager = WadManager();

      expect(
        () => manager.getNumForName('MISSING'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('lumpLength returns size', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([1, 2, 3, 4, 5]))],
      );

      manager.addWad(bytes);

      expect(manager.lumpLength(0), 5);
    });

    test('lumpLength throws on invalid index', () {
      final manager = WadManager();

      expect(() => manager.lumpLength(0), throwsA(isA<RangeError>()));
    });

    test('lumpName returns name', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('TESTNAME', Uint8List.fromList([1]))],
      );

      manager.addWad(bytes);

      expect(manager.lumpName(0), 'TESTNAME');
    });

    test('readLump returns data', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([10, 20, 30]))],
      );

      manager.addWad(bytes);

      expect(manager.readLump(0), [10, 20, 30]);
    });

    test('readLump reads from correct WAD', () {
      final manager = WadManager();
      final wad1 = _createMinimalWad(
        lumps: [('LUMP1', Uint8List.fromList([1, 1, 1]))],
      );
      final wad2 = _createMinimalWad(
        type: 'PWAD',
        lumps: [('LUMP2', Uint8List.fromList([2, 2, 2]))],
      );

      manager
        ..addWad(wad1)
        ..addWad(wad2);

      expect(manager.readLump(0), [1, 1, 1]);
      expect(manager.readLump(1), [2, 2, 2]);
    });

    test('cacheLumpNum caches data', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([1, 2, 3]))],
      );

      manager.addWad(bytes);

      final first = manager.cacheLumpNum(0);
      final second = manager.cacheLumpNum(0);

      expect(identical(first, second), isTrue);
    });

    test('cacheLumpName returns cached data', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('CACHED', Uint8List.fromList([4, 5, 6]))],
      );

      manager.addWad(bytes);

      expect(manager.cacheLumpName('CACHED'), [4, 5, 6]);
    });

    test('clearCache clears cached data', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('LUMP', Uint8List.fromList([1]))],
      );

      manager.addWad(bytes);
      final first = manager.cacheLumpNum(0);
      manager.clearCache();
      final second = manager.cacheLumpNum(0);

      expect(identical(first, second), isFalse);
    });

    test('getLumpInfo returns info', () {
      final manager = WadManager();
      final bytes = _createMinimalWad(
        lumps: [('INFO', Uint8List.fromList([1, 2]))],
      );

      manager.addWad(bytes);
      final info = manager.getLumpInfo(0);

      expect(info.name, 'INFO');
      expect(info.size, 2);
    });
  });
}
