import 'dart:typed_data';

abstract final class _WadConstants {
  static const int lumpNameLength = 8;
}

enum WadType {
  iwad,
  pwad,
}

class WadHeader {

  const WadHeader({
    required this.type,
    required this.numLumps,
    required this.infoTableOffset,
  });

  factory WadHeader.parse(ByteData data) {
    final id = String.fromCharCodes([
      data.getUint8(0),
      data.getUint8(1),
      data.getUint8(2),
      data.getUint8(3),
    ]);

    final WadType type;
    if (id == 'IWAD') {
      type = WadType.iwad;
    } else if (id == 'PWAD') {
      type = WadType.pwad;
    } else {
      throw FormatException('Invalid WAD identification: $id');
    }

    return WadHeader(
      type: type,
      numLumps: data.getInt32(4, Endian.little),
      infoTableOffset: data.getInt32(8, Endian.little),
    );
  }
  final WadType type;
  final int numLumps;
  final int infoTableOffset;
}

class LumpInfo {

  const LumpInfo({
    required this.name,
    required this.position,
    required this.size,
    required this.fileIndex,
  });
  final String name;
  final int position;
  final int size;
  final int fileIndex;
}

class WadReader {

  WadReader(this._data);
  final ByteData _data;
  int position = 0;

  int get length => _data.lengthInBytes;

  int readInt8() {
    final value = _data.getInt8(position);
    position += 1;
    return value;
  }

  int readUint8() {
    final value = _data.getUint8(position);
    position += 1;
    return value;
  }

  int readInt16() {
    final value = _data.getInt16(position, Endian.little);
    position += 2;
    return value;
  }

  int readUint16() {
    final value = _data.getUint16(position, Endian.little);
    position += 2;
    return value;
  }

  int readInt32() {
    final value = _data.getInt32(position, Endian.little);
    position += 4;
    return value;
  }

  int readUint32() {
    final value = _data.getUint32(position, Endian.little);
    position += 4;
    return value;
  }

  String readString(int length) {
    final bytes = <int>[];
    for (var i = 0; i < length; i++) {
      final byte = _data.getUint8(position + i);
      if (byte == 0) break;
      bytes.add(byte);
    }
    position += length;
    return String.fromCharCodes(bytes).toUpperCase();
  }

  Uint8List readBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _data.getUint8(position + i);
    }
    position += length;
    return bytes;
  }

  void skip(int count) {
    position += count;
  }
}

class WadFile {

  WadFile._({
    required Uint8List bytes,
    required this.header,
    required this.lumps,
    required this.fileIndex,
  }) : _bytes = bytes;

  factory WadFile.parse(Uint8List bytes, {int fileIndex = 0}) {
    final data = ByteData.sublistView(bytes);
    final header = WadHeader.parse(data);

    final lumps = <LumpInfo>[];
    final reader = WadReader(data)
      ..position = header.infoTableOffset;

    for (var i = 0; i < header.numLumps; i++) {
      final position = reader.readInt32();
      final size = reader.readInt32();
      final name = reader.readString(_WadConstants.lumpNameLength);

      lumps.add(LumpInfo(
        name: name,
        position: position,
        size: size,
        fileIndex: fileIndex,
      ),);
    }

    return WadFile._(
      bytes: bytes,
      header: header,
      lumps: lumps,
      fileIndex: fileIndex,
    );
  }
  final Uint8List _bytes;
  final WadHeader header;
  final List<LumpInfo> lumps;
  final int fileIndex;

  Uint8List readLump(int index) {
    if (index < 0 || index >= lumps.length) {
      throw RangeError.index(index, lumps, 'index');
    }

    final lump = lumps[index];
    return Uint8List.sublistView(_bytes, lump.position, lump.position + lump.size);
  }

  Uint8List readLumpByName(String name) {
    final index = getLumpIndex(name);
    if (index == -1) {
      throw ArgumentError('Lump not found: $name');
    }
    return readLump(index);
  }

  int getLumpIndex(String name) {
    final upperName = name.toUpperCase();
    for (var i = lumps.length - 1; i >= 0; i--) {
      if (lumps[i].name == upperName) {
        return i;
      }
    }
    return -1;
  }

  bool hasLump(String name) => getLumpIndex(name) != -1;

  int get numLumps => lumps.length;
}

class WadManager {
  final List<WadFile> _wadFiles = [];
  final List<LumpInfo> _allLumps = [];
  final Map<int, Uint8List?> _cache = {};

  void addWad(Uint8List bytes) {
    final fileIndex = _wadFiles.length;
    final wad = WadFile.parse(bytes, fileIndex: fileIndex);
    _wadFiles.add(wad);

    for (final lump in wad.lumps) {
      _allLumps.add(lump);
    }
  }

  int get numLumps => _allLumps.length;

  int checkNumForName(String name) {
    final upperName = name.toUpperCase();
    for (var i = _allLumps.length - 1; i >= 0; i--) {
      if (_allLumps[i].name == upperName) {
        return i;
      }
    }
    return -1;
  }

  int getNumForName(String name) {
    final index = checkNumForName(name);
    if (index == -1) {
      throw ArgumentError('W_GetNumForName: $name not found!');
    }
    return index;
  }

  int lumpLength(int lump) {
    if (lump < 0 || lump >= _allLumps.length) {
      throw RangeError('W_LumpLength: $lump >= numLumps');
    }
    return _allLumps[lump].size;
  }

  String lumpName(int lump) {
    if (lump < 0 || lump >= _allLumps.length) {
      throw RangeError.index(lump, _allLumps, 'lump');
    }
    return _allLumps[lump].name;
  }

  Uint8List readLump(int lump) {
    if (lump < 0 || lump >= _allLumps.length) {
      throw RangeError('W_ReadLump: $lump >= numLumps');
    }

    final info = _allLumps[lump];
    final wad = _wadFiles[info.fileIndex];
    final wadLumpIndex = wad.lumps.indexWhere(
      (l) => l.position == info.position && l.size == info.size,
    );

    return wad.readLump(wadLumpIndex);
  }

  Uint8List cacheLumpNum(int lump) {
    if (_cache.containsKey(lump)) {
      final cached = _cache[lump];
      if (cached != null) {
        return cached;
      }
    }

    final data = readLump(lump);
    _cache[lump] = data;
    return data;
  }

  Uint8List cacheLumpName(String name) {
    return cacheLumpNum(getNumForName(name));
  }

  void clearCache() {
    _cache.clear();
  }

  LumpInfo getLumpInfo(int lump) {
    if (lump < 0 || lump >= _allLumps.length) {
      throw RangeError.index(lump, _allLumps, 'lump');
    }
    return _allLumps[lump];
  }
}
