import 'dart:typed_data';

import 'package:doom_core/src/serialization/game_serializer.dart';

/// Binary serializer matching the original DOOM save/demo format.
///
/// Uses little-endian byte order for multi-byte values.
class BinarySerializer implements GameSerializer {
  @override
  GameDataWriter createWriter() => BinaryDataWriter();

  @override
  GameDataReader createReader(Object data) {
    if (data is Uint8List) {
      return BinaryDataReader(data);
    }
    throw ArgumentError('BinarySerializer requires Uint8List data');
  }

  @override
  String get formatExtension => '.dsg';

  @override
  String get formatName => 'Binary (Original DOOM)';
}

/// Binary writer implementation.
class BinaryDataWriter implements GameDataWriter {
  BinaryDataWriter([int initialCapacity = _initialCapacity])
      : _data = ByteData(initialCapacity);

  static const int _initialCapacity = 0x20000; // 128KB default

  ByteData _data;
  int _position = 0;

  void _ensureCapacity(int bytesNeeded) {
    final required = _position + bytesNeeded;
    if (required > _data.lengthInBytes) {
      final newCapacity = (required * 2).clamp(required, required + 0x10000);
      final newData = ByteData(newCapacity);
      for (var i = 0; i < _position; i++) {
        newData.setUint8(i, _data.getUint8(i));
      }
      _data = newData;
    }
  }

  @override
  void writeByte(int value) {
    _ensureCapacity(1);
    _data.setUint8(_position++, value & 0xFF);
  }

  @override
  void writeShort(int value) {
    _ensureCapacity(2);
    _data.setInt16(_position, value, Endian.little);
    _position += 2;
  }

  @override
  void writeInt(int value) {
    _ensureCapacity(4);
    _data.setInt32(_position, value, Endian.little);
    _position += 4;
  }

  @override
  void writeFixed(int value) {
    // Fixed-point stored as 32-bit integer in binary format
    writeInt(value);
  }

  @override
  void writeString(String value, int maxLength) {
    _ensureCapacity(maxLength);
    final bytes = value.codeUnits;
    for (var i = 0; i < maxLength; i++) {
      if (i < bytes.length) {
        _data.setUint8(_position++, bytes[i] & 0xFF);
      } else {
        _data.setUint8(_position++, 0); // Null padding
      }
    }
  }

  @override
  void writeBytes(List<int> bytes) {
    _ensureCapacity(bytes.length);
    for (final b in bytes) {
      _data.setUint8(_position++, b & 0xFF);
    }
  }

  @override
  void writeBool({required bool value}) {
    writeByte(value ? 1 : 0);
  }

  @override
  Uint8List toBytes() {
    return Uint8List.view(_data.buffer, 0, _position);
  }

  @override
  String toText() {
    throw UnsupportedError('Binary format does not support text output');
  }

  @override
  int get position => _position;

  @override
  void pad() {
    // Align to 4-byte boundary (PADSAVEP from original)
    final padding = (4 - (_position & 3)) & 3;
    for (var i = 0; i < padding; i++) {
      writeByte(0);
    }
  }
}

/// Binary reader implementation.
class BinaryDataReader implements GameDataReader {
  BinaryDataReader(this._bytes) : _data = ByteData.view(_bytes.buffer);

  final Uint8List _bytes;
  final ByteData _data;
  int _position = 0;

  @override
  int readByte() {
    if (_position >= _bytes.length) {
      throw StateError('Attempt to read past end of data');
    }
    return _data.getUint8(_position++);
  }

  @override
  int readShort() {
    if (_position + 2 > _bytes.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _data.getInt16(_position, Endian.little);
    _position += 2;
    return value;
  }

  @override
  int readInt() {
    if (_position + 4 > _bytes.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _data.getInt32(_position, Endian.little);
    _position += 4;
    return value;
  }

  @override
  int readFixed() {
    // Fixed-point stored as 32-bit integer
    return readInt();
  }

  @override
  String readString(int maxLength) {
    if (_position + maxLength > _bytes.length) {
      throw StateError('Attempt to read past end of data');
    }

    final chars = <int>[];
    for (var i = 0; i < maxLength; i++) {
      final c = _data.getUint8(_position++);
      if (c == 0) {
        // Skip remaining null bytes
        _position += maxLength - i - 1;
        break;
      }
      chars.add(c);
    }
    return String.fromCharCodes(chars);
  }

  @override
  List<int> readBytes(int count) {
    if (_position + count > _bytes.length) {
      throw StateError('Attempt to read past end of data');
    }

    final result = <int>[];
    for (var i = 0; i < count; i++) {
      result.add(_data.getUint8(_position++));
    }
    return result;
  }

  @override
  bool readBool() {
    return readByte() != 0;
  }

  @override
  bool get isAtEnd => _position >= _bytes.length;

  @override
  int get position => _position;

  @override
  void skipPadding() {
    // Skip to next 4-byte boundary
    final padding = (4 - (_position & 3)) & 3;
    _position += padding;
  }

  /// Peek at the next byte without advancing position.
  int peek() {
    if (_position >= _bytes.length) {
      return -1;
    }
    return _data.getUint8(_position);
  }

  /// Read a signed byte (-128 to 127).
  int readSignedByte() {
    final unsigned = readByte();
    return unsigned < 128 ? unsigned : unsigned - 256;
  }
}
