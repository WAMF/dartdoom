import 'dart:typed_data';

/// Abstract interface for writing game data in a format-agnostic way.
///
/// Implementations can write to binary, JSON, YAML, or other formats.
abstract class GameDataWriter {
  /// Write a single byte (0-255).
  void writeByte(int value);

  /// Write a signed 16-bit integer.
  void writeShort(int value);

  /// Write a signed 32-bit integer.
  void writeInt(int value);

  /// Write a fixed-point value (16.16 format).
  /// Binary format stores as-is; text formats may convert to decimal.
  void writeFixed(int value);

  /// Write a fixed-length string, padded with nulls if shorter.
  void writeString(String value, int maxLength);

  /// Write raw bytes.
  void writeBytes(List<int> bytes);

  /// Write a boolean as a single byte (0 or 1).
  void writeBool({required bool value});

  /// Get the serialized data as bytes (for binary formats).
  Uint8List toBytes();

  /// Get the serialized data as text (for JSON/YAML formats).
  String toText();

  /// Current write position (for binary formats).
  int get position;

  /// Align write position to 4-byte boundary (for binary compatibility).
  void pad();
}

/// Abstract interface for reading game data in a format-agnostic way.
abstract class GameDataReader {
  /// Read a single byte (0-255).
  int readByte();

  /// Read a signed 16-bit integer.
  int readShort();

  /// Read a signed 32-bit integer.
  int readInt();

  /// Read a fixed-point value (16.16 format).
  int readFixed();

  /// Read a fixed-length string, stopping at null terminator.
  String readString(int maxLength);

  /// Read raw bytes.
  List<int> readBytes(int count);

  /// Read a boolean from a single byte.
  bool readBool();

  /// Check if we've reached the end of data.
  bool get isAtEnd;

  /// Current read position (for binary formats).
  int get position;

  /// Skip bytes to align to 4-byte boundary.
  void skipPadding();
}

/// Factory interface for creating readers and writers.
///
/// Each serialization format (binary, JSON, YAML) implements this interface.
abstract class GameSerializer {
  /// Create a new writer for this format.
  GameDataWriter createWriter();

  /// Create a reader from serialized data.
  ///
  /// For binary formats, [data] should be a Uint8List.
  /// For text formats, [data] should be a String.
  GameDataReader createReader(Object data);

  /// File extension for this format (e.g., '.dsg', '.json').
  String get formatExtension;

  /// Human-readable name for this format.
  String get formatName;
}
