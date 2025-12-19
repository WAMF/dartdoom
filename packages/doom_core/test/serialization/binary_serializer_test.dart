import 'dart:typed_data';

import 'package:doom_core/src/serialization/binary_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('BinarySerializer', () {
    late BinarySerializer serializer;

    setUp(() {
      serializer = BinarySerializer();
    });

    test('formatExtension returns .dsg', () {
      expect(serializer.formatExtension, equals('.dsg'));
    });

    test('formatName returns Binary', () {
      expect(serializer.formatName, equals('Binary (Original DOOM)'));
    });

    group('BinaryDataWriter', () {
      late BinaryDataWriter writer;

      setUp(() {
        writer = BinaryDataWriter();
      });

      group('writeByte', () {
        test('stores single byte', () {
          writer.writeByte(0x42);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(1));
          expect(bytes[0], equals(0x42));
        });

        test('masks to 8 bits', () {
          writer.writeByte(0x1FF);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
        });

        test('handles min value 0x00', () {
          writer.writeByte(0x00);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
        });

        test('handles max value 0xFF', () {
          writer.writeByte(0xFF);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
        });

        test('handles negative as unsigned', () {
          writer.writeByte(-1);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
        });
      });

      group('writeShort', () {
        test('stores 16-bit little-endian', () {
          writer.writeShort(0x1234);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(2));
          expect(bytes[0], equals(0x34)); // Low byte
          expect(bytes[1], equals(0x12)); // High byte
        });

        test('handles negative values', () {
          writer.writeShort(-1);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
          expect(bytes[1], equals(0xFF));
        });

        test('handles min signed 16-bit (-32768)', () {
          writer.writeShort(-32768);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x80)); // -32768 = 0x8000
        });

        test('handles max signed 16-bit (32767)', () {
          writer.writeShort(32767);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
          expect(bytes[1], equals(0x7F)); // 32767 = 0x7FFF
        });

        test('handles zero', () {
          writer.writeShort(0);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
        });
      });

      group('writeInt', () {
        test('stores 32-bit little-endian', () {
          writer.writeInt(0x12345678);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(4));
          expect(bytes[0], equals(0x78));
          expect(bytes[1], equals(0x56));
          expect(bytes[2], equals(0x34));
          expect(bytes[3], equals(0x12));
        });

        test('handles negative values', () {
          writer.writeInt(-1);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
          expect(bytes[1], equals(0xFF));
          expect(bytes[2], equals(0xFF));
          expect(bytes[3], equals(0xFF));
        });

        test('handles min signed 32-bit (-2147483648)', () {
          writer.writeInt(-2147483648);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
          expect(bytes[2], equals(0x00));
          expect(bytes[3], equals(0x80)); // -2147483648 = 0x80000000
        });

        test('handles max signed 32-bit (2147483647)', () {
          writer.writeInt(2147483647);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
          expect(bytes[1], equals(0xFF));
          expect(bytes[2], equals(0xFF));
          expect(bytes[3], equals(0x7F)); // 2147483647 = 0x7FFFFFFF
        });

        test('handles zero', () {
          writer.writeInt(0);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
          expect(bytes[2], equals(0x00));
          expect(bytes[3], equals(0x00));
        });
      });

      group('writeFixed', () {
        test('stores fixed-point as 32-bit', () {
          // 1.0 in fixed-point = 65536 (FRACUNIT)
          writer.writeFixed(65536);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(4));
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
          expect(bytes[2], equals(0x01));
          expect(bytes[3], equals(0x00));
        });

        test('handles 0.5 in fixed-point (32768)', () {
          writer.writeFixed(32768);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x80));
          expect(bytes[2], equals(0x00));
          expect(bytes[3], equals(0x00));
        });

        test('handles negative fixed-point (-1.0 = -65536)', () {
          writer.writeFixed(-65536);
          final bytes = writer.toBytes();
          // -65536 = 0xFFFF0000 in two's complement
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
          expect(bytes[2], equals(0xFF));
          expect(bytes[3], equals(0xFF));
        });

        test('handles max fixed-point (32767.9999...)', () {
          // Max positive fixed-point is 0x7FFFFFFF
          writer.writeFixed(0x7FFFFFFF);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0xFF));
          expect(bytes[1], equals(0xFF));
          expect(bytes[2], equals(0xFF));
          expect(bytes[3], equals(0x7F));
        });

        test('handles min fixed-point (-32768.0)', () {
          // Min negative fixed-point is 0x80000000
          writer.writeFixed(-2147483648);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0x00));
          expect(bytes[1], equals(0x00));
          expect(bytes[2], equals(0x00));
          expect(bytes[3], equals(0x80));
        });
      });

      group('writeString', () {
        test('writes null-padded string', () {
          writer.writeString('ABC', 8);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(8));
          expect(bytes[0], equals(0x41)); // 'A'
          expect(bytes[1], equals(0x42)); // 'B'
          expect(bytes[2], equals(0x43)); // 'C'
          expect(bytes[3], equals(0x00)); // null padding
          expect(bytes[7], equals(0x00));
        });

        test('truncates long strings', () {
          writer.writeString('ABCDEFGHIJ', 4);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(4));
          expect(bytes[0], equals(0x41));
          expect(bytes[3], equals(0x44)); // 'D'
        });

        test('handles empty string', () {
          writer.writeString('', 4);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(4));
          expect(bytes[0], equals(0x00));
          expect(bytes[3], equals(0x00));
        });

        test('handles exact length string (no truncation)', () {
          writer.writeString('ABCD', 4);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(4));
          expect(bytes[0], equals(0x41));
          expect(bytes[3], equals(0x44));
        });

        test('handles maxLength of 1', () {
          writer.writeString('Hello', 1);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(1));
          expect(bytes[0], equals(0x48)); // 'H'
        });
      });

      group('writeBool', () {
        test('writes 1 for true', () {
          writer.writeBool(value: true);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(1));
        });

        test('writes 0 for false', () {
          writer.writeBool(value: false);
          final bytes = writer.toBytes();
          expect(bytes[0], equals(0));
        });
      });

      group('writeBytes', () {
        test('writes raw bytes', () {
          writer.writeBytes([0x01, 0x02, 0x03]);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(3));
          expect(bytes[0], equals(0x01));
          expect(bytes[1], equals(0x02));
          expect(bytes[2], equals(0x03));
        });

        test('handles empty byte list', () {
          writer.writeBytes([]);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(0));
        });

        test('handles all byte values 0x00-0xFF', () {
          final allBytes = List.generate(256, (i) => i);
          writer.writeBytes(allBytes);
          final bytes = writer.toBytes();
          expect(bytes.length, equals(256));
          for (var i = 0; i < 256; i++) {
            expect(bytes[i], equals(i));
          }
        });
      });

      group('pad', () {
        test('aligns to 4-byte boundary from 1', () {
          writer.writeByte(0x01);
          writer.pad();
          expect(writer.position, equals(4));
        });

        test('aligns to 4-byte boundary from 2', () {
          writer.writeShort(0x0102);
          writer.pad();
          expect(writer.position, equals(4));
        });

        test('aligns to 4-byte boundary from 3', () {
          writer
            ..writeByte(0x01)
            ..writeByte(0x02)
            ..writeByte(0x03);
          writer.pad();
          expect(writer.position, equals(4));
        });

        test('does nothing when already aligned at 4', () {
          writer.writeInt(0x12345678);
          final posBefore = writer.position;
          writer.pad();
          expect(writer.position, equals(posBefore));
        });

        test('does nothing when already aligned at 0', () {
          writer.pad();
          expect(writer.position, equals(0));
        });

        test('aligns to next boundary from 5', () {
          writer
            ..writeInt(0x12345678)
            ..writeByte(0x01);
          writer.pad();
          expect(writer.position, equals(8));
        });
      });

      group('position', () {
        test('starts at 0', () {
          expect(writer.position, equals(0));
        });

        test('tracks bytes written', () {
          writer.writeByte(0x01);
          expect(writer.position, equals(1));
          writer.writeShort(0x1234);
          expect(writer.position, equals(3));
          writer.writeInt(0x12345678);
          expect(writer.position, equals(7));
        });
      });
    });

    group('BinaryDataReader', () {
      group('readByte', () {
        test('reads single byte', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x42]));
          expect(reader.readByte(), equals(0x42));
        });

        test('reads 0x00', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x00]));
          expect(reader.readByte(), equals(0x00));
        });

        test('reads 0xFF', () {
          final reader = BinaryDataReader(Uint8List.fromList([0xFF]));
          expect(reader.readByte(), equals(0xFF));
        });
      });

      group('readShort', () {
        test('reads 16-bit little-endian', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x34, 0x12]));
          expect(reader.readShort(), equals(0x1234));
        });

        test('returns signed value for -1', () {
          final reader = BinaryDataReader(Uint8List.fromList([0xFF, 0xFF]));
          expect(reader.readShort(), equals(-1));
        });

        test('reads min signed 16-bit (-32768)', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x00, 0x80]));
          expect(reader.readShort(), equals(-32768));
        });

        test('reads max signed 16-bit (32767)', () {
          final reader = BinaryDataReader(Uint8List.fromList([0xFF, 0x7F]));
          expect(reader.readShort(), equals(32767));
        });

        test('reads zero', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x00, 0x00]));
          expect(reader.readShort(), equals(0));
        });
      });

      group('readInt', () {
        test('reads 32-bit little-endian', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
          expect(reader.readInt(), equals(0x12345678));
        });

        test('returns signed value for -1', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF]));
          expect(reader.readInt(), equals(-1));
        });

        test('reads min signed 32-bit (-2147483648)', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x00, 0x00, 0x00, 0x80]));
          expect(reader.readInt(), equals(-2147483648));
        });

        test('reads max signed 32-bit (2147483647)', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0x7F]));
          expect(reader.readInt(), equals(2147483647));
        });

        test('reads zero', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x00, 0x00, 0x00, 0x00]));
          expect(reader.readInt(), equals(0));
        });
      });

      group('readFixed', () {
        test('reads 32-bit fixed-point', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x00, 0x00, 0x01, 0x00]));
          expect(reader.readFixed(), equals(65536)); // 1.0 in fixed-point
        });

        test('reads 0.5 fixed-point (32768)', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x00, 0x80, 0x00, 0x00]));
          expect(reader.readFixed(), equals(32768));
        });

        test('reads negative fixed-point (-1.0)', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x00, 0x00, 0xFF, 0xFF]));
          expect(reader.readFixed(), equals(-65536));
        });
      });

      group('readString', () {
        test('reads null-terminated string', () {
          final reader = BinaryDataReader(
            Uint8List.fromList([0x41, 0x42, 0x43, 0x00, 0x00, 0x00, 0x00, 0x00]),
          );
          expect(reader.readString(8), equals('ABC'));
        });

        test('reads full-length string without null terminator', () {
          final reader = BinaryDataReader(
            Uint8List.fromList([0x41, 0x42, 0x43, 0x44]),
          );
          expect(reader.readString(4), equals('ABCD'));
        });

        test('reads empty string (all nulls)', () {
          final reader = BinaryDataReader(
            Uint8List.fromList([0x00, 0x00, 0x00, 0x00]),
          );
          expect(reader.readString(4), equals(''));
        });
      });

      group('readBool', () {
        test('returns true for 1', () {
          final reader = BinaryDataReader(Uint8List.fromList([1]));
          expect(reader.readBool(), isTrue);
        });

        test('returns false for 0', () {
          final reader = BinaryDataReader(Uint8List.fromList([0]));
          expect(reader.readBool(), isFalse);
        });

        test('returns true for any non-zero value', () {
          final reader = BinaryDataReader(Uint8List.fromList([255]));
          expect(reader.readBool(), isTrue);
        });
      });

      group('readBytes', () {
        test('reads raw bytes', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x01, 0x02, 0x03]));
          expect(reader.readBytes(3), equals([0x01, 0x02, 0x03]));
        });

        test('reads zero bytes', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01, 0x02]));
          expect(reader.readBytes(0), equals([]));
        });

        test('reads all byte values 0x00-0xFF', () {
          final allBytes = Uint8List.fromList(List.generate(256, (i) => i));
          final reader = BinaryDataReader(allBytes);
          final result = reader.readBytes(256);
          for (var i = 0; i < 256; i++) {
            expect(result[i], equals(i));
          }
        });
      });

      group('skipPadding', () {
        test('advances to 4-byte boundary from 1', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x01, 0, 0, 0, 0x02]));
          reader.readByte();
          reader.skipPadding();
          expect(reader.position, equals(4));
          expect(reader.readByte(), equals(0x02));
        });

        test('advances to 4-byte boundary from 2', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x01, 0x02, 0, 0, 0x03]));
          reader
            ..readByte()
            ..readByte();
          reader.skipPadding();
          expect(reader.position, equals(4));
        });

        test('advances to 4-byte boundary from 3', () {
          final reader = BinaryDataReader(
              Uint8List.fromList([0x01, 0x02, 0x03, 0, 0x04]));
          reader
            ..readByte()
            ..readByte()
            ..readByte();
          reader.skipPadding();
          expect(reader.position, equals(4));
        });

        test('does nothing when already aligned', () {
          final reader = BinaryDataReader(
              Uint8List.fromList([0x01, 0x02, 0x03, 0x04, 0x05]));
          reader.readInt();
          reader.skipPadding();
          expect(reader.position, equals(4));
        });
      });

      group('isAtEnd', () {
        test('returns false initially when data exists', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01]));
          expect(reader.isAtEnd, isFalse);
        });

        test('returns true when exhausted', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01]));
          reader.readByte();
          expect(reader.isAtEnd, isTrue);
        });

        test('returns true for empty data', () {
          final reader = BinaryDataReader(Uint8List.fromList([]));
          expect(reader.isAtEnd, isTrue);
        });
      });

      group('error handling', () {
        test('throws on readByte past end', () {
          final reader = BinaryDataReader(Uint8List.fromList([]));
          expect(() => reader.readByte(), throwsStateError);
        });

        test('throws on readShort past end', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01]));
          expect(() => reader.readShort(), throwsStateError);
        });

        test('throws on readInt past end', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01, 0x02]));
          expect(() => reader.readInt(), throwsStateError);
        });

        test('throws on readFixed past end', () {
          final reader =
              BinaryDataReader(Uint8List.fromList([0x01, 0x02, 0x03]));
          expect(() => reader.readFixed(), throwsStateError);
        });

        test('throws on readString past end', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x41, 0x42]));
          expect(() => reader.readString(5), throwsStateError);
        });

        test('throws on readBytes past end', () {
          final reader = BinaryDataReader(Uint8List.fromList([0x01, 0x02]));
          expect(() => reader.readBytes(5), throwsStateError);
        });
      });
    });

    group('roundtrip serialization', () {
      test('byte roundtrip preserves all values 0x00-0xFF', () {
        final writer = BinaryDataWriter();
        for (var i = 0; i < 256; i++) {
          writer.writeByte(i);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (var i = 0; i < 256; i++) {
          expect(reader.readByte(), equals(i));
        }
      });

      test('short roundtrip preserves boundary values', () {
        final writer = BinaryDataWriter();
        const values = [
          0, // Zero
          1, // Positive
          -1, // Negative
          32767, // Max signed 16-bit
          -32768, // Min signed 16-bit
          0x7FFF, // Max positive
          0x1234, // Arbitrary positive
        ];

        for (final v in values) {
          writer.writeShort(v);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (final v in values) {
          expect(reader.readShort(), equals(v.toSigned(16)),
              reason: 'Failed for value $v');
        }
      });

      test('int roundtrip preserves boundary values', () {
        final writer = BinaryDataWriter();
        const values = [
          0, // Zero
          1, // Positive
          -1, // Negative
          2147483647, // Max signed 32-bit
          -2147483648, // Min signed 32-bit
          0x7FFFFFFF, // Max positive
          0x12345678, // Arbitrary positive
          -12345678, // Arbitrary negative
        ];

        for (final v in values) {
          writer.writeInt(v);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (final v in values) {
          expect(reader.readInt(), equals(v.toSigned(32)),
              reason: 'Failed for value $v');
        }
      });

      test('fixed roundtrip preserves DOOM fixed-point values', () {
        final writer = BinaryDataWriter();
        const fracUnit = 65536; // FRACUNIT
        final values = [
          0, // 0.0
          fracUnit, // 1.0
          fracUnit ~/ 2, // 0.5
          -fracUnit, // -1.0
          fracUnit * 100, // 100.0
          -fracUnit * 100, // -100.0
          0x7FFFFFFF, // Max fixed-point
          -2147483648, // Min fixed-point (0x80000000)
          fracUnit + 32768, // 1.5
        ];

        for (final v in values) {
          writer.writeFixed(v);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (final v in values) {
          expect(reader.readFixed(), equals(v.toSigned(32)),
              reason: 'Failed for fixed value $v');
        }
      });

      test('string roundtrip preserves values', () {
        final writer = BinaryDataWriter();
        const strings = [
          'Test', // Normal string
          '', // Empty string
          'ABCDEFGH', // 8 chars
        ];

        for (final s in strings) {
          writer.writeString(s, 8);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (final s in strings) {
          expect(reader.readString(8), equals(s),
              reason: 'Failed for string "$s"');
        }
      });

      test('bool roundtrip preserves values', () {
        final writer = BinaryDataWriter();
        final values = [true, false, true, true, false];

        for (final v in values) {
          writer.writeBool(value: v);
        }

        final reader = BinaryDataReader(writer.toBytes());
        for (final v in values) {
          expect(reader.readBool(), equals(v));
        }
      });

      test('mixed data roundtrip preserves all values', () {
        final writer = BinaryDataWriter();
        writer
          ..writeByte(0x42)
          ..writeShort(-1234)
          ..writeInt(0x12345678)
          ..writeFixed(65536)
          ..writeString('Test', 8)
          ..writeBool(value: true)
          ..writeBool(value: false)
          ..writeBytes([0x01, 0x02, 0x03, 0x04]);

        final reader = BinaryDataReader(writer.toBytes());
        expect(reader.readByte(), equals(0x42));
        expect(reader.readShort(), equals(-1234));
        expect(reader.readInt(), equals(0x12345678));
        expect(reader.readFixed(), equals(65536));
        expect(reader.readString(8), equals('Test'));
        expect(reader.readBool(), isTrue);
        expect(reader.readBool(), isFalse);
        expect(reader.readBytes(4), equals([0x01, 0x02, 0x03, 0x04]));
        expect(reader.isAtEnd, isTrue);
      });

      test('padding roundtrip maintains alignment', () {
        final writer = BinaryDataWriter();
        writer
          ..writeByte(0x01)
          ..pad()
          ..writeInt(0x12345678)
          ..writeByte(0x02)
          ..pad()
          ..writeShort(0x5678);

        final reader = BinaryDataReader(writer.toBytes());
        expect(reader.readByte(), equals(0x01));
        reader.skipPadding();
        expect(reader.position, equals(4));
        expect(reader.readInt(), equals(0x12345678));
        expect(reader.readByte(), equals(0x02));
        reader.skipPadding();
        expect(reader.position, equals(12));
        expect(reader.readShort(), equals(0x5678));
      });
    });

    group('createReader from serializer', () {
      test('creates reader from Uint8List', () {
        final data = Uint8List.fromList([0x01, 0x02, 0x03, 0x04]);
        final reader = serializer.createReader(data);
        expect(reader.readInt(), equals(0x04030201));
      });
    });
  });
}
