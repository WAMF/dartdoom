import 'dart:convert';
import 'dart:typed_data';

import 'package:doom_core/src/serialization/game_serializer.dart';

/// JSON serializer for human-readable save files.
///
/// Unlike the binary serializer, this format is not compatible with original
/// DOOM save files, but provides a readable format for debugging and modding.
class JsonSerializer implements GameSerializer {
  @override
  GameDataWriter createWriter() => JsonDataWriter();

  @override
  GameDataReader createReader(Object data) {
    if (data is Uint8List) {
      final jsonString = utf8.decode(data);
      return JsonDataReader(jsonString);
    } else if (data is String) {
      return JsonDataReader(data);
    }
    throw ArgumentError('JsonSerializer expects Uint8List or String data');
  }

  @override
  String get formatExtension => '.json';

  @override
  String get formatName => 'JSON';
}

/// JSON writer implementation.
///
/// Writes data as a sequence of named fields that can be converted to JSON.
/// To maintain compatibility with the binary interface, values are written
/// sequentially and stored in a list.
class JsonDataWriter implements GameDataWriter {
  final List<dynamic> _values = [];

  @override
  void writeByte(int value) {
    _values.add(value & 0xff);
  }

  @override
  void writeShort(int value) {
    // Store as signed 16-bit
    final signed = value.toSigned(16);
    _values.add(signed);
  }

  @override
  void writeInt(int value) {
    // Store as signed 32-bit
    final signed = value.toSigned(32);
    _values.add(signed);
  }

  @override
  void writeFixed(int value) {
    // Store fixed-point as a map with both raw and decimal representation
    final decimal = value / 65536.0;
    _values.add({'raw': value, 'decimal': decimal});
  }

  @override
  void writeString(String value, int maxLength) {
    // Truncate to maxLength and remove null terminators
    var str = value;
    if (str.length > maxLength) {
      str = str.substring(0, maxLength);
    }
    // Remove any embedded nulls
    final nullIndex = str.indexOf('\x00');
    if (nullIndex >= 0) {
      str = str.substring(0, nullIndex);
    }
    _values.add(str);
  }

  @override
  void writeBytes(List<int> bytes) {
    // Store as base64 for compactness
    _values.add({'bytes': base64Encode(bytes)});
  }

  @override
  void writeBool({required bool value}) {
    _values.add(value);
  }

  @override
  Uint8List toBytes() {
    final jsonString = toText();
    return Uint8List.fromList(utf8.encode(jsonString));
  }

  @override
  String toText() {
    return const JsonEncoder.withIndent('  ').convert({'data': _values});
  }

  @override
  int get position => _values.length;

  @override
  void pad() {
    // JSON doesn't need padding, but we add a marker for compatibility
    _values.add({'_pad': true});
  }
}

/// JSON reader implementation.
class JsonDataReader implements GameDataReader {
  JsonDataReader(String jsonString) {
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    _values = (decoded['data'] as List).cast<dynamic>();
  }

  late final List<dynamic> _values;
  int _position = 0;

  @override
  int readByte() {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is int) {
      return value & 0xff;
    }
    throw StateError('Expected int at position ${_position - 1}, got $value');
  }

  @override
  int readShort() {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is int) {
      return value.toSigned(16);
    }
    throw StateError('Expected int at position ${_position - 1}, got $value');
  }

  @override
  int readInt() {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is int) {
      return value.toSigned(32);
    }
    throw StateError('Expected int at position ${_position - 1}, got $value');
  }

  @override
  int readFixed() {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is Map) {
      return (value['raw'] as num).toInt();
    } else if (value is int) {
      return value;
    }
    throw StateError(
      'Expected fixed-point map at position ${_position - 1}, got $value',
    );
  }

  @override
  String readString(int maxLength) {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is String) {
      return value.length > maxLength ? value.substring(0, maxLength) : value;
    }
    throw StateError(
      'Expected string at position ${_position - 1}, got $value',
    );
  }

  @override
  List<int> readBytes(int count) {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is Map && value.containsKey('bytes')) {
      return base64Decode(value['bytes'] as String);
    }
    throw StateError(
      'Expected bytes map at position ${_position - 1}, got $value',
    );
  }

  @override
  bool readBool() {
    if (_position >= _values.length) {
      throw StateError('Attempt to read past end of data');
    }
    final value = _values[_position++];
    if (value is bool) {
      return value;
    } else if (value is int) {
      return value != 0;
    }
    throw StateError('Expected bool at position ${_position - 1}, got $value');
  }

  @override
  bool get isAtEnd => _position >= _values.length;

  @override
  int get position => _position;

  @override
  void skipPadding() {
    // Skip padding markers
    if (_position < _values.length) {
      final value = _values[_position];
      if (value is Map && value.containsKey('_pad')) {
        _position++;
      }
    }
  }
}
